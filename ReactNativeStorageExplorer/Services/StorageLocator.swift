//
//  StorageLocator.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

nonisolated struct StorageLocator {
    private static let manifestFileName = "manifest.json"
    private static let expoGoBundleID = "host.exp.Exponent"
    private static let mmkvDirectoryPaths = ["Documents/mmkv", "Library/mmkv"]

    @concurrent
    func locate() async throws -> [StorageLocation] {
        try bootedDevices()
            .flatMap(storageLocations(on:))
            .sorted { $0.modificationDate > $1.modificationDate }
    }


    private struct DeviceList: Decodable {
        let devices: [String: [DeviceEntry]]
    }

    private struct DeviceEntry: Decodable {
        let udid: String
        let name: String
        let dataPath: String
    }

    private struct Device {
        let udid: String
        let name: String
        let osVersion: String
        let dataPath: String
    }

    private func bootedDevices() throws -> [Device] {
        let output = try Simctl.run(["list", "devices", "booted", "--json"])

        return try JSONDecoder().decode(DeviceList.self, from: output).devices.flatMap { runtime, entries in
            entries.map {
                Device(udid: $0.udid, name: $0.name, osVersion: osVersion(fromRuntime: runtime), dataPath: $0.dataPath)
            }
        }
    }

    private func osVersion(fromRuntime runtime: String) -> String {
        let components = (runtime.components(separatedBy: ".").last ?? runtime).components(separatedBy: "-")
        guard let platform = components.first, components.count > 1 else { return runtime }
        return "\(platform) \(components.dropFirst().joined(separator: "."))"
    }


    private func storageLocations(on device: Device) -> [StorageLocation] {
        let containersURL = URL(fileURLWithPath: device.dataPath).appending(path: "Containers")
        let installedApps = installedApps(inBundleContainers: containersURL.appending(path: "Bundle/Application"))

        return contents(of: containersURL.appending(path: "Data/Application")).flatMap { containerURL -> [StorageLocation] in
            let containerBundleID = bundleID(ofDataContainer: containerURL)

            return storageCandidates(inContainer: containerURL).compactMap { candidate -> StorageLocation? in
                let dates = [
                    candidate.asyncStorageURL.flatMap { modificationDate(of: $0.appending(path: Self.manifestFileName)) },
                    candidate.mmkvURL.flatMap(latestModificationDate(inDirectory:))
                ]
                guard let modificationDate = dates.compactMap({ $0 }).max() else { return nil }

                let appBundleID = containerBundleID ?? candidate.fallbackBundleID
                return StorageLocation(
                    deviceUDID: device.udid,
                    deviceName: device.name,
                    osVersion: device.osVersion,
                    appName: candidate.projectName ?? installedApps[appBundleID]?.name ?? appBundleID,
                    bundleID: appBundleID,
                    iconURL: installedApps[appBundleID]?.iconURL,
                    appVersion: installedApps[appBundleID]?.version,
                    appBuild: installedApps[appBundleID]?.build,
                    isExpoGoProject: candidate.projectName != nil,
                    containerURL: containerURL,
                    asyncStorageURL: candidate.asyncStorageURL,
                    mmkvURL: candidate.mmkvURL,
                    modificationDate: modificationDate
                )
            }
        }
    }

    private struct StorageCandidate {
        let asyncStorageURL: URL?
        let mmkvURL: URL?
        let projectName: String?
        let fallbackBundleID: String
    }

    private func storageCandidates(inContainer containerURL: URL) -> [StorageCandidate] {
        let asyncStorageBundleURL = contents(of: containerURL.appending(path: "Library/Application Support"))
            .first { hasManifest(at: $0.appending(path: "RCTAsyncLocalStorage_V1")) }

        let app = StorageCandidate(
            asyncStorageURL: asyncStorageBundleURL?.appending(path: "RCTAsyncLocalStorage_V1"),
            mmkvURL: Self.mmkvDirectoryPaths
                .map { containerURL.appending(path: $0) }
                .first { !mmkvInstanceFiles(in: $0).isEmpty },
            projectName: nil,
            fallbackBundleID: asyncStorageBundleURL?.lastPathComponent ?? containerURL.lastPathComponent
        )

        let expoGoProjects = contents(of: containerURL.appending(path: "Documents/ExponentExperienceData"))
            .flatMap(contents(of:))
            .map { projectURL in
                StorageCandidate(
                    asyncStorageURL: projectURL.appending(path: "RCTAsyncLocalStorage"),
                    mmkvURL: nil,
                    projectName: projectName(fromExpoGoFolder: projectURL.lastPathComponent),
                    fallbackBundleID: Self.expoGoBundleID
                )
            }

        return [app] + expoGoProjects
    }

    private func hasManifest(at storageURL: URL) -> Bool {
        FileManager.default.fileExists(atPath: storageURL.appending(path: Self.manifestFileName).path(percentEncoded: false))
    }

    private func mmkvInstanceFiles(in directoryURL: URL) -> [URL] {
        contents(of: directoryURL).filter { $0.pathExtension != "crc" }
    }

    private func latestModificationDate(inDirectory directoryURL: URL) -> Date? {
        mmkvInstanceFiles(in: directoryURL).compactMap(modificationDate(of:)).max()
    }

    private func modificationDate(of url: URL) -> Date? {
        try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }


    private func bundleID(ofDataContainer containerURL: URL) -> String? {
        let metadataURL = containerURL.appending(path: ".com.apple.mobile_container_manager.metadata.plist")
        return propertyList(at: metadataURL)?["MCMMetadataIdentifier"] as? String
    }

    private struct InstalledApp {
        let name: String
        let iconURL: URL?
        let version: String?
        let build: String?
    }

    private func installedApps(inBundleContainers url: URL) -> [String: InstalledApp] {
        let appURLs = contents(of: url)
            .flatMap(contents(of:))
            .filter { $0.pathExtension == "app" }

        return appURLs.reduce(into: [:]) { apps, appURL in
            guard let info = propertyList(at: appURL.appending(path: "Info.plist")),
                  let bundleID = info["CFBundleIdentifier"] as? String,
                  let name = (info["CFBundleDisplayName"] ?? info["CFBundleName"]) as? String else { return }
            apps[bundleID] = InstalledApp(
                name: name,
                iconURL: iconURL(in: appURL, info: info),
                version: info["CFBundleShortVersionString"] as? String,
                build: info["CFBundleVersion"] as? String
            )
        }
    }

    private func iconURL(in appURL: URL, info: [String: Any]) -> URL? {
        let icons = info["CFBundleIcons"] as? [String: Any]
        let primaryIcon = icons?["CFBundlePrimaryIcon"] as? [String: Any]
        guard let baseName = (primaryIcon?["CFBundleIconFiles"] as? [String])?.last else { return nil }

        return ["@3x.png", "@2x.png", ".png"]
            .map { appURL.appending(path: baseName + $0) }
            .first { FileManager.default.fileExists(atPath: $0.path(percentEncoded: false)) }
    }

    private func propertyList(at url: URL) -> [String: Any]? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
    }

    private func projectName(fromExpoGoFolder folderName: String) -> String {
        let uuidLength = 36
        guard folderName.count > uuidLength + 1,
              UUID(uuidString: String(folderName.suffix(uuidLength))) != nil else { return folderName }
        return String(folderName.dropLast(uuidLength + 1))
    }

    private func contents(of url: URL) -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []
    }
}
