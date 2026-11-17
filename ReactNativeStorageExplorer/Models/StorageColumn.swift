//
//  StorageColumn.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

enum StorageColumn: String, CaseIterable, Identifiable {
    case value
    case type
    case size
    case modified

    var id: Self { self }

    var title: String {
        switch self {
        case .value: "Value"
        case .type: "Type"
        case .size: "Size"
        case .modified: "Modified"
        }
    }

    enum LayoutKey {
        static let keyWidth = "storageTable.keyWidth"
        static let typeWidth = "storageTable.typeWidth"
        static let sizeWidth = "storageTable.sizeWidth"
        static let modifiedWidth = "storageTable.modifiedWidth"
        static let hiddenColumns = "storageTable.hiddenColumns"

        static let all = [keyWidth, typeWidth, sizeWidth, modifiedWidth, hiddenColumns]
    }

    static func hiddenColumns(from storedValue: String) -> Set<StorageColumn> {
        Set(storedValue.split(separator: ",").compactMap { StorageColumn(rawValue: String($0)) })
    }

    static func storedValue(for hiddenColumns: Set<StorageColumn>) -> String {
        allCases.filter(hiddenColumns.contains).map(\.rawValue).joined(separator: ",")
    }
}
