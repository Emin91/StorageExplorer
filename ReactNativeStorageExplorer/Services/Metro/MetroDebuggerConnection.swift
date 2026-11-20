//
//  MetroDebuggerConnection.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 20.11.25.
//

import Foundation

actor MetroDebuggerConnection {
    private var client: CDPClient?
    private var connectedAppKey: String?
    private var pendingConnection: (appKey: String, task: Task<CDPClient, Error>)?

    func client(bundleID: String, deviceName: String, metroPort: Int) async throws -> CDPClient {
        let appKey = "\(bundleID)|\(deviceName)|\(metroPort)"
        if let pendingConnection, pendingConnection.appKey == appKey {
            return try await pendingConnection.task.value
        }
        if let client, connectedAppKey == appKey {
            let isClosed = await client.isClosed
            if !isClosed {
                return client
            }
        }
        if let pendingConnection, pendingConnection.appKey == appKey {
            return try await pendingConnection.task.value
        }

        await disconnect()
        let task = Task<CDPClient, Error> {
            let target = try await MetroTargetProvider(port: metroPort).target(bundleID: bundleID, deviceName: deviceName)
            guard let url = URL(string: target.webSocketDebuggerUrl) else {
                throw MetroBridgeError.appNotFound(bundleID: bundleID)
            }
            let newClient = CDPClient(url: url)
            await newClient.connect()
            return newClient
        }
        pendingConnection = (appKey, task)
        defer {
            if pendingConnection?.task == task { pendingConnection = nil }
        }

        let newClient = try await task.value
        client = newClient
        connectedAppKey = appKey
        return newClient
    }

    func disconnect(_ failedClient: CDPClient? = nil) async {
        if let failedClient, failedClient !== client { return }
        await client?.close()
        client = nil
        connectedAppKey = nil
    }
}
