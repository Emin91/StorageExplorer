//
//  HandleTabController.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import AppKit
import SwiftUI

@MainActor
final class HandleTabController {
    private enum Layout {
        static let windowWidth = HandleTabView.Layout.hoveredWidth
        static let height = HandleTabView.Layout.height
        static let verticalOffsetRatio: CGFloat = 0.25
    }

    var onActivate: (() -> Void)?

    private let panel: NSPanel
    private let hostingView: FirstMouseHostingView<HandleTabView>
    private var configuration: (isOnLeft: Bool, isHinting: Bool)?

    init() {
        panel = NSPanel(contentRect: .zero, styleMask: [.nonactivatingPanel], backing: .buffered, defer: true)
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .none
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]

        hostingView = FirstMouseHostingView(rootView: HandleTabView(isOnLeft: false, onTap: {}))
        hostingView.sizingOptions = []
        panel.contentView = hostingView
    }

    func show(nextTo simulatorFrame: CGRect, onLeft: Bool, isHinting: Bool) {
        if configuration?.isOnLeft != onLeft || configuration?.isHinting != isHinting {
            configuration = (onLeft, isHinting)
            hostingView.rootView = HandleTabView(isOnLeft: onLeft, isHinting: isHinting) { [weak self] in
                self?.onActivate?()
            }
        }

        let frame = CGRect(
            x: onLeft
                ? simulatorFrame.minX + SimulatorMetrics.transparentInset - Layout.windowWidth
                : simulatorFrame.maxX - SimulatorMetrics.transparentInset,
            y: simulatorFrame.midY - simulatorFrame.height * Layout.verticalOffsetRatio - Layout.height / 2,
            width: Layout.windowWidth,
            height: Layout.height
        )
        panel.setFrame(frame, display: true)

        if !panel.isVisible {
            panel.orderFrontRegardless()
        }
    }

    func hide() {
        panel.orderOut(nil)
    }
}
