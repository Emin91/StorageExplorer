//
//  AppSettings.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Combine
import Foundation

@MainActor
final class AppSettings: ObservableObject {
    enum Key {
        static let spacing = "settings.spacing"
        static let material = "settings.material"
        static let opacity = "settings.opacity"
        static let enabledPlugins = "settings.enabledPlugins"
        static let showsDockIcon = "settings.showsDockIcon"
        static let appSelectionMode = "settings.appSelectionMode"
        static let metroPort = "settings.metroPort"
        static let highlightsChanges = "settings.highlightsChanges"
        static let highlightColor = "settings.highlightColor"
        static let highlightDuration = "settings.highlightDuration"
    }

    enum Defaults {
        static let spacing: Double = 8
        static let material: PanelMaterial = .hud
        static let opacity: Double = 1
        static let enabledPlugins: Set<StoragePlugin> = [.asyncStorage]
        static let showsDockIcon = true
        static let appSelectionMode: AppSelectionMode = .followRunningApp
        static let metroPort = 8081
        static let highlightsChanges = true
        static let highlightColor: HighlightColor = .orange
        static let highlightDuration: Double = 0.5
    }

    private let defaults: UserDefaults

    let didResetToDefaults = PassthroughSubject<Void, Never>()

    @Published var spacing: Double {
        didSet { defaults.set(spacing, forKey: Key.spacing) }
    }

    @Published var material: PanelMaterial {
        didSet { defaults.set(material.rawValue, forKey: Key.material) }
    }

    @Published var opacity: Double {
        didSet { defaults.set(opacity, forKey: Key.opacity) }
    }

    @Published var enabledPlugins: Set<StoragePlugin> {
        didSet { defaults.set(enabledPlugins.map(\.rawValue), forKey: Key.enabledPlugins) }
    }

    @Published var showsDockIcon: Bool {
        didSet { defaults.set(showsDockIcon, forKey: Key.showsDockIcon) }
    }

    @Published var appSelectionMode: AppSelectionMode {
        didSet { defaults.set(appSelectionMode.rawValue, forKey: Key.appSelectionMode) }
    }

    @Published var metroPort: Int {
        didSet { defaults.set(metroPort, forKey: Key.metroPort) }
    }

    @Published var highlightsChanges: Bool {
        didSet { defaults.set(highlightsChanges, forKey: Key.highlightsChanges) }
    }

    @Published var highlightColor: HighlightColor {
        didSet { defaults.set(highlightColor.rawValue, forKey: Key.highlightColor) }
    }

    @Published var highlightDuration: Double {
        didSet { defaults.set(highlightDuration, forKey: Key.highlightDuration) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        spacing = defaults.object(forKey: Key.spacing) as? Double ?? Defaults.spacing
        material = defaults.string(forKey: Key.material).flatMap(PanelMaterial.init(rawValue:)) ?? Defaults.material
        opacity = defaults.object(forKey: Key.opacity) as? Double ?? Defaults.opacity
        enabledPlugins = defaults.stringArray(forKey: Key.enabledPlugins)
            .map { Set($0.compactMap(StoragePlugin.init(rawValue:))) } ?? Defaults.enabledPlugins
        showsDockIcon = defaults.object(forKey: Key.showsDockIcon) as? Bool ?? Defaults.showsDockIcon
        appSelectionMode = defaults.string(forKey: Key.appSelectionMode)
            .flatMap(AppSelectionMode.init(rawValue:)) ?? Defaults.appSelectionMode
        metroPort = defaults.object(forKey: Key.metroPort) as? Int ?? Defaults.metroPort
        highlightsChanges = defaults.object(forKey: Key.highlightsChanges) as? Bool ?? Defaults.highlightsChanges
        highlightColor = defaults.string(forKey: Key.highlightColor)
            .flatMap(HighlightColor.init(rawValue:)) ?? Defaults.highlightColor
        highlightDuration = defaults.object(forKey: Key.highlightDuration) as? Double ?? Defaults.highlightDuration
    }

    func isEnabled(_ plugin: StoragePlugin) -> Bool {
        enabledPlugins.contains(plugin)
    }

    func setEnabled(_ isEnabled: Bool, for plugin: StoragePlugin) {
        if isEnabled {
            enabledPlugins.insert(plugin)
        } else {
            enabledPlugins.remove(plugin)
        }
    }

    func resetToDefaults() {
        spacing = Defaults.spacing
        material = Defaults.material
        opacity = Defaults.opacity
        enabledPlugins = Defaults.enabledPlugins
        showsDockIcon = Defaults.showsDockIcon
        appSelectionMode = Defaults.appSelectionMode
        metroPort = Defaults.metroPort
        highlightsChanges = Defaults.highlightsChanges
        highlightColor = Defaults.highlightColor
        highlightDuration = Defaults.highlightDuration

        StorageColumn.LayoutKey.all.forEach(defaults.removeObject(forKey:))
        didResetToDefaults.send()
    }
}
