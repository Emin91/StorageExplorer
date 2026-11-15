//
//  ReduxPersistParser.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

nonisolated struct ReduxPersistParser {
    private static let keyPrefix = "persist:"

    func items(from storageItems: [StorageItem]) -> [StorageItem] {
        storageItems
            .filter { $0.key.hasPrefix(Self.keyPrefix) }
            .flatMap(slices(of:))
            .sorted {
                ($0.namespace ?? "", $0.key.lowercased()) < ($1.namespace ?? "", $1.key.lowercased())
            }
    }

    private func slices(of item: StorageItem) -> [StorageItem] {
        let configKey = String(item.key.dropFirst(Self.keyPrefix.count))

        guard let object = try? JSONSerialization.jsonObject(with: Data(item.value.utf8)) as? [String: Any] else {
            return [StorageItem(key: configKey, value: item.value, modifiedAt: item.modifiedAt)]
        }

        return object.map { sliceKey, sliceValue in
            StorageItem(
                key: sliceKey,
                value: (sliceValue as? String) ?? jsonString(from: sliceValue),
                namespace: configKey,
                modifiedAt: item.modifiedAt
            )
        }
    }

    private func jsonString(from value: Any) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed, .sortedKeys]) else {
            return String(describing: value)
        }
        return String(decoding: data, as: UTF8.self)
    }
}
