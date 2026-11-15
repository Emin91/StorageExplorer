//
//  StorageExplorerApp.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import SwiftUI

@main
struct StorageExplorerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(settings: appDelegate.settings)
        }
        .defaultLaunchBehavior(.suppressed)

        MenuBarExtra("Storage Explorer", systemImage: "externaldrive.fill") {
            MenuBarMenu(layoutViewModel: appDelegate.layoutViewModel)
        }
    }
}
