//
//  PanelMaterial.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import AppKit

enum PanelMaterial: String, CaseIterable, Identifiable {
    case hud
    case popover
    case sidebar
    case menu
    case underWindow

    var id: Self { self }

    var title: String {
        switch self {
        case .hud: "HUD"
        case .popover: "Popover"
        case .sidebar: "Sidebar"
        case .menu: "Menu"
        case .underWindow: "Under Window"
        }
    }

    var visualEffectMaterial: NSVisualEffectView.Material {
        switch self {
        case .hud: .hudWindow
        case .popover: .popover
        case .sidebar: .sidebar
        case .menu: .menu
        case .underWindow: .underWindowBackground
        }
    }
}
