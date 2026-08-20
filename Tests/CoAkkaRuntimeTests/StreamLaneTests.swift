import Foundation
import XCTest

@testable import CoAkkaRuntime

final class StreamLaneTests: XCTestCase {
  func testNativeRoundTripAcrossCallbacks() throws {
    guard let runtime = ProcessInfo.processInfo.environment["COAKKA_STREAM_LANE_RUNTIME_LIB"] else {
      throw XCTSkip("current stream-lane runtime not configured")
    }
    var payload = Data(count: 2 * 1024 * 1024 + 731)
    payload.withUnsafeMutableBytes { bytes in
      for index in bytes.indices { bytes[index] = UInt8((index * 31 + 17) & 0xff) }
    }
    var publisherConfig = StreamLaneConfig()
    publisherConfig.flags = [.publisher]
    let publisher = try StreamLane.openOwned(
      publisherConfig,
      owner: LaneOwnerConfig(
        ownerInstanceID: "swift-stream-replica-3", advertisedHost: "127.0.0.1"),
      runtimeLibPath: runtime)
    defer { try? publisher.close() }
    var subscriberConfig = StreamLaneConfig()
    subscriberConfig.flags = [.subscriber]
    let subscriber = try StreamLane.open(subscriberConfig, runtimeLibPath: runtime)
    defer { try? subscriber.close() }

    let source = LockedStreamBytes(payload)
    let grant = try publisher.preparePublishGrant(
      StreamPublishSpec(
        sessionID: "swift-stream", authorizationToken: "swift-token", formatID: 0x4341_4D31,
        maxFrameBytes: 64 * 1024
      ) { destination in source.fill(destination) })
    let sink = LockedStreamBytes()
    XCTAssertEqual(grant.owner.ownerInstanceID, "swift-stream-replica-3")
    XCTAssertEqual(grant.owner.advertisedHost, "127.0.0.1")
    XCTAssertGreaterThan(grant.owner.port, 0)
    let receivedGrant = try JSONDecoder().decode(
      StreamPublishGrant.self, from: JSONEncoder().encode(grant))
    try subscriber.subscribe(
      receivedGrant.subscribeSpec(initialWindowBytes: 256 * 1024) { frame, _ in
        sink.append(frame)
        return .continue
      })

    let published = try terminal(publisher, .publish)
    let consumed = try terminal(subscriber, .subscribe)
    XCTAssertTrue(published.succeeded)
    XCTAssertTrue(consumed.succeeded)
    XCTAssertEqual(sink.data(), payload)
    XCTAssertEqual(try subscriber.stats().consumedBytes, UInt64(payload.count))
    _ = try publisher.pressure("swift-stream", direction: .publish)
  }

  private func terminal(_ lane: StreamLane, _ direction: StreamDirection) throws
    -> StreamSessionSnapshot
  {
    var sequence: UInt64 = 0
    for _ in 0..<64 {
      let snapshot = try lane.waitSession(
        "swift-stream", direction: direction, afterSequence: sequence, timeoutMs: 30_000)
      if snapshot.terminal { return snapshot }
      sequence = snapshot.updateSequence
    }
    throw RuntimeError.nativeStatus(-5, "stream did not reach terminal state")
  }
}

private final class LockedStreamBytes: @unchecked Sendable {
  private let lock = NSLock()
  private var storage: Data
  private var offset = 0
  init(_ storage: Data = Data()) { self.storage = storage }
  func fill(_ destination: UnsafeMutableRawBufferPointer) -> StreamSourceResult {
    lock.lock()
    defer { lock.unlock() }
    if offset == storage.count { return .end }
    let count = min(destination.count, storage.count - offset)
    storage.copyBytes(to: destination.bindMemory(to: UInt8.self), from: offset..<(offset + count))
    offset += count
    return .frame(size: count)
  }
  func append(_ source: UnsafeRawBufferPointer) {
    lock.lock()
    storage.append(source.bindMemory(to: UInt8.self))
    lock.unlock()
  }
  func data() -> Data {
    lock.lock()
    defer { lock.unlock() }
    return storage
  }
}
