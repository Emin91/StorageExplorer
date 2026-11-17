//
//  PluginStorageViewModel.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Combine
import Foundation

@MainActor
final class PluginStorageViewModel: ObservableObject {
    private static let pollingInterval: Duration = .seconds(1)

    @Published private(set) var items: [StorageItem] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var hasData = false

    @Published var selectedItemID: StorageItem.ID?

    @Published var searchText = ""
    @Published var searchScope: SearchScope = .all
    @Published var typeFilter: Set<StorageValueType> = []
    @Published var sort: StorageSort?

    let appSelection: AppSelectionViewModel

    private let source: any StorageSource
    private var watcher: DirectoryWatcher?
    private var pollingTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private var observedLocationID: StorageLocation.ID?
    private var observedDirectoryURL: URL?
    private var itemsLocationID: StorageLocation.ID?

    init(source: any StorageSource, appSelection: AppSelectionViewModel) {
        self.source = source
        self.appSelection = appSelection

        Publishers.CombineLatest(appSelection.$selectedLocationID, appSelection.$locations)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.selectionDidChange() }
            .store(in: &cancellables)

        appSelection.reloadRequests
            .sink { [weak self] in
                Task { await self?.reloadItems() }
            }
            .store(in: &cancellables)
    }

    var searchQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isFiltering: Bool {
        !searchQuery.isEmpty || !typeFilter.isEmpty
    }

    var filteredItems: [StorageItem] {
        let query = searchQuery
        let filtered = items.filter { item in
            let matchesType = typeFilter.isEmpty || typeFilter.contains(item.type)
            let matchesQuery = query.isEmpty
                || (searchScope.includesKeys && item.key.matches(query))
                || (searchScope.includesValues && item.value.matches(query))
            return matchesType && matchesQuery
        }
        return sort?.sorted(filtered) ?? filtered
    }

    var availableTypes: [StorageValueType] {
        let presentTypes = Set(items.map(\.type))
        return StorageValueType.allCases.filter(presentTypes.contains)
    }

    func resetTypeFilter() {
        typeFilter = []
    }

    func setFilter(_ isOn: Bool, for type: StorageValueType) {
        if isOn {
            typeFilter.insert(type)
        } else {
            typeFilter.remove(type)
        }
    }

    private var selectedLocation: StorageLocation? {
        appSelection.selectedLocation
    }

    private func selectionDidChange() {
        let directoryURL = selectedLocation.flatMap(source.directoryURL(for:))
        guard selectedLocation?.id != observedLocationID || directoryURL != observedDirectoryURL else { return }

        if selectedLocation?.id != observedLocationID {
            selectedItemID = nil
        }
        observedLocationID = selectedLocation?.id
        observedDirectoryURL = directoryURL
        hasData = directoryURL != nil
        startObserving(directoryURL)
    }

    private func startObserving(_ directoryURL: URL?) {
        watcher = nil
        pollingTask?.cancel()
        pollingTask = nil

        if let directoryURL {
            switch source.changeDetection {
            case .directoryEvents:
                watcher = makeWatcher(for: directoryURL)
            case .polling:
                pollingTask = Task { [weak self] in
                    while !Task.isCancelled {
                        try? await Task.sleep(for: Self.pollingInterval)
                        await self?.reloadItems()
                    }
                }
            }
        }

        Task { await reloadItems() }
    }

    private func makeWatcher(for directoryURL: URL) -> DirectoryWatcher? {
        let directoryExists = FileManager.default.fileExists(atPath: directoryURL.path(percentEncoded: false))
        let watchedURL = directoryExists ? directoryURL : directoryURL.deletingLastPathComponent()

        return DirectoryWatcher(url: watchedURL) { [weak self] in
            guard let self else { return }
            self.watcher = self.makeWatcher(for: directoryURL)
            Task { await self.reloadItems() }
        }
    }

    private func reloadItems() async {
        guard let location = selectedLocation, source.directoryURL(for: location) != nil else {
            items = []
            errorMessage = nil
            return
        }

        do {
            let loadedItems = try await source.readItems(for: location)
            guard location.id == appSelection.selectedLocationID else { return }

            let trackedItems = trackingModifications(in: loadedItems, at: location)
            if trackedItems != items {
                items = trackedItems
            }
            if let selectedItemID, !items.contains(where: { $0.id == selectedItemID }) {
                self.selectedItemID = nil
            }
            itemsLocationID = location.id
            errorMessage = nil
        } catch {
            items = []
            errorMessage = error.localizedDescription
        }
    }

    private func trackingModifications(in loadedItems: [StorageItem], at location: StorageLocation) -> [StorageItem] {
        guard itemsLocationID == location.id else { return loadedItems }

        let previousItems = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        let now = Date()

        return loadedItems.map { item in
            var item = item
            if let previous = previousItems[item.id], previous.value == item.value {
                item.modifiedAt = previous.modifiedAt
            } else {
                item.modifiedAt = item.modifiedAt ?? now
            }
            return item
        }
    }
}
