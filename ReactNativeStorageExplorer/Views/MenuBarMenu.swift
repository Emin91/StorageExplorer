//
//  MenuBarMenu.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import AppKit
import SwiftUI

struct MenuBarMenu: View {
    @ObservedObject var layoutViewModel: PanelLayoutViewModel

    var body: some View {
        Button(layoutViewModel.isHidden ? "Show Panel" : "Hide Panel") {
            layoutViewModel.isHidden.toggle()
        }

        Divider()

        SettingsLink {
            Text("Settings…")
        }
        .keyboardShortcut(",")

        Divider()

        Button("Quit Storage Explorer") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
