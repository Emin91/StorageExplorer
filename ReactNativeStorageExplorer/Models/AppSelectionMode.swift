//
//  AppSelectionMode.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

enum AppSelectionMode: String, CaseIterable, Identifiable {
    case followRunningApp
    case rememberLastApp

    var id: Self { self }

    var title: String {
        switch self {
        case .followRunningApp: "Running App"
        case .rememberLastApp: "Last Selected App"
        }
    }
}
