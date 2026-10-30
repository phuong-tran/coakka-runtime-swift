import Foundation
import CoAkkaRuntimeC
import XCTest
@testable import CoAkkaRuntime

final class LaneCorePolicyTests: XCTestCase {
    func testSuccessfulNullOwnerIsAContractViolationNotNoMemory() throws {
        XCTAssertThrowsError(try requireCoreOwner(nil, operation: "test")) { error in
            guard case RuntimeError.contractViolation = error else { return XCTFail("invented native cause") }
        }
        let pointer = try XCTUnwrap(OpaquePointer(bitPattern: 1))
        XCTAssertEqual(try requireCoreOwner(pointer, operation: "test"), pointer)
    }

    func testCoreOwnedRolesAndMissingOwnerRefusal() throws {
        let owner = LaneOwnerConfig(ownerInstanceID: "p400-owner", advertisedHost: "127.0.0.1")
        var config = StreamLaneConfig(); config.flags = [.subscriber]
        let subscriber = try StreamLane.openOwned(config, owner: owner)
        defer { try? subscriber.close() }
        XCTAssertGreaterThan(try subscriber.stats().capacity, 0)
        var fileConfig = FileLaneConfig(); fileConfig.flags = [.sender]
        let sender = try FileLane.openOwned(fileConfig, owner: owner)
        defer { try? sender.close() }
        XCTAssertGreaterThan(try sender.stats().queueCapacity, 0)
        let stream = try StreamLane.open()
        defer { try? stream.close() }
        XCTAssertThrowsError(try stream.preparePublishGrant(StreamPublishSpec(sessionID: "no-owner",
            authorizationToken: "token", formatID: 1, maxFrameBytes: 64) { _ in .end })) { error in
            guard case RuntimeError.nativeStatus(let status, _) = error else { return XCTFail("local owner-state guess") }
            XCTAssertEqual(status, -3)
        }
        XCTAssertEqual(try stream.stats().preparedPublisherCount, 0)
        let file = try FileLane.open()
        defer { try? file.close() }
        XCTAssertThrowsError(try file.prepareReceiveGrant(FileReceiveSpec(transferID: "no-owner",
            authorizationToken: "token", destinationPath: "unused-p400-destination", expectedSize: 0,
            expectedSHA256: Data(repeating: 0, count: 32)))) { error in
            guard case RuntimeError.nativeStatus(let status, _) = error else { return XCTFail("local File owner-state guess") }
            XCTAssertEqual(status, -3)
        }
        XCTAssertEqual(try file.stats().preparedReceiveCount, 0)
    }

    func testCoreIssuedFileTokenSurvivesCodableAndDigestBoundRemains() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("coakka-p400-grant-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        let lane = try FileLane.openOwned(owner: LaneOwnerConfig(ownerInstanceID: "p400-file",
            advertisedHost: "127.0.0.1"))
        defer { try? lane.close() }
        let token = "grant-Đường-😺"
        let grant = try lane.prepareReceiveGrant(FileReceiveSpec(transferID: "unicode-file",
            authorizationToken: token, destinationPath: directory.appendingPathComponent("Đích-😺.bin").path, expectedSize: 1,
            expectedSHA256: Data(repeating: 0, count: 32)))
        let restored = try JSONDecoder().decode(FileReceiveGrant.self, from: JSONEncoder().encode(grant))
        XCTAssertEqual(restored.authorizationToken, token)
        XCTAssertEqual(restored.expectedSHA256.count, 32)
        let invalid = FileReceiveGrant(owner: grant.owner, transferID: grant.transferID,
            authorizationToken: token, expectedSize: 0, expectedSHA256: Data(repeating: 0, count: 31))
        XCTAssertThrowsError(try JSONDecoder().decode(FileReceiveGrant.self, from: JSONEncoder().encode(invalid)))
        try lane.cancel(grant.transferID, direction: .receive)
        try lane.forget(grant.transferID, direction: .receive)
    }

    func testUntrustedGrantDecodeDoesNotMirrorCoreAdmission() throws {
        let grant = StreamPublishGrant(owner: LaneOwnerEndpoint(ownerInstanceID: "",
            advertisedHost: "127.0.0.1", port: 0), sessionID: "", authorizationToken: "",
            formatID: 0, maxFrameBytes: 0)
        let restored = try JSONDecoder().decode(StreamPublishGrant.self, from: JSONEncoder().encode(grant))
        let lane = try StreamLane.open()
        defer { try? lane.close() }
        let spec = restored.subscribeSpec(initialWindowBytes: 0) { _, _ in
            XCTFail("refused callback invoked"); return .continue
        }
        XCTAssertThrowsError(try lane.subscribe(spec)) { error in
            guard case RuntimeError.nativeStatus(let status, _) = error else { return XCTFail("grant admission mirrored") }
            XCTAssertEqual(status, -1)
        }
    }

    func testCoreIssuedUnicodeGrantSurvivesCodable() throws {
        let token = "grant-Đường-😺"
        var config = StreamLaneConfig(); config.flags = [.publisher]
        let lane = try StreamLane.openOwned(config,
            owner: LaneOwnerConfig(ownerInstanceID: "p400-owner", advertisedHost: "127.0.0.1"))
        var restored: StreamPublishGrant?
        var refusal: Error?
        let accepted: UInt64
        do {
            let grant = try lane.preparePublishGrant(StreamPublishSpec(sessionID: "unicode-token",
                authorizationToken: token, formatID: 1, maxFrameBytes: 64) { _ in .end })
            XCTAssertEqual(grant.authorizationToken, token, "Core granted the exact token")
            do { restored = try JSONDecoder().decode(StreamPublishGrant.self, from: JSONEncoder().encode(grant)) }
            catch { refusal = error }
            accepted = try lane.stats().preparedPublisherCount
        } catch { try lane.close(); throw error }
        try lane.close() // No native owner/callback remains at the negative oracle.
        print("CORE_GRANT_ACCEPTED=\(accepted) CODABLE_PROJECTED=\(restored != nil) LOCAL_REFUSAL=\(refusal != nil)")
        XCTAssertEqual(accepted, 1)
        XCTAssertEqual(restored?.authorizationToken, token, "Codable refused a Core-issued token: \(String(describing: refusal))")
    }
}
