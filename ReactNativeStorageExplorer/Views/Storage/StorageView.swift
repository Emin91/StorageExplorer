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

    @AppStorage(StorageColumn.LayoutKey.hiddenColumns) private var hiddenColumnsValue = ""

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
            ContentUnavailableView {
                Label("Can't Read Storage", systemImage: "exclamationmark.triangle")
            } description: {
                Text(errorMessage)
            } actions: {
                if let guideURL = plugin.guideURL {
                    Link(destination: guideURL) {
                        Label("Open \(plugin.title) Setup Guide", systemImage: "book")
                    }
                }
            }
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
                            .animation(.easeInOut(duration: 0.25), value: viewModel.sort)
                            .animation(.easeInOut(duration: 0.25), value: viewModel.typeFilter)
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
            columnsMenu
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }

    private var columnsMenu: some View {
        Menu {
            Section("Columns") {
                ForEach(["Row Number", "Key"], id: \.self) { title in
                    Toggle(title, isOn: .constant(true))
                        .disabled(true)
                }
                ForEach(StorageColumn.allCases) { column in
                    Toggle(column.title, isOn: columnVisibility(column))
                }
            }
        } label: {
            Image(systemName: "tablecells")
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Show or Hide Columns")
    }

    private func columnVisibility(_ column: StorageColumn) -> Binding<Bool> {
        Binding(
            get: { !StorageColumn.hiddenColumns(from: hiddenColumnsValue).contains(column) },
            set: { isVisible in
                var hiddenColumns = StorageColumn.hiddenColumns(from: hiddenColumnsValue)
                if isVisible {
                    hiddenColumns.remove(column)
                } else {
                    hiddenColumns.insert(column)
                }
                hiddenColumnsValue = StorageColumn.storedValue(for: hiddenColumns)
            }
        )
    }

    private var scopeMenu: some View {
        Menu {
            Picker("Search In", selection: $viewModel.searchScope) {
                ForEach(SearchScope.allCases) { scope in
                    Text(scope.title).tag(scope)
                }
            }
            .pickerStyle(.inline)

            Section("Show Types") {
                ForEach(viewModel.availableTypes, id: \.self) { type in
                    Toggle(type.title, isOn: Binding(
                        get: { viewModel.typeFilter.contains(type) },
                        set: { viewModel.setFilter($0, for: type) }
                    ))
                }
                if !viewModel.typeFilter.isEmpty {
                    Button("Show All Types") {
                        viewModel.typeFilter = []
                    }
                }
            }
        } label: {
            Image(systemName: viewModel.typeFilter.isEmpty
                ? "line.3.horizontal.decrease.circle"
                : "line.3.horizontal.decrease.circle.fill")
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
            if query.isEmpty {
                ContentUnavailableView(
                    "No Keys of Selected Types",
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text("Change the type filter to see more keys.")
                )
            } else {
                ContentUnavailableView.search(text: query)
            }
        } else {
            StorageTable(
                items: filteredItems,
                keyHighlight: viewModel.searchScope.includesKeys ? query : "",
                valueHighlight: viewModel.searchScope.includesValues ? query : "",
                sort: $viewModel.sort
            ) { item in
                viewModel.selectedItemID = item.id
            }
        }
    }

    private var totals: some View {
        let shownItems = viewModel.filteredItems
        let totalSize = shownItems.reduce(0) { $0 + $1.size }
        let isFiltering = viewModel.isFiltering

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
