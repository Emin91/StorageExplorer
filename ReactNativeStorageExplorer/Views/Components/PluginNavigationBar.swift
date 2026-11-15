//
//  PluginNavigationBar.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import SwiftUI

struct PluginNavigationBar: View {
    let plugin: StoragePlugin
    @ObservedObject var viewModel: PluginStorageViewModel
    let onBackToPlugins: (() -> Void)?

    var body: some View {
        ZStack {
            Label(plugin.title, systemImage: plugin.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack {
                backButton
                Spacer()
            }
        }
        .frame(height: 28)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedItemID)
    }

    @ViewBuilder
    private var backButton: some View {
        if viewModel.selectedItemID != nil {
            navigationButton("Keys") {
                viewModel.selectedItemID = nil
            }
        } else if let onBackToPlugins {
            navigationButton("Plugins", action: onBackToPlugins)
        }
    }

    private func navigationButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .fontWeight(.semibold)
                Text(title)
            }
            .font(.callout.weight(.medium))
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.primary.opacity(0.08), in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .transition(.opacity)
    }
}
