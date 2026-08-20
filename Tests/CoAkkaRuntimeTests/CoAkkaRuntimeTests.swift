import CoAkkaRuntime
import XCTest

final class CoAkkaRuntimeTests: XCTestCase {
    func testTransportABILayouts() {
        XCTAssertEqual(
            RuntimeTransportABI.sizes,
            RuntimeTransportABISizes(
                capabilities: 48,
                connectionOptions: 48,
                connectionValidation: 40,
                connectionConfig: 72,
                connectionApplyResult: 136,
                securityOptions: 72,
                securityValidation: 24,
                securityConfig: 40,
                securityIdentity: 248,
                securityInfo: 296,
                securityApplyResult: 344
            )
        )
    }

    func testUnknownTransportValuesRemainRepresentable() {
        XCTAssertEqual(TcpConnectionMode(rawValue: 999).rawValue, 999)
        XCTAssertEqual(TcpSecurityMode(rawValue: 999).rawValue, 999)
        XCTAssertEqual(TransportApplyReason(rawValue: 999).rawValue, 999)
    }

    func testInvalidStartValuesAreRejectedInsteadOfRewritten() {
        XCTAssertThrowsError(
            try RuntimeHost.start(
                ConnectorStartSpec(
                    systemName: "swift-invalid",
                    nodeID: "swift-invalid-node",
                    queueCapacity: 0,
                    generation: 0,
                    routes: [.local("svc.echo")]
                )
            )
        ) { error in
            guard case RuntimeError.invalidArgument(let message) = error else {
                return XCTFail("unexpected error: \(error)")
            }
            XCTAssertEqual(message, "queueCapacity must be greater than zero")
        }
    }

    func testNetworkPolicyDefaultsEmbeddedAndRejectsWildcardAdvertise() {
        let local = RuntimeRouteSpec.local("svc.echo")
        XCTAssertEqual(local.port, 0)
        XCTAssertThrowsError(
            try RuntimeHost.start(
                ConnectorStartSpec(
                    systemName: "swift-invalid-network",
                    nodeID: "swift-invalid-network-node",
                    routes: [local],
                    network: .networkNode(
                        bindHost: "0.0.0.0",
                        bindPort: 19301,
                        advertiseHost: "0.0.0.0"
                    )
                )
            )
        ) { error in
            guard case RuntimeError.invalidArgument(let message) = error else {
                return XCTFail("unexpected error: \(error)")
            }
            XCTAssertEqual(message, "advertiseHost must not be wildcard")
        }
    }

    func testRuntimeSmoke() throws {
        let runtime = try RuntimeHost.start(
            ConnectorStartSpec(
                systemName: "swift-test",
                nodeID: "swift-test-node",
                queueCapacity: 64,
                routes: [.local("svc.echo", port: 19192)]
            )
        )
        defer {
            runtime.close()
        }

        try runtime.registerTextHandler("svc.echo") { request in
            "echo-\(request)"
        }

        let response = try runtime.askText(
            source: "swift-test",
            target: "svc.echo",
            payload: "hello-test",
            timeoutMs: 2_000,
            deliveryHint: .requireLocal
        )
        XCTAssertTrue(response.contains("hello-test"))
        XCTAssertEqual(try runtime.runtimeInfo().abiVersion, 1)
        XCTAssertEqual(try runtime.runtimeConfig().routeCount, 1)
        XCTAssertEqual(runtime.clientStats().deliveredRequests, 1)
        XCTAssertEqual(runtime.clientStats().matchedResponses, 1)
    }

    func testFileLaneRoundtripCrossesNativeQuantum() throws {
        guard let runtime = ProcessInfo.processInfo.environment["COAKKA_FILE_LANE_RUNTIME_LIB"] else {
            throw XCTSkip("current file-lane runtime not configured")
        }
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(
            "coakka-swift-file-lane-\(UUID().uuidString)"
        )
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("source.bin")
        let destination = root.appendingPathComponent("destination.bin")
        let payload = Data(
            (0..<(9 * 1024 * 1024 + 731)).map { UInt8(truncatingIfNeeded: $0 * 31 + 17) }
        )
        try payload.write(to: source)
        let digest = try FileLane.sha256(path: source.path, runtimeLibPath: runtime)
        var receiverConfig = FileLaneConfig()
        receiverConfig.flags = [.receiver]
        var senderConfig = FileLaneConfig()
        senderConfig.flags = [.sender]
        let receiver = try FileLane.openOwned(
            receiverConfig,
            owner: LaneOwnerConfig(
                ownerInstanceID: "swift-file-replica-2", advertisedHost: "127.0.0.1"),
            runtimeLibPath: runtime)
        let sender = try FileLane.open(senderConfig, runtimeLibPath: runtime)
        defer {
            try? sender.close()
            try? receiver.close()
        }
        let id = "swift-file-lane-multi-quantum"
        let token = "swift-file-lane-token"
        let grant = try receiver.prepareReceiveGrant(
            FileReceiveSpec(
                transferID: id,
                authorizationToken: token,
                destinationPath: destination.path,
                expectedSize: digest.size,
                expectedSHA256: digest.sha256
            )
        )
        XCTAssertEqual(grant.owner.ownerInstanceID, "swift-file-replica-2")
        XCTAssertEqual(grant.owner.advertisedHost, "127.0.0.1")
        XCTAssertGreaterThan(grant.owner.port, 0)
        let receivedGrant = try JSONDecoder().decode(
          FileReceiveGrant.self, from: JSONEncoder().encode(grant))
        try sender.submitSend(receivedGrant.sendSpec(sourcePath: source.path))
        let sent = try waitTerminal(sender, id, .send)
        let received = try waitTerminal(receiver, id, .receive)
        XCTAssertTrue(sent.succeeded, sent.detail)
        XCTAssertTrue(received.succeeded, received.detail)
        XCTAssertEqual(try Data(contentsOf: destination), payload)
    }

    private func waitTerminal(
        _ lane: FileLane,
        _ id: String,
        _ direction: FileTransferDirection
    ) throws -> FileTransferSnapshot {
        var sequence: UInt64 = 0
        for _ in 0..<64 {
            let value = try lane.waitTransfer(id, direction: direction, afterSequence: sequence)
            if value.terminal { return value }
            sequence = value.updateSequence
        }
        throw RuntimeError.timeout(id)
    }
}
