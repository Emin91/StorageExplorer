//
//  StorageItem.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

nonisolated struct StorageItem: Identifiable, Hashable, Sendable {
    let key: String
    let value: String
    let namespace: String?
    let group: String?
    let type: StorageValueType
    let size: Int
    let preview: String
    var modifiedAt: Date?

    var id: String {
        namespace.map { "\($0)/\(key)" } ?? key
    }

    private static let previewLength = 300

    private static func preview(of value: String) -> String {
        let start = value.prefix(previewLength)
            .replacingOccurrences(of: "\n", with: " ")
        let isTruncated = value.prefix(previewLength + 1).count > previewLength
        return isTruncated ? start + "…" : start
    }

    init(
        key: String,
        value: String,
        namespace: String? = nil,
        group: String? = nil,
        type: StorageValueType? = nil,
        modifiedAt: Date? = nil
    ) {
        self.key = key
        self.value = value
        self.namespace = namespace
        self.group = group
        self.type = type ?? StorageValueType(inferringFrom: value)
        self.size = value.utf8.count
        self.preview = Self.preview(of: value)
        self.modifiedAt = modifiedAt
    }
}
