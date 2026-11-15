//
//  JSONValue.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

nonisolated indirect enum JSONValue: Equatable, Sendable {
    struct Member: Equatable, Sendable {
        let key: String
        let value: JSONValue
    }

    case object([Member])
    case array([JSONValue])
    case encodedJSON(JSONValue)
    case string(String)
    case number(String)
    case bool(Bool)
    case null

    init?(parsing text: String) {
        guard let object = try? JSONSerialization.jsonObject(with: Data(text.utf8), options: .fragmentsAllowed) else {
            return nil
        }
        self.init(object)
    }

    private init(_ object: Any) {
        switch object {
        case let dictionary as [String: Any]:
            let isReduxPersistState = Self.isReduxPersistState(dictionary)
            self = .object(
                dictionary
                    .map { key, value in
                        Member(key: key, value: isReduxPersistState ? Self.decodedMember(value) : JSONValue(value))
                    }
                    .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
            )
        case let array as [Any]:
            self = .array(array.map { JSONValue($0) })
        case let string as String:
            self = Self.decodedContainer(in: string).map(JSONValue.encodedJSON) ?? .string(string)
        case let number as NSNumber:
            self = CFGetTypeID(number) == CFBooleanGetTypeID() ? .bool(number.boolValue) : .number(number.stringValue)
        default:
            self = .null
        }
    }

    private static func isReduxPersistState(_ dictionary: [String: Any]) -> Bool {
        guard let persist = dictionary["_persist"] as? String else { return false }
        return JSONValue(parsing: persist)?.children != nil
    }

    private static func decodedMember(_ value: Any) -> JSONValue {
        guard let string = value as? String, let decoded = JSONValue(parsing: string) else { return JSONValue(value) }
        return decoded.children != nil ? .encodedJSON(decoded) : decoded
    }

    private static func decodedContainer(in string: String) -> JSONValue? {
        guard let first = string.first(where: { !$0.isWhitespace }), first == "{" || first == "[",
              let value = JSONValue(parsing: string) else { return nil }
        return value
    }

    var children: [(label: String, value: JSONValue)]? {
        switch self {
        case .object(let members): members.map { ($0.key, $0.value) }
        case .array(let elements): elements.enumerated().map { ("\($0.offset)", $0.element) }
        case .encodedJSON(let value): value.children
        default: nil
        }
    }

    var summary: String {
        switch self {
        case .object(let members): "{\(members.count)}"
        case .array(let elements): "[\(elements.count)]"
        case .encodedJSON(let value): "\"\(value.summary)\""
        default: ""
        }
    }
}
