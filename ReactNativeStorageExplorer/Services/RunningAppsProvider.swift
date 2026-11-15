//
//  RunningAppsProvider.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

nonisolated struct RunningAppsProvider {
    struct RunningApp: Hashable, Sendable {
        let deviceUDID: String
        let bundleID: String
        let pid: Int
    }

    private static let appLabelPrefix = "UIKitApplication:"

    @concurrent
    func runningApps(onDevices deviceUDIDs: Set<String>) async -> [RunningApp] {
        deviceUDIDs.flatMap { udid in
            (try? Simctl.run(["spawn", udid, "launchctl", "list"])).map { parse($0, deviceUDID: udid) } ?? []
        }
    }

    private func parse(_ output: Data, deviceUDID: String) -> [RunningApp] {
        String(decoding: output, as: UTF8.self)
            .split(separator: "\n")
            .compactMap { line in
                let columns = line.split(separator: "\t")
                guard columns.count == 3,
                      let pid = Int(columns[0]),
                      columns[2].hasPrefix(Self.appLabelPrefix) else { return nil }

                let bundleID = columns[2].dropFirst(Self.appLabelPrefix.count).prefix { $0 != "[" }
                return RunningApp(deviceUDID: deviceUDID, bundleID: String(bundleID), pid: pid)
            }
    }
}
