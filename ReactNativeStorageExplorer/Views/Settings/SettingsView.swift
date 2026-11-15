//
//  SettingsView.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    private static let maxScreenHeightRatio = 0.7

    private var maxHeight: CGFloat {
        let screenHeight = NSScreen.main?.visibleFrame.height ?? 800
        return screenHeight * Self.maxScreenHeightRatio
    }

    @State private var launchesAtLogin = LaunchAtLogin.isEnabled

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at Login", isOn: $launchesAtLogin)
                    .tint(.orange)
                    .onChange(of: launchesAtLogin) { _, isEnabled in
                        try? LaunchAtLogin.setEnabled(isEnabled)
                        launchesAtLogin = LaunchAtLogin.isEnabled
                    }

                Toggle(isOn: $settings.showsDockIcon) {
                    Text("Show in Dock")
                    Text("The menu bar icon is always available.")
                }
                .tint(.orange)

                Picker(selection: $settings.appSelectionMode) {
                    ForEach(AppSelectionMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                } label: {
                    Text("Select on Launch")
                    Text("The pin next to the app picker switches between the two at any time.")
                }
            }

            Section("Plugins") {
                ForEach(StoragePlugin.allCases) { plugin in
                    PluginToggle(plugin: plugin, isOn: Binding(
                        get: { settings.isEnabled(plugin) },
                        set: { settings.setEnabled($0, for: plugin) }
                    ))
                }
            }

            Section("Layout") {
                LabeledSlider(
                    title: "Spacing from Simulator",
                    value: $settings.spacing,
                    range: 0...32,
                    step: 1,
                    format: { "\(Int($0)) pt" }
                )
            }

            Section("Appearance") {
                Picker("Background", selection: $settings.material) {
                    ForEach(PanelMaterial.allCases) { material in
                        Text(material.title).tag(material)
                    }
                }

                LabeledSlider(
                    title: "Opacity",
                    value: $settings.opacity,
                    range: 0.5...1,
                    step: 0.05,
                    format: { "\(Int(($0 * 100).rounded()))%" }
                )
            }

            Section {
                Button("Reset to Defaults", action: settings.resetToDefaults)
            }

            AboutAuthorSection()
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .background(VisualEffectBackground(material: settings.material.visualEffectMaterial).ignoresSafeArea())
        .background(WindowConfigurator { window in
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
            window.isOpaque = false
            window.backgroundColor = .clear
            window.level = .floating
        })
        .frame(width: 420)
        .frame(maxHeight: maxHeight)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { NSApp.activate() }
    }
}

private struct PluginToggle: View {
    let plugin: StoragePlugin
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(plugin.title)
                        if !plugin.isAvailable {
                            Text("Coming Soon")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(.quaternary, in: Capsule())
                        }
                    }

                    Text(plugin.packageName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: plugin.systemImage)
            }
        }
        .toggleStyle(.switch)
        .tint(.orange)
        .disabled(!plugin.isAvailable)
    }
}

private struct LabeledSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: (Double) -> String

    private var snappedValue: Binding<Double> {
        Binding(
            get: { value },
            set: { value = ($0 / step).rounded() * step }
        )
    }

    var body: some View {
        LabeledContent {
            HStack {
                Slider(value: snappedValue, in: range)
                    .tint(.orange)
                Text(format(value))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 52, alignment: .trailing)
            }
        } label: {
            Text(title)
        }
    }
}

#Preview {
    SettingsView(settings: AppSettings())
}
