//
//  StorageView.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import SwiftUI

struct StorageView: View {
    let plugin: StoragePlugin
    @ObservedObject var viewModel: PluginStorageViewModel
    @ObservedObject var appSelection: AppSelectionViewModel

    private var selectedItem: StorageItem? {
        viewModel.items.first { $0.id == viewModel.selectedItemID }
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var content: some View {
        if let errorMessage = viewModel.errorMessage ?? appSelection.errorMessage {
            ContentUnavailableView(
                "Can't Read Storage",
                systemImage: "exclamationmark.triangle",
                description: Text(errorMessage)
            )
        } else if appSelection.locations.isEmpty {
            ContentUnavailableView(
                "No Apps Found",
                systemImage: "externaldrive.badge.questionmark",
                description: Text("Run a React Native app on a booted Simulator.")
            )
        } else if !viewModel.hasData {
            ContentUnavailableView(
                "No \(plugin.title) Data",
                systemImage: plugin.systemImage,
                description: Text("The selected app doesn't use \(plugin.packageName).")
            )
        } else if viewModel.items.isEmpty {
            ContentUnavailableView("Storage Is Empty", systemImage: "tray")
        } else {
            ZStack {
                if let selectedItem {
                    ValueDetailView(item: selectedItem)
                        .transition(.move(edge: .trailing))
                } else {
                    VStack(spacing: 0) {
                        searchBar
                        totals
                        results
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .transition(.move(edge: .leading))
                }
            }
            .clipped()
            .animation(.easeInOut(duration: 0.25), value: viewModel.selectedItemID)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 6) {
            SearchField(text: $viewModel.searchText, prompt: "Search keys and values")
            scopeMenu
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }

    private var scopeMenu: some View {
        Menu {
            Picker("Search In", selection: $viewModel.searchScope) {
                ForEach(SearchScope.allCases) { scope in
                    Text(scope.title).tag(scope)
                }
            }
            .pickerStyle(.inline)
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Search in: \(viewModel.searchScope.title)")
    }

    @ViewBuilder
    private var results: some View {
        let query = viewModel.searchQuery
        let filteredItems = viewModel.filteredItems

        if filteredItems.isEmpty {
            ContentUnavailableView.search(text: query)
        } else {
            StorageTable(
                items: filteredItems,
                keyHighlight: viewModel.searchScope.includesKeys ? query : "",
                valueHighlight: viewModel.searchScope.includesValues ? query : ""
            ) { item in
                viewModel.selectedItemID = item.id
            }
        }
    }

    private var totals: some View {
        let shownItems = viewModel.filteredItems
        let totalSize = shownItems.reduce(0) { $0 + $1.size }
        let isFiltering = !viewModel.searchQuery.isEmpty

        return HStack(spacing: 6) {
            statBadge(
                isFiltering
                    ? Text("\(shownItems.count) of ^[\(viewModel.items.count) key](inflect: true)")
                    : Text("^[\(viewModel.items.count) key](inflect: true)"),
                systemImage: "key"
            )
            statBadge(Text(totalSize.formattedByteCount), systemImage: "internaldrive")
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func statBadge(_ text: Text, systemImage: String) -> some View {
        Label {
            text
        } icon: {
            Image(systemName: systemImage)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.primary.opacity(0.06), in: Capsule())
    }
}
