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

    @State private var isHovered = false

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
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }

    private var summary: Text {
        guard viewModel.hasData else { return Text("No data in the selected app") }

        let totalSize = viewModel.items.reduce(0) { $0 + $1.size }
        return Text("^[\(viewModel.items.count) key](inflect: true) · \(totalSize.formattedByteCount)")
    }
}
