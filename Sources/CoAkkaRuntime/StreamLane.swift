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
/// Side of a retained stream record.
public enum StreamDirection: UInt32, Sendable {
  case publish = 1
  case subscribe = 2
}
/// Observable lifecycle state for one stream side.
public enum StreamState: UInt32, Sendable {
  case prepared = 1
  case queued, connecting, active, stopping, ended, rejected, failed, canceled
}
/// Stable terminal outcome reported independently by each peer.
public enum StreamResult: UInt32, Sendable {
  case none = 0
  case ok, notPrepared, tokenMismatch, formatMismatch, frameLimit, networkIO, timeout
  case queueFull, protocolError, sourceError, consumerError, internalError, canceledByHost
  case tlsConfigInvalid, tlsHandshakeFailed, peerCertUntrusted, peerCertExpired
  case peerIdentityMismatch, clientCertRequired
}
/// Coalesced transport pressure consumed by app-host policy.
public enum StreamPressureState: UInt32, Sendable {
  case inactive = 0
  case flowing, pressured, stalled, recovering
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
public typealias StreamSource = (UnsafeMutableRawBufferPointer) -> StreamSourceResult
/// Consumes borrowed bytes. The buffer is valid only during the callback.
public typealias StreamConsumer = (UnsafeRawBufferPointer, StreamFrameMetadata) ->
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
/// Zero tuning values select conservative native defaults.
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
public struct StreamPublishSpec {
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
public struct StreamSubscribeSpec {
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

/// Copied session progress with process-local monotonic timestamps.
public struct StreamSessionSnapshot: Sendable {
  public let direction: StreamDirection, state: StreamState, result: StreamResult
  public let formatID, frames, bytes, droppedFrames, lastSequence: UInt64
  public let negotiatedMaxFrameBytes, windowBytes: UInt32
  public let cancelRequested: Bool
  public let updateSequence, submittedMonoNs, startedMonoNs, updatedMonoNs, terminalMonoNs: UInt64
  public let detail: String
  public var terminal: Bool { state.rawValue >= StreamState.ended.rawValue }
  public var succeeded: Bool { state == .ended && result == .ok }
}

/// Copied, policy-neutral transport-pressure observation.
public struct StreamPressureSnapshot: Sendable {
  public let direction: StreamDirection, state: StreamPressureState
  public let reasons: StreamPressureReasons
  public let availableCreditBytes, windowCapacityBytes: UInt32
  public let updateSequence, transitionCount, observedMonoNs, stateStartedMonoNs: UInt64
  public let pressureStartedMonoNs, lastProgressMonoNs, observedDeliveryBps: UInt64
  public let currentOperationNs, lastOperationNs, totalPressuredNs, maxPressuredNs: UInt64
}

/// Bounded queue, active-session, terminal, frame, byte, and drop counters.
public struct StreamLaneStats: Sendable {
  public let capacity, queuedSubscribers, preparedPublishers, activePublishers: Int
  public let activeSubscribers, retainedRecords: Int
  public let submittedSubscribers, preparedPublisherCount, endedPublishers, endedSubscribers: UInt64
  public let failedPublishers, failedSubscribers, canceledSessions, publishedFrames: UInt64
  public let publishedBytes, consumedFrames, consumedBytes, sourceReportedDrops: UInt64
}

private final class StreamSourceHolder: @unchecked Sendable {
  let callback: StreamSource
  init(_ callback: @escaping StreamSource) { self.callback = callback }
}
private final class StreamConsumerHolder: @unchecked Sendable {
  let callback: StreamConsumer
  init(_ callback: @escaping StreamConsumer) { self.callback = callback }
}

private let streamSourceThunk: coakka_swift_stream_source_fn = {
  context, destination, capacity, out in
  guard let context, let destination, let out, capacity > 0 else { return -1 }
  let holder = Unmanaged<StreamSourceHolder>.fromOpaque(context).takeUnretainedValue()
  let result = holder.callback(UnsafeMutableRawBufferPointer(start: destination, count: capacity))
  switch result {
  case .wouldBlock: return -6
  case .end: return -7
  case .frame(let size, let captured, let dropped, let flags):
    guard size > 0, size <= capacity else { return -1 }
    out.pointee.captured_mono_ns = captured
    out.pointee.dropped_before = dropped
    out.pointee.flags = flags.rawValue
    out.pointee.size = size
    return 0
  }
}

private let streamConsumerThunk: coakka_swift_stream_consumer_fn = { context, data, frame in
  guard let context, let data, let frame, frame.pointee.size > 0 else { return -1 }
  let holder = Unmanaged<StreamConsumerHolder>.fromOpaque(context).takeUnretainedValue()
  let metadata = StreamFrameMetadata(
    sequence: frame.pointee.sequence,
    capturedMonoNs: frame.pointee.captured_mono_ns, droppedBefore: frame.pointee.dropped_before,
    flags: StreamFrameFlags(rawValue: frame.pointee.flags))
  return holder.callback(UnsafeRawBufferPointer(start: data, count: frame.pointee.size), metadata)
    == .continue ? 0 : -7
}

private struct StreamCallbackKey: Hashable {
  let id: String
  let direction: StreamDirection
}

/// Independent native streaming lane with synchronized callback and close ownership.
public final class StreamLane: @unchecked Sendable {
  private let library: NativeRuntimeLibrary
  private let condition = NSCondition()
  private var lane: OpaquePointer?
  private var closing = false
  private var activeCalls = 0
  private var callbacks: [StreamCallbackKey: UnsafeMutableRawPointer] = [:]
  private init(library: NativeRuntimeLibrary, lane: OpaquePointer) {
    self.library = library
    self.lane = lane
  }

  /// Opens and starts a lane.
  /// - Parameters:
  ///   - config: Bounded capabilities, workers, security, flow-control, and pressure settings.
  ///   - runtimeLibPath: Explicit native runtime path, or `nil` to use package resolution.
  public static func open(
    _ config: StreamLaneConfig = StreamLaneConfig(),
    runtimeLibPath: String? = nil
  ) throws -> StreamLane {
    let allowed = StreamLaneFlags.publisher.rawValue | StreamLaneFlags.subscriber.rawValue
    guard !config.flags.isEmpty, config.flags.rawValue & ~allowed == 0, config.capacity <= 64,
      config.maxFrameBytes <= 4 * 1024 * 1024, config.maxWindowBytes <= 16 * 1024 * 1024,
      config.sourceRetryMs <= 1_000, config.publisherWorkerCount <= 4,
      config.subscriberWorkerCount <= 4,
      [
        config.pressureAfterMs, config.stalledAfterMs, config.recoveryAfterMs,
        config.pressureObservationMs,
      ].allSatisfy({ $0 <= 60_000 }),
      config.maxFrameBytes == 0 || config.maxWindowBytes == 0
        || config.maxWindowBytes >= config.maxFrameBytes
    else { throw RuntimeError.invalidArgument("invalid stream-lane bounds or worker count") }
    let library = try NativeRuntimeLibrary(path: runtimeNativePath(explicitPath: runtimeLibPath))
    let handle = try library.requireHandle()
    guard coakka_swift_stream_available(handle) != 0 else {
      throw RuntimeError.loadFailed("native runtime does not export complete stream-lane ABI")
    }
    let strings = StreamCStringOwner([
      config.bindHost, config.security?.credentialID ?? "",
      config.security?.caCertificateFile ?? "", config.security?.identityCertificateFile ?? "",
      config.security?.privateKeyFile ?? "",
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
    if config.security != nil {
      status = withUnsafePointer(to: &security) {
        native.security = $0
        return coakka_swift_stream_create(handle, &native, &out)
      }
    } else {
      status = coakka_swift_stream_create(handle, &native, &out)
    }
    try throwIfNativeError(status, operation: "stream_lane_create")
    guard let out else { throw RuntimeError.nativeStatus(-2, "stream_lane_create") }
    let start = coakka_swift_stream_start(handle, out)
    if start != 0 {
      coakka_swift_stream_destroy(handle, out)
      try throwIfNativeError(start, operation: "stream_lane_start")
    }
    return StreamLane(library: library, lane: out)
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

  /// Prepares an authorized publisher and retains its source until `forget` or `close`.
  /// - Parameter spec: Session identity, opaque format, frame bound, and bounded source callback.
  public func preparePublish(_ spec: StreamPublishSpec) throws {
    try validate(spec.sessionID, spec.authorizationToken, spec.maxFrameBytes)
    try withLane { h, l in
      let holder = Unmanaged.passRetained(StreamSourceHolder(spec.source))
      let pointer = holder.toOpaque()
      let strings = StreamCStringOwner([spec.sessionID, spec.authorizationToken])
      do {
        try throwIfNativeError(
          coakka_swift_stream_prepare_publish(
            h, l, strings[0], strings[1],
            spec.formatID, spec.maxFrameBytes, streamSourceThunk, pointer),
          operation: "stream_lane_prepare_publish")
      } catch {
        holder.release()
        throw error
      }
      condition.lock()
      callbacks[StreamCallbackKey(id: spec.sessionID, direction: .publish)] = pointer
      condition.unlock()
    }
  }

  /// Queues a subscriber and retains its consumer until `forget` or `close`.
  /// - Parameter spec: Endpoint, authorization, opaque format, window, and bounded consumer callback.
  public func subscribe(_ spec: StreamSubscribeSpec) throws {
    try validate(spec.sessionID, spec.authorizationToken, spec.maxFrameBytes)
    guard !spec.remoteHost.isEmpty, spec.remotePort > 0 else {
      throw RuntimeError.invalidArgument("remote host and port are required")
    }
    try withLane { h, l in
      let holder = Unmanaged.passRetained(StreamConsumerHolder(spec.consumer))
      let pointer = holder.toOpaque()
      let strings = StreamCStringOwner([spec.sessionID, spec.authorizationToken, spec.remoteHost])
      do {
        try throwIfNativeError(
          coakka_swift_stream_subscribe(
            h, l, strings[0], strings[1],
            strings[2], spec.remotePort, spec.formatID, spec.maxFrameBytes, spec.initialWindowBytes,
            spec.timeoutMs, streamConsumerThunk, pointer), operation: "stream_lane_subscribe")
      } catch {
        holder.release()
        throw error
      }
      condition.lock()
      callbacks[StreamCallbackKey(id: spec.sessionID, direction: .subscribe)] = pointer
      condition.unlock()
    }
  }

  /// Returns the current copied session snapshot without waiting.
  public func session(_ id: String, direction: StreamDirection) throws -> StreamSessionSnapshot {
    try readSession(id, direction, 0, 0, false)
  }
  /// Waits for a session update newer than `afterSequence` or for `timeoutMs`.
  public func waitSession(
    _ id: String, direction: StreamDirection, afterSequence: UInt64 = 0,
    timeoutMs: UInt32 = 30_000
  ) throws -> StreamSessionSnapshot {
    try readSession(id, direction, afterSequence, timeoutMs, true)
  }
  private func readSession(
    _ id: String, _ direction: StreamDirection, _ sequence: UInt64,
    _ timeout: UInt32, _ wait: Bool
  ) throws -> StreamSessionSnapshot {
    try withLane { h, l in
      var n = coakka_swift_stream_session_snapshot_t()
      let status = id.withCString {
        wait
          ? coakka_swift_stream_wait_session(h, l, $0, direction.rawValue, sequence, timeout, &n)
          : coakka_swift_stream_get_session(h, l, $0, direction.rawValue, &n)
      }
      try throwIfNativeError(status, operation: "stream_lane_session")
      return StreamSessionSnapshot(
        direction: StreamDirection(rawValue: n.direction)!,
        state: StreamState(rawValue: n.state)!, result: StreamResult(rawValue: n.result)!,
        formatID: n.format_id,
        frames: n.frames, bytes: n.bytes, droppedFrames: n.dropped_frames,
        lastSequence: n.last_sequence,
        negotiatedMaxFrameBytes: n.negotiated_max_frame_bytes, windowBytes: n.window_bytes,
        cancelRequested: n.cancel_requested != 0, updateSequence: n.update_sequence,
        submittedMonoNs: n.submitted_mono_ns, startedMonoNs: n.started_mono_ns,
        updatedMonoNs: n.updated_mono_ns, terminalMonoNs: n.terminal_mono_ns,
        detail: streamDetail(&n.detail))
    }
  }

  /// Returns the current policy-neutral pressure snapshot without waiting.
  public func pressure(_ id: String, direction: StreamDirection) throws -> StreamPressureSnapshot {
    try readPressure(id, direction, 0, 0, false)
  }
  /// Waits for pressure newer than `afterSequence` or for `timeoutMs`.
  public func waitPressure(
    _ id: String, direction: StreamDirection, afterSequence: UInt64 = 0,
    timeoutMs: UInt32 = 30_000
  ) throws -> StreamPressureSnapshot {
    try readPressure(id, direction, afterSequence, timeoutMs, true)
  }
  private func readPressure(
    _ id: String, _ direction: StreamDirection, _ sequence: UInt64,
    _ timeout: UInt32, _ wait: Bool
  ) throws -> StreamPressureSnapshot {
    try withLane { h, l in
      var n = coakka_swift_stream_pressure_snapshot_t()
      let status = id.withCString {
        wait
          ? coakka_swift_stream_wait_pressure(h, l, $0, direction.rawValue, sequence, timeout, &n)
          : coakka_swift_stream_get_pressure(h, l, $0, direction.rawValue, &n)
      }
      try throwIfNativeError(status, operation: "stream_lane_pressure")
      return StreamPressureSnapshot(
        direction: StreamDirection(rawValue: n.direction)!,
        state: StreamPressureState(rawValue: n.state)!,
        reasons: StreamPressureReasons(rawValue: n.reason_bits),
        availableCreditBytes: n.available_credit_bytes,
        windowCapacityBytes: n.window_capacity_bytes,
        updateSequence: n.update_sequence, transitionCount: n.transition_count,
        observedMonoNs: n.observed_mono_ns,
        stateStartedMonoNs: n.state_started_mono_ns,
        pressureStartedMonoNs: n.pressure_started_mono_ns,
        lastProgressMonoNs: n.last_progress_mono_ns, observedDeliveryBps: n.observed_delivery_bps,
        currentOperationNs: n.current_operation_ns, lastOperationNs: n.last_operation_ns,
        totalPressuredNs: n.total_pressured_ns, maxPressuredNs: n.max_pressured_ns)
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
    try withLane { h, l in
      let status = id.withCString {
        forget
          ? coakka_swift_stream_forget(h, l, $0, direction.rawValue)
          : coakka_swift_stream_cancel(h, l, $0, direction.rawValue)
      }
      try throwIfNativeError(status, operation: "stream_lane_control")
      if forget {
        condition.lock()
        let pointer = callbacks.removeValue(forKey: .init(id: id, direction: direction))
        condition.unlock()
        if let pointer { releaseCallback(pointer, direction) }
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
    for (key, pointer) in callbacks { releaseCallback(pointer, key.direction) }
    callbacks.removeAll()
    lane = nil
    condition.broadcast()
    condition.unlock()
    if status != 0 && status != -7 {
      try throwIfNativeError(status, operation: "stream_lane_stop")
    }
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

private func validate(_ id: String, _ token: String, _ maxFrame: UInt32) throws {
  guard !id.isEmpty, id.utf8.count <= 64, !token.isEmpty, token.utf8.count <= 128,
    maxFrame > 0, maxFrame <= 4 * 1024 * 1024
  else {
    throw RuntimeError.invalidArgument("invalid session identity or frame bound")
  }
}
private func releaseCallback(_ pointer: UnsafeMutableRawPointer, _ direction: StreamDirection) {
  if direction == .publish {
    Unmanaged<StreamSourceHolder>.fromOpaque(pointer).release()
  } else {
    Unmanaged<StreamConsumerHolder>.fromOpaque(pointer).release()
  }
}
private func streamDetail<T>(_ tuple: inout T) -> String {
  withUnsafeBytes(of: &tuple) { raw in
    String(decoding: raw.prefix { $0 != 0 }, as: UTF8.self)
  }
}
private final class StreamCStringOwner {
  private var pointers: [UnsafeMutablePointer<CChar>] = []
  init(_ values: [String]) {
    for value in values {
      let bytes = value.utf8CString
      let pointer = UnsafeMutablePointer<CChar>.allocate(capacity: bytes.count)
      bytes.withUnsafeBufferPointer {
        pointer.initialize(from: $0.baseAddress!, count: bytes.count)
      }
      pointers.append(pointer)
    }
  }
  deinit { for pointer in pointers { pointer.deallocate() } }
  subscript(_ index: Int) -> UnsafePointer<CChar> { UnsafePointer(pointers[index]) }
}
