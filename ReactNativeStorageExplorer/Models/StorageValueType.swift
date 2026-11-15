//
//  StorageValueType.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

nonisolated enum StorageValueType: String, Sendable {
    case string
    case number
    case boolean
    case null
    case object
    case array
    case binary

    init(inferringFrom value: String) {
        guard let json = try? JSONSerialization.jsonObject(with: Data(value.utf8), options: .fragmentsAllowed) else {
            self = .string
            return
        }

        switch json {
        case is [Any]: self = .array
        case is [String: Any]: self = .object
        case is NSNull: self = .null
        case let number as NSNumber:
            self = CFGetTypeID(number) == CFBooleanGetTypeID() ? .boolean : .number
        default: self = .string
        }
    }

    var title: String { rawValue.capitalized }
}
