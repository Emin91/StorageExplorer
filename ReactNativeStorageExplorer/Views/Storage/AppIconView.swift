//
//  AppIconView.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import SwiftUI

struct AppIconView: View {
    let url: URL?
    var size: CGFloat = 18

    var body: some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .interpolation(.high)
        } placeholder: {
            Image(systemName: "app.dashed")
                .resizable()
                .foregroundStyle(.secondary)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }
}
