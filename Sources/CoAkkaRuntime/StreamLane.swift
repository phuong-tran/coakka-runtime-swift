import CoAkkaRuntimeC
import Foundation

/// Direction capabilities enabled when opening a stream lane.
public struct StreamLaneFlags: OptionSet, Sendable {
  public let rawValue: UInt32
  public init(rawValue: UInt32) { self.rawValue = rawValue }
  public static let publisher = Self(rawValue: 1)
  public static let subscriber = Self(rawValue: 1 << 1)
}

/// Application annotations transported with a frame without interpretation.
public struct StreamFrameFlags: OptionSet, Sendable {
  public let rawValue: UInt32
  public init(rawValue: UInt32) { self.rawValue = rawValue }
  public static let keyframe = Self(rawValue: 1)
  public static let discontinuity = Self(rawValue: 1 << 1)
  public static let endOfSegment = Self(rawValue: 1 << 2)
}

/// Policy-neutral reasons observed by the transport.
public struct StreamPressureReasons: OptionSet, Sendable {
  public let rawValue: UInt32
  public init(rawValue: UInt32) { self.rawValue = rawValue }
  public static let creditWait = Self(rawValue: 1)
  public static let transportWrite = Self(rawValue: 1 << 1)
  public static let consumerBusy = Self(rawValue: 1 << 2)
  public static let transportRead = Self(rawValue: 1 << 3)
}

/// Transport protection; per-session authorization remains mandatory.
public enum StreamLaneSecurityMode: UInt32, Sendable {
  case direct = 0
  case tls, mutualTLS
}
/// Core-issued record side. Future numeric values are preserved.
public struct StreamDirection: RawRepresentable, Hashable, Sendable {
  public let rawValue: UInt32
  public init(rawValue: UInt32) { self.rawValue = rawValue }
  public static let publish = Self(rawValue: UInt32(COAKKA_V2_STREAM_DIRECTION_PUBLISH.rawValue))
  public static let subscribe = Self(rawValue: UInt32(COAKKA_V2_STREAM_DIRECTION_SUBSCRIBE.rawValue))
}
/// Core-issued lifecycle state, including future numeric values.
public struct StreamState: RawRepresentable, Hashable, Sendable {
  public let rawValue: UInt32
  public init(rawValue: UInt32) { self.rawValue = rawValue }
  public static let prepared = Self(rawValue: UInt32(COAKKA_V2_STREAM_STATE_PREPARED.rawValue))
  public static let queued = Self(rawValue: UInt32(COAKKA_V2_STREAM_STATE_QUEUED.rawValue))
  public static let connecting = Self(rawValue: UInt32(COAKKA_V2_STREAM_STATE_CONNECTING.rawValue))
  public static let active = Self(rawValue: UInt32(COAKKA_V2_STREAM_STATE_ACTIVE.rawValue))
  public static let stopping = Self(rawValue: UInt32(COAKKA_V2_STREAM_STATE_STOPPING.rawValue))
  public static let ended = Self(rawValue: UInt32(COAKKA_V2_STREAM_STATE_ENDED.rawValue))
  public static let rejected = Self(rawValue: UInt32(COAKKA_V2_STREAM_STATE_REJECTED.rawValue))
  public static let failed = Self(rawValue: UInt32(COAKKA_V2_STREAM_STATE_FAILED.rawValue))
  public static let canceled = Self(rawValue: UInt32(COAKKA_V2_STREAM_STATE_CANCELED.rawValue))
}
/// Core-issued result; unknown codes are retained rather than defaulted.
public struct StreamResult: RawRepresentable, Hashable, Sendable {
  public let rawValue: UInt32
  public init(rawValue: UInt32) { self.rawValue = rawValue }
  public static let none = Self(rawValue: UInt32(COAKKA_V2_STREAM_RESULT_NONE.rawValue))
  public static let ok = Self(rawValue: UInt32(COAKKA_V2_STREAM_RESULT_OK.rawValue))
  public static let notPrepared = Self(rawValue: UInt32(COAKKA_V2_STREAM_RESULT_NOT_PREPARED.rawValue))
  public static let tokenMismatch = Self(rawValue: UInt32(COAKKA_V2_STREAM_RESULT_TOKEN_MISMATCH.rawValue))
  public static let formatMismatch = Self(rawValue: UInt32(COAKKA_V2_STREAM_RESULT_FORMAT_MISMATCH.rawValue))
  public static let frameLimit = Self(rawValue: UInt32(COAKKA_V2_STREAM_RESULT_FRAME_LIMIT.rawValue))
  public static let networkIO = Self(rawValue: UInt32(COAKKA_V2_STREAM_RESULT_NETWORK_IO.rawValue))
  public static let timeout = Self(rawValue: UInt32(COAKKA_V2_STREAM_RESULT_TIMEOUT.rawValue))
  public static let queueFull = Self(rawValue: UInt32(COAKKA_V2_STREAM_RESULT_QUEUE_FULL.rawValue))
  public static let protocolError = Self(rawValue: UInt32(COAKKA_V2_STREAM_RESULT_PROTOCOL_ERROR.rawValue))
  public static let sourceError = Self(rawValue: UInt32(COAKKA_V2_STREAM_RESULT_SOURCE_ERROR.rawValue))
  public static let consumerError = Self(rawValue: UInt32(COAKKA_V2_STREAM_RESULT_CONSUMER_ERROR.rawValue))
  public static let internalError = Self(rawValue: UInt32(COAKKA_V2_STREAM_RESULT_INTERNAL_ERROR.rawValue))
  public static let canceledByHost = Self(rawValue: UInt32(COAKKA_V2_STREAM_RESULT_CANCELED_BY_HOST.rawValue))
  public static let tlsConfigInvalid = Self(rawValue: UInt32(COAKKA_V2_STREAM_RESULT_TLS_CONFIG_INVALID.rawValue))
  public static let tlsHandshakeFailed = Self(rawValue: UInt32(COAKKA_V2_STREAM_RESULT_TLS_HANDSHAKE_FAILED.rawValue))
  public static let peerCertUntrusted = Self(rawValue: UInt32(COAKKA_V2_STREAM_RESULT_PEER_CERT_UNTRUSTED.rawValue))
  public static let peerCertExpired = Self(rawValue: UInt32(COAKKA_V2_STREAM_RESULT_PEER_CERT_EXPIRED.rawValue))
  public static let peerIdentityMismatch = Self(rawValue: UInt32(COAKKA_V2_STREAM_RESULT_PEER_IDENTITY_MISMATCH.rawValue))
  public static let clientCertRequired = Self(rawValue: UInt32(COAKKA_V2_STREAM_RESULT_CLIENT_CERT_REQUIRED.rawValue))
}
/// Core-issued coalesced pressure, preserving future numeric states.
public struct StreamPressureState: RawRepresentable, Hashable, Sendable {
  public let rawValue: UInt32
  public init(rawValue: UInt32) { self.rawValue = rawValue }
  public static let inactive = Self(rawValue: UInt32(COAKKA_V2_STREAM_PRESSURE_INACTIVE.rawValue))
  public static let flowing = Self(rawValue: UInt32(COAKKA_V2_STREAM_PRESSURE_FLOWING.rawValue))
  public static let pressured = Self(rawValue: UInt32(COAKKA_V2_STREAM_PRESSURE_PRESSURED.rawValue))
  public static let stalled = Self(rawValue: UInt32(COAKKA_V2_STREAM_PRESSURE_STALLED.rawValue))
  public static let recovering = Self(rawValue: UInt32(COAKKA_V2_STREAM_PRESSURE_RECOVERING.rawValue))
}
/// Result of one bounded source callback.
public enum StreamSourceResult: Sendable {
  /// `size` bytes were written into the borrowed destination.
  case frame(
    size: Int, capturedMonoNs: UInt64 = 0, droppedBefore: UInt64 = 0,
    flags: StreamFrameFlags = [])
  /// No frame is ready; native code retries after the configured delay.
  case wouldBlock
  /// The source ended normally.
  case end
}
/// Action returned after consuming one borrowed frame.
public enum StreamConsumerDecision: Sendable { case `continue`, stop }

/// Immutable metadata paired with a borrowed frame.
public struct StreamFrameMetadata: Sendable {
  public let sequence: UInt64
  public let capturedMonoNs: UInt64
  public let droppedBefore: UInt64
  public let flags: StreamFrameFlags
}

/// Fills runtime-owned storage. The buffer is valid only during the callback.
/// Bound all work/waits; never close the same lane from its callback.
/// Core worker invocation is outside the caller's actor; captures must be safe to share.
public typealias StreamSource = @Sendable (UnsafeMutableRawBufferPointer) -> StreamSourceResult
/// Consumes borrowed bytes. The buffer is valid only during the callback.
/// Bound all work/waits; never close the same lane from its callback.
public typealias StreamConsumer = @Sendable (UnsafeRawBufferPointer, StreamFrameMetadata) ->
  StreamConsumerDecision

/// TLS material copied at lane startup. Never log key paths or session tokens.
public struct StreamLaneSecurityConfig: Sendable {
  public var mode: StreamLaneSecurityMode = .direct
  public var credentialGeneration: UInt64 = 0
  public var credentialID = ""
  public var caCertificateFile = ""
  public var identityCertificateFile = ""
  public var privateKeyFile = ""
  public init() {}
}

/// Bounded workers, frames, flow control, and pressure timing.
/// Size fields are bytes, time fields are milliseconds, and zero tuning values
/// select conservative core-runtime defaults.
public struct StreamLaneConfig: Sendable {
  public var flags: StreamLaneFlags = [.publisher, .subscriber]
  public var bindHost = "127.0.0.1"
  public var bindPort: UInt16 = 0
  public var capacity = 0
  public var maxFrameBytes: UInt32 = 0
  public var maxWindowBytes: UInt32 = 0
  public var ioTimeoutMs: UInt32 = 0
  public var sourceRetryMs: UInt32 = 0
  public var progressFrames: UInt32 = 0
  public var progressIntervalMs: UInt32 = 0
  public var publisherWorkerCount: UInt32 = 0
  public var subscriberWorkerCount: UInt32 = 0
  public var security: StreamLaneSecurityConfig?
  public var pressureAfterMs: UInt32 = 0
  public var stalledAfterMs: UInt32 = 0
  public var recoveryAfterMs: UInt32 = 0
  public var pressureObservationMs: UInt32 = 0
  public init() {}
}

/// Publisher authorization, format contract, frame bound, and source callback.
public struct StreamPublishSpec: Sendable {
  public var sessionID: String
  public var authorizationToken: String
  public var formatID: UInt64
  public var maxFrameBytes: UInt32
  public var source: StreamSource
  public init(
    sessionID: String, authorizationToken: String, formatID: UInt64,
    maxFrameBytes: UInt32, source: @escaping StreamSource
  ) {
    self.sessionID = sessionID
    self.authorizationToken = authorizationToken
    self.formatID = formatID
    self.maxFrameBytes = maxFrameBytes
    self.source = source
  }
}

/// Publisher endpoint, authorization, flow-control window, and consumer callback.
public struct StreamSubscribeSpec: Sendable {
  public var sessionID: String
  public var authorizationToken: String
  public var remoteHost: String
  public var remotePort: UInt16
  public var formatID: UInt64
  public var maxFrameBytes: UInt32
  public var initialWindowBytes: UInt32
  public var timeoutMs: UInt32
  public var consumer: StreamConsumer
  public init(
    sessionID: String, authorizationToken: String, remoteHost: String,
    remotePort: UInt16, formatID: UInt64, maxFrameBytes: UInt32,
    initialWindowBytes: UInt32, timeoutMs: UInt32 = 0,
    consumer: @escaping StreamConsumer
  ) {
    self.sessionID = sessionID
    self.authorizationToken = authorizationToken
    self.remoteHost = remoteHost
    self.remotePort = remotePort
    self.formatID = formatID
    self.maxFrameBytes = maxFrameBytes
    self.initialWindowBytes = initialWindowBytes
    self.timeoutMs = timeoutMs
    self.consumer = consumer
  }
}

/// Single-admission publish capability pinned to one exact replica.
/// The first valid OPEN consumes the token; retry requires a fresh grant.
public struct StreamPublishGrant: Sendable, Codable, CustomStringConvertible {
  private enum CodingKeys: String, CodingKey {
    case owner, sessionID, authorizationToken, formatID, maxFrameBytes
  }

  public let owner: LaneOwnerEndpoint
  public let sessionID: String
  public let authorizationToken: String
  public let formatID: UInt64
  public let maxFrameBytes: UInt32

  public init(
    owner: LaneOwnerEndpoint, sessionID: String, authorizationToken: String,
    formatID: UInt64, maxFrameBytes: UInt32
  ) {
    self.owner = owner
    self.sessionID = sessionID
    self.authorizationToken = authorizationToken
    self.formatID = formatID
    self.maxFrameBytes = maxFrameBytes
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let owner = try values.decode(LaneOwnerEndpoint.self, forKey: .owner)
    let sessionID = try values.decode(String.self, forKey: .sessionID)
    let authorizationToken = try values.decode(String.self, forKey: .authorizationToken)
    let formatID = try values.decode(UInt64.self, forKey: .formatID)
    let maxFrameBytes = try values.decode(UInt32.self, forKey: .maxFrameBytes)
    // Typed values are not a second admission policy. Core validates them when
    // used; C-string representation is checked at that actual FFI boundary.
    self.init(
      owner: owner, sessionID: sessionID, authorizationToken: authorizationToken,
      formatID: formatID, maxFrameBytes: maxFrameBytes)
  }

  public func subscribeSpec(
    initialWindowBytes: UInt32, timeoutMs: UInt32 = 0,
    consumer: @escaping StreamConsumer
  ) -> StreamSubscribeSpec {
    StreamSubscribeSpec(
      sessionID: sessionID, authorizationToken: authorizationToken,
      remoteHost: owner.advertisedHost, remotePort: owner.port,
      formatID: formatID, maxFrameBytes: maxFrameBytes,
      initialWindowBytes: initialWindowBytes, timeoutMs: timeoutMs, consumer: consumer)
  }

  public var description: String {
    "StreamPublishGrant(owner: \(owner), sessionID: \(sessionID), authorizationToken: <redacted>, formatID: \(formatID), maxFrameBytes: \(maxFrameBytes))"
  }
}

/// Copied session progress with process-local monotonic timestamps.
/// Frame and byte counters are cumulative for this side; `updateSequence`
/// advances whenever retained state changes.
public struct StreamSessionSnapshot: Sendable {
  public let direction: StreamDirection, state: StreamState, result: StreamResult
  public let formatID, frames, bytes, droppedFrames, lastSequence: UInt64
  public let negotiatedMaxFrameBytes, windowBytes: UInt32
  public let cancelRequested: Bool
  public let updateSequence, submittedMonoNs, startedMonoNs, updatedMonoNs, terminalMonoNs: UInt64
  public let detail: String
  /// Core's terminal-transition marker, independent of known state ordinals.
  public var terminal: Bool { terminalMonoNs != 0 }
  /// Recognizes the documented successful end; unknown results are not success.
  public var succeeded: Bool { terminal && state == .ended && result == .ok }
}

extension StreamSessionSnapshot {
  init(native n: coakka_swift_stream_session_snapshot_t) {
    var detail = n.detail
    self.init(direction: StreamDirection(rawValue: n.direction), state: StreamState(rawValue: n.state),
      result: StreamResult(rawValue: n.result), formatID: n.format_id,
      frames: n.frames, bytes: n.bytes, droppedFrames: n.dropped_frames, lastSequence: n.last_sequence,
      negotiatedMaxFrameBytes: n.negotiated_max_frame_bytes, windowBytes: n.window_bytes,
      cancelRequested: n.cancel_requested != 0, updateSequence: n.update_sequence,
      submittedMonoNs: n.submitted_mono_ns, startedMonoNs: n.started_mono_ns,
      updatedMonoNs: n.updated_mono_ns, terminalMonoNs: n.terminal_mono_ns,
      detail: streamDetail(&detail))
  }
}

/// Copied, policy-neutral transport-pressure observation.
/// Durations and timestamps are nanoseconds; `observedDeliveryBps` is bytes per second.
public struct StreamPressureSnapshot: Sendable {
  public let direction: StreamDirection, state: StreamPressureState
  public let reasons: StreamPressureReasons
  public let availableCreditBytes, windowCapacityBytes: UInt32
  public let updateSequence, transitionCount, observedMonoNs, stateStartedMonoNs: UInt64
  public let pressureStartedMonoNs, lastProgressMonoNs, observedDeliveryBps: UInt64
  public let currentOperationNs, lastOperationNs, totalPressuredNs, maxPressuredNs: UInt64
}

extension StreamPressureSnapshot {
  init(native n: coakka_swift_stream_pressure_snapshot_t) {
    self.init(direction: StreamDirection(rawValue: n.direction), state: StreamPressureState(rawValue: n.state),
      reasons: StreamPressureReasons(rawValue: n.reason_bits),
      availableCreditBytes: n.available_credit_bytes, windowCapacityBytes: n.window_capacity_bytes,
      updateSequence: n.update_sequence, transitionCount: n.transition_count,
      observedMonoNs: n.observed_mono_ns, stateStartedMonoNs: n.state_started_mono_ns,
      pressureStartedMonoNs: n.pressure_started_mono_ns, lastProgressMonoNs: n.last_progress_mono_ns,
      observedDeliveryBps: n.observed_delivery_bps, currentOperationNs: n.current_operation_ns,
      lastOperationNs: n.last_operation_ns, totalPressuredNs: n.total_pressured_ns,
      maxPressuredNs: n.max_pressured_ns)
  }
}

/// Bounded queue, active-session, terminal, frame, byte, and drop counters.
public struct StreamLaneStats: Sendable {
  public let capacity, queuedSubscribers, preparedPublishers, activePublishers: Int
  public let activeSubscribers, retainedRecords: Int
  public let submittedSubscribers, preparedPublisherCount, endedPublishers, endedSubscribers: UInt64
  public let failedPublishers, failedSubscribers, canceledSessions, publishedFrames: UInt64
  public let publishedBytes, consumedFrames, consumedBytes, sourceReportedDrops: UInt64
}

private final class StreamSourceHolder: Sendable {
  let callback: StreamSource
  init(_ callback: @escaping StreamSource) { self.callback = callback }
}
private final class StreamConsumerHolder: Sendable {
  let callback: StreamConsumer
  init(_ callback: @escaping StreamConsumer) { self.callback = callback }
}

private let streamSourceThunk: coakka_swift_stream_source_fn = {
  context, destination, capacity, out in
  guard let context, let destination, let out, capacity > 0 else { return COAKKA_V2_ERR_INVALID_ARG }
  let holder = Unmanaged<StreamSourceHolder>.fromOpaque(context).takeUnretainedValue()
  let result = holder.callback(UnsafeMutableRawBufferPointer(start: destination, count: capacity))
  switch result {
  case .wouldBlock: return COAKKA_V2_ERR_WOULD_BLOCK
  case .end: return COAKKA_V2_ERR_CLOSED
  case .frame(let size, let captured, let dropped, let flags):
    guard size > 0, size <= capacity else { return COAKKA_V2_ERR_INVALID_ARG }
    out.pointee.captured_mono_ns = captured
    out.pointee.dropped_before = dropped
    out.pointee.flags = flags.rawValue
    out.pointee.size = size
    return COAKKA_V2_OK
  }
}

private let streamConsumerThunk: coakka_swift_stream_consumer_fn = { context, data, frame in
  guard let context, let data, let frame, frame.pointee.size > 0 else { return COAKKA_V2_ERR_INVALID_ARG }
  let holder = Unmanaged<StreamConsumerHolder>.fromOpaque(context).takeUnretainedValue()
  let metadata = StreamFrameMetadata(
    sequence: frame.pointee.sequence,
    capturedMonoNs: frame.pointee.captured_mono_ns, droppedBefore: frame.pointee.dropped_before,
    flags: StreamFrameFlags(rawValue: frame.pointee.flags))
  return holder.callback(UnsafeRawBufferPointer(start: data, count: frame.pointee.size), metadata)
    == .continue ? COAKKA_V2_OK : COAKKA_V2_ERR_CLOSED
}

/// Independent native streaming lane with synchronized callback and close ownership.
public final class StreamLane: @unchecked Sendable {
  // SAFETY: `condition` serializes lane state and callback ownership; close
  // stops callbacks and drains `activeCalls` before releasing retained holders.
  private let library: NativeRuntimeLibrary
  private let condition = NSCondition()
  private var lane: OpaquePointer?
  private var closing = false
  private var activeCalls = 0
  private let callbacks: StreamCallbackOwners
  private init(library: NativeRuntimeLibrary, lane: OpaquePointer,
    callbacks: StreamCallbackOwners) {
    self.library = library
    self.lane = lane
    self.callbacks = callbacks
  }

  /// Opens and starts a lane.
  /// - Parameters:
  ///   - config: Bounded capabilities, workers, security, flow-control, and pressure settings.
  ///   - runtimeLibPath: Explicit core-runtime path, or `nil` to use package resolution.
  public static func open(
    _ config: StreamLaneConfig = StreamLaneConfig(),
    runtimeLibPath: String? = nil
  ) throws -> StreamLane {
    try openInternal(config, owner: nil, runtimeLibPath: runtimeLibPath)
  }

  /// Opens a lane that can issue replica-pinned publish grants.
  public static func openOwned(
    _ config: StreamLaneConfig = StreamLaneConfig(), owner: LaneOwnerConfig,
    runtimeLibPath: String? = nil
  ) throws -> StreamLane {
    return try openInternal(config, owner: owner, runtimeLibPath: runtimeLibPath)
  }

  private static func openInternal(
    _ config: StreamLaneConfig, owner: LaneOwnerConfig?, runtimeLibPath: String?
  ) throws -> StreamLane {
    // This signed-to-size_t representation guard is host-owned. Core owns
    // flags, resource/timing bounds, cross-field law and effective defaults.
    guard config.capacity >= 0 else { throw RuntimeError.invalidArgument("negative stream-lane capacity") }
    let library = try NativeRuntimeLibrary(path: runtimeNativePath(explicitPath: runtimeLibPath))
    let handle = try library.requireHandle()
    try requireCoreFeature(handle, query: coakka_swift_stream_available, operation: "query Core stream-lane feature")
    if owner != nil { try requireLaneOwnerGrants(library) }
    let strings = try NativeCStringStorage([
      config.bindHost, config.security?.credentialID ?? "",
      config.security?.caCertificateFile ?? "", config.security?.identityCertificateFile ?? "",
      config.security?.privateKeyFile ?? "", owner?.ownerInstanceID ?? "",
      owner?.advertisedHost ?? "",
    ])
    var security = coakka_swift_stream_security_config_t()
    if let value = config.security {
      security.struct_size = MemoryLayout.size(ofValue: security)
      security.mode = value.mode.rawValue
      security.credential_generation = value.credentialGeneration
      security.credential_id = strings[1]
      security.ca_certificate_file = strings[2]
      security.identity_certificate_file = strings[3]
      security.private_key_file = strings[4]
    }
    var native = coakka_swift_stream_config_t()
    native.struct_size = MemoryLayout.size(ofValue: native)
    native.flags = config.flags.rawValue
    native.bind_host = strings[0]
    native.bind_port = config.bindPort
    native.capacity = config.capacity
    native.max_frame_bytes = config.maxFrameBytes
    native.max_window_bytes = config.maxWindowBytes
    native.io_timeout_ms = config.ioTimeoutMs
    native.source_retry_ms = config.sourceRetryMs
    native.progress_frames = config.progressFrames
    native.progress_interval_ms = config.progressIntervalMs
    native.publisher_worker_count = config.publisherWorkerCount
    native.subscriber_worker_count = config.subscriberWorkerCount
    native.pressure_after_ms = config.pressureAfterMs
    native.stalled_after_ms = config.stalledAfterMs
    native.recovery_after_ms = config.recoveryAfterMs
    native.pressure_observation_ms = config.pressureObservationMs
    var out: OpaquePointer?
    let status: Int32
    var nativeOwner = coakka_swift_lane_owner_config_t()
    nativeOwner.struct_size = MemoryLayout.size(ofValue: nativeOwner)
    nativeOwner.owner_instance_id = strings[5]
    nativeOwner.advertised_host = strings[6]
    if config.security != nil {
      status = withUnsafePointer(to: &security) {
        native.security = $0
        if owner != nil {
          var owned = coakka_swift_stream_owned_config_t()
          owned.struct_size = MemoryLayout.size(ofValue: owned)
          owned.lane = native
          owned.owner = nativeOwner
          return coakka_swift_stream_create_owned(handle, &owned, &out)
        }
        return coakka_swift_stream_create(handle, &native, &out)
      }
    } else if owner != nil {
      var owned = coakka_swift_stream_owned_config_t()
      owned.struct_size = MemoryLayout.size(ofValue: owned)
      owned.lane = native
      owned.owner = nativeOwner
      status = coakka_swift_stream_create_owned(handle, &owned, &out)
    } else {
      status = coakka_swift_stream_create(handle, &native, &out)
    }
    try throwIfNativeError(status, operation: "stream_lane_create")
    let created = try requireCoreOwner(out, operation: "Stream Lane creation")
    do {
      var stats = coakka_swift_stream_stats_t()
      try throwIfNativeError(coakka_swift_stream_stats(handle, created, &stats), operation: "stream_lane_stats")
      let callbacks = try StreamCallbackOwners(capacity: stats.capacity)
      try throwIfNativeError(coakka_swift_stream_start(handle, created), operation: "stream_lane_start")
      return StreamLane(library: library, lane: created, callbacks: callbacks)
    } catch {
      coakka_swift_stream_destroy(handle, created)
      throw error
    }
  }

  /// Publisher port selected when the lane started.
  public var boundPort: UInt16 {
    get throws {
      try withLane { h, l in
        var out: UInt16 = 0
        try throwIfNativeError(
          coakka_swift_stream_bound_port(h, l, &out), operation: "stream_lane_bound_port")
        return out
      }
    }
  }

  /// Prepares an authorized publisher. Its source stays rooted until Core
  /// replaces/removes the record, successful `forget`, or completed `close`.
  /// - Parameter spec: Session identity, opaque format, frame bound, and bounded source callback.
  public func preparePublish(_ spec: StreamPublishSpec) throws {
    _ = try preparePublishInternal(spec, grantRequested: false)
  }

  /// Prepares one publisher and returns a single-admission capability for this replica.
  public func preparePublishGrant(_ spec: StreamPublishSpec) throws -> StreamPublishGrant {
    guard let grant = try preparePublishInternal(spec, grantRequested: true) else {
      throw RuntimeError.contractViolation("Core grant projection omitted its accepted value")
    }
    return grant
  }

  private func preparePublishInternal(
    _ spec: StreamPublishSpec, grantRequested: Bool
  ) throws -> StreamPublishGrant? {
    let holder = StreamSourceHolder(spec.source)
    // Even pre-admission refusal must not run captured app deinit beneath a
    // mutation lock/native borrow. Accepted roots additionally live in the owner.
    defer { withExtendedLifetime(holder) {} }
    return try withCallbackMutation { h, l, retired in
      if grantRequested { try requireLaneOwnerGrants(library) }
      let strings = try NativeCStringStorage([spec.sessionID, spec.authorizationToken])
      let pointer = Unmanaged.passUnretained(holder).toOpaque()
      var nativeGrant = coakka_swift_stream_publish_grant_t()
      let status = try callbacks.admit(.init(id: spec.sessionID, direction: .publish), root: holder, call: {
        if grantRequested {
          return coakka_swift_stream_prepare_publish_grant(
              h, l, strings[0], strings[1], spec.formatID, spec.maxFrameBytes,
              streamSourceThunk, pointer, &nativeGrant)
        } else {
          return coakka_swift_stream_prepare_publish(
              h, l, strings[0], strings[1],
              spec.formatID, spec.maxFrameBytes, streamSourceThunk, pointer)
        }
      }, presence: { self.presence(h, l, $0) }, retired: &retired)
      try throwIfNativeError(status, operation: grantRequested ? "stream_lane_prepare_publish_grant" : "stream_lane_prepare_publish")
      guard grantRequested else { return nil }
      var ownerID = nativeGrant.owner.owner_instance_id
      var advertisedHost = nativeGrant.owner.advertised_host
      var sessionID = nativeGrant.session_id
      var token = nativeGrant.authorization_token
      return StreamPublishGrant(
        owner: LaneOwnerEndpoint(
          ownerInstanceID: fixedString(&ownerID), advertisedHost: fixedString(&advertisedHost),
          port: nativeGrant.owner.port),
        sessionID: fixedString(&sessionID), authorizationToken: fixedString(&token),
        formatID: nativeGrant.format_id, maxFrameBytes: nativeGrant.max_frame_bytes)
    }
  }

  /// Queues a subscriber. Its consumer stays rooted until Core removes the
  /// record, successful `forget`, or completed `close`.
  /// - Parameter spec: Endpoint, authorization, opaque format, window, and bounded consumer callback.
  public func subscribe(_ spec: StreamSubscribeSpec) throws {
    let holder = StreamConsumerHolder(spec.consumer)
    defer { withExtendedLifetime(holder) {} }
    try withCallbackMutation { h, l, retired in
      let strings = try NativeCStringStorage([spec.sessionID, spec.authorizationToken, spec.remoteHost])
      let pointer = Unmanaged.passUnretained(holder).toOpaque()
      let status = try callbacks.admit(.init(id: spec.sessionID, direction: .subscribe), root: holder, call: {
          coakka_swift_stream_subscribe(
            h, l, strings[0], strings[1],
            strings[2], spec.remotePort, spec.formatID, spec.maxFrameBytes, spec.initialWindowBytes,
            spec.timeoutMs, streamConsumerThunk, pointer)
      }, presence: { self.presence(h, l, $0) }, retired: &retired)
      try throwIfNativeError(status, operation: "stream_lane_subscribe")
    }
  }

  /// Returns the current copied session snapshot without waiting.
  public func session(_ sessionID: String, direction: StreamDirection) throws
    -> StreamSessionSnapshot
  {
    try readSession(sessionID, direction, 0, 0, false)
  }
  /// Waits for a session update newer than `afterSequence` or for `timeoutMs`.
  public func waitSession(
    _ sessionID: String, direction: StreamDirection, afterSequence: UInt64 = 0,
    timeoutMs: UInt32 = 30_000
  ) throws -> StreamSessionSnapshot {
    try readSession(sessionID, direction, afterSequence, timeoutMs, true)
  }
  private func readSession(
    _ id: String, _ direction: StreamDirection, _ sequence: UInt64,
    _ timeout: UInt32, _ wait: Bool
  ) throws -> StreamSessionSnapshot {
    try validateCString(id, name: "session ID")
    return try withLane { h, l in
      var n = coakka_swift_stream_session_snapshot_t()
      let status = id.withCString {
        wait
          ? coakka_swift_stream_wait_session(h, l, $0, direction.rawValue, sequence, timeout, &n)
          : coakka_swift_stream_get_session(h, l, $0, direction.rawValue, &n)
      }
      try throwIfNativeError(status, operation: "stream_lane_session")
      return StreamSessionSnapshot(native: n)
    }
  }

  /// Returns the current policy-neutral pressure snapshot without waiting.
  public func pressure(_ sessionID: String, direction: StreamDirection) throws
    -> StreamPressureSnapshot
  {
    try readPressure(sessionID, direction, 0, 0, false)
  }
  /// Waits for pressure newer than `afterSequence` or for `timeoutMs`.
  public func waitPressure(
    _ sessionID: String, direction: StreamDirection, afterSequence: UInt64 = 0,
    timeoutMs: UInt32 = 30_000
  ) throws -> StreamPressureSnapshot {
    try readPressure(sessionID, direction, afterSequence, timeoutMs, true)
  }
  private func readPressure(
    _ id: String, _ direction: StreamDirection, _ sequence: UInt64,
    _ timeout: UInt32, _ wait: Bool
  ) throws -> StreamPressureSnapshot {
    try validateCString(id, name: "session ID")
    return try withLane { h, l in
      var n = coakka_swift_stream_pressure_snapshot_t()
      let status = id.withCString {
        wait
          ? coakka_swift_stream_wait_pressure(h, l, $0, direction.rawValue, sequence, timeout, &n)
          : coakka_swift_stream_get_pressure(h, l, $0, direction.rawValue, &n)
      }
      try throwIfNativeError(status, operation: "stream_lane_pressure")
      return StreamPressureSnapshot(native: n)
    }
  }

  /// Requests cooperative cancellation; observe terminal state before forgetting.
  public func cancel(_ id: String, direction: StreamDirection) throws {
    try control(id, direction, false)
  }
  /// Releases a terminal record and its retained callback.
  public func forget(_ id: String, direction: StreamDirection) throws {
    try control(id, direction, true)
  }
  private func control(_ id: String, _ direction: StreamDirection, _ forget: Bool) throws {
    try validateCString(id, name: "session ID")
    try withCallbackMutation { h, l, retired in
      let status = id.withCString {
        forget
          ? coakka_swift_stream_forget(h, l, $0, direction.rawValue)
          : coakka_swift_stream_cancel(h, l, $0, direction.rawValue)
      }
      try throwIfNativeError(status, operation: "stream_lane_control")
      if forget {
        callbacks.forget(.init(id: id, direction: direction), retired: &retired)
      }
    }
  }

  /// Returns copied lane-level queue, frame, byte, and drop counters.
  public func stats() throws -> StreamLaneStats {
    try withLane { h, l in
      var n = coakka_swift_stream_stats_t()
      try throwIfNativeError(coakka_swift_stream_stats(h, l, &n), operation: "stream_lane_stats")
      return StreamLaneStats(
        capacity: n.capacity, queuedSubscribers: n.queued_subscribers,
        preparedPublishers: n.prepared_publishers, activePublishers: n.active_publishers,
        activeSubscribers: n.active_subscribers, retainedRecords: n.retained_records,
        submittedSubscribers: n.submitted_subscribers,
        preparedPublisherCount: n.prepared_publisher_count,
        endedPublishers: n.ended_publishers, endedSubscribers: n.ended_subscribers,
        failedPublishers: n.failed_publishers, failedSubscribers: n.failed_subscribers,
        canceledSessions: n.canceled_sessions, publishedFrames: n.published_frames,
        publishedBytes: n.published_bytes,
        consumedFrames: n.consumed_frames, consumedBytes: n.consumed_bytes,
        sourceReportedDrops: n.source_reported_drops)
    }
  }

  /// Stops the lane, joins native workers, drains host calls, and releases callbacks.
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
    let status = coakka_swift_stream_stop(h, value)
    condition.lock()
    while activeCalls != 0 { condition.wait() }
    coakka_swift_stream_destroy(h, value)
    let retired = callbacks.detach()
    lane = nil
    condition.broadcast()
    condition.unlock()
    withExtendedLifetime(retired) {} // App deinit may reenter only outside lock/borrow.
    if status != 0 && status != -7 {
      try throwIfNativeError(status, operation: "stream_lane_stop")
    }
  }
  deinit { try? close() }
  private func presence(_ h: OpaquePointer, _ l: OpaquePointer, _ key: StreamCallbackKey) -> Int32 {
    var snapshot = coakka_swift_stream_session_snapshot_t()
    return key.id.withCString { coakka_swift_stream_get_session(h, l, $0, key.direction.rawValue, &snapshot) }
  }

  private func withCallbackMutation<T>(
    _ body: (OpaquePointer, OpaquePointer, inout [AnyObject]) throws -> T
  ) throws -> T {
    var retired: [AnyObject] = []
    retired.reserveCapacity(callbacks.limit + 1)
    defer { withExtendedLifetime(retired) {} }
    return try withLane { h, l in
      condition.lock()
      defer { condition.unlock() }
      return try body(h, l, &retired)
    }
  }
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

private func streamDetail<T>(_ tuple: inout T) -> String {
  withUnsafeBytes(of: &tuple) { raw in
    String(decoding: raw.prefix { $0 != 0 }, as: UTF8.self)
  }
}
