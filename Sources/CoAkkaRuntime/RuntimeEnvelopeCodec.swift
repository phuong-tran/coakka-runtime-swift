import Foundation

private let fieldVarint = 0
private let fieldBytes = 2

struct RuntimeEnvelope {
    var messageID = ""
    var correlationID = ""
    var source = ""
    var target = ""
    var kind: UInt64 = 0
    var oneWay = false
    var payload = Data()
}

enum RuntimeEnvelopeCodec {
    static func decodeEnvelope(_ data: Data) throws -> RuntimeEnvelope {
        var reader = FieldReader(data)
        var envelope = RuntimeEnvelope()
        while let tag = try reader.nextTag() {
            switch tag.number {
            case 1:
                envelope.messageID = try reader.readString(expected: tag.type)
            case 2:
                envelope.correlationID = try reader.readString(expected: tag.type)
            case 3:
                envelope.source = try reader.readString(expected: tag.type)
            case 4:
                envelope.target = try reader.readString(expected: tag.type)
            case 6:
                envelope.kind = try reader.readVarint(expected: tag.type)
            case 7:
                envelope.oneWay = try reader.readVarint(expected: tag.type) != 0
            case 9:
                envelope.payload = try reader.readBytes(expected: tag.type)
            default:
                try reader.skip(tag.type)
            }
        }
        return envelope
    }

    static func decodeDeadletter(_ data: Data) throws -> RuntimeDeadletter {
        var reader = FieldReader(data)
        var original = RuntimeEnvelope()
        var reason: UInt64 = 0
        var detail = ""
        while let tag = try reader.nextTag() {
            switch tag.number {
            case 1:
                original = try decodeEnvelope(try reader.readBytes(expected: tag.type))
            case 2:
                reason = try reader.readVarint(expected: tag.type)
            case 3:
                detail = try reader.readString(expected: tag.type)
            default:
                try reader.skip(tag.type)
            }
        }
        return RuntimeDeadletter(
            reason: reasonName(reason),
            detail: detail,
            originalMessageID: original.messageID,
            originalSource: original.source,
            originalTarget: original.target
        )
    }

    private static func reasonName(_ value: UInt64) -> String {
        switch value {
        case 1:
            return "DEADLETTER_REASON_NO_ACTIVE_SNAPSHOT"
        case 2:
            return "DEADLETTER_REASON_ROUTE_MISS"
        case 3:
            return "DEADLETTER_REASON_NO_RESPONSIBLE_HOST"
        case 4:
            return "DEADLETTER_REASON_QUEUE_REJECTED"
        case 5:
            return "DEADLETTER_REASON_LOCAL_HANDOFF_FAILED"
        case 6:
            return "DEADLETTER_REASON_DELIVERY_FAILED"
        case 7:
            return "DEADLETTER_REASON_REMOTE_SEND_FAILED"
        default:
            return "DEADLETTER_REASON_UNSPECIFIED"
        }
    }
}

private struct FieldTag {
    var number: Int
    var type: Int
}

private struct FieldReader {
    private let bytes: [UInt8]
    private var offset = 0

    init(_ data: Data) {
        bytes = Array(data)
    }

    mutating func nextTag() throws -> FieldTag? {
        guard offset < bytes.count else {
            return nil
        }
        let value = try readVarintRaw()
        return FieldTag(number: Int(value >> 3), type: Int(value & 0x7))
    }

    mutating func readVarint(expected: Int) throws -> UInt64 {
        guard expected == fieldVarint else {
            throw RuntimeError.invalidArgument("unexpected field type \(expected)")
        }
        return try readVarintRaw()
    }

    mutating func readBytes(expected: Int) throws -> Data {
        guard expected == fieldBytes else {
            throw RuntimeError.invalidArgument("unexpected field type \(expected)")
        }
        let length = Int(try readVarintRaw())
        guard length >= 0, offset + length <= bytes.count else {
            throw RuntimeError.invalidArgument("truncated field")
        }
        defer {
            offset += length
        }
        return Data(bytes[offset..<offset + length])
    }

    mutating func readString(expected: Int) throws -> String {
        String(data: try readBytes(expected: expected), encoding: .utf8) ?? ""
    }

    mutating func skip(_ type: Int) throws {
        switch type {
        case fieldVarint:
            _ = try readVarintRaw()
        case fieldBytes:
            _ = try readBytes(expected: type)
        default:
            throw RuntimeError.invalidArgument("unsupported field type \(type)")
        }
    }

    private mutating func readVarintRaw() throws -> UInt64 {
        var result: UInt64 = 0
        var shift: UInt64 = 0
        while offset < bytes.count {
            let byte = bytes[offset]
            offset += 1
            result |= UInt64(byte & 0x7f) << shift
            if byte & 0x80 == 0 {
                return result
            }
            shift += 7
            if shift >= 64 {
                throw RuntimeError.invalidArgument("field value is too large")
            }
        }
        throw RuntimeError.invalidArgument("truncated field")
    }
}
