import CoAkkaRuntimeC
import Foundation

/// Stable identity and directly reachable host for one exact lane replica.
public struct LaneOwnerConfig: Sendable, Codable {
  public var ownerInstanceID: String
  public var advertisedHost: String

  public init(ownerInstanceID: String, advertisedHost: String) {
    self.ownerInstanceID = ownerInstanceID
    self.advertisedHost = advertisedHost
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
  public var description: String {
    "LaneOwnerEndpoint(ownerInstanceID: \(ownerInstanceID), advertisedHost: \(advertisedHost), port: \(port))"
  }
}

func requireLaneOwnerGrants(_ library: NativeRuntimeLibrary) throws {
  let handle = try library.requireHandle()
  try requireCoreFeature(handle, query: coakka_swift_lane_owner_grants_available, operation: "query Core lane-owner grants")
}

func fixedString<T>(_ value: inout T) -> String {
  withUnsafeBytes(of: &value) { raw in
    String(decoding: raw.prefix { $0 != 0 }, as: UTF8.self)
  }
}
