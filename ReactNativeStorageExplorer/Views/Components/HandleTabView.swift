//
//  HandleTabView.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import SwiftUI

struct HandleTabView: View {
    let isOnLeft: Bool
    var isHinting = false
    let onTap: () -> Void

    @State private var isHovered = false
    @State private var isPeeking = false

    enum Layout {
        static let width: CGFloat = 4
        static let hoveredWidth: CGFloat = 60
        static let height: CGFloat = 72
        static let cornerRadius: CGFloat = 8
        static let iconPadding: CGFloat = 16
        static let peekWidth: CGFloat = 18
        static let peekDuration: Duration = .milliseconds(600)
        static let peekPause: Duration = .milliseconds(1400)
    }

    private var currentWidth: CGFloat {
        if isHovered { return Layout.hoveredWidth }
        return isPeeking ? Layout.peekWidth : Layout.width
    }

    var body: some View {
        UnevenRoundedRectangle(cornerRadii: outerCornerRadii)
            .fill(Color.orange.gradient)
            .overlay(alignment: isOnLeft ? .leading : .trailing) {
                Image(systemName: "externaldrive.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .fixedSize()
                    .padding(.horizontal, Layout.iconPadding)
            }
            .clipShape(UnevenRoundedRectangle(cornerRadii: outerCornerRadii))
            .frame(width: currentWidth, height: Layout.height)
            .contentShape(Rectangle())
            .onHover { hovering in
                withAnimation(.spring(duration: 0.25)) {
                    isHovered = hovering
                }
            }
            .onTapGesture(perform: onTap)
            .task(id: isHinting) {
                await peekRepeatedly()
            }
            .help("Show Storage Explorer")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isOnLeft ? .trailing : .leading)
    }

    private func peekRepeatedly() async {
        while isHinting, !Task.isCancelled {
            if !isHovered {
                withAnimation(.easeInOut(duration: 0.6)) { isPeeking = true }
                try? await Task.sleep(for: Layout.peekDuration)
                withAnimation(.easeInOut(duration: 0.6)) { isPeeking = false }
            }
            try? await Task.sleep(for: Layout.peekPause)
        }
        isPeeking = false
    }

    private var outerCornerRadii: RectangleCornerRadii {
        let radius = Layout.cornerRadius
        return isOnLeft
            ? RectangleCornerRadii(topLeading: radius, bottomLeading: radius)
            : RectangleCornerRadii(bottomTrailing: radius, topTrailing: radius)
    }
}
