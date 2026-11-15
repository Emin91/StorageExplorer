//
//  AppSelectionViewModel.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Combine
import Foundation

@MainActor
final class AppSelectionViewModel: ObservableObject {
    private static let monitoringInterval: Duration = .seconds(2)
    private static let lastSelectedAppKey = "lastSelectedApp"

    @Published private(set) var locations: [StorageLocation] = []
    @Published private(set) var activeLocationID: StorageLocation.ID?
    @Published private(set) var errorMessage: String?

    @Published var isSelectionPinned = false
    @Published private(set) var selectedLocationID: StorageLocation.ID? {
        didSet { saveLastSelectedApp() }
    }

    let reloadRequests = PassthroughSubject<Void, Never>()

    private let locator = StorageLocator()
    private let runningAppsProvider = RunningAppsProvider()
    private let defaults: UserDefaults

    init(settings: AppSettings, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isSelectionPinned = settings.appSelectionMode == .rememberLastApp
    }

    var selectedLocation: StorageLocation? {
        locations.first { $0.id == selectedLocationID }
    }

    func monitorLocations() async {
        while !Task.isCancelled {
            await refreshLocations()
            try? await Task.sleep(for: Self.monitoringInterval)
        }
    }

    func select(_ locationID: StorageLocation.ID?) {
        isSelectionPinned = true
        selectedLocationID = locationID
    }

    func refresh() async {
        await refreshLocations()
        reloadRequests.send()
    }

    private func refreshLocations() async {
        do {
            locations = try await locator.locate()
            errorMessage = nil
        } catch {
            locations = []
            errorMessage = error.localizedDescription
        }

        activeLocationID = await activeLocation()?.id

        if !isSelectionPinned, let activeLocationID {
            selectedLocationID = activeLocationID
        } else if selectedLocation == nil {
            selectedLocationID = (lastSelectedLocation ?? locations.first)?.id
        }
    }


    private func persistentKey(of location: StorageLocation) -> String {
        "\(location.deviceUDID)|\(location.bundleID)|\(location.appName)"
    }

    private var lastSelectedLocation: StorageLocation? {
        guard let key = defaults.string(forKey: Self.lastSelectedAppKey) else { return nil }
        return locations.first { persistentKey(of: $0) == key }
    }

    private func saveLastSelectedApp() {
        guard let selectedLocation else { return }
        defaults.set(persistentKey(of: selectedLocation), forKey: Self.lastSelectedAppKey)
    }

    private func activeLocation() async -> StorageLocation? {
        let deviceUDIDs = Set(locations.map(\.deviceUDID))
        let runningApps = await runningAppsProvider.runningApps(onDevices: deviceUDIDs)

        let runningLocations = locations.compactMap { location -> (location: StorageLocation, pid: Int)? in
            runningApps
                .first { $0.deviceUDID == location.deviceUDID && $0.bundleID == location.bundleID }
                .map { (location, $0.pid) }
        }

        guard let latestPID = runningLocations.map(\.pid).max() else { return nil }
        return runningLocations.first { $0.pid == latestPID }?.location
    }
}
