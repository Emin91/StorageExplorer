//
//  MetroTargetProvider.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

nonisolated struct MetroTargetProvider {
    struct Target: Decodable, Sendable {
        let title: String?
        let description: String?
        let appId: String?
        let deviceName: String?
        let webSocketDebuggerUrl: String
        let reactNative: ReactNativeInfo?

        struct ReactNativeInfo: Decodable, Sendable {
            let capabilities: Capabilities?
        }

        struct Capabilities: Decodable, Sendable {
            let nativePageReloads: Bool?
            let prefersFuseboxFrontend: Bool?
        }

        var isMainRuntime: Bool {
            let capabilities = reactNative?.capabilities
            return capabilities?.nativePageReloads == true
                || capabilities?.prefersFuseboxFrontend == true
                || description?.contains("React Native") == true
        }

        func belongs(toBundleID bundleID: String) -> Bool {
            appId == bundleID || [title, description].contains { $0?.contains(bundleID) == true }
        }
    }

    let port: Int

    func targets() async throws -> [Target] {
        let url = URL(string: "http://localhost:\(port)/json/list")!
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode([Target].self, from: data)
        } catch is DecodingError {
            return []
        } catch {
            throw ReduxBridgeError.metroNotRunning(port: port)
        }
    }

    func target(bundleID: String, deviceName: String) async throws -> Target {
        let allTargets = try await targets()
        let appTargets = allTargets.filter { $0.belongs(toBundleID: bundleID) }
        let candidates = appTargets.isEmpty && allTargets.count == 1 ? allTargets : appTargets

        let onDevice = candidates.filter { $0.deviceName == deviceName }
        let deviceCandidates = onDevice.isEmpty ? candidates : onDevice

        guard let target = deviceCandidates.last(where: \.isMainRuntime) ?? deviceCandidates.first else {
            throw ReduxBridgeError.appNotFound(bundleID: bundleID)
        }
        return target
    }
}
