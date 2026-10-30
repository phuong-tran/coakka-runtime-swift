// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "coakka-v2-runtime-swift", platforms: [.macOS(.v13)],
    products: [.library(name: "CoAkkaRuntime", type: .dynamic, targets: ["CoAkkaRuntime"])],
    targets: [.target(name: "CoAkkaRuntimeC", publicHeadersPath: "include"),
        .target(name: "CoAkkaRuntime", dependencies: ["CoAkkaRuntimeC"], resources: [.copy("Resources")]),
        .testTarget(name: "CoAkkaRuntimeTests", dependencies: ["CoAkkaRuntime", "CoAkkaRuntimeC"])],
    cLanguageStandard: .c11)
