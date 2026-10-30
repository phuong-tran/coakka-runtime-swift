import CoAkkaRuntimeC
import Foundation
import XCTest
@testable import CoAkkaRuntime

final class CoreReasonProjectionTests: XCTestCase {
  private func frame(_ reason: UInt64) -> Data {
    var data = Data([0x10])
    var value = reason
    while value > 127 { data.append(UInt8(value & 127) | 128); value >>= 7 }
    data.append(UInt8(value))
    return data
  }

  func testExactCoreNamesAndUnknownNumericFacts() throws {
    let library = try NativeRuntimeLibrary(path: runtimeNativePath(explicitPath: nil))
    let names = ["unspecified", "no_active_snapshot", "route_miss", "no_responsible_host",
      "queue_rejected", "local_handoff_failed", "delivery_failed", "remote_transport_failed",
      "runtime_stopped", "invalid_envelope", "endpoint_unavailable", "remote_reply_timeout",
      "locality_mismatch", "expired_before_delivery", "one_way_dropped_by_policy", "remote_transport_security_failed"]
    for reason in 0..<16 {
      let value = try RuntimeEnvelopeCodec.decodeDeadletter(frame(UInt64(reason)), reasonName: library.deadletterReasonName)
      XCTAssertEqual(value.reasonCode, UInt32(reason))
      XCTAssertEqual(value.reason, names[reason])
    }
    for reason in [UInt32(65_536), UInt32.max] {
      let value = try RuntimeEnvelopeCodec.decodeDeadletter(frame(UInt64(reason)), reasonName: library.deadletterReasonName)
      XCTAssertEqual(value.reasonCode, reason)
      XCTAssertEqual(value.reason, "unknown")
    }
    XCTAssertThrowsError(try RuntimeEnvelopeCodec.decodeDeadletter(frame(UInt64(UInt32.max) + 1),
      reasonName: library.deadletterReasonName))
    XCTAssertNil(coakka_swift_deadletter_reason_name(nil, 2), "no module is not an unknown Core fact")
    let module = try library.requireHandle()
    library.close()
    XCTAssertEqual(try coreDeadletterReasonName(module, 2), "route_miss",
      "process module outlives wrapper/session retirement during result projection")
    XCTAssertThrowsError(try library.deadletterReasonName(2))
  }
}
