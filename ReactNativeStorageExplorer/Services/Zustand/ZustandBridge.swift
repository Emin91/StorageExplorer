//
//  ZustandBridge.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 20.11.25.
//

import Foundation

actor ZustandBridge {
    private let connection: MetroDebuggerConnection
    private var lastVersion: String?
    private var cachedItems: [StorageItem] = []

    init(connection: MetroDebuggerConnection) {
        self.connection = connection
    }

    func readItems(bundleID: String, deviceName: String, metroPort: Int) async throws -> [StorageItem] {
        let client = try await connection.client(bundleID: bundleID, deviceName: deviceName, metroPort: metroPort)
        do {
            let version = try await installedVersion(client)
            if version != lastVersion {
                cachedItems = try await readState(client)
                lastVersion = version
            }
            return cachedItems
        } catch {
            lastVersion = nil
            cachedItems = []
            if case MetroBridgeError.zustandStoresNotFound = error {
                throw error
            }
            await connection.disconnect(client)
            throw error
        }
    }

    private func installedVersion(_ client: CDPClient) async throws -> String {
        if let version = try await client.evaluate(ZustandScripts.version) {
            return version
        }

        guard try await client.evaluate(ZustandScripts.install) == "ok",
              let version = try await client.evaluate(ZustandScripts.version) else {
            throw MetroBridgeError.zustandStoresNotFound
        }
        return version
    }

    private func readState(_ client: CDPClient) async throws -> [StorageItem] {
        guard let json = try await client.evaluate(ZustandScripts.state),
              let stores = try? JSONDecoder().decode([[String]].self, from: Data(json.utf8)) else {
            throw MetroBridgeError.zustandStoresNotFound
        }

        return stores.compactMap { store in
            guard store.count == 2 else { return nil }
            return StorageItem(key: store[0], value: store[1])
        }
    }
}
