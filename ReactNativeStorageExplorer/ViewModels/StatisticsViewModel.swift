//
//  StatisticsViewModel.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Combine
import Foundation

final class StatisticsViewModel: ObservableObject {
    struct Summary: Equatable {
        var keyCount = 0
        var size = 0
    }

    @Published private(set) var summaries: [StoragePlugin: Summary] = [:]

    private let pluginViewModels: [StoragePlugin: PluginStorageViewModel]
    private var cancellables = Set<AnyCancellable>()

    init(pluginViewModels: [StoragePlugin: PluginStorageViewModel]) {
        self.pluginViewModels = pluginViewModels
        reload()

        Publishers.MergeMany(pluginViewModels.values.map { $0.$items.map { _ in () } })
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .sink { [weak self] in self?.reload() }
            .store(in: &cancellables)
    }

    func summary(for plugin: StoragePlugin) -> Summary {
        summaries[plugin] ?? Summary()
    }

    private func reload() {
        let newSummaries = pluginViewModels.mapValues { viewModel in
            Summary(
                keyCount: viewModel.items.count,
                size: viewModel.items.reduce(0) { $0 + $1.size }
            )
        }
        if newSummaries != summaries {
            summaries = newSummaries
        }
    }
}
