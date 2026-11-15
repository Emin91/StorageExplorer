//
//  SearchScope.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

enum SearchScope: String, CaseIterable, Identifiable {
    case all
    case keys
    case values

    var id: Self { self }

    var title: String {
        switch self {
        case .all: "Keys and Values"
        case .keys: "Keys Only"
        case .values: "Values Only"
        }
    }

    var includesKeys: Bool { self != .values }
    var includesValues: Bool { self != .keys }
}
