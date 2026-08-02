import CoAkkaRuntimeC
import Foundation

public struct CoAkkaStatus: RawRepresentable, Equatable, Sendable {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    public static let ok = Self(rawValue: 0)
    public static let invalidArgument = Self(rawValue: -1)
    public static let noMemory = Self(rawValue: -2)
    public static let badState = Self(rawValue: -3)
    public static let staleGeneration = Self(rawValue: -4)
    public static let io = Self(rawValue: -5)
    public static let wouldBlock = Self(rawValue: -6)
    public static let closed = Self(rawValue: -7)
    public static let featureUnavailable = Self(rawValue: -8)
    public static let featureNotEntitled = Self(rawValue: -9)
}

public struct RuntimeCapabilities: OptionSet, Sendable {
    public let rawValue: UInt64

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    public static let tcpBoundedPool = Self(rawValue: 1 << 0)
    public static let tcpPoolTuning = Self(rawValue: 1 << 1)
    public static let tcpTLS = Self(rawValue: 1 << 2)
    public static let tcpMutualTLS = Self(rawValue: 1 << 3)
    public static let tlsCredentialReload = Self(rawValue: 1 << 4)
    public static let tlsExternalProvider = Self(rawValue: 1 << 5)
    public static let tcpPersistentSingleFlight = Self(rawValue: 1 << 6)
    public static let tcpMultiplexing = Self(rawValue: 1 << 7)
}

public struct TcpConnectionMode: RawRepresentable, Equatable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let perExchange = Self(rawValue: 0)
    public static let boundedPool = Self(rawValue: 1)
    public static let persistentSingleFlight = Self(rawValue: 2)
    public static let multiplexing = Self(rawValue: 3)
}

public struct TcpSecurityMode: RawRepresentable, Equatable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let plaintext = Self(rawValue: 0)
    public static let tls = Self(rawValue: 1)
    public static let mutualTLS = Self(rawValue: 2)
}

public struct TlsReloadMode: RawRepresentable, Equatable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let graceful = Self(rawValue: 0)
    public static let drainExistingConnections = Self(rawValue: 1)
}

public struct TransportApplyReason: RawRepresentable, Equatable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let none = Self(rawValue: 0)
    public static let invalidArgument = Self(rawValue: 1)
    public static let featureUnavailable = Self(rawValue: 2)
    public static let featureNotEntitled = Self(rawValue: 3)
    public static let runtimeNotConfigurable = Self(rawValue: 4)
    public static let securityModeChangeRequiresRecreate = Self(rawValue: 5)
    public static let staleCredentialGeneration = Self(rawValue: 6)
    public static let credentialRejected = Self(rawValue: 7)
    public static let resourceFailure = Self(rawValue: 8)
    public static let adapterRejected = Self(rawValue: 9)
}

public struct TcpConnectionValidationCode: RawRepresentable, Equatable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let valid = Self(rawValue: 0)
    public static let invalidStructSize = Self(rawValue: 1)
    public static let unknownField = Self(rawValue: 2)
    public static let modeRequired = Self(rawValue: 3)
    public static let unknownMode = Self(rawValue: 4)
    public static let fieldNotApplicable = Self(rawValue: 5)
    public static let valueOutOfRange = Self(rawValue: 6)
    public static let featureUnavailable = Self(rawValue: 7)
    public static let featureNotEntitled = Self(rawValue: 8)
    public static let reservedNonzero = Self(rawValue: 9)
    public static let fieldOutsideStruct = Self(rawValue: 10)
    public static let valueWithoutField = Self(rawValue: 11)
}

public struct TcpSecurityValidationCode: RawRepresentable, Equatable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let valid = Self(rawValue: 0)
    public static let invalidStructSize = Self(rawValue: 1)
    public static let unknownField = Self(rawValue: 2)
    public static let modeRequired = Self(rawValue: 3)
    public static let unknownMode = Self(rawValue: 4)
    public static let reservedNonzero = Self(rawValue: 5)
    public static let fieldOutsideStruct = Self(rawValue: 6)
    public static let fieldNotApplicable = Self(rawValue: 7)
    public static let requiredFieldMissing = Self(rawValue: 8)
    public static let sourceUnavailable = Self(rawValue: 9)
    public static let featureUnavailable = Self(rawValue: 10)
    public static let invalidGeneration = Self(rawValue: 11)
    public static let credentialIDTooLong = Self(rawValue: 12)
    public static let valueWithoutField = Self(rawValue: 13)
}

/// Startup-only connection policy. Nil tuning values preserve core defaults.
public struct TcpConnectionStrategySpec: Equatable, Sendable {
    public var mode: TcpConnectionMode
    public var maxConnections: UInt32?
    public var maxRequestsPerConnection: UInt64?
    public var idleTimeoutMs: UInt64?

    public init(
        mode: TcpConnectionMode = .perExchange,
        maxConnections: UInt32? = nil,
        maxRequestsPerConnection: UInt64? = nil,
        idleTimeoutMs: UInt64? = nil
    ) {
        self.mode = mode
        self.maxConnections = maxConnections
        self.maxRequestsPerConnection = maxRequestsPerConnection
        self.idleTimeoutMs = idleTimeoutMs
    }
}

/// Startup security policy or same-mode TLS/mTLS credential reload request.
public struct TcpSecuritySpec: Equatable, Sendable {
    public var mode: TcpSecurityMode
    public var reloadMode: TlsReloadMode
    public var credentialGeneration: UInt64
    public var credentialID: String
    public var caCertificateFile: String
    public var identityCertificateFile: String
    public var privateKeyFile: String

    public init(
        mode: TcpSecurityMode = .plaintext,
        reloadMode: TlsReloadMode = .graceful,
        credentialGeneration: UInt64 = 0,
        credentialID: String = "",
        caCertificateFile: String = "",
        identityCertificateFile: String = "",
        privateKeyFile: String = ""
    ) {
        self.mode = mode
        self.reloadMode = reloadMode
        self.credentialGeneration = credentialGeneration
        self.credentialID = credentialID
        self.caCertificateFile = caCertificateFile
        self.identityCertificateFile = identityCertificateFile
        self.privateKeyFile = privateKeyFile
    }
}

public struct RuntimeCapabilitySnapshot: Equatable, Sendable {
    public let edition: UInt32
    public let licenseStatus: UInt32
    public let compiledCapabilities: RuntimeCapabilities
    public let entitledCapabilities: RuntimeCapabilities
    public let effectiveCapabilities: RuntimeCapabilities
    public let tcpConnectionDefaultsRevision: UInt32

    public func supports(_ capabilities: RuntimeCapabilities) -> Bool {
        effectiveCapabilities.contains(capabilities)
    }
}

public struct TcpConnectionConfigSnapshot: Equatable, Sendable {
    public let defaultsRevision: UInt32
    public let mode: TcpConnectionMode
    public let applicableFields: UInt64
    public let explicitlyConfiguredFields: UInt64
    public let defaultedFields: UInt64
    public let configurableFields: UInt64
    public let maxConnections: UInt32
    public let maxRequestsPerConnection: UInt64
    public let idleTimeoutMs: UInt64
}

public struct TcpConnectionApplyResult: Equatable, Sendable {
    public let status: CoAkkaStatus
    public let changed: Bool
    public let reason: TransportApplyReason
    public let reasonName: String
    public let runtimeState: UInt32
    public let validationCode: TcpConnectionValidationCode
    public let validationField: UInt64
    public let minimumValue: UInt64
    public let maximumValue: UInt64
    public let activeConfig: TcpConnectionConfigSnapshot

    public var applied: Bool { status == .ok }
}

public struct TcpSecurityInfoSnapshot: Equatable, Sendable {
    public let mode: TcpSecurityMode
    public let credentialSourceKind: UInt32
    public let reloadMode: TlsReloadMode
    public let reloadStatus: UInt32
    public let credentialGeneration: UInt64
    public let credentialID: String
    public let minimumProtocolVersion: UInt32
    public let maximumProtocolVersion: UInt32
    public let inboundVerificationFlags: UInt64
    public let outboundVerificationFlags: UInt64
    public let identityNotBeforeUnixSeconds: Int64
    public let identityNotAfterUnixSeconds: Int64
    public let identityFingerprintSHA256: String
}

public struct TcpSecurityApplyResult: Equatable, Sendable {
    public let status: CoAkkaStatus
    public let changed: Bool
    public let reason: TransportApplyReason
    public let reasonName: String
    public let runtimeState: UInt32
    public let validationCode: TcpSecurityValidationCode
    public let validationField: UInt64
    public let activeSecurity: TcpSecurityInfoSnapshot

    public var applied: Bool { status == .ok }
}

public struct RuntimeTransportABISizes: Equatable, Sendable {
    public let capabilities: Int
    public let connectionOptions: Int
    public let connectionValidation: Int
    public let connectionConfig: Int
    public let connectionApplyResult: Int
    public let securityOptions: Int
    public let securityValidation: Int
    public let securityConfig: Int
    public let securityIdentity: Int
    public let securityInfo: Int
    public let securityApplyResult: Int

    public init(
        capabilities: Int,
        connectionOptions: Int,
        connectionValidation: Int,
        connectionConfig: Int,
        connectionApplyResult: Int,
        securityOptions: Int,
        securityValidation: Int,
        securityConfig: Int,
        securityIdentity: Int,
        securityInfo: Int,
        securityApplyResult: Int
    ) {
        self.capabilities = capabilities
        self.connectionOptions = connectionOptions
        self.connectionValidation = connectionValidation
        self.connectionConfig = connectionConfig
        self.connectionApplyResult = connectionApplyResult
        self.securityOptions = securityOptions
        self.securityValidation = securityValidation
        self.securityConfig = securityConfig
        self.securityIdentity = securityIdentity
        self.securityInfo = securityInfo
        self.securityApplyResult = securityApplyResult
    }
}

public enum RuntimeTransportABI {
    /// Returns Swift's compiled sizes for all eleven public transport ABI blocks.
    ///
    /// This is synchronous, allocates no native state, and is available in every
    /// edition. Sizes are layout diagnostics for the current target, not execution
    /// evidence for another operating system.
    public static var sizes: RuntimeTransportABISizes {
        RuntimeTransportABISizes(
            capabilities: MemoryLayout<coakka_swift_runtime_capabilities_t>.size,
            connectionOptions: MemoryLayout<coakka_swift_tcp_connection_options_t>.size,
            connectionValidation: MemoryLayout<coakka_swift_tcp_connection_validation_t>.size,
            connectionConfig: MemoryLayout<coakka_swift_tcp_connection_config_t>.size,
            connectionApplyResult: MemoryLayout<coakka_swift_tcp_connection_apply_result_t>.size,
            securityOptions: MemoryLayout<coakka_swift_tcp_security_options_t>.size,
            securityValidation: MemoryLayout<coakka_swift_tcp_security_validation_t>.size,
            securityConfig: MemoryLayout<coakka_swift_tcp_security_config_t>.size,
            securityIdentity: MemoryLayout<coakka_swift_tcp_security_identity_t>.size,
            securityInfo: MemoryLayout<coakka_swift_tcp_security_info_t>.size,
            securityApplyResult: MemoryLayout<coakka_swift_tcp_security_apply_result_t>.size
        )
    }
}

extension RuntimeHost {
    /// Loads one runtime module and copies its capability/edition truth before startup.
    ///
    /// `runtimeLibPath` follows the same resolver as `start`; the module identity is
    /// retained for process lifetime and a different later path is rejected. The call
    /// is synchronous, thread-safe, non-blocking except for module loading, and is
    /// available in every edition. Load and ABI errors are thrown as `RuntimeError`.
    public static func readRuntimeCapabilities(runtimeLibPath: String? = nil) throws -> RuntimeCapabilitySnapshot {
        let path = try runtimeNativePath(explicitPath: runtimeLibPath)
        let library = try NativeRuntimeLibrary(path: path)
        let handle = try library.requireHandle()
        let abi = coakka_swift_runtime_get_abi_version(handle)
        guard abi == expectedABI else {
            throw RuntimeError.unsupportedABI(abi)
        }
        return try readCapabilities(library: library)
    }

    /// Copies compiled, entitled, and effective capabilities from the loaded runtime.
    ///
    /// The returned value owns its data. The call is synchronous, serialized with
    /// transport mutation and close, available in every edition, and throws when the
    /// host is closed or the native getter fails.
    public func runtimeCapabilities() throws -> RuntimeCapabilitySnapshot {
        try withTransportLock {
            _ = try requireTransportOpen()
            return try readCapabilities(library: library)
        }
    }

    /// Copies the effective connection mode, tuning, and explicit/default provenance.
    ///
    /// The returned snapshot owns its data. The synchronous getter is serialized with
    /// apply and close, does not mutate state, and reports native status as an error.
    public func tcpConnectionConfig() throws -> TcpConnectionConfigSnapshot {
        try withTransportLock {
            let runtime = try requireTransportOpen()
            return try readConnectionConfig(library: library, runtime: runtime)
        }
    }

    /// Copies active non-secret TLS/mTLS state and certificate identity metadata.
    ///
    /// Secret material is never returned. The synchronous getter is serialized with
    /// reload and close and is available whenever the loaded runtime exposes this ABI.
    public func tcpSecurityInfo() throws -> TcpSecurityInfoSnapshot {
        try withTransportLock {
            let runtime = try requireTransportOpen()
            return try readSecurityInfo(library: library, runtime: runtime)
        }
    }

    /// Returns the owned structured result of an explicit startup connection apply.
    ///
    /// Nil means the caller omitted the startup policy. The immutable copied result is
    /// safe to read from any thread and remains available after close.
    public func startupTcpConnectionResult() -> TcpConnectionApplyResult? {
        startupConnectionResult
    }

    /// Returns the owned structured result of an explicit startup security apply.
    ///
    /// Nil means the caller omitted the startup policy. Secret paths are not retained
    /// in the result, which is safe to read from any thread and remains after close.
    public func startupTcpSecurityResult() -> TcpSecurityApplyResult? {
        startupSecurityResult
    }

    /// Attempts an atomic connection-policy apply and returns active state afterward.
    ///
    /// Optional tuning values are present only when non-nil; no binding-side defaults
    /// are substituted. The call is synchronous and serialized with getters/close.
    /// Connection strategy is startup-configured, so a started runtime normally returns
    /// a structured `badState` result with `changed == false`.
    public func applyTcpConnectionStrategy(_ spec: TcpConnectionStrategySpec) throws -> TcpConnectionApplyResult {
        try withTransportLock {
            let runtime = try requireTransportOpen()
            return try applyConnection(library: library, runtime: runtime, spec: spec)
        }
    }

    /// Applies startup security or atomically reloads newer same-mode TLS credentials.
    ///
    /// String storage is borrowed only for this synchronous call; file I/O may block.
    /// The call is serialized with getters/close. A failed validation/load keeps the
    /// previous immutable TLS context active and the structured result reports it.
    public func applyTcpSecurity(_ spec: TcpSecuritySpec) throws -> TcpSecurityApplyResult {
        try withTransportLock {
            let runtime = try requireTransportOpen()
            return try applySecurity(library: library, runtime: runtime, spec: spec)
        }
    }

    func withTransportLock<T>(_ operation: () throws -> T) rethrows -> T {
        transportLock.lock()
        defer { transportLock.unlock() }
        return try operation()
    }

    func requireTransportOpen() throws -> OpaquePointer {
        try throwIfClosed()
        guard let runtime else {
            throw RuntimeError.closed
        }
        return runtime
    }
}

func readCapabilities(library: NativeRuntimeLibrary) throws -> RuntimeCapabilitySnapshot {
    let handle = try library.requireHandle()
    var native = coakka_swift_runtime_capabilities_t()
    try throwIfNativeError(
        coakka_swift_runtime_get_capabilities(handle, &native),
        operation: "read runtime capabilities"
    )
    return RuntimeCapabilitySnapshot(
        edition: native.edition,
        licenseStatus: native.license_status,
        compiledCapabilities: RuntimeCapabilities(rawValue: native.compiled_capabilities),
        entitledCapabilities: RuntimeCapabilities(rawValue: native.entitled_capabilities),
        effectiveCapabilities: RuntimeCapabilities(rawValue: native.effective_capabilities),
        tcpConnectionDefaultsRevision: native.tcp_connection_defaults_revision
    )
}

func applyConnection(
    library: NativeRuntimeLibrary,
    runtime: OpaquePointer,
    spec: TcpConnectionStrategySpec
) throws -> TcpConnectionApplyResult {
    let handle = try library.requireHandle()
    var options = coakka_swift_tcp_connection_options_t()
    options.struct_size = MemoryLayout<coakka_swift_tcp_connection_options_t>.size
    options.fields = UInt64(COAKKA_SWIFT_TCP_CONNECTION_FIELD_MODE)
    options.mode = spec.mode.rawValue
    if let value = spec.maxConnections {
        options.fields |= UInt64(COAKKA_SWIFT_TCP_CONNECTION_FIELD_MAX_CONNECTIONS)
        options.max_connections = value
    }
    if let value = spec.maxRequestsPerConnection {
        options.fields |= UInt64(COAKKA_SWIFT_TCP_CONNECTION_FIELD_MAX_REQUESTS_PER_CONNECTION)
        options.max_requests_per_connection = value
    }
    if let value = spec.idleTimeoutMs {
        options.fields |= UInt64(COAKKA_SWIFT_TCP_CONNECTION_FIELD_IDLE_TIMEOUT_MS)
        options.idle_timeout_ms = value
    }

    var native = coakka_swift_tcp_connection_apply_result_t()
    native.struct_size = MemoryLayout<coakka_swift_tcp_connection_apply_result_t>.size
    let status = coakka_swift_runtime_apply_tcp_connection_options(handle, runtime, &options, &native)
    guard status == native.apply_status else {
        throw RuntimeError.nativeStatus(status, "connection apply status mismatch (result (native.apply_status))")
    }
    return connectionResult(native, library: library)
}

func applySecurity(
    library: NativeRuntimeLibrary,
    runtime: OpaquePointer,
    spec: TcpSecuritySpec
) throws -> TcpSecurityApplyResult {
    let stringFields = [
        ("credentialID", spec.credentialID),
        ("caCertificateFile", spec.caCertificateFile),
        ("identityCertificateFile", spec.identityCertificateFile),
        ("privateKeyFile", spec.privateKeyFile),
    ]
    for (name, value) in stringFields where value.utf8.contains(0) {
        throw RuntimeError.invalidArgument("\(name) must not contain NUL")
    }

    let handle = try library.requireHandle()
    return try spec.credentialID.withCString { credentialID in
        try spec.caCertificateFile.withCString { caFile in
            try spec.identityCertificateFile.withCString { identityFile in
                try spec.privateKeyFile.withCString { keyFile in
                    var options = coakka_swift_tcp_security_options_t()
                    options.struct_size = MemoryLayout<coakka_swift_tcp_security_options_t>.size
                    options.fields = UInt64(COAKKA_SWIFT_TCP_SECURITY_FIELD_MODE)
                    options.mode = spec.mode.rawValue

                    if spec.mode != .plaintext {
                        options.fields = UInt64(COAKKA_SWIFT_TCP_SECURITY_ALL_FIELDS)
                        options.credential_source_kind = UInt32(COAKKA_SWIFT_TLS_CREDENTIAL_SOURCE_FILE)
                        options.reload_mode = spec.reloadMode.rawValue
                        options.credential_generation = spec.credentialGeneration
                        options.credential_id = credentialID
                        options.ca_certificate_file = caFile
                        options.identity_certificate_file = identityFile
                        options.private_key_file = keyFile
                    } else {
                        if spec.reloadMode != .graceful {
                            options.fields |= UInt64(COAKKA_SWIFT_TCP_SECURITY_FIELD_RELOAD_MODE)
                            options.reload_mode = spec.reloadMode.rawValue
                        }
                        if spec.credentialGeneration != 0 {
                            options.fields |= UInt64(COAKKA_SWIFT_TCP_SECURITY_FIELD_CREDENTIAL_GENERATION)
                            options.credential_generation = spec.credentialGeneration
                        }
                        if !spec.credentialID.isEmpty {
                            options.fields |= UInt64(COAKKA_SWIFT_TCP_SECURITY_FIELD_CREDENTIAL_ID)
                            options.credential_id = credentialID
                        }
                        if !spec.caCertificateFile.isEmpty || !spec.identityCertificateFile.isEmpty || !spec.privateKeyFile.isEmpty {
                            options.fields |= UInt64(COAKKA_SWIFT_TCP_SECURITY_FIELD_CREDENTIAL_SOURCE)
                            options.credential_source_kind = UInt32(COAKKA_SWIFT_TLS_CREDENTIAL_SOURCE_FILE)
                        }
                        if !spec.caCertificateFile.isEmpty {
                            options.fields |= UInt64(COAKKA_SWIFT_TCP_SECURITY_FIELD_CA_CERTIFICATE_FILE)
                            options.ca_certificate_file = caFile
                        }
                        if !spec.identityCertificateFile.isEmpty {
                            options.fields |= UInt64(COAKKA_SWIFT_TCP_SECURITY_FIELD_IDENTITY_CERTIFICATE_FILE)
                            options.identity_certificate_file = identityFile
                        }
                        if !spec.privateKeyFile.isEmpty {
                            options.fields |= UInt64(COAKKA_SWIFT_TCP_SECURITY_FIELD_PRIVATE_KEY_FILE)
                            options.private_key_file = keyFile
                        }
                    }

                    var native = coakka_swift_tcp_security_apply_result_t()
                    native.struct_size = MemoryLayout<coakka_swift_tcp_security_apply_result_t>.size
                    let status = coakka_swift_runtime_apply_tcp_security_options(handle, runtime, &options, &native)
                    guard status == native.apply_status else {
                        throw RuntimeError.nativeStatus(status, "security apply status mismatch (result \(native.apply_status))")
                    }
                    return securityResult(native, library: library)
                }
            }
        }
    }
}

private func readConnectionConfig(
    library: NativeRuntimeLibrary,
    runtime: OpaquePointer
) throws -> TcpConnectionConfigSnapshot {
    let handle = try library.requireHandle()
    var native = coakka_swift_tcp_connection_config_t()
    try throwIfNativeError(
        coakka_swift_runtime_get_tcp_connection_config(handle, runtime, &native),
        operation: "read TCP connection config"
    )
    return connectionConfig(native)
}

private func readSecurityInfo(
    library: NativeRuntimeLibrary,
    runtime: OpaquePointer
) throws -> TcpSecurityInfoSnapshot {
    let handle = try library.requireHandle()
    var native = coakka_swift_tcp_security_info_t()
    try throwIfNativeError(
        coakka_swift_runtime_get_tcp_security_info(handle, runtime, &native),
        operation: "read TCP security info"
    )
    return securityInfo(native)
}

private func connectionResult(
    _ native: coakka_swift_tcp_connection_apply_result_t,
    library: NativeRuntimeLibrary
) -> TcpConnectionApplyResult {
    TcpConnectionApplyResult(
        status: CoAkkaStatus(rawValue: native.apply_status),
        changed: native.changed != 0,
        reason: TransportApplyReason(rawValue: native.reason),
        reasonName: nativeString(coakka_swift_transport_apply_reason_name(library.handle, native.reason)),
        runtimeState: native.runtime_state,
        validationCode: TcpConnectionValidationCode(rawValue: native.validation.code),
        validationField: native.validation.field,
        minimumValue: native.validation.minimum_value,
        maximumValue: native.validation.maximum_value,
        activeConfig: connectionConfig(native.effective_config)
    )
}

private func securityResult(
    _ native: coakka_swift_tcp_security_apply_result_t,
    library: NativeRuntimeLibrary
) -> TcpSecurityApplyResult {
    TcpSecurityApplyResult(
        status: CoAkkaStatus(rawValue: native.apply_status),
        changed: native.changed != 0,
        reason: TransportApplyReason(rawValue: native.reason),
        reasonName: nativeString(coakka_swift_transport_apply_reason_name(library.handle, native.reason)),
        runtimeState: native.runtime_state,
        validationCode: TcpSecurityValidationCode(rawValue: native.validation.code),
        validationField: native.validation.field,
        activeSecurity: securityInfo(native.active_security)
    )
}

private func connectionConfig(_ native: coakka_swift_tcp_connection_config_t) -> TcpConnectionConfigSnapshot {
    TcpConnectionConfigSnapshot(
        defaultsRevision: native.defaults_revision,
        mode: TcpConnectionMode(rawValue: native.mode),
        applicableFields: native.applicable_fields,
        explicitlyConfiguredFields: native.explicitly_configured_fields,
        defaultedFields: native.defaulted_fields,
        configurableFields: native.configurable_fields,
        maxConnections: native.max_connections,
        maxRequestsPerConnection: native.max_requests_per_connection,
        idleTimeoutMs: native.idle_timeout_ms
    )
}

private func securityInfo(_ native: coakka_swift_tcp_security_info_t) -> TcpSecurityInfoSnapshot {
    var identity = native.identity
    return TcpSecurityInfoSnapshot(
        mode: TcpSecurityMode(rawValue: native.config.mode),
        credentialSourceKind: native.config.credential_source_kind,
        reloadMode: TlsReloadMode(rawValue: native.config.reload_mode),
        reloadStatus: native.config.reload_status,
        credentialGeneration: native.config.credential_generation,
        credentialID: fixedCString(&identity.credential_id_value),
        minimumProtocolVersion: identity.minimum_protocol_version,
        maximumProtocolVersion: identity.maximum_protocol_version,
        inboundVerificationFlags: identity.inbound_verification_flags,
        outboundVerificationFlags: identity.outbound_verification_flags,
        identityNotBeforeUnixSeconds: identity.identity_not_before_unix_seconds,
        identityNotAfterUnixSeconds: identity.identity_not_after_unix_seconds,
        identityFingerprintSHA256: fixedCString(&identity.identity_fingerprint_sha256)
    )
}

private func fixedCString<T>(_ value: inout T) -> String {
    withUnsafeBytes(of: &value) { bytes in
        String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
    }
}
