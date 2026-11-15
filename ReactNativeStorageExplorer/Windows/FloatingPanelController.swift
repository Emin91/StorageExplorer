//
//  FloatingPanelController.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import AppKit
import Combine
import SwiftUI

@MainActor
final class FloatingPanelController: NSObject, NSWindowDelegate {
    private enum Layout {
        static let defaultWidth: CGFloat = 440
        static let minWidth: CGFloat = 360
        static let maxWidth: CGFloat = 720

        static let defaultHeightRatio: CGFloat = 0.6
        static let minHeightRatio: CGFloat = 0.4
        static let maxHeightRatio: CGFloat = 0.7

        static let collapsedGap: CGFloat = 8

        static let detachOffset: CGFloat = 24
        static let animationDuration: TimeInterval = 0.3
        static let fadeDuration: TimeInterval = 0.2
    }

    private let panel: FloatingPanel
    private let tracker: SimulatorWindowTracker
    private let settings: AppSettings
    private let layoutViewModel: PanelLayoutViewModel
    private let appSelection: AppSelectionViewModel
    private let pluginViewModels: [StoragePlugin: PluginStorageViewModel]
    private var cancellables = Set<AnyCancellable>()
    private var simulatorFrame: CGRect?
    private var preferredSize: CGSize?
    private var expandedHeight: CGFloat?
    private var sizeLimits = (min: CGSize.zero, max: CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                            height: CGFloat.greatestFiniteMagnitude))
    private let frameAnimator: WindowFrameAnimator
    private let handleTab = HandleTabController()

    init(tracker: SimulatorWindowTracker, settings: AppSettings, layoutViewModel: PanelLayoutViewModel) {
        self.layoutViewModel = layoutViewModel
        self.tracker = tracker
        self.settings = settings
        let panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: Layout.defaultWidth, height: 480))
        self.panel = panel
        self.frameAnimator = WindowFrameAnimator(window: panel)

        let appSelection = AppSelectionViewModel(settings: settings)
        self.appSelection = appSelection
        let sources: [StoragePlugin: any StorageSource] = [
            .asyncStorage: AsyncStorageSource(),
            .mmkv: MMKVSource(),
            .reduxPersist: ReduxPersistSource()
        ]
        self.pluginViewModels = sources.mapValues { PluginStorageViewModel(source: $0, appSelection: appSelection) }
        super.init()

        let hostingView = NSHostingView(rootView: ContentView(
            layoutViewModel: layoutViewModel,
            appSelection: appSelection,
            pluginViewModels: pluginViewModels,
            settings: settings
        ))
        hostingView.sizingOptions = []
        panel.setContent(hostingView)
        panel.delegate = self

        tracker.onFrameChange = { [weak self] frame in
            self?.update(for: frame)
        }

        layoutViewModel.$position
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.positionDidChange() }
            .store(in: &cancellables)

        layoutViewModel.$isDetached
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.detachedStateDidChange() }
            .store(in: &cancellables)

        handleTab.onActivate = { [weak self] in
            self?.layoutViewModel.isHidden = false
        }

        layoutViewModel.$isHidden
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.hiddenStateDidChange() }
            .store(in: &cancellables)

        layoutViewModel.$isCollapsed
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.collapsedStateDidChange() }
            .store(in: &cancellables)

        applySettings()
        settings.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.applySettings() }
            .store(in: &cancellables)
    }

    func start() {
        tracker.start()
    }

    private func update(for simulatorFrame: CGRect?) {
        self.simulatorFrame = simulatorFrame
        updateHandleTab()

        guard let simulatorFrame else {
            if !layoutViewModel.isDetached {
                panel.orderOut(nil)
            }
            return
        }

        layout(nextTo: simulatorFrame)

        if !panel.isVisible, !layoutViewModel.isHidden {
            panel.orderFrontRegardless()
        }
    }


    private func positionDidChange() {
        guard !layoutViewModel.isDetached, let simulatorFrame else { return }

        let shift = simulatorShift(toFit: layoutViewModel.position, simulatorFrame: simulatorFrame)
        let targetFrame = dockedFrame(nextTo: simulatorFrame.offsetBy(dx: shift ?? 0, dy: 0))

        animate { targetFrame }
        if let shift {
            tracker.moveSimulatorWindow(byX: shift)
        }
    }

    private func detachedStateDidChange() {
        let isDetached = layoutViewModel.isDetached
        panel.isMovable = isDetached

        if isDetached {
            let targetFrame = panel.frame.offsetBy(dx: detachDirection * Layout.detachOffset, dy: 0)
            animate { targetFrame }
        } else if simulatorFrame == nil {
            panel.orderOut(nil)
        } else {
            animate { [weak self] in
                guard let self else { return .zero }
                return self.simulatorFrame.map { self.dockedFrame(nextTo: $0) } ?? self.panel.frame
            }
        }
    }

    private func applySettings() {
        panel.material = settings.material.visualEffectMaterial
        panel.alphaValue = settings.opacity

        if let simulatorFrame {
            layout(nextTo: simulatorFrame)
        }
    }

    private func hiddenStateDidChange() {
        updateHandleTab()

        if layoutViewModel.isHidden {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Layout.fadeDuration
                panel.animator().alphaValue = 0
            } completionHandler: { [weak self] in
                MainActor.assumeIsolated {
                    guard let self, self.layoutViewModel.isHidden else { return }
                    self.panel.orderOut(nil)
                }
            }
        } else if simulatorFrame != nil || layoutViewModel.isDetached {
            if let simulatorFrame {
                layout(nextTo: simulatorFrame)
            }
            panel.alphaValue = 0
            panel.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Layout.fadeDuration
                panel.animator().alphaValue = settings.opacity
            }
        }
    }

    private func updateHandleTab() {
        guard layoutViewModel.isHidden, let simulatorFrame else {
            handleTab.hide()
            return
        }

        let isPanelOnLeft = sideFrame(nextTo: simulatorFrame).midX < simulatorFrame.midX
        handleTab.show(nextTo: simulatorFrame, onLeft: isPanelOnLeft, isHinting: layoutViewModel.showsHandleTabHint)
    }

    private func collapsedStateDidChange() {
        if !layoutViewModel.isDetached, simulatorFrame != nil {
            animate { [weak self] in
                guard let self else { return .zero }
                return self.simulatorFrame.map { self.dockedFrame(nextTo: $0) } ?? self.panel.frame
            }
            return
        }

        let currentFrame = panel.frame
        let height: CGFloat
        if layoutViewModel.isCollapsed {
            expandedHeight = currentFrame.height
            height = layoutViewModel.headerHeight
        } else {
            height = expandedHeight ?? preferredSize?.height ?? currentFrame.height
        }

        let targetFrame = CGRect(x: currentFrame.minX, y: currentFrame.maxY - height, width: currentFrame.width, height: height)
        animate { targetFrame }
    }

    private var detachDirection: CGFloat {
        guard let simulatorFrame else { return 1 }
        return panel.frame.midX < simulatorFrame.midX ? -1 : 1
    }


    private func layout(nextTo simulatorFrame: CGRect) {
        guard !frameAnimator.isAnimating, !layoutViewModel.isDetached else { return }

        let newFrame = dockedFrame(nextTo: simulatorFrame)
        if newFrame.size == panel.frame.size {
            panel.setFrameOrigin(newFrame.origin)
        } else {
            panel.setFrame(newFrame, display: true)
        }
    }

    private func animate(to targetFrame: @escaping () -> CGRect) {
        frameAnimator.animate(duration: Layout.animationDuration, to: targetFrame) { [weak self] in
            guard let self, let simulatorFrame = self.simulatorFrame else { return }
            self.layout(nextTo: simulatorFrame)
        }
    }

    private func dockedFrame(nextTo simulatorFrame: CGRect) -> CGRect {
        let expandedFrame = sideFrame(nextTo: simulatorFrame)
        return layoutViewModel.isCollapsed ? collapsedFrame(nextTo: simulatorFrame) : expandedFrame
    }

    private func sideFrame(nextTo simulatorFrame: CGRect) -> CGRect {
        sizeLimits = (
            min: CGSize(width: Layout.minWidth, height: simulatorFrame.height * Layout.minHeightRatio),
            max: CGSize(width: Layout.maxWidth, height: simulatorFrame.height * Layout.maxHeightRatio)
        )

        let size = clamped(preferredSize ?? defaultSize(for: simulatorFrame))
        return frame(nextTo: simulatorFrame, size: size, position: layoutViewModel.position)
    }

    private func collapsedFrame(nextTo simulatorFrame: CGRect) -> CGRect {
        let deviceFrame = simulatorFrame.insetBy(dx: SimulatorMetrics.transparentInset, dy: SimulatorMetrics.transparentInset)
        let width = deviceFrame.width
        let height = layoutViewModel.headerHeight
        var frame = CGRect(
            x: deviceFrame.minX,
            y: deviceFrame.maxY + Layout.collapsedGap,
            width: width,
            height: height
        )

        if let visibleFrame = screen(containing: simulatorFrame)?.visibleFrame {
            if frame.maxY > visibleFrame.maxY {
                frame.origin.y = deviceFrame.minY - Layout.collapsedGap - height
            }
            frame.origin.x = min(max(frame.minX, visibleFrame.minX), visibleFrame.maxX - width)
        }

        return frame
    }

    private func frame(nextTo simulatorFrame: CGRect, size: CGSize, position: PanelPosition) -> CGRect {
        let leftX = simulatorFrame.minX - settings.spacing - size.width
        let rightX = simulatorFrame.maxX + settings.spacing
        let y = position.isTop ? simulatorFrame.maxY - size.height : simulatorFrame.minY

        var frame = CGRect(x: position.isLeft ? leftX : rightX, y: y, width: size.width, height: size.height)

        if let visibleFrame = screen(containing: simulatorFrame)?.visibleFrame {
            if position.isLeft, frame.minX < visibleFrame.minX {
                frame.origin.x = rightX
            } else if !position.isLeft, frame.maxX > visibleFrame.maxX {
                frame.origin.x = leftX
            }
        }

        return frame
    }

    private func simulatorShift(toFit position: PanelPosition, simulatorFrame: CGRect) -> CGFloat? {
        guard let visibleFrame = screen(containing: simulatorFrame)?.visibleFrame else { return nil }

        let requiredSpace = panel.frame.width + settings.spacing
        let shift = position.isLeft
            ? max(0, visibleFrame.minX - (simulatorFrame.minX - requiredSpace))
            : min(0, visibleFrame.maxX - (simulatorFrame.maxX + requiredSpace))

        let movedFrame = simulatorFrame.offsetBy(dx: shift, dy: 0)
        guard shift != 0,
              movedFrame.minX >= visibleFrame.minX,
              movedFrame.maxX <= visibleFrame.maxX else { return nil }

        return shift
    }

    private func screen(containing simulatorFrame: CGRect) -> NSScreen? {
        NSScreen.screens.first { $0.frame.intersects(simulatorFrame) } ?? NSScreen.main
    }

    private func defaultSize(for simulatorFrame: CGRect) -> CGSize {
        CGSize(width: Layout.defaultWidth, height: simulatorFrame.height * Layout.defaultHeightRatio)
    }

    private func clamped(_ size: CGSize) -> CGSize {
        CGSize(
            width: min(max(size.width, sizeLimits.min.width), sizeLimits.max.width),
            height: min(max(size.height, sizeLimits.min.height), sizeLimits.max.height)
        )
    }


    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        layoutViewModel.isCollapsed ? panel.frame.size : clamped(frameSize)
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        let height = layoutViewModel.isCollapsed ? (preferredSize?.height ?? expandedHeight) : panel.frame.height
        preferredSize = height.map { CGSize(width: panel.frame.width, height: $0) }

        if let simulatorFrame {
            layout(nextTo: simulatorFrame)
        }
    }
}
