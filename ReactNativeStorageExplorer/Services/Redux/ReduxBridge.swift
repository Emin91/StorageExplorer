//
//  ReduxBridge.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

actor ReduxBridge {
    private let connection: MetroDebuggerConnection
    private var cachedClient: CDPClient?
    private var lastVersion: String?
    private var cachedItems: [StorageItem] = []

    init(connection: MetroDebuggerConnection) {
        self.connection = connection
    }

    func readItems(bundleID: String, deviceName: String, metroPort: Int) async throws -> [StorageItem] {
        let client = try await connection.client(bundleID: bundleID, deviceName: deviceName, metroPort: metroPort)
        do {
            if client !== cachedClient {
                cachedClient = client
                lastVersion = nil
                cachedItems = []
            }

            let version = try await installedVersion(client)
            if version != lastVersion {
                cachedItems = try await readState(client)
                lastVersion = version
            }
            return cachedItems
        } catch {
            if case MetroBridgeError.reduxStoreNotFound = error {
                throw error
            }
            await connection.disconnect(client)
            throw error
        }
    }

    private func installedVersion(_ client: CDPClient) async throws -> String {
        if let version = try await client.evaluate(ReduxScripts.version) {
            return version
        }

        guard try await client.evaluate(ReduxScripts.install) == "ok",
              let version = try await client.evaluate(ReduxScripts.version) else {
            throw MetroBridgeError.reduxStoreNotFound
        }
        return version
    }

    private enum Group {
        static let slices = "Slices"
        static let queryAPIs = "RTK Query"
    }

    private func readState(_ client: CDPClient) async throws -> [StorageItem] {
        guard let json = try await client.evaluate(ReduxScripts.state),
              let slices = try? JSONDecoder().decode([[String]].self, from: Data(json.utf8)) else {
            throw MetroBridgeError.reduxStoreNotFound
        }

        let items = slices.compactMap { slice -> StorageItem? in
            guard slice.count == 3 else { return nil }
            let group = slice[2] == "api" ? Group.queryAPIs : Group.slices
            return StorageItem(key: slice[0], value: slice[1], group: group)
        }
        return items.filter { $0.group == Group.slices } + items.filter { $0.group == Group.queryAPIs }
    }
}
