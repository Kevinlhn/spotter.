//
//  AnyCodable.swift
//  Lightweight representation for arbitrary JSON values.
//
import Foundation

public struct AnyCodable: Codable, Sendable, Hashable, Equatable {
    public let value: Any

    // Normalize common bridged numeric types so equality/hash behave predictably
    public init(normalizing value: Any) {
        switch value {
        case let number as NSNumber:
            // Distinguish between Bool and numeric NSNumbers
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                self.value = number.boolValue
            } else {
                // Prefer Int when representable exactly, otherwise Double
                let double = number.doubleValue
                let int = number.int64Value
                if Double(int) == double { self.value = Int(truncatingIfNeeded: int) } else { self.value = double }
            }
        case let array as [Any]:
            self.value = array.map { AnyCodable(normalizing: $0).value }
        case let dict as [String: Any]:
            var out: [String: Any] = [:]
            for (k, v) in dict { out[k] = AnyCodable(normalizing: v).value }
            self.value = out
        default:
            self.value = value
        }
    }

    public init(_ value: Any) {
        self = AnyCodable(normalizing: value)
    }
}

extension AnyCodable {
    private static func equals(_ lhs: Any, _ rhs: Any) -> Bool {
        switch (lhs, rhs) {
        case (is NSNull, is NSNull):
            return true
        case let (l as Bool, r as Bool):
            return l == r
        case let (l as Int, r as Int):
            return l == r
        case let (l as Double, r as Double):
            return l == r
        case let (l as String, r as String):
            return l == r
        case let (l as [Any], r as [Any]):
            guard l.count == r.count else { return false }
            for (le, re) in zip(l, r) {
                if !equals(le, re) { return false }
            }
            return true
        case let (l as [String: Any], r as [String: Any]):
            if l.count != r.count { return false }
            // Compare by keys then values recursively
            for (key, lval) in l {
                guard let rval = r[key] else { return false }
                if !equals(lval, rval) { return false }
            }
            return true
        default:
            return false
        }
    }
}

extension AnyCodable {
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        return equals(lhs.value, rhs.value)
    }
}

extension AnyCodable {
    public func hash(into hasher: inout Hasher) {
        switch value {
        case is NSNull:
            hasher.combine(0)
        case let v as Bool:
            hasher.combine(1)
            hasher.combine(v)
        case let v as Int:
            hasher.combine(2)
            hasher.combine(v)
        case let v as Double:
            hasher.combine(3)
            hasher.combine(v)
        case let v as String:
            hasher.combine(4)
            hasher.combine(v)
        case let arr as [Any]:
            hasher.combine(5)
            for e in arr { AnyCodable(e).hash(into: &hasher) }
        case let dict as [String: Any]:
            hasher.combine(6)
            // Ensure order-independent hashing by sorting keys
            for key in dict.keys.sorted() {
                hasher.combine(key)
                AnyCodable(dict[key]!).hash(into: &hasher)
            }
        default:
            // Unsupported types should not occur if created via decoding; still provide a stable bucket
            hasher.combine(999)
            hasher.combine(String(describing: type(of: value)))
        }
    }
}

extension AnyCodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self.value = NSNull(); return }
        if let int = try? container.decode(Int.self) { self.value = int; return }
        if let dbl = try? container.decode(Double.self) { self.value = dbl; return }
        if let bool = try? container.decode(Bool.self) { self.value = bool; return }
        if let string = try? container.decode(String.self) { self.value = string; return }
        if let arr = try? container.decode([AnyCodable].self) { self.value = arr.map { $0.value }; return }
        if let dict = try? container.decode([String: AnyCodable].self) { self.value = dict.mapValues { $0.value }; return }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let int as Int:
            try container.encode(int)
        case let dbl as Double:
            try container.encode(dbl)
        case let bool as Bool:
            try container.encode(bool)
        case let string as String:
            try container.encode(string)
        case let arr as [Any]:
            try container.encode(arr.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            let ctx = EncodingError.Context(codingPath: container.codingPath, debugDescription: "Unsupported JSON")
            throw EncodingError.invalidValue(value, ctx)
        }
    }
}
