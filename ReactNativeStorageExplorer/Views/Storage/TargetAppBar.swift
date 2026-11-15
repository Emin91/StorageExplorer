//
//  TargetAppBar.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import SwiftUI

struct TargetAppBar: View {
    @ObservedObject var viewModel: AppSelectionViewModel

    var body: some View {
        HStack(spacing: 0) {
            AppIconView(url: viewModel.selectedLocation?.iconURL)
                .padding(.leading, 4)
                .padding(.trailing, 6)

            appMenu

            Divider()
                .frame(height: 16)
                .padding(.horizontal, 6)

            pinButton
            refreshButton
                .padding(.trailing, 2)
        }
        .groupedControlBackground()
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .task { await viewModel.monitorLocations() }
    }

    private var appMenu: some View {
        Menu {
            Picker("App", selection: Binding(get: { viewModel.selectedLocationID }, set: viewModel.select)) {
                ForEach(viewModel.locations) { location in
                    Text(menuTitle(for: location))
                        .tag(Optional(location.id))
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        } label: {
            selectedAppTitle
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .menuStyle(.borderlessButton)
        .disabled(viewModel.locations.isEmpty)
    }

    private var selectedAppTitle: Text {
        guard let location = viewModel.selectedLocation else { return Text("No Apps Found") }

        let isOnSeveralDevices = viewModel.locations.contains {
            $0.bundleID == location.bundleID && $0.deviceUDID != location.deviceUDID
        }
        let deviceDescription = isOnSeveralDevices ? "\(location.deviceName), \(location.osVersion)" : nil

        let details = [location.versionDescription, deviceDescription]
            .compactMap { $0 }
            .joined(separator: " · ")
        guard !details.isEmpty else { return Text(location.appName) }

        return Text(location.appName)
            + Text("  \(details)")
                .font(.caption)
                .foregroundStyle(.secondary)
    }

    private func menuTitle(for location: StorageLocation) -> String {
        let title = "\(location.appName) — \(location.bundleID) (\(location.deviceName), \(location.osVersion))"
        return location.id == viewModel.activeLocationID ? "\(title) · Active" : title
    }

    private var pinButton: some View {
        Button {
            viewModel.isSelectionPinned.toggle()
        } label: {
            Image(systemName: viewModel.isSelectionPinned ? "pin.fill" : "pin")
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.borderless)
        .help(viewModel.isSelectionPinned ? "Unpin: follow the active app" : "Pin the selected app")
    }

    private var refreshButton: some View {
        Button {
            Task { await viewModel.refresh() }
        } label: {
            Image(systemName: "arrow.clockwise")
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.borderless)
        .help("Refresh")
    }
}
