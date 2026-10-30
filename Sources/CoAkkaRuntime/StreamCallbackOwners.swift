import CoAkkaRuntimeC

struct StreamCallbackKey: Hashable {
  let id: String
  let direction: StreamDirection
}

// The Stream owner's existing condition serializes mutations. These are ARC
// roots and received outcomes, not a connector reconstruction of native state.
final class StreamCallbackOwners {
  final class Entry {
    let root: AnyObject
    var previous: Entry?
    var status: Int32?
    init(_ root: AnyObject, previous: Entry?) { self.root = root; self.previous = previous }
  }
  let limit: Int
  private var entries: [StreamCallbackKey: Entry]
  private var retiredKeys: [StreamCallbackKey] = []

  init(capacity: Int) throws {
    guard capacity > 0, capacity < Int.max else {
      throw RuntimeError.contractViolation("Core returned an unrepresentable Stream callback capacity")
    }
    limit = capacity + 1
    entries = Dictionary(minimumCapacity: limit)
    retiredKeys.reserveCapacity(limit)
  }

  func admit(_ key: StreamCallbackKey, root: AnyObject, call: () throws -> Int32,
    presence: (StreamCallbackKey) -> Int32, retired: inout [AnyObject]) throws -> Int32 {
    let previous = entries[key]
    if let previous, previous.status == nil {
      throw RuntimeError.contractViolation("Stream callback outcome unresolved; successful forget or close required")
    }
    if previous == nil && entries.count == limit {
      prune(presence, retired: &retired)
      guard entries.count < limit else {
        throw RuntimeError.resourceLimit("Stream callback ownership storage exhausted")
      }
    }
    let candidate = Entry(root, previous: previous)
    entries[key] = candidate // Strong publication precedes native admission.
    let status = try call() // An unreceived outcome retains candidate+previous.
    candidate.status = status
    if status != 0 {
      entries[key] = previous
      retired.append(candidate)
    } else {
      if let previous { retired.append(previous) }
      candidate.previous = nil
      prune(presence, retired: &retired)
    }
    return status
  }

  private func prune(_ presence: (StreamCallbackKey) -> Int32, retired: inout [AnyObject]) {
    retiredKeys.removeAll(keepingCapacity: true)
    for (key, entry) in entries where entry.status != nil {
      if presence(key) == Int32(COAKKA_V2_ERR_BAD_STATE.rawValue) { retiredKeys.append(key) }
    }
    for key in retiredKeys {
      if let entry = entries.removeValue(forKey: key) { retired.append(entry) }
    }
    retiredKeys.removeAll(keepingCapacity: true)
  }

  func forget(_ key: StreamCallbackKey, retired: inout [AnyObject]) {
    if let entry = entries.removeValue(forKey: key) { retired.append(entry) }
  }

  func detach() -> [StreamCallbackKey: Entry] {
    let retired = entries
    entries = [:]
    return retired
  }
}
