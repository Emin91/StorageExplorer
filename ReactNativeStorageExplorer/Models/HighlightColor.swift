//
//  HighlightColor.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import SwiftUI

enum HighlightColor: String, CaseIterable, Identifiable {
    case orange
    case yellow
    case green
    case blue
    case purple
    case pink

    var id: Self { self }

    var title: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .blue: .blue
        case .purple: .purple
        case .pink: .pink
        }
    }
}
