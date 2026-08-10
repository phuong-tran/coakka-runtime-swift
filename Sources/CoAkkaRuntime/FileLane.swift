import CoAkkaRuntimeC
import Foundation

/// Direction capabilities enabled when opening a file lane.
public struct FileLaneFlags: OptionSet, Sendable {
  public let rawValue: UInt32
  public init(rawValue: UInt32) { self.rawValue = rawValue }
  public static let sender = Self(rawValue: 1)
  public static let receiver = Self(rawValue: 1 << 1)
}
/// Transport protection; per-transfer authorization remains mandatory.
public enum FileLaneSecurityMode: UInt32, Sendable {
  case direct = 0
  case tls = 1
  case mutualTLS = 2
}
/// Side of a retained transfer record.
public enum FileTransferDirection: UInt32, Sendable {
  case send = 1
  case receive = 2
}
/// Observable file-transfer lifecycle state.
public enum FileTransferState: UInt32, Sendable {
  case prepared = 1
  case queued, connecting, transferring, verifying, completed, paused, rejected, failed, canceled
}
/// Stable terminal outcome reported independently by each peer.
public enum FileTransferResult: UInt32, Sendable {
  case none = 0
  case ok, notPrepared, tokenMismatch, metadataMismatch, sizeLimit, storageIO, integrityMismatch,
    networkIO, timeout, queueFull, protocolError, sourceChanged, internalError, canceledByHost,
    tlsConfigInvalid, tlsHandshakeFailed, peerCertUntrusted, peerCertExpired, peerIdentityMismatch,
    clientCertRequired
}

/// TLS material read at lane startup. Never log key paths or transfer tokens.
public struct FileLaneSecurityConfig: Sendable {
  public var mode: FileLaneSecurityMode = .direct
  public var credentialGeneration: UInt64 = 0
  public var credentialID = ""
  public var caCertificateFile = ""
  public var identityCertificateFile = ""
  public var privateKeyFile = ""
  public init() {}
}
/// Bounded lane configuration. Zero tuning fields select core-runtime defaults.
/// Size fields are bytes, time fields are milliseconds, and `bindPort == 0`
/// requests an ephemeral receiver port.
public struct FileLaneConfig: Sendable {
  public var flags: FileLaneFlags = [.sender, .receiver]
  public var bindHost = "127.0.0.1"
  public var bindPort: UInt16 = 0
  public var queueCapacity = 0
  public var maxFileSize: UInt64 = 0
  public var ioTimeoutMs: UInt32 = 0
  public var checkpointBytes: UInt64 = 0
  public var progressBytes: UInt64 = 0
  public var progressIntervalMs: UInt32 = 0
  public var senderWorkerCount: UInt32 = 0
  public var receiverWorkerCount: UInt32 = 0
  public var security: FileLaneSecurityConfig?
  public init() {}
}
/// Receiver authorization and exact content identity for one transfer.
public struct FileReceiveSpec: Sendable {
  public var transferID: String
  public var authorizationToken: String
  public var destinationPath: String
  public var expectedSize: UInt64
  public var expectedSHA256: Data
  public init(
    transferID: String, authorizationToken: String, destinationPath: String, expectedSize: UInt64,
    expectedSHA256: Data
  ) {
    self.transferID = transferID
    self.authorizationToken = authorizationToken
    self.destinationPath = destinationPath
    self.expectedSize = expectedSize
    self.expectedSHA256 = expectedSHA256
  }
}
/// Source and receiver endpoint for one previously prepared transfer.
public struct FileSendSpec: Sendable {
  public var transferID: String
  public var authorizationToken: String
  public var remoteHost: String
  public var remotePort: UInt16
  public var sourcePath: String
  public var expectedSize: UInt64
  public var expectedSHA256: Data
  public var timeoutMs: UInt32 = 0
  public init(
    transferID: String, authorizationToken: String, remoteHost: String, remotePort: UInt16,
    sourcePath: String, expectedSize: UInt64, expectedSHA256: Data
  ) {
    self.transferID = transferID
    self.authorizationToken = authorizationToken
    self.remoteHost = remoteHost
    self.remotePort = remotePort
    self.sourcePath = sourcePath
    self.expectedSize = expectedSize
    self.expectedSHA256 = expectedSHA256
  }
}
/// A file SHA-256 and exact byte count.
public struct FileDigest: Equatable, Sendable {
  public let sha256: Data
  public let size: UInt64
}
/// Immutable progress view with process-local monotonic timestamps.
/// `progressMilli` ranges from 0 to 100000 (100.000%) and `updateSequence`
/// advances whenever retained state changes.
public struct FileTransferSnapshot: Sendable {
  public let direction: FileTransferDirection
  public let state: FileTransferState
  public let result: FileTransferResult
  public let expectedSize: UInt64
  public let transferredBytes: UInt64
  public let committedOffset: UInt64
  public let progressMilli: UInt32
  public let cancelRequested: Bool
  public let updateSequence: UInt64
  public let submittedMonoNs: UInt64
  public let startedMonoNs: UInt64
  public let updatedMonoNs: UInt64
  public let terminalMonoNs: UInt64
  public let detail: String
  public var terminal: Bool { state.rawValue >= FileTransferState.completed.rawValue }
  public var succeeded: Bool { state == .completed && result == .ok }
}
/// Bounded queue, active-work, terminal-count, and completed-byte counters.
public struct FileLaneStats: Sendable {
  public let queueCapacity, queuedSends, preparedReceives, activeSends, activeReceives,
    retainedRecords: Int
  public let submittedSends, preparedReceiveCount, completedSends, completedReceives, failedSends,
    failedReceives, canceledTransfers, completedSendBytes, completedReceiveBytes: UInt64
}

/// An independent bulk-transfer lane backed by the CoAkka core-runtime.
///
/// Prepare the receiver before submitting the sender. Continue `waitTransfer`
/// from each update sequence until both peers report success, then forget
/// retained records. `close()` stops the lane, wakes waits, and drains calls.
/// File bytes do not belong in runtime `Envelope` payloads.
public final class FileLane: @unchecked Sendable {
  // SAFETY: every mutable lifecycle field is serialized by `condition`; the
  // immutable library handle outlives all calls and close drains `activeCalls`.
  private let library: NativeRuntimeLibrary
  private let condition = NSCondition()
  private var lane: OpaquePointer?
  private var closing = false
  private var activeCalls = 0
  private init(library: NativeRuntimeLibrary, lane: OpaquePointer) {
    self.library = library
    self.lane = lane
  }
  /// Opens and starts a lane, failing when file transfer is unavailable.
  /// - Parameters:
  ///   - config: Bounded capabilities, workers, progress, and security settings.
  ///   - runtimeLibPath: Explicit core-runtime path, or `nil` for connector resolution.
  public static func open(
    _ config: FileLaneConfig = FileLaneConfig(), runtimeLibPath: String? = nil
  ) throws -> FileLane {
    let allowedFlags = FileLaneFlags.sender.rawValue | FileLaneFlags.receiver.rawValue
    guard !config.flags.isEmpty, config.flags.rawValue & ~allowedFlags == 0,
      config.senderWorkerCount <= 4, config.receiverWorkerCount <= 4
    else { throw RuntimeError.invalidArgument("invalid file-lane flags or worker count") }
    let library = try NativeRuntimeLibrary(path: runtimeNativePath(explicitPath: runtimeLibPath))
    let handle = try library.requireHandle()
    guard coakka_swift_file_lane_available(handle) != 0 else {
      throw RuntimeError.loadFailed("native runtime does not export file-lane ABI")
    }
    let strings = CStringOwner([
      config.bindHost, config.security?.credentialID ?? "",
      config.security?.caCertificateFile ?? "", config.security?.identityCertificateFile ?? "",
      config.security?.privateKeyFile ?? "",
    ])
    var security = coakka_swift_file_lane_security_config_t()
    if let value = config.security {
      security.struct_size = MemoryLayout.size(ofValue: security)
      security.mode = value.mode.rawValue
      security.credential_generation = value.credentialGeneration
      security.credential_id = UnsafePointer(strings[1])
      security.ca_certificate_file = UnsafePointer(strings[2])
      security.identity_certificate_file = UnsafePointer(strings[3])
      security.private_key_file = UnsafePointer(strings[4])
    }
    var native = coakka_swift_file_lane_config_t()
    native.struct_size = MemoryLayout.size(ofValue: native)
    native.flags = config.flags.rawValue
    native.bind_host = UnsafePointer(strings[0])
    native.bind_port = config.bindPort
    native.queue_capacity = config.queueCapacity
    native.max_file_size = config.maxFileSize
    native.io_timeout_ms = config.ioTimeoutMs
    native.checkpoint_bytes = config.checkpointBytes
    native.progress_bytes = config.progressBytes
    native.progress_interval_ms = config.progressIntervalMs
    native.sender_worker_count = config.senderWorkerCount
    native.receiver_worker_count = config.receiverWorkerCount
    var out: OpaquePointer?
    let createStatus: Int32
    if config.security != nil {
      createStatus = withUnsafePointer(to: &security) {
        native.security = $0
        return coakka_swift_file_lane_create(handle, &native, &out)
      }
    } else {
      createStatus = coakka_swift_file_lane_create(handle, &native, &out)
    }
    try throwIfNativeError(createStatus, operation: "file_lane_create")
    guard let out else { throw RuntimeError.nativeStatus(-2, "file_lane_create") }
    let start = coakka_swift_file_lane_start(handle, out)
    if start != 0 {
      coakka_swift_file_lane_destroy(handle, out)
      try throwIfNativeError(start, operation: "file_lane_start")
    }
    return FileLane(library: library, lane: out)
  }
  /// Computes the exact source identity through the selected core-runtime.
  /// - Parameters:
  ///   - path: Readable regular file to hash.
  ///   - runtimeLibPath: Explicit core-runtime path, or `nil` for connector resolution.
  public static func sha256(path: String, runtimeLibPath: String? = nil) throws -> FileDigest {
    let library = try NativeRuntimeLibrary(path: runtimeNativePath(explicitPath: runtimeLibPath))
    let handle = try library.requireHandle()
    var bytes = [UInt8](repeating: 0, count: 32)
    var size: UInt64 = 0
    let status = path.withCString { p in
      bytes.withUnsafeMutableBufferPointer {
        coakka_swift_file_sha256_path(handle, p, $0.baseAddress, &size)
      }
    }
    try throwIfNativeError(status, operation: "file_sha256_path")
    return FileDigest(sha256: Data(bytes), size: size)
  }
  /// Receiver port selected when the lane started.
  public var boundPort: UInt16 {
    get throws {
      try withLane { h, l in
        var out: UInt16 = 0
        try throwIfNativeError(
          coakka_swift_file_lane_get_bound_port(h, l, &out), operation: "file_lane_get_bound_port")
        return out
      }
    }
  }
  /// Authorizes one destination and expected content identity.
  /// - Parameter spec: Local destination, one-use grant, exact byte size, and SHA-256.
  public func prepareReceive(_ spec: FileReceiveSpec) throws {
    guard spec.expectedSHA256.count == 32 else {
      throw RuntimeError.invalidArgument("expectedSHA256 must contain 32 bytes")
    }
    try withLane { h, l in
      let c = CStringOwner([spec.transferID, spec.authorizationToken, spec.destinationPath])
      try spec.expectedSHA256.withUnsafeBytes { b in
        try throwIfNativeError(
          coakka_swift_file_lane_prepare_receive(
            h, l, c[0], c[1], c[2], spec.expectedSize,
            b.bindMemory(to: UInt8.self).baseAddress),
          operation: "file_lane_prepare_receive")
      }
    }
  }
  /// Queues a send after the remote application prepares the receive.
  /// - Parameter spec: Source plus the endpoint and grant returned by the receiver.
  public func submitSend(_ spec: FileSendSpec) throws {
    guard spec.expectedSHA256.count == 32, spec.remotePort > 0 else {
      throw RuntimeError.invalidArgument("invalid send spec")
    }
    try withLane { h, l in
      let c = CStringOwner([
        spec.transferID, spec.authorizationToken, spec.remoteHost, spec.sourcePath,
      ])
      try spec.expectedSHA256.withUnsafeBytes { b in
        try throwIfNativeError(
          coakka_swift_file_lane_submit_send(
            h, l, c[0], c[1], c[2], spec.remotePort, c[3], spec.expectedSize,
            b.bindMemory(to: UInt8.self).baseAddress, spec.timeoutMs),
          operation: "file_lane_submit_send")
      }
    }
  }
  /// Returns the current copied snapshot without waiting.
  /// - Parameters:
  ///   - transferID: Application correlation ID used by both peers.
  ///   - direction: Sender or receiver record to observe.
  public func transfer(_ transferID: String, direction: FileTransferDirection) throws
    -> FileTransferSnapshot
  { try read(transferID, direction, 0, 0, false) }
  /// Blocks until the sequence advances, the timeout expires, or the lane stops.
  public func waitTransfer(
    _ transferID: String, direction: FileTransferDirection, afterSequence: UInt64 = 0,
    timeoutMs: UInt32 = 30_000
  ) throws -> FileTransferSnapshot {
    try read(transferID, direction, afterSequence, timeoutMs, true)
  }
  private func read(
    _ id: String, _ d: FileTransferDirection, _ seq: UInt64, _ ms: UInt32, _ wait: Bool
  ) throws -> FileTransferSnapshot {
    try withLane { h, l in
      var n = coakka_swift_file_transfer_snapshot_t()
      let status = id.withCString {
        wait
          ? coakka_swift_file_lane_wait_transfer(h, l, $0, d.rawValue, seq, ms, &n)
          : coakka_swift_file_lane_get_transfer(h, l, $0, d.rawValue, &n)
      }
      try throwIfNativeError(status, operation: "file_lane_transfer")
      var detail = n.detail
      let text = withUnsafeBytes(of: &detail) { raw -> String in
        let bytes = raw.prefix { $0 != 0 }
        return String(decoding: bytes, as: UTF8.self)
      }
      return FileTransferSnapshot(
        direction: FileTransferDirection(rawValue: n.direction)!,
        state: FileTransferState(rawValue: n.state)!,
        result: FileTransferResult(rawValue: n.result)!, expectedSize: n.expected_size,
        transferredBytes: n.transferred_bytes, committedOffset: n.committed_offset,
        progressMilli: n.progress_milli, cancelRequested: n.cancel_requested != 0,
        updateSequence: n.update_sequence, submittedMonoNs: n.submitted_mono_ns,
        startedMonoNs: n.started_mono_ns, updatedMonoNs: n.updated_mono_ns,
        terminalMonoNs: n.terminal_mono_ns, detail: text)
    }
  }
  /// Requests cooperative cancellation; observe terminal state before forget.
  public func cancel(_ transferID: String, direction: FileTransferDirection) throws {
    try control(transferID, direction, false)
  }
  /// Releases one retained terminal record after recording its outcome.
  public func forget(_ transferID: String, direction: FileTransferDirection) throws {
    try control(transferID, direction, true)
  }
  private func control(_ id: String, _ d: FileTransferDirection, _ forget: Bool) throws {
    try withLane { h, l in
      try id.withCString {
        try throwIfNativeError(
          forget
            ? coakka_swift_file_lane_forget(h, l, $0, d.rawValue)
            : coakka_swift_file_lane_cancel(h, l, $0, d.rawValue), operation: "file_lane_control")
      }
    }
  }
  /// Returns a copied lane-level observability snapshot.
  public func stats() throws -> FileLaneStats {
    try withLane { h, l in
      var n = coakka_swift_file_lane_stats_t()
      try throwIfNativeError(
        coakka_swift_file_lane_get_stats(h, l, &n), operation: "file_lane_get_stats")
      return FileLaneStats(
        queueCapacity: n.queue_capacity, queuedSends: n.queued_sends,
        preparedReceives: n.prepared_receives, activeSends: n.active_sends,
        activeReceives: n.active_receives, retainedRecords: n.retained_records,
        submittedSends: n.submitted_sends, preparedReceiveCount: n.prepared_receive_count,
        completedSends: n.completed_sends, completedReceives: n.completed_receives,
        failedSends: n.failed_sends, failedReceives: n.failed_receives,
        canceledTransfers: n.canceled_transfers, completedSendBytes: n.completed_send_bytes,
        completedReceiveBytes: n.completed_receive_bytes)
    }
  }
  /// Stops the lane, wakes blocked waits, drains calls, and releases native state.
  public func close() throws {
    condition.lock()
    guard let value = lane else {
      condition.unlock()
      return
    }
    if closing {
      while lane != nil { condition.wait() }
      condition.unlock()
      return
    }
    closing = true
    condition.unlock()
    let h = try library.requireHandle()
    let status = coakka_swift_file_lane_stop(h, value)
    condition.lock()
    while activeCalls != 0 { condition.wait() }
    coakka_swift_file_lane_destroy(h, value)
    lane = nil
    condition.broadcast()
    condition.unlock()
    if status != 0 && status != -7 { try throwIfNativeError(status, operation: "file_lane_stop") }
  }
  deinit { try? close() }
  private func withLane<T>(_ body: (OpaquePointer, OpaquePointer) throws -> T) throws -> T {
    condition.lock()
    guard !closing, let lane else {
      condition.unlock()
      throw RuntimeError.closed
    }
    activeCalls += 1
    condition.unlock()
    defer {
      condition.lock()
      activeCalls -= 1
      if activeCalls == 0 { condition.broadcast() }
      condition.unlock()
    }
    return try body(try library.requireHandle(), lane)
  }
}

private final class CStringOwner {
  private var pointers: [UnsafeMutablePointer<CChar>] = []
  init(_ values: [String]) {
    for value in values {
      let bytes = value.utf8CString
      let pointer = UnsafeMutablePointer<CChar>.allocate(capacity: bytes.count)
      bytes.withUnsafeBufferPointer { source in
        pointer.initialize(from: source.baseAddress!, count: bytes.count)
      }
      pointers.append(pointer)
    }
  }
  deinit { for pointer in pointers { pointer.deallocate() } }
  subscript(_ index: Int) -> UnsafePointer<CChar> { UnsafePointer(pointers[index]) }
}
