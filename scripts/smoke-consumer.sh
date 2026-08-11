#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
swift_root="$(cd "${script_dir}/.." && pwd)"
work_root="$(mktemp -d "${TMPDIR:-/tmp}/coakka-runtime-swift-consumer.XXXXXX")"

bash "${script_dir}/stage-runtime-native.sh"
bash "${script_dir}/verify-native-payload.sh"

mkdir -p "${work_root}/Sources/ConsumerSmoke"
cat >"${work_root}/Package.swift" <<EOF
// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CoAkkaRuntimeSwiftConsumerSmoke",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(name: "coakka-runtime-swift", path: "${swift_root}"),
    ],
    targets: [
        .executableTarget(
            name: "ConsumerSmoke",
            dependencies: [
                .product(name: "CoAkkaRuntime", package: "coakka-runtime-swift"),
            ]
        ),
    ]
)
EOF

cat >"${work_root}/Sources/ConsumerSmoke/main.swift" <<'EOF'
import CoAkkaRuntime

let capabilities = try RuntimeHost.readRuntimeCapabilities()
let mode: TcpConnectionMode = capabilities.supports(.tcpBoundedPool)
    ? .boundedPool
    : .perExchange
let runtime = try RuntimeHost.start(
    ConnectorStartSpec(
        systemName: "swift-consumer-smoke",
        nodeID: "swift-consumer-smoke-node",
        queueCapacity: 64,
        routes: [.local("svc.echo")],
        connectionStrategy: TcpConnectionStrategySpec(mode: mode),
        security: TcpSecuritySpec()
    )
)
defer {
    runtime.close()
}

try runtime.registerTextHandler("svc.echo") { request in
    "echo-\(request)"
}

let response = try runtime.askText(
    source: "swift-consumer-smoke",
    target: "svc.echo",
    payload: "hello-consumer",
    timeoutMs: 2_000,
    deliveryHint: .requireLocal
)

guard runtime.startupTcpConnectionResult()?.applied == true,
      runtime.startupTcpSecurityResult()?.applied == true,
      try runtime.tcpConnectionConfig().mode == mode else {
    fatalError("explicit startup transport policy was not preserved")
}

print("consumer_response=\(response) delivered=\(runtime.clientStats().deliveredRequests) capabilities=\(capabilities.effectiveCapabilities.rawValue)")
EOF

(
  cd "${work_root}"
  swift run ConsumerSmoke
)

echo "[swift-runtime-consumer-smoke] ok ${work_root}"
