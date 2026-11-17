//
//  PluginCard.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import SwiftUI

struct PluginCard: View {
    let plugin: StoragePlugin
    @ObservedObject var viewModel: PluginStorageViewModel
    let action: () -> Void

    @AppStorage(AppSettings.Key.highlightsChanges) private var highlightsChanges = AppSettings.Defaults.highlightsChanges
    @AppStorage(AppSettings.Key.highlightColor) private var highlightColor = AppSettings.Defaults.highlightColor
    @AppStorage(AppSettings.Key.highlightDuration) private var highlightDuration = AppSettings.Defaults.highlightDuration

    @State private var isHovered = false
    @State private var lastSeenChange: Date?
    @State private var isFlashing = false
    @State private var flashID = 0

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: plugin.systemImage)
                    .font(.title3)
                    .frame(width: 36, height: 36)
                    .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(plugin.title)
                        .font(.headline)
                    summary
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                Color.primary.opacity(isHovered ? 0.1 : 0.06),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .background(
                highlightColor.color.opacity(isFlashing ? 0.35 : 0),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onChange(of: viewModel.items, initial: true) { _, newItems in
            flashIfChanged(newItems)
        }
    }

    private static let maxChangeAge: TimeInterval = 3

    private func flashIfChanged(_ items: [StorageItem]) {
        guard let latestChange = items.compactMap(\.modifiedAt).max() else { return }
        defer { lastSeenChange = latestChange }

        let isFresh = latestChange > Date().addingTimeInterval(-Self.maxChangeAge)
        guard highlightsChanges, isFresh, latestChange != lastSeenChange else { return }

        flashID += 1
        let currentFlashID = flashID
        withAnimation(.easeOut(duration: 0.15)) {
            isFlashing = true
        }
        Task {
            try? await Task.sleep(for: .seconds(highlightDuration))
            guard currentFlashID == flashID else { return }
            withAnimation(.easeOut(duration: 0.8)) {
                isFlashing = false
            }
        }
    }

    private var summary: Text {
        guard viewModel.hasData else { return Text("No data in the selected app") }

        let totalSize = viewModel.items.reduce(0) { $0 + $1.size }
        return Text("^[\(viewModel.items.count) key](inflect: true) · \(totalSize.formattedByteCount)")
    }
}
