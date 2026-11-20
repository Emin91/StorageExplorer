//
//  StorageSource.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

enum StorageChangeDetection {
    case directoryEvents
    case polling
}

protocol StorageSource {
    var changeDetection: StorageChangeDetection { get }
    func directoryURL(for location: StorageLocation) -> URL?
    func readItems(for location: StorageLocation) async throws -> [StorageItem]
}

struct AsyncStorageSource: StorageSource {
    private let reader = AsyncStorageReader()

    var changeDetection: StorageChangeDetection { .directoryEvents }

    func directoryURL(for location: StorageLocation) -> URL? {
        location.asyncStorageURL
    }

    func readItems(for location: StorageLocation) async throws -> [StorageItem] {
        guard let directoryURL = location.asyncStorageURL else { return [] }
        return try await reader.readItems(in: directoryURL)
    }
}

struct MMKVSource: StorageSource {
    private let reader = MMKVReader()

    var changeDetection: StorageChangeDetection { .polling }

    func directoryURL(for location: StorageLocation) -> URL? {
        location.mmkvURL
    }

    func readItems(for location: StorageLocation) async throws -> [StorageItem] {
        guard let directoryURL = location.mmkvURL else { return [] }
        return try await reader.readItems(in: directoryURL)
    }
}

final class ReduxSource: StorageSource {
    private let bridge: ReduxBridge
    private let settings: AppSettings

    init(settings: AppSettings, connection: MetroDebuggerConnection) {
        self.settings = settings
        bridge = ReduxBridge(connection: connection)
    }

    var changeDetection: StorageChangeDetection { .polling }

    func directoryURL(for location: StorageLocation) -> URL? {
        location.containerURL
    }

    func readItems(for location: StorageLocation) async throws -> [StorageItem] {
        try await bridge.readItems(
            bundleID: location.bundleID,
            deviceName: location.deviceName,
            metroPort: settings.metroPort
        )
    }
}

final class ZustandSource: StorageSource {
    private let bridge: ZustandBridge
    private let settings: AppSettings

    init(settings: AppSettings, connection: MetroDebuggerConnection) {
        self.settings = settings
        bridge = ZustandBridge(connection: connection)
    }

    var changeDetection: StorageChangeDetection { .polling }

    func directoryURL(for location: StorageLocation) -> URL? {
        location.containerURL
    }

    func readItems(for location: StorageLocation) async throws -> [StorageItem] {
        try await bridge.readItems(
            bundleID: location.bundleID,
            deviceName: location.deviceName,
            metroPort: settings.metroPort
        )
    }
}

struct ReduxPersistSource: StorageSource {
    private let asyncStorage = AsyncStorageSource()
    private let mmkv = MMKVSource()
    private let parser = ReduxPersistParser()

    var changeDetection: StorageChangeDetection { .polling }

    func directoryURL(for location: StorageLocation) -> URL? {
        location.asyncStorageURL ?? location.mmkvURL
    }

    func readItems(for location: StorageLocation) async throws -> [StorageItem] {
        let storageItems = try await asyncStorage.readItems(for: location) + mmkv.readItems(for: location)
        return parser.items(from: storageItems)
    }
}
