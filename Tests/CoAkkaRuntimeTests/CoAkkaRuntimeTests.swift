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
}
