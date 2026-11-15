//
//  GroupedControlBackground.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import SwiftUI

extension View {
    func groupedControlBackground() -> some View {
        padding(.vertical, 3)
            .padding(.horizontal, 4)
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
    }
}
