import CoAkkaRuntime
import XCTest

final class CoAkkaRuntimeTests: XCTestCase {
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
