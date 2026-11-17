//
//  ReduxBridge.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

actor ReduxBridge {
    private var client: CDPClient?
    private var connectedAppKey: String?
    private var lastVersion: String?
    private var cachedItems: [StorageItem] = []

    func readItems(bundleID: String, deviceName: String, metroPort: Int) async throws -> [StorageItem] {
        do {
            let client = try await connectedClient(bundleID: bundleID, deviceName: deviceName, metroPort: metroPort)
            let version = try await installedVersion(client)

            if version != lastVersion {
                cachedItems = try await readState(client)
                lastVersion = version
            }
            return cachedItems
        } catch {
            await disconnect()
            throw error
        }
    }

    private func connectedClient(bundleID: String, deviceName: String, metroPort: Int) async throws -> CDPClient {
        let appKey = "\(bundleID)|\(deviceName)|\(metroPort)"
        if let client, connectedAppKey == appKey {
            let isClosed = await client.isClosed
            if !isClosed {
                return client
            }
        }

        await disconnect()
        let target = try await MetroTargetProvider(port: metroPort).target(bundleID: bundleID, deviceName: deviceName)
        guard let url = URL(string: target.webSocketDebuggerUrl) else {
            throw ReduxBridgeError.appNotFound(bundleID: bundleID)
        }

        let newClient = CDPClient(url: url)
        await newClient.connect()
        client = newClient
        connectedAppKey = appKey
        return newClient
    }

    private func disconnect() async {
        await client?.close()
        client = nil
        connectedAppKey = nil
        lastVersion = nil
        cachedItems = []
    }

    private func installedVersion(_ client: CDPClient) async throws -> String {
        if let version = try await client.evaluate(ReduxScripts.version) {
            return version
        }

        guard try await client.evaluate(ReduxScripts.install) == "ok",
              let version = try await client.evaluate(ReduxScripts.version) else {
            throw ReduxBridgeError.storeNotFound
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
            throw ReduxBridgeError.storeNotFound
        }

        let items = slices.compactMap { slice -> StorageItem? in
            guard slice.count == 3 else { return nil }
            let group = slice[2] == "api" ? Group.queryAPIs : Group.slices
            return StorageItem(key: slice[0], value: slice[1], group: group)
        }
        return items.filter { $0.group == Group.slices } + items.filter { $0.group == Group.queryAPIs }
    }
}
