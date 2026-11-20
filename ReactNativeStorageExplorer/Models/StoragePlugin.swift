//
//  StoragePlugin.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

nonisolated enum StoragePlugin: String, CaseIterable, Identifiable, Sendable {
    case asyncStorage
    case mmkv
    case reduxPersist
    case redux
    case zustand
    case mobx
    case realm
    case encryptedStorage

    var id: Self { self }

    var title: String {
        switch self {
        case .asyncStorage: "AsyncStorage"
        case .mmkv: "MMKV"
        case .reduxPersist: "Redux Persist"
        case .redux: "Redux"
        case .zustand: "Zustand"
        case .mobx: "MobX"
        case .realm: "Realm"
        case .encryptedStorage: "Encrypted Storage"
        }
    }

    var packageName: String {
        switch self {
        case .asyncStorage: "@react-native-async-storage/async-storage"
        case .mmkv: "react-native-mmkv"
        case .reduxPersist: "redux-persist"
        case .redux: "react-redux"
        case .zustand: "zustand"
        case .mobx: "mobx"
        case .realm: "realm"
        case .encryptedStorage: "react-native-encrypted-storage"
        }
    }

    var systemImage: String {
        switch self {
        case .asyncStorage: "externaldrive"
        case .mmkv: "bolt.horizontal"
        case .reduxPersist: "square.stack.3d.up"
        case .redux: "point.3.connected.trianglepath.dotted"
        case .zustand: "pawprint"
        case .mobx: "arrow.triangle.branch"
        case .realm: "cylinder.split.1x2"
        case .encryptedStorage: "lock"
        }
    }

    var guideURL: URL? {
        switch self {
        case .redux: URL(string: "https://github.com/Emin91/StorageExplorer/blob/main/docs/plugins/redux.md")
        case .zustand: URL(string: "https://github.com/Emin91/StorageExplorer/blob/main/docs/plugins/zustand.md")
        default: nil
        }
    }

    var isAvailable: Bool {
        switch self {
        case .asyncStorage, .mmkv, .reduxPersist, .redux, .zustand: true
        case .mobx, .realm, .encryptedStorage: false
        }
    }

    var usesMetro: Bool {
        self == .redux || self == .zustand
    }
}
