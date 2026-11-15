//
//  LaunchAtLogin.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation
import ServiceManagement

enum LaunchAtLogin {
    private static let defaultAppliedKey = "launchAtLogin.defaultApplied"

    static func applyDefaultIfNeeded(defaults: UserDefaults = .standard) {
        guard !defaults.bool(forKey: defaultAppliedKey) else { return }
        defaults.set(true, forKey: defaultAppliedKey)
        try? setEnabled(true)
    }

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ isEnabled: Bool) throws {
        if isEnabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
