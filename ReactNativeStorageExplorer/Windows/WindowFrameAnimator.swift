//
//  WindowFrameAnimator.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import AppKit

@MainActor
final class WindowFrameAnimator: NSObject {
    private weak var window: NSWindow?
    private var displayLink: CADisplayLink?
    private var startFrame = CGRect.zero
    private var startTime: CFTimeInterval = 0
    private var duration: CFTimeInterval = 0
    private var targetFrame: () -> CGRect = { .zero }
    private var completion: (() -> Void)?

    var isAnimating: Bool { displayLink != nil }

    init(window: NSWindow) {
        self.window = window
    }

    func animate(
        duration: CFTimeInterval,
        to targetFrame: @escaping () -> CGRect,
        completion: (() -> Void)? = nil
    ) {
        guard let window else { return }
        stop()

        startFrame = window.frame
        startTime = CACurrentMediaTime()
        self.duration = duration
        self.targetFrame = targetFrame
        self.completion = completion

        let link = window.displayLink(target: self, selector: #selector(step(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stop() {
        displayLink?.invalidate()
        displayLink = nil
        completion = nil
    }

    @objc private func step(_ link: CADisplayLink) {
        guard let window else {
            stop()
            return
        }

        let progress = min((CACurrentMediaTime() - startTime) / duration, 1)
        window.setFrame(interpolate(from: startFrame, to: targetFrame(), progress: easeInOut(progress)), display: true)

        if progress >= 1 {
            let completion = completion
            stop()
            completion?()
        }
    }

    private func easeInOut(_ t: CGFloat) -> CGFloat {
        t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
    }

    private func interpolate(from start: CGRect, to end: CGRect, progress: CGFloat) -> CGRect {
        CGRect(
            x: start.minX + (end.minX - start.minX) * progress,
            y: start.minY + (end.minY - start.minY) * progress,
            width: start.width + (end.width - start.width) * progress,
            height: start.height + (end.height - start.height) * progress
        )
    }
}
