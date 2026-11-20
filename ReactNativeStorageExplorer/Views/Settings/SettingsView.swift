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

    private var metroPortField: some View {
        LabeledContent {
            TextField("Metro Port", value: metroPort, format: .number.grouping(.never))
                .labelsHidden()
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        } label: {
            Text("Metro Port")
            Text("Default: \(AppSettings.Defaults.metroPort)")
        }
        .padding(.leading, 28)
    }

    private var metroPort: Binding<Int> {
        Binding(
            get: { settings.metroPort },
            set: { settings.metroPort = min(max($0, 1), 65_535) }
        )
    }

    @State private var launchesAtLogin = LaunchAtLogin.isEnabled

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at Login", isOn: $launchesAtLogin)
                    .tint(.orange)
                    .controlSize(.small)
                    .onChange(of: launchesAtLogin) { _, isEnabled in
                        try? LaunchAtLogin.setEnabled(isEnabled)
                        launchesAtLogin = LaunchAtLogin.isEnabled
                    }

                Toggle(isOn: $settings.showsDockIcon) {
                    Text("Show in Dock")
                    Text("The menu bar icon is always available.")
                }
                .tint(.orange)
                .controlSize(.small)

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
                        set: { isOn in
                            withAnimation(.easeInOut(duration: 0.25)) {
                                settings.setEnabled(isOn, for: plugin)
                            }
                        }
                    ))

                    if plugin == .redux, settings.isEnabled(.redux) {
                        metroPortField
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }

            Section("Change Highlight") {
                Toggle("Highlight changed values", isOn: $settings.highlightsChanges)
                    .tint(.orange)
                    .controlSize(.small)

                LabeledContent("Color") {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(settings.highlightColor.color)
                            .frame(width: 12, height: 12)
                        Picker("Color", selection: $settings.highlightColor) {
                            ForEach(HighlightColor.allCases) { color in
                                Text(color.title).tag(color)
                            }
                        }
                        .labelsHidden()
                        .fixedSize()
                    }
                }
                .disabled(!settings.highlightsChanges)

                LabeledSlider(
                    title: "Duration",
                    value: $settings.highlightDuration,
                    range: 0.2...2,
                    step: 0.1,
                    format: { String(format: "%.1f s", $0) }
                )
                .disabled(!settings.highlightsChanges)
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
        .controlSize(.small)
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
                    .controlSize(.small)
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
