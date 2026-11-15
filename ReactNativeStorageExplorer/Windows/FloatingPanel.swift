//
//  FloatingPanel.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import AppKit

final class FloatingPanel: NSPanel {
    private enum Appearance {
        static let cornerRadius: CGFloat = 12
        static let borderWidth: CGFloat = 1
        static let borderColor = NSColor.white.withAlphaComponent(0.12)
    }

    private let effectView = NSVisualEffectView()

    var material: NSVisualEffectView.Material {
        get { effectView.material }
        set { effectView.material = newValue }
    }

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        isMovable = false
        animationBehavior = .none
        collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]

        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func setFrame(_ frameRect: NSRect, display flag: Bool) {
        let sizeChanged = frameRect.size != frame.size
        super.setFrame(frameRect, display: flag)
        if sizeChanged {
            invalidateShadow()
        }
    }

    func setContent(_ view: NSView) {
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.maskImage = Self.roundedMask(radius: Appearance.cornerRadius)

        let borderView = BorderView()
        borderView.wantsLayer = true
        borderView.layer?.cornerRadius = Appearance.cornerRadius
        borderView.layer?.borderWidth = Appearance.borderWidth
        borderView.layer?.borderColor = Appearance.borderColor.cgColor

        for subview in [view, borderView] {
            subview.frame = effectView.bounds
            subview.autoresizingMask = [.width, .height]
            effectView.addSubview(subview)
        }

        contentView = effectView
        invalidateShadow()
    }

    private static func roundedMask(radius: CGFloat) -> NSImage {
        let side = radius * 2 + 1
        let image = NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        image.resizingMode = .stretch
        return image
    }
}

private final class BorderView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
