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
    let type: StorageValueType
    let size: Int
    var modifiedAt: Date?

    var id: String {
        namespace.map { "\($0)/\(key)" } ?? key
    }

    init(key: String, value: String, namespace: String? = nil, type: StorageValueType? = nil, modifiedAt: Date? = nil) {
        self.key = key
        self.value = value
        self.namespace = namespace
        self.type = type ?? StorageValueType(inferringFrom: value)
        self.size = value.utf8.count
        self.modifiedAt = modifiedAt
    }
}
