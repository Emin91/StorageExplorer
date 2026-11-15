//
//  AppDelegate.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import AppKit
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = AppSettings()
    let layoutViewModel = PanelLayoutViewModel()

    private var panelController: FloatingPanelController?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        LaunchAtLogin.applyDefaultIfNeeded()

        NSApp.setActivationPolicy(settings.showsDockIcon ? .regular : .accessory)
        settings.$showsDockIcon
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] showsDockIcon in
                self?.updateActivationPolicy(showsDockIcon: showsDockIcon)
            }
            .store(in: &cancellables)

        let controller = FloatingPanelController(
            tracker: SimulatorWindowTracker(),
            settings: settings,
            layoutViewModel: layoutViewModel
        )
        controller.start()
        panelController = controller
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        layoutViewModel.isHidden = false
        return false
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        false
    }

    private func updateActivationPolicy(showsDockIcon: Bool) {
        NSApp.setActivationPolicy(showsDockIcon ? .regular : .accessory)
        NSApp.activate()
    }
}
