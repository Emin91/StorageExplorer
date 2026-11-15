//
//  PanelHeaderView.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import AppKit
import SwiftUI

struct PanelHeaderView: View {
    @ObservedObject var layoutViewModel: PanelLayoutViewModel

    private var showsPositionMenu: Bool {
        !layoutViewModel.isDetached && !layoutViewModel.isCollapsed
    }

    var body: some View {
        HStack(spacing: 8) {
            Label("Storage Explorer", systemImage: "externaldrive.fill")
                .font(.headline)
                .labelStyle(.titleAndIcon)
                .lineLimit(1)

            Spacer(minLength: 8)

            windowControls
            settingsButton
            quitButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.25), value: showsPositionMenu)
        .contentShape(Rectangle())
        .gesture(WindowDragGesture(), isEnabled: layoutViewModel.isDetached)
    }

    private var windowControls: some View {
        HStack(spacing: 2) {
            if showsPositionMenu {
                positionMenu
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }

            headerButton(
                layoutViewModel.isCollapsed ? "rectangle.expand.vertical" : "rectangle.compress.vertical",
                help: layoutViewModel.isCollapsed ? "Expand" : "Minimize"
            ) {
                layoutViewModel.isCollapsed.toggle()
            }

            headerButton("eye.slash", help: "Hide") {
                layoutViewModel.isHidden = true
            }

            headerButton(
                layoutViewModel.isDetached ? "pin.slash" : "pin.fill",
                help: layoutViewModel.isDetached ? "Attach to Simulator" : "Detach from Simulator"
            ) {
                layoutViewModel.isDetached.toggle()
            }
        }
        .groupedControlBackground()
    }

    private var positionMenu: some View {
        Menu {
            Picker("Position", selection: $layoutViewModel.position) {
                ForEach(PanelPosition.allCases) { position in
                    Label(position.title, systemImage: position.systemImage)
                        .tag(position)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        } label: {
            Image(systemName: layoutViewModel.position.systemImage)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .frame(width: 24, height: 22)
        .help("Position")
    }

    private func headerButton(_ systemImage: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 24, height: 22)
        }
        .buttonStyle(.borderless)
        .help(help)
    }

    private var quitButton: some View {
        Button {
            NSApp.terminate(nil)
        } label: {
            Image(systemName: "power")
                .frame(width: 24, height: 22)
        }
        .buttonStyle(.borderless)
        .help("Quit Storage Explorer")
    }

    private var settingsButton: some View {
        SettingsLink {
            Image(systemName: "gearshape")
                .frame(width: 24, height: 22)
        }
        .buttonStyle(.borderless)
        .help("Settings")
    }
}
