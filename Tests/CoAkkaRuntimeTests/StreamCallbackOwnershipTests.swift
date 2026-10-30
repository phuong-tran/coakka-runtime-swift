import Foundation
import XCTest
@testable import CoAkkaRuntime

final class StreamCallbackOwnershipTests: XCTestCase {
  private func publisher(capacity: Int = 1) throws -> StreamLane {
    guard let runtime = ProcessInfo.processInfo.environment["COAKKA_STREAM_LANE_RUNTIME_LIB"] else {
      throw XCTSkip("explicit exact Core required")
    }
    var config = StreamLaneConfig()
    config.flags = [.publisher]
    config.capacity = capacity
    return try StreamLane.open(config, runtimeLibPath: runtime)
  }
  private final class Source: Sendable {
    func next(_ destination: UnsafeMutableRawBufferPointer) -> StreamSourceResult { .end }
  }
  private final class WeakSource {
    weak var value: Source?
    init(_ value: Source) { self.value = value }
  }

  @inline(never)
  private func install(_ lane: StreamLane, session: String) throws -> WeakSource {
    let source = Source()
    try lane.preparePublish(StreamPublishSpec(
      sessionID: session, authorizationToken: "swift-root-token", formatID: 1, maxFrameBytes: 64
    ) { source.next($0) })
    return WeakSource(source)
  }

  func testSameKeyReplacementRetiresARC() throws {
    guard let runtime = ProcessInfo.processInfo.environment["COAKKA_STREAM_LANE_RUNTIME_LIB"] else {
      throw XCTSkip("explicit exact Core required")
    }
    var config = StreamLaneConfig()
    config.flags = [.publisher]
    config.capacity = 1
    let lane = try StreamLane.open(config, runtimeLibPath: runtime)
    var references: [WeakSource] = []
    do {
      for _ in 0..<32 { references.append(try install(lane, session: "swift-same-key")) }
      XCTAssertEqual(try lane.stats().capacity, 1)
      XCTAssertEqual(try lane.stats().retainedRecords, 1)
    } catch {
      try lane.close()
      throw error
    }
    let before = references.filter { $0.value != nil }.count
    try lane.close() // Every native worker/owner is retired before the oracle.
    let after = references.filter { $0.value != nil }.count
    print("SWIFT_ARC_NATIVE_CLOSED retained-before=\(before) retained-after=\(after)")
    XCTAssertEqual(after, 0, "lost retained application holders survive native closure")
    XCTAssertLessThanOrEqual(before, 1, "replaced application holders remain strongly rooted")
  }

  func testCorePruningRetiresARC() throws {
    let lane = try publisher()
    defer { try? lane.close() }
    var references: [WeakSource] = []
    for index in 0..<32 {
      let id = "swift-prune-\(index)"
      references.append(try install(lane, session: id))
      try lane.cancel(id, direction: .publish)
      XCTAssertTrue(try lane.session(id, direction: .publish).terminal)
    }
    XCTAssertEqual(try lane.stats().capacity, 1)
    XCTAssertEqual(try lane.stats().retainedRecords, 1)
    XCTAssertLessThanOrEqual(references.filter { $0.value != nil }.count, 2)
    try lane.close()
    XCTAssertTrue(references.allSatisfy { $0.value == nil })
  }

  @inline(never)
  private func refused(_ lane: StreamLane) throws -> WeakSource {
    let source = Source()
    XCTAssertThrowsError(try lane.preparePublish(StreamPublishSpec(
      sessionID: "refusal", authorizationToken: "swift-root-token", formatID: 0, maxFrameBytes: 64
    ) { source.next($0) })) { error in
      guard case RuntimeError.nativeStatus(-1, _) = error else { return XCTFail("\(error)") }
    }
    return WeakSource(source)
  }

  func testRefusalCancelAndForgetKeepNativeTruth() throws {
    let lane = try publisher()
    defer { try? lane.close() }
    let previous = try install(lane, session: "refusal")
    let rejected = try refused(lane)
    XCTAssertNotNil(previous.value)
    XCTAssertNil(rejected.value)
    XCTAssertThrowsError(try lane.forget("refusal", direction: .publish)) { error in
      guard case RuntimeError.nativeStatus(-3, _) = error else { return XCTFail("\(error)") }
    }
    XCTAssertNotNil(previous.value)
    try lane.cancel("refusal", direction: .publish)
    XCTAssertNotNil(previous.value)
    try lane.forget("refusal", direction: .publish)
    XCTAssertNil(previous.value)
  }

  private final class ReentrantSource: Sendable {
    let lane: StreamLane
    init(_ lane: StreamLane) { self.lane = lane }
    func next(_ destination: UnsafeMutableRawBufferPointer) -> StreamSourceResult { .end }
    deinit { try? lane.close() }
  }
  @inline(never)
  private func installReentrant(_ lane: StreamLane) throws {
    let source = ReentrantSource(lane)
    try lane.preparePublish(StreamPublishSpec(
      sessionID: "deinit", authorizationToken: "swift-root-token", formatID: 1, maxFrameBytes: 64
    ) { source.next($0) })
  }
  func testRetiredAppDeinitReentersCloseOutsideBorrow() throws {
    let lane = try publisher()
    try installReentrant(lane)
    try lane.cancel("deinit", direction: .publish)
    try lane.forget("deinit", direction: .publish)
    XCTAssertThrowsError(try lane.stats()) { error in
      guard case RuntimeError.closed = error else { return XCTFail("\(error)") }
    }
    try lane.close()
  }

  private final class ByteSource: @unchecked Sendable {
    let value: UInt8
    private let lock = NSLock()
    private var sent = false
    init(_ value: UInt8) { self.value = value }
    func next(_ destination: UnsafeMutableRawBufferPointer) -> StreamSourceResult {
      lock.lock(); defer { lock.unlock() }
      if sent { return .end }
      destination[0] = value
      sent = true
      return .frame(size: 1)
    }
  }
  private final class WeakByte {
    weak var value: ByteSource?
    let format: UInt64
    init(_ value: ByteSource) { self.value = value; format = UInt64(value.value) }
  }
  private final class Results: @unchecked Sendable {
    private let lock = NSLock()
    private var roots: [WeakByte] = []
    private var errors: [String] = []
    func add(_ root: WeakByte) { lock.lock(); roots.append(root); lock.unlock() }
    func fail(_ error: Error) { lock.lock(); errors.append(String(describing: error)); lock.unlock() }
    func snapshot() -> ([WeakByte], [String]) { lock.lock(); defer { lock.unlock() }; return (roots, errors) }
  }
  private final class Sink: @unchecked Sendable {
    private let lock = NSLock()
    private var bytes: [UInt8] = []
    func append(_ frame: UnsafeRawBufferPointer) { lock.lock(); bytes.append(contentsOf: frame); lock.unlock() }
    func snapshot() -> [UInt8] { lock.lock(); defer { lock.unlock() }; return bytes }
  }
  @inline(never)
  private static func installByte(_ lane: StreamLane, id: String, value: UInt8) throws -> WeakByte {
    let source = ByteSource(value)
    try lane.preparePublish(StreamPublishSpec(sessionID: id, authorizationToken: "swift-root-token",
      formatID: UInt64(value), maxFrameBytes: 64) { source.next($0) })
    return WeakByte(source)
  }
  private func terminal(_ lane: StreamLane, id: String, direction: StreamDirection) throws -> StreamSessionSnapshot {
    var sequence: UInt64 = 0
    for _ in 0..<32 {
      let value = try lane.waitSession(id, direction: direction, afterSequence: sequence, timeoutMs: 2_000)
      if value.terminal { return value }
      sequence = value.updateSequence
    }
    throw RuntimeError.contractViolation("Stream terminal update missing")
  }
  func testConcurrentReplacementKeepsCoreAcceptedCallback() throws {
    let lane = try publisher(capacity: 0)
    defer { try? lane.close() }
    var config = StreamLaneConfig()
    config.flags = [.subscriber]
    let subscriber = try StreamLane.open(config,
      runtimeLibPath: ProcessInfo.processInfo.environment["COAKKA_STREAM_LANE_RUNTIME_LIB"]!)
    defer { try? subscriber.close() }
    for round in 0..<24 {
      let id = "swift-race-\(round)"
      let results = Results()
      DispatchQueue.concurrentPerform(iterations: 2) { index in
        do { results.add(try StreamCallbackOwnershipTests.installByte(lane, id: id, value: UInt8(index + 1))) }
        catch { results.fail(error) }
      }
      let (references, errors) = results.snapshot()
      XCTAssertTrue(errors.isEmpty, "\(errors)")
      XCTAssertEqual(references.count, 2)
      let accepted = try lane.session(id, direction: .publish)
      XCTAssertTrue(accepted.formatID == 1 || accepted.formatID == 2)
      for reference in references { XCTAssertEqual(reference.value != nil, reference.format == accepted.formatID) }
      let sink = Sink()
      try subscriber.subscribe(StreamSubscribeSpec(sessionID: id, authorizationToken: "swift-root-token",
        remoteHost: "127.0.0.1", remotePort: try lane.boundPort, formatID: accepted.formatID,
        maxFrameBytes: 64, initialWindowBytes: 128) { frame, _ in sink.append(frame); return .continue })
      XCTAssertTrue(try terminal(subscriber, id: id, direction: .subscribe).succeeded)
      XCTAssertTrue(try terminal(lane, id: id, direction: .publish).succeeded)
      XCTAssertEqual(sink.snapshot(), [UInt8(accepted.formatID)])
      try subscriber.forget(id, direction: .subscribe)
      try lane.forget(id, direction: .publish)
      XCTAssertTrue(references.allSatisfy { $0.value == nil })
    }
  }

  func testPrepareInspectCloseBorrowRace() throws {
    for _ in 0..<12 {
      let lane = try publisher()
      let group = DispatchGroup()
      let results = Results()
      group.enter()
      DispatchQueue.global().async {
        defer { group.leave() }
        for _ in 0..<64 {
          do {
            try lane.preparePublish(StreamPublishSpec(sessionID: "close", authorizationToken: "swift-root-token",
              formatID: 1, maxFrameBytes: 64) { _ in .end })
            _ = try lane.stats()
          } catch RuntimeError.closed { return }
          catch RuntimeError.nativeStatus(-7, _) { return }
          catch { results.fail(error); return }
        }
      }
      try lane.close()
      XCTAssertEqual(group.wait(timeout: .now() + 2), .success)
      XCTAssertTrue(results.snapshot().1.isEmpty)
      try lane.close()
    }
  }
}
