import CoAkkaRuntimeC
import Foundation

/// Direction capabilities enabled when opening a file lane.
public struct FileLaneFlags: OptionSet, Sendable {
  public let rawValue: UInt32
  public init(rawValue: UInt32) { self.rawValue = rawValue }
  public static let sender = Self(rawValue: 1)
  public static let receiver = Self(rawValue: 1 << 1)
}
/// Transport protection; per-transfer authorization remains mandatory.
public enum FileLaneSecurityMode: UInt32, Sendable {
  case direct = 0
  case tls = 1
  case mutualTLS = 2
}
/// Core-issued side of a retained record. Future raw values are preserved.
public struct FileTransferDirection: RawRepresentable, Hashable, Sendable {
  public let rawValue: UInt32
  public init(rawValue: UInt32) { self.rawValue = rawValue }
  public static let send = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_DIRECTION_SEND.rawValue))
  public static let receive = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_DIRECTION_RECEIVE.rawValue))
}
/// Core-issued lifecycle state, including future numeric values.
public struct FileTransferState: RawRepresentable, Hashable, Sendable {
  public let rawValue: UInt32
  public init(rawValue: UInt32) { self.rawValue = rawValue }
  public static let prepared = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_STATE_PREPARED.rawValue))
  public static let queued = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_STATE_QUEUED.rawValue))
  public static let connecting = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_STATE_CONNECTING.rawValue))
  public static let transferring = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_STATE_TRANSFERRING.rawValue))
  public static let verifying = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_STATE_VERIFYING.rawValue))
  public static let completed = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_STATE_COMPLETED.rawValue))
  public static let paused = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_STATE_PAUSED.rawValue))
  public static let rejected = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_STATE_REJECTED.rawValue))
  public static let failed = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_STATE_FAILED.rawValue))
  public static let canceled = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_STATE_CANCELED.rawValue))
}
/// Core-issued result reported independently by each peer; unknown codes remain numeric.
public struct FileTransferResult: RawRepresentable, Hashable, Sendable {
  public let rawValue: UInt32
  public init(rawValue: UInt32) { self.rawValue = rawValue }
  public static let none = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_RESULT_NONE.rawValue))
  public static let ok = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_RESULT_OK.rawValue))
  public static let notPrepared = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_RESULT_NOT_PREPARED.rawValue))
  public static let tokenMismatch = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_RESULT_TOKEN_MISMATCH.rawValue))
  public static let metadataMismatch = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_RESULT_METADATA_MISMATCH.rawValue))
  public static let sizeLimit = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_RESULT_SIZE_LIMIT.rawValue))
  public static let storageIO = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_RESULT_STORAGE_IO.rawValue))
  public static let integrityMismatch = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_RESULT_INTEGRITY_MISMATCH.rawValue))
  public static let networkIO = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_RESULT_NETWORK_IO.rawValue))
  public static let timeout = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_RESULT_TIMEOUT.rawValue))
  public static let queueFull = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_RESULT_QUEUE_FULL.rawValue))
  public static let protocolError = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_RESULT_PROTOCOL_ERROR.rawValue))
  public static let sourceChanged = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_RESULT_SOURCE_CHANGED.rawValue))
  public static let internalError = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_RESULT_INTERNAL_ERROR.rawValue))
  public static let canceledByHost = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_RESULT_CANCELED_BY_HOST.rawValue))
  public static let tlsConfigInvalid = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_RESULT_TLS_CONFIG_INVALID.rawValue))
  public static let tlsHandshakeFailed = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_RESULT_TLS_HANDSHAKE_FAILED.rawValue))
  public static let peerCertUntrusted = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_RESULT_PEER_CERT_UNTRUSTED.rawValue))
  public static let peerCertExpired = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_RESULT_PEER_CERT_EXPIRED.rawValue))
  public static let peerIdentityMismatch = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_RESULT_PEER_IDENTITY_MISMATCH.rawValue))
  public static let clientCertRequired = Self(rawValue: UInt32(COAKKA_V2_FILE_TRANSFER_RESULT_CLIENT_CERT_REQUIRED.rawValue))
}

/// TLS material read at lane startup. Never log key paths or transfer tokens.
public struct FileLaneSecurityConfig: Sendable {
  public var mode: FileLaneSecurityMode = .direct
  public var credentialGeneration: UInt64 = 0
  public var credentialID = ""
  public var caCertificateFile = ""
  public var identityCertificateFile = ""
  public var privateKeyFile = ""
  public init() {}
}
/// Bounded lane configuration. Zero tuning fields select core-runtime defaults.
/// Size fields are bytes, time fields are milliseconds, and `bindPort == 0`
/// requests an ephemeral receiver port.
public struct FileLaneConfig: Sendable {
  public var flags: FileLaneFlags = [.sender, .receiver]
  public var bindHost = "127.0.0.1"
  public var bindPort: UInt16 = 0
  public var queueCapacity = 0
  public var maxFileSize: UInt64 = 0
  public var ioTimeoutMs: UInt32 = 0
  public var checkpointBytes: UInt64 = 0
  public var progressBytes: UInt64 = 0
  public var progressIntervalMs: UInt32 = 0
  public var senderWorkerCount: UInt32 = 0
  public var receiverWorkerCount: UInt32 = 0
  public var security: FileLaneSecurityConfig?
  public init() {}
}
/// Receiver authorization and exact content identity for one transfer.
public struct FileReceiveSpec: Sendable {
  public var transferID: String
  public var authorizationToken: String
  public var destinationPath: String
  public var expectedSize: UInt64
  public var expectedSHA256: Data
  public init(
    transferID: String, authorizationToken: String, destinationPath: String, expectedSize: UInt64,
    expectedSHA256: Data
  ) {
    self.transferID = transferID
    self.authorizationToken = authorizationToken
    self.destinationPath = destinationPath
    self.expectedSize = expectedSize
    self.expectedSHA256 = expectedSHA256
  }
}
/// Source and receiver endpoint for one previously prepared transfer.
public struct FileSendSpec: Sendable {
  public var transferID: String
  public var authorizationToken: String
  public var remoteHost: String
  public var remotePort: UInt16
  public var sourcePath: String
  public var expectedSize: UInt64
  public var expectedSHA256: Data
  public var timeoutMs: UInt32 = 0
  public init(
    transferID: String, authorizationToken: String, remoteHost: String, remotePort: UInt16,
    sourcePath: String, expectedSize: UInt64, expectedSHA256: Data
  ) {
    self.transferID = transferID
    self.authorizationToken = authorizationToken
    self.remoteHost = remoteHost
    self.remotePort = remotePort
    self.sourcePath = sourcePath
    self.expectedSize = expectedSize
    self.expectedSHA256 = expectedSHA256
  }
}
/// Receiver-issued transfer capability pinned to one exact replica.
/// The token is scoped to this transfer and may be reused only for bounded
/// resume and idempotent completed-status handling while the owner retains it.
public struct FileReceiveGrant: Sendable, Codable, CustomStringConvertible {
  private enum CodingKeys: String, CodingKey {
    case owner, transferID, authorizationToken, expectedSize, expectedSHA256
  }

  public let owner: LaneOwnerEndpoint
  public let transferID: String
  public let authorizationToken: String
  public let expectedSize: UInt64
  public let expectedSHA256: Data

  public init(
    owner: LaneOwnerEndpoint, transferID: String, authorizationToken: String,
    expectedSize: UInt64, expectedSHA256: Data
  ) {
    self.owner = owner
    self.transferID = transferID
    self.authorizationToken = authorizationToken
    self.expectedSize = expectedSize
    self.expectedSHA256 = expectedSHA256
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let owner = try values.decode(LaneOwnerEndpoint.self, forKey: .owner)
    let transferID = try values.decode(String.self, forKey: .transferID)
    let authorizationToken = try values.decode(String.self, forKey: .authorizationToken)
    let expectedSize = try values.decode(UInt64.self, forKey: .expectedSize)
    let expectedSHA256 = try values.decode(Data.self, forKey: .expectedSHA256)
    guard expectedSHA256.count == 32 else {
      throw RuntimeError.invalidArgument("expectedSHA256 must contain exactly 32 bytes")
    }
    self.init(
      owner: owner, transferID: transferID, authorizationToken: authorizationToken,
      expectedSize: expectedSize, expectedSHA256: expectedSHA256)
  }

  public func sendSpec(sourcePath: String, timeoutMs: UInt32 = 0) -> FileSendSpec {
    var result = FileSendSpec(
      transferID: transferID, authorizationToken: authorizationToken,
      remoteHost: owner.advertisedHost, remotePort: owner.port,
      sourcePath: sourcePath, expectedSize: expectedSize, expectedSHA256: expectedSHA256)
    result.timeoutMs = timeoutMs
    return result
  }

  public var description: String {
    "FileReceiveGrant(owner: \(owner), transferID: \(transferID), authorizationToken: <redacted>, expectedSize: \(expectedSize))"
  }
}
/// A file SHA-256 and exact byte count.
public struct FileDigest: Equatable, Sendable {
  public let sha256: Data
  public let size: UInt64
}
/// Immutable progress view with process-local monotonic timestamps.
/// `progressMilli` ranges from 0 to 100000 (100.000%) and `updateSequence`
/// advances whenever retained state changes.
public struct FileTransferSnapshot: Sendable {
  public let direction: FileTransferDirection
  public let state: FileTransferState
  public let result: FileTransferResult
  public let expectedSize: UInt64
  public let transferredBytes: UInt64
  public let committedOffset: UInt64
  public let progressMilli: UInt32
  public let cancelRequested: Bool
  public let updateSequence: UInt64
  public let submittedMonoNs: UInt64
  public let startedMonoNs: UInt64
  public let updatedMonoNs: UInt64
  public let terminalMonoNs: UInt64
  public let detail: String
  /// Core's terminal-transition marker, not an ordering guess (PAUSED is not terminal).
  public var terminal: Bool { terminalMonoNs != 0 }
  /// Recognizes the documented successful completion; unknown results are not success.
  public var succeeded: Bool { terminal && state == .completed && result == .ok }
}

extension FileTransferSnapshot {
  // Pure owned projection shared by the native getter and focused tests.
  // No borrowed pointer escapes; the fixed detail array is copied as before.
  init(native n: coakka_swift_file_transfer_snapshot_t) {
    var detail = n.detail
    self.init(direction: FileTransferDirection(rawValue: n.direction),
      state: FileTransferState(rawValue: n.state), result: FileTransferResult(rawValue: n.result),
      expectedSize: n.expected_size, transferredBytes: n.transferred_bytes,
      committedOffset: n.committed_offset, progressMilli: n.progress_milli,
      cancelRequested: n.cancel_requested != 0, updateSequence: n.update_sequence,
      submittedMonoNs: n.submitted_mono_ns, startedMonoNs: n.started_mono_ns,
      updatedMonoNs: n.updated_mono_ns, terminalMonoNs: n.terminal_mono_ns,
      detail: fixedString(&detail))
  }
}
/// Bounded queue, active-work, terminal-count, and completed-byte counters.
public struct FileLaneStats: Sendable {
  public let queueCapacity, queuedSends, preparedReceives, activeSends, activeReceives,
    retainedRecords: Int
  public let submittedSends, preparedReceiveCount, completedSends, completedReceives, failedSends,
    failedReceives, canceledTransfers, completedSendBytes, completedReceiveBytes: UInt64
}

/// An independent bulk-transfer lane backed by the CoAkka core-runtime.
///
/// Prepare the receiver before submitting the sender. Continue `waitTransfer`
/// from each update sequence until both peers report success, then forget
/// retained records. `close()` stops the lane, wakes waits, and drains calls.
/// File bytes do not belong in runtime `Envelope` payloads.
public final class FileLane: @unchecked Sendable {
  // SAFETY: every mutable lifecycle field is serialized by `condition`; the
  // immutable library handle outlives all calls and close drains `activeCalls`.
  private let library: NativeRuntimeLibrary
  private let condition = NSCondition()
  private var lane: OpaquePointer?
  private var closing = false
  private var activeCalls = 0
  private init(library: NativeRuntimeLibrary, lane: OpaquePointer) {
    self.library = library
    self.lane = lane
  }
  /// Opens and starts a lane, failing when file transfer is unavailable.
  /// - Parameters:
  ///   - config: Bounded capabilities, workers, progress, and security settings.
  ///   - runtimeLibPath: Explicit core-runtime path, or `nil` for connector resolution.
  public static func open(
    _ config: FileLaneConfig = FileLaneConfig(), runtimeLibPath: String? = nil
  ) throws -> FileLane {
    try openInternal(config, owner: nil, runtimeLibPath: runtimeLibPath)
  }

  /// Opens a lane that can issue replica-pinned receive grants.
  public static func openOwned(
    _ config: FileLaneConfig = FileLaneConfig(), owner: LaneOwnerConfig,
    runtimeLibPath: String? = nil
  ) throws -> FileLane {
    return try openInternal(config, owner: owner, runtimeLibPath: runtimeLibPath)
  }

  private static func openInternal(
    _ config: FileLaneConfig, owner: LaneOwnerConfig?, runtimeLibPath: String?
  ) throws -> FileLane {
    // Swift Int cannot project a negative value into Core's size_t intent.
    // Flags, worker/resource bounds and defaults are validated by Core.
    guard config.queueCapacity >= 0 else { throw RuntimeError.invalidArgument("negative file-lane capacity") }
    let library = try NativeRuntimeLibrary(path: runtimeNativePath(explicitPath: runtimeLibPath))
    let handle = try library.requireHandle()
    try requireCoreFeature(handle, query: coakka_swift_file_lane_available, operation: "query Core file-lane feature")
    if owner != nil { try requireLaneOwnerGrants(library) }
    let strings = try NativeCStringStorage([
      config.bindHost, config.security?.credentialID ?? "",
      config.security?.caCertificateFile ?? "", config.security?.identityCertificateFile ?? "",
      config.security?.privateKeyFile ?? "", owner?.ownerInstanceID ?? "",
      owner?.advertisedHost ?? "",
    ])
    var security = coakka_swift_file_lane_security_config_t()
    if let value = config.security {
      security.struct_size = MemoryLayout.size(ofValue: security)
      security.mode = value.mode.rawValue
      security.credential_generation = value.credentialGeneration
      security.credential_id = UnsafePointer(strings[1])
      security.ca_certificate_file = UnsafePointer(strings[2])
      security.identity_certificate_file = UnsafePointer(strings[3])
      security.private_key_file = UnsafePointer(strings[4])
    }
    var native = coakka_swift_file_lane_config_t()
    native.struct_size = MemoryLayout.size(ofValue: native)
    native.flags = config.flags.rawValue
    native.bind_host = UnsafePointer(strings[0])
    native.bind_port = config.bindPort
    native.queue_capacity = config.queueCapacity
    native.max_file_size = config.maxFileSize
    native.io_timeout_ms = config.ioTimeoutMs
    native.checkpoint_bytes = config.checkpointBytes
    native.progress_bytes = config.progressBytes
    native.progress_interval_ms = config.progressIntervalMs
    native.sender_worker_count = config.senderWorkerCount
    native.receiver_worker_count = config.receiverWorkerCount
    var out: OpaquePointer?
    let createStatus: Int32
    var nativeOwner = coakka_swift_lane_owner_config_t()
    nativeOwner.struct_size = MemoryLayout.size(ofValue: nativeOwner)
    nativeOwner.owner_instance_id = UnsafePointer(strings[5])
    nativeOwner.advertised_host = UnsafePointer(strings[6])
    if config.security != nil {
      createStatus = withUnsafePointer(to: &security) {
        native.security = $0
        if owner != nil {
          var owned = coakka_swift_file_lane_owned_config_t()
          owned.struct_size = MemoryLayout.size(ofValue: owned)
          owned.lane = native
          owned.owner = nativeOwner
          return coakka_swift_file_lane_create_owned(handle, &owned, &out)
        }
        return coakka_swift_file_lane_create(handle, &native, &out)
      }
    } else if owner != nil {
      var owned = coakka_swift_file_lane_owned_config_t()
      owned.struct_size = MemoryLayout.size(ofValue: owned)
      owned.lane = native
      owned.owner = nativeOwner
      createStatus = coakka_swift_file_lane_create_owned(handle, &owned, &out)
    } else {
      createStatus = coakka_swift_file_lane_create(handle, &native, &out)
    }
    try throwIfNativeError(createStatus, operation: "file_lane_create")
    let created = try requireCoreOwner(out, operation: "File Lane creation")
    let start = coakka_swift_file_lane_start(handle, created)
    if start != 0 {
      coakka_swift_file_lane_destroy(handle, created)
      try throwIfNativeError(start, operation: "file_lane_start")
    }
    return FileLane(library: library, lane: created)
  }
  /// Computes the exact source identity through the selected core-runtime.
  /// - Parameters:
  ///   - path: Readable regular file to hash.
  ///   - runtimeLibPath: Explicit core-runtime path, or `nil` for connector resolution.
  public static func sha256(path: String, runtimeLibPath: String? = nil) throws -> FileDigest {
    try validateCString(path, name: "file path")
    let library = try NativeRuntimeLibrary(path: runtimeNativePath(explicitPath: runtimeLibPath))
    let handle = try library.requireHandle()
    var bytes = [UInt8](repeating: 0, count: 32)
    var size: UInt64 = 0
    let status = path.withCString { p in
      bytes.withUnsafeMutableBufferPointer {
        coakka_swift_file_sha256_path(handle, p, $0.baseAddress, &size)
      }
    }
    try throwIfNativeError(status, operation: "file_sha256_path")
    return FileDigest(sha256: Data(bytes), size: size)
  }
  /// Receiver port selected when the lane started.
  public var boundPort: UInt16 {
    get throws {
      try withLane { h, l in
        var out: UInt16 = 0
        try throwIfNativeError(
          coakka_swift_file_lane_get_bound_port(h, l, &out), operation: "file_lane_get_bound_port")
        return out
      }
    }
  }
  /// Authorizes one destination and expected content identity.
  /// - Parameter spec: Local destination, transfer-scoped token, exact byte size, and SHA-256.
  public func prepareReceive(_ spec: FileReceiveSpec) throws {
    guard spec.expectedSHA256.count == 32 else {
      throw RuntimeError.invalidArgument("expectedSHA256 must contain 32 bytes")
    }
    try withLane { h, l in
      let c = try NativeCStringStorage([spec.transferID, spec.authorizationToken, spec.destinationPath])
      try spec.expectedSHA256.withUnsafeBytes { b in
        try throwIfNativeError(
          coakka_swift_file_lane_prepare_receive(
            h, l, c[0], c[1], c[2], spec.expectedSize,
            b.bindMemory(to: UInt8.self).baseAddress),
          operation: "file_lane_prepare_receive")
      }
    }
  }
  /// Prepares one receive and returns a capability containing this replica's exact endpoint.
  public func prepareReceiveGrant(_ spec: FileReceiveSpec) throws -> FileReceiveGrant {
    guard spec.expectedSHA256.count == 32 else {
      throw RuntimeError.invalidArgument("expectedSHA256 must contain 32 bytes")
    }
    return try withLane { h, l in
      try requireLaneOwnerGrants(library)
      let c = try NativeCStringStorage([spec.transferID, spec.authorizationToken, spec.destinationPath])
      var grant = coakka_swift_file_receive_grant_t()
      try spec.expectedSHA256.withUnsafeBytes { b in
        try throwIfNativeError(
          coakka_swift_file_lane_prepare_receive_grant(
            h, l, c[0], c[1], c[2], spec.expectedSize,
            b.bindMemory(to: UInt8.self).baseAddress, &grant),
          operation: "file_lane_prepare_receive_grant")
      }
      var ownerID = grant.owner.owner_instance_id
      var advertisedHost = grant.owner.advertised_host
      var transferID = grant.transfer_id
      var token = grant.authorization_token
      var digest = grant.expected_sha256
      let digestData = withUnsafeBytes(of: &digest) { Data($0) }
      return FileReceiveGrant(
        owner: LaneOwnerEndpoint(
          ownerInstanceID: fixedString(&ownerID), advertisedHost: fixedString(&advertisedHost),
          port: grant.owner.port),
        transferID: fixedString(&transferID), authorizationToken: fixedString(&token),
        expectedSize: grant.expected_size, expectedSHA256: digestData)
    }
  }
  /// Queues a send after the remote application prepares the receive.
  /// - Parameter spec: Source plus the endpoint and grant returned by the receiver.
  public func submitSend(_ spec: FileSendSpec) throws {
    guard spec.expectedSHA256.count == 32 else {
      throw RuntimeError.invalidArgument("expectedSHA256 must contain 32 bytes")
    }
    try withLane { h, l in
      let c = try NativeCStringStorage([
        spec.transferID, spec.authorizationToken, spec.remoteHost, spec.sourcePath,
      ])
      try spec.expectedSHA256.withUnsafeBytes { b in
        try throwIfNativeError(
          coakka_swift_file_lane_submit_send(
            h, l, c[0], c[1], c[2], spec.remotePort, c[3], spec.expectedSize,
            b.bindMemory(to: UInt8.self).baseAddress, spec.timeoutMs),
          operation: "file_lane_submit_send")
      }
    }
  }
  /// Returns the current copied snapshot without waiting.
  /// - Parameters:
  ///   - transferID: Application correlation ID used by both peers.
  ///   - direction: Sender or receiver record to observe.
  public func transfer(_ transferID: String, direction: FileTransferDirection) throws
    -> FileTransferSnapshot
  { try read(transferID, direction, 0, 0, false) }
  /// Blocks until the sequence advances, the timeout expires, or the lane stops.
  public func waitTransfer(
    _ transferID: String, direction: FileTransferDirection, afterSequence: UInt64 = 0,
    timeoutMs: UInt32 = 30_000
  ) throws -> FileTransferSnapshot {
    try read(transferID, direction, afterSequence, timeoutMs, true)
  }
  private func read(
    _ id: String, _ d: FileTransferDirection, _ seq: UInt64, _ ms: UInt32, _ wait: Bool
  ) throws -> FileTransferSnapshot {
    try validateCString(id, name: "transfer ID")
    return try withLane { h, l in
      var n = coakka_swift_file_transfer_snapshot_t()
      let status = id.withCString {
        wait
          ? coakka_swift_file_lane_wait_transfer(h, l, $0, d.rawValue, seq, ms, &n)
          : coakka_swift_file_lane_get_transfer(h, l, $0, d.rawValue, &n)
      }
      try throwIfNativeError(status, operation: "file_lane_transfer")
      return FileTransferSnapshot(native: n)
    }
  }
  /// Requests cooperative cancellation; observe terminal state before forget.
  public func cancel(_ transferID: String, direction: FileTransferDirection) throws {
    try control(transferID, direction, false)
  }
  /// Releases one retained terminal record after recording its outcome.
  public func forget(_ transferID: String, direction: FileTransferDirection) throws {
    try control(transferID, direction, true)
  }
  private func control(_ id: String, _ d: FileTransferDirection, _ forget: Bool) throws {
    try validateCString(id, name: "transfer ID")
    try withLane { h, l in
      try id.withCString {
        try throwIfNativeError(
          forget
            ? coakka_swift_file_lane_forget(h, l, $0, d.rawValue)
            : coakka_swift_file_lane_cancel(h, l, $0, d.rawValue), operation: "file_lane_control")
      }
    }
  }
  /// Returns a copied lane-level observability snapshot.
  public func stats() throws -> FileLaneStats {
    try withLane { h, l in
      var n = coakka_swift_file_lane_stats_t()
      try throwIfNativeError(
        coakka_swift_file_lane_get_stats(h, l, &n), operation: "file_lane_get_stats")
      return FileLaneStats(
        queueCapacity: n.queue_capacity, queuedSends: n.queued_sends,
        preparedReceives: n.prepared_receives, activeSends: n.active_sends,
        activeReceives: n.active_receives, retainedRecords: n.retained_records,
        submittedSends: n.submitted_sends, preparedReceiveCount: n.prepared_receive_count,
        completedSends: n.completed_sends, completedReceives: n.completed_receives,
        failedSends: n.failed_sends, failedReceives: n.failed_receives,
        canceledTransfers: n.canceled_transfers, completedSendBytes: n.completed_send_bytes,
        completedReceiveBytes: n.completed_receive_bytes)
    }
  }
  /// Stops the lane, wakes blocked waits, drains calls, and releases native state.
  public func close() throws {
    condition.lock()
    guard let value = lane else {
      condition.unlock()
      return
    }
    if closing {
      while lane != nil { condition.wait() }
      condition.unlock()
      return
    }
    closing = true
    condition.unlock()
    let h = try library.requireHandle()
    let status = coakka_swift_file_lane_stop(h, value)
    condition.lock()
    while activeCalls != 0 { condition.wait() }
    coakka_swift_file_lane_destroy(h, value)
    lane = nil
    condition.broadcast()
    condition.unlock()
    if status != 0 && status != -7 { try throwIfNativeError(status, operation: "file_lane_stop") }
  }
  deinit { try? close() }
  private func withLane<T>(_ body: (OpaquePointer, OpaquePointer) throws -> T) throws -> T {
    condition.lock()
    guard !closing, let lane else {
      condition.unlock()
      throw RuntimeError.closed
    }
    activeCalls += 1
    condition.unlock()
    defer {
      condition.lock()
      activeCalls -= 1
      if activeCalls == 0 { condition.broadcast() }
      condition.unlock()
    }
    return try body(try library.requireHandle(), lane)
  }
}
