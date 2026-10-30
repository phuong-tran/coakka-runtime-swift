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

    static func decodeDeadletter(_ data: Data, reasonName: (UInt32) throws -> String) throws -> RuntimeDeadletter {
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
        guard let code = UInt32(exactly: reason) else {
            throw RuntimeError.invalidArgument("deadletter reason exceeds UInt32 representation")
        }
        return RuntimeDeadletter(
            reasonCode: code, reason: try reasonName(code),
            detail: detail,
            originalMessageID: original.messageID,
            originalSource: original.source,
            originalTarget: original.target
        )
    }

}

private struct FieldTag {
    var number: Int
    var type: Int
}

private struct FieldReader {
    private let bytes: Data
    private var offset = 0

    init(_ data: Data) {
        bytes = data
    }

    mutating func nextTag() throws -> FieldTag? {
        guard offset < bytes.count else {
            return nil
        }
        let value = try readVarintRaw()
        guard value >> 3 != 0 else { throw RuntimeError.invalidArgument("invalid field tag") }
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
        guard let length = Int(exactly: try readVarintRaw()), length <= bytes.count - offset else {
            throw RuntimeError.invalidArgument("truncated field")
        }
        defer {
            offset += length
        }
        return Data(bytes[offset..<offset + length])
    }

    mutating func readString(expected: Int) throws -> String {
        guard let text = String(data: try readBytes(expected: expected), encoding: .utf8) else {
            throw RuntimeError.invalidArgument("invalid UTF-8 field")
        }
        return text
    }

    mutating func skip(_ type: Int) throws {
        switch type {
        case fieldVarint:
            _ = try readVarintRaw()
        case fieldBytes:
            _ = try readBytes(expected: type)
        case 1, 5:
            let size = type == 1 ? 8 : 4
            guard size <= bytes.count - offset else { throw RuntimeError.invalidArgument("truncated fixed field") }
            offset += size
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
            guard shift != 63 || byte <= 1 else { throw RuntimeError.invalidArgument("field value is too large") }
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
