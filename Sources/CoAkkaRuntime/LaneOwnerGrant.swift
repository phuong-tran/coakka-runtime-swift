import CoAkkaRuntimeC
import Foundation

private let laneOwnerGrantFeature: UInt32 = 1 << 25

/// Stable identity and directly reachable host for one exact lane replica.
public struct LaneOwnerConfig: Sendable, Codable {
  public var ownerInstanceID: String
  public var advertisedHost: String

  public init(ownerInstanceID: String, advertisedHost: String) {
    self.ownerInstanceID = ownerInstanceID
    self.advertisedHost = advertisedHost
  }

  func validate() throws {
    try validateVisibleASCII(ownerInstanceID, name: "ownerInstanceID", maximum: 127)
    try validateVisibleASCII(advertisedHost, name: "advertisedHost", maximum: 255)
  }
}

/// Direct endpoint of the owner that retains a prepared lane record.
public struct LaneOwnerEndpoint: Sendable, Codable, CustomStringConvertible {
  public let ownerInstanceID: String
  public let advertisedHost: String
  public let port: UInt16

  public init(ownerInstanceID: String, advertisedHost: String, port: UInt16) {
    self.ownerInstanceID = ownerInstanceID
    self.advertisedHost = advertisedHost
    self.port = port
  }

  func validate() throws {
    try validateVisibleASCII(ownerInstanceID, name: "ownerInstanceID", maximum: 127)
    try validateVisibleASCII(advertisedHost, name: "advertisedHost", maximum: 255)
    guard port != 0 else { throw RuntimeError.invalidArgument("owner port must be non-zero") }
  }

  public var description: String {
    "LaneOwnerEndpoint(ownerInstanceID: \(ownerInstanceID), advertisedHost: \(advertisedHost), port: \(port))"
  }
}

func requireLaneOwnerGrants(_ library: NativeRuntimeLibrary) throws {
  let handle = try library.requireHandle()
  var info = coakka_swift_runtime_info_t()
  info.struct_size = MemoryLayout.size(ofValue: info)
  try throwIfNativeError(coakka_swift_runtime_get_info(handle, &info), operation: "runtime_get_info")
  guard info.feature_flags & laneOwnerGrantFeature != 0,
    coakka_swift_lane_owner_grants_available(handle) != 0
  else { throw RuntimeError.loadFailed("native runtime does not export lane-owner grants") }
}

func validateVisibleASCII(_ value: String, name: String, maximum: Int) throws {
  let bytes = Array(value.utf8)
  guard !bytes.isEmpty, bytes.count <= maximum, bytes.allSatisfy({ $0 >= 0x21 && $0 <= 0x7e })
  else {
    throw RuntimeError.invalidArgument("\(name) must contain 1...\(maximum) visible ASCII bytes")
  }
}

func fixedString<T>(_ value: inout T) -> String {
  withUnsafeBytes(of: &value) { raw in
    String(decoding: raw.prefix { $0 != 0 }, as: UTF8.self)
  }
}
