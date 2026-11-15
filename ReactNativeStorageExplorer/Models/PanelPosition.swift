//
//  PanelPosition.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

enum PanelPosition: String, CaseIterable, Identifiable {
    case topLeft
    case bottomLeft
    case topRight
    case bottomRight

    var id: Self { self }

    var isLeft: Bool { self == .topLeft || self == .bottomLeft }
    var isTop: Bool { self == .topLeft || self == .topRight }

    var title: String {
        switch self {
        case .topLeft: "Left Top"
        case .bottomLeft: "Left Bottom"
        case .topRight: "Right Top"
        case .bottomRight: "Right Bottom"
        }
    }

    var systemImage: String {
        switch self {
        case .topLeft: "rectangle.inset.topleft.filled"
        case .bottomLeft: "rectangle.inset.bottomleft.filled"
        case .topRight: "rectangle.inset.topright.filled"
        case .bottomRight: "rectangle.inset.bottomright.filled"
        }
    }
}
