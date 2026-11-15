//
//  ContentView.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var layoutViewModel: PanelLayoutViewModel
    let appSelection: AppSelectionViewModel
    let pluginViewModels: [StoragePlugin: PluginStorageViewModel]
    @ObservedObject var settings: AppSettings

    @State private var openedPlugin: StoragePlugin?

    private var enabledPlugins: [StoragePlugin] {
        StoragePlugin.allCases.filter(settings.isEnabled)
    }

    var body: some View {
        VStack(spacing: 0) {
            PanelHeaderView(layoutViewModel: layoutViewModel)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: {
                    layoutViewModel.headerHeight = $0
                }

            if !layoutViewModel.isCollapsed {
                Divider()
                mainContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.easeInOut(duration: 0.3), value: enabledPlugins)
    }

    @ViewBuilder
    private var mainContent: some View {
        if enabledPlugins.isEmpty {
            ContentUnavailableView(
                "No Plugins Enabled",
                systemImage: "puzzlepiece.extension",
                description: Text("Turn on a storage plugin in Settings.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
        } else {
            VStack(spacing: 0) {
                TargetAppBar(viewModel: appSelection)
                Divider()
                pluginSections
            }
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private var pluginSections: some View {
        Group {
            if enabledPlugins.count == 1, let plugin = enabledPlugins.first {
                pluginScreen(plugin, onBackToPlugins: nil)
                    .transition(.opacity)
            } else if let openedPlugin, enabledPlugins.contains(openedPlugin) {
                pluginScreen(openedPlugin) { self.openedPlugin = nil }
                    .transition(.move(edge: .trailing))
            } else {
                pluginList
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .animation(.easeInOut(duration: 0.25), value: openedPlugin)
    }

    private var pluginList: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(enabledPlugins) { plugin in
                    if let viewModel = viewModel(for: plugin) {
                        PluginCard(plugin: plugin, viewModel: viewModel) {
                            openedPlugin = plugin
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .scale(scale: 0.95).combined(with: .opacity)
                        ))
                    }
                }
            }
            .padding(12)
        }
    }

    private func pluginScreen(_ plugin: StoragePlugin, onBackToPlugins: (() -> Void)?) -> some View {
        VStack(spacing: 0) {
            if let viewModel = viewModel(for: plugin) {
                PluginNavigationBar(plugin: plugin, viewModel: viewModel, onBackToPlugins: onBackToPlugins)
                Divider()
            }
            content(for: plugin)
        }
    }

    private func viewModel(for plugin: StoragePlugin) -> PluginStorageViewModel? {
        pluginViewModels[plugin]
    }

    @ViewBuilder
    private func content(for plugin: StoragePlugin) -> some View {
        if let viewModel = viewModel(for: plugin) {
            StorageView(plugin: plugin, viewModel: viewModel, appSelection: appSelection)
        } else {
            ContentUnavailableView(plugin.title, systemImage: plugin.systemImage, description: Text("Coming soon."))
        }
    }
}

#Preview {
    let appSelection = AppSelectionViewModel(settings: AppSettings())
    ContentView(
        layoutViewModel: PanelLayoutViewModel(),
        appSelection: appSelection,
        pluginViewModels: [
            .asyncStorage: PluginStorageViewModel(source: AsyncStorageSource(), appSelection: appSelection)
        ],
        settings: AppSettings()
    )
    .frame(width: 440, height: 480)
}
