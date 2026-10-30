import CoAkkaRuntimeC
import Foundation

extension RuntimeHost {
    public func ask(source: String, target: String, payload: Data, timeoutMs: UInt32 = 5_000,
        deliveryHint: DeliveryHint = .routerDefault) throws -> RuntimeResponse {
        let result = try beginAsk(source: source, target: target, payload: payload, timeoutMs: timeoutMs,
            hint: deliveryHint).awaitResult(timeoutMs: timeoutMs, payloadOnly: false)
        let bytes = try accept(result)
        let envelope = try RuntimeEnvelopeCodec.decodeEnvelope(bytes)
        return RuntimeResponse(messageID: envelope.messageID, correlationID: envelope.correlationID,
            source: envelope.source, target: envelope.target, payload: envelope.payload)
    }

    /// Payload-only path. Core validates kind and projects the bytes; no Swift
    /// wire parser, matcher or borrowed native memory escapes the synchronous call.
    public func askPayload(source: String, target: String, payload: Data, timeoutMs: UInt32 = 5_000,
        deliveryHint: DeliveryHint = .routerDefault) throws -> Data {
        try accept(beginAsk(source: source, target: target, payload: payload, timeoutMs: timeoutMs,
            hint: deliveryHint).awaitResult(timeoutMs: timeoutMs, payloadOnly: true))
    }

    /// At most64 jobs per host can be queued/active, with eight process-wide
    /// Dispatch wait lanes. Scheduling is not part of Core's caller wait window.
    /// Task cancellation only
    /// records intent; the worker serializes cancel after/before the full native
    /// wait, never from a cancellation callback. Remote completion remains unknown.
    public func askPayloadAsync(source: String, target: String, payload: Data, timeoutMs: UInt32 = 5_000,
        deliveryHint: DeliveryHint = .routerDefault) async throws -> Data {
        let cancellation = RuntimeCancellation()
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            let ticket = try beginAsk(source: source, target: target, payload: payload, timeoutMs: timeoutMs, hint: deliveryHint)
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<NativeAskResult, Error>) in
                RuntimeAskExecutor.enqueue {
                    do { continuation.resume(returning: try ticket.awaitResult(timeoutMs: timeoutMs, payloadOnly: true, cancellation: cancellation)) }
                    catch { continuation.resume(throwing: error) }
                }
            }
            return try accept(result)
        } onCancel: { cancellation.cancel() }
    }

    public func askText(source: String, target: String, payload: String, timeoutMs: UInt32 = 5_000,
        deliveryHint: DeliveryHint = .routerDefault) throws -> String {
        let bytes = try askPayload(source: source, target: target, payload: Data(payload.utf8), timeoutMs: timeoutMs, deliveryHint: deliveryHint)
        guard let text = String(data: bytes, encoding: .utf8) else { throw RuntimeError.invalidArgument("response payload is not UTF-8") }
        return text
    }

    func beginAsk(source: String, target: String, payload: Data, timeoutMs: UInt32, hint: DeliveryHint) throws -> NativeAskTicket {
        try validateCString(source, name: "source")
        try validateCString(target, name: "target")
        clientLock.lock()
        guard nextID < UInt64.max else { clientLock.unlock(); throw RuntimeError.resourceLimit("message identity space exhausted") }
        nextID += 1
        let id = "\(source)-swift-\(nextID)"
        clientLock.unlock()
        let replyTo = "\(source)/replies"
        return try id.withCString { idPointer in
            try source.withCString { sourcePointer in
                try target.withCString { targetPointer in
                    try replyTo.withCString { replyPointer in
                        try payload.withUnsafeBytes { bytes in
                            var spec = coakka_swift_raw_request_spec_t()
                            spec.struct_size = MemoryLayout.size(ofValue: spec)
                            spec.message_id = idPointer; spec.source = sourcePointer
                            spec.target = targetPointer; spec.reply_to = replyPointer
                            spec.payload = bytes.bindMemory(to: UInt8.self).baseAddress
                            spec.payload_len = payload.count; spec.timeout_ms = timeoutMs
                            spec.delivery_hint = hint.rawValue
                            var wire: UnsafeMutablePointer<UInt8>?
                            var length = 0
                            defer { coakka_swift_client_bytes_release(session.handle, wire) }
                            try throwIfNativeError(coakka_swift_build_raw_request(session.handle, &spec, &wire, &length), operation: "build request")
                            let ticket = try session.begin(wire, count: length)
                            return NativeAskTicket(session: session, ticket: ticket, messageID: id)
                        }
                    }
                }
            }
        }
    }

    private func accept(_ result: NativeAskResult) throws -> Data {
        clientLock.lock()
        if result.kind == UInt32(COAKKA_SWIFT_CLIENT_RESULT_RESPONSE) { matchedResponses &+= 1 }
        if result.kind == UInt32(COAKKA_SWIFT_CLIENT_RESULT_DEADLETTER) { matchedDeadletters &+= 1 }
        clientLock.unlock()
        if result.kind == UInt32(COAKKA_SWIFT_CLIENT_RESULT_DEADLETTER) {
            throw RuntimeError.deadletter(try RuntimeEnvelopeCodec.decodeDeadletter(result.bytes,
                reasonName: { try coreDeadletterReasonName(session.handle, $0) }))
        }
        guard result.kind == UInt32(COAKKA_SWIFT_CLIENT_RESULT_RESPONSE) else {
            throw RuntimeError.contractViolation("Core returned an unknown ask result kind \(result.kind)")
        }
        return result.bytes
    }
}

struct NativeAskResult: Sendable {
    let kind: UInt32
    let bytes: Data
}

/// Created once, transferred to exactly one synchronous call or Dispatch work
/// item. No other caller sees this ticket. The session borrow outlives destroy.
final class NativeAskTicket: @unchecked Sendable {
    let session: RuntimeSession
    let ticket: OpaquePointer
    let messageID: String
    private var consumed = false // accessed only by the exclusive ticket owner
    init(session: RuntimeSession, ticket: OpaquePointer, messageID: String) {
        self.session = session; self.ticket = ticket; self.messageID = messageID
    }

    func awaitResult(timeoutMs: UInt32, payloadOnly: Bool, cancellation: RuntimeCancellation? = nil) throws -> NativeAskResult {
        guard !consumed else { throw RuntimeError.contractViolation("ask ticket already consumed") }
        consumed = true
        let handle = session.handle
        defer {
            coakka_swift_ask_ticket_destroy(handle, ticket)
            session.endBorrow()
        }
        if cancellation?.isCancelled == true {
            coakka_swift_ask_ticket_cancel(handle, ticket)
            throw CancellationError()
        }
        var kind: UInt32 = 0
        var wire: UnsafeMutablePointer<UInt8>?
        var size = 0
        defer { coakka_swift_client_bytes_release(handle, wire) }
        let status = coakka_swift_ask_ticket_await(handle, ticket, timeoutMs, &kind, &wire, &size)
        // Preserve real Core failure even when a task concurrently cancels.
        if status != 0 && status != Int32(COAKKA_SWIFT_STATUS_WOULD_BLOCK) {
            try throwIfNativeError(status, operation: "await ask")
        }
        if cancellation?.isCancelled == true {
            coakka_swift_ask_ticket_cancel(handle, ticket)
            throw CancellationError()
        }
        if status == Int32(COAKKA_SWIFT_STATUS_WOULD_BLOCK) { throw RuntimeError.timeout(messageID) }
        if payloadOnly && kind == UInt32(COAKKA_SWIFT_CLIENT_RESULT_RESPONSE) {
            var payload: UnsafeMutablePointer<UInt8>?
            var length = 0
            defer { coakka_swift_client_bytes_release(handle, payload) }
            try throwIfNativeError(coakka_swift_copy_envelope_payload(handle, wire, size, 2, &payload, &length), operation: "copy response payload")
            return NativeAskResult(kind: kind, bytes: try copyNativeBytes(payload, count: length))
        }
        return NativeAskResult(kind: kind, bytes: try copyNativeBytes(wire, count: size))
    }
}
