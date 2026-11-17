//
//  StorageLocation.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

nonisolated struct StorageLocation: Identifiable, Hashable, Sendable {
    let deviceUDID: String
    let deviceName: String
    let osVersion: String
    let appName: String
    let bundleID: String
    let iconURL: URL?
    let appVersion: String?
    let appBuild: String?
    let isExpoGoProject: Bool
    let containerURL: URL
    let asyncStorageURL: URL?
    let mmkvURL: URL?
    let modificationDate: Date

    var dataFolderURL: URL {
        if isExpoGoProject, let asyncStorageURL {
            return asyncStorageURL.deletingLastPathComponent()
        }
        return containerURL
    }

    var id: URL { asyncStorageURL ?? containerURL }

    var versionDescription: String? {
        guard let appVersion else { return nil }
        if isExpoGoProject {
            return "Expo Go \(appVersion)"
        }
        return appBuild.map { "\(appVersion) (\($0))" } ?? appVersion
    }
}
