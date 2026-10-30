import XCTest
@testable import CoAkkaRuntime

// The private transaction seam covers an unreceived call outcome. Separate
// public tests exercise actual Core statuses and callback invocation/lifetime.
final class StreamCallbackOwnerTests: XCTestCase {
  private final class Target {}
  private final class WeakTarget {
    weak var value: Target?
    init(_ value: Target) { self.value = value }
  }
  private enum Injected: Error { case outcome }

  @inline(never)
  private func admit(_ owners: StreamCallbackOwners, _ id: String, presence: Int32 = 0,
    call: () throws -> Int32) throws -> WeakTarget {
    let target = Target()
    let reference = WeakTarget(target)
    var retired: [AnyObject] = []
    retired.reserveCapacity(owners.limit + 1)
    defer { withExtendedLifetime(retired) {} }
    do {
      _ = try owners.admit(.init(id: id, direction: .publish), root: target, call: call,
        presence: { _ in presence }, retired: &retired)
    } catch Injected.outcome { }
    return reference
  }

  func testUnknownOutcomeRefusalBoundsAndExactAbsence() throws {
    let owners = try StreamCallbackOwners(capacity: 1)
    XCTAssertEqual(owners.limit, 2)
    let previous = try admit(owners, "same") { 0 }
    let rejected = try admit(owners, "same") { -1 }
    XCTAssertNotNil(previous.value)
    XCTAssertNil(rejected.value)
    let unknown = try admit(owners, "same") { throw Injected.outcome }
    XCTAssertNotNil(previous.value)
    XCTAssertNotNil(unknown.value)
    var called = false
    XCTAssertThrowsError(try admit(owners, "same") { called = true; return 0 }) { error in
      guard case RuntimeError.contractViolation = error else { return XCTFail("\(error)") }
    }
    XCTAssertFalse(called)
    let other = try admit(owners, "other", presence: -2) { 0 }
    XCTAssertNotNil(other.value, "NoMemory is not record absence")
    XCTAssertThrowsError(try admit(owners, "full", presence: -2) { called = true; return 0 }) { error in
      guard case RuntimeError.resourceLimit = error else { return XCTFail("\(error)") }
    }
    XCTAssertFalse(called, "exhaustion refuses before Core")
    let removed = try admit(owners, "new", presence: -3) { 0 }
    XCTAssertNil(other.value)
    XCTAssertNil(removed.value)
    XCTAssertNotNil(previous.value, "absence never discards an unresolved candidate/previous pair")
    XCTAssertNotNil(unknown.value)
    var retired: [AnyObject] = []
    retired.reserveCapacity(owners.limit + 1)
    owners.forget(.init(id: "same", direction: .publish), retired: &retired)
    withExtendedLifetime(owners.detach()) {}
    retired.removeAll()
    XCTAssertNil(previous.value)
    XCTAssertNil(unknown.value)
  }
}
