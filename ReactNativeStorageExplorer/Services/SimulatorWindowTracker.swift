//
//  SimulatorWindowTracker.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import AppKit
import ApplicationServices

@_silgen_name("_AXUIElementGetWindow")
private func _AXUIElementGetWindow(_ element: AXUIElement, _ windowID: UnsafeMutablePointer<CGWindowID>) -> AXError

@MainActor
final class SimulatorWindowTracker: NSObject {
    var onFrameChange: ((CGRect?) -> Void)?

    private static let simulatorBundleID = "com.apple.iphonesimulator"

    private static let idleTicksBeforeStop = 30

    private static let appNotifications = [
        kAXFocusedWindowChangedNotification,
        kAXMainWindowChangedNotification,
        kAXWindowCreatedNotification
    ]

    private static let windowNotifications = [
        kAXMovedNotification,
        kAXResizedNotification,
        kAXWindowMiniaturizedNotification,
        kAXWindowDeminiaturizedNotification,
        kAXUIElementDestroyedNotification
    ]

    private var observer: AXObserver?
    private var appElement: AXUIElement?
    private var trackedWindow: AXUIElement?
    private var trackedWindowID: CGWindowID?
    private var lastFrame: CGRect?
    private var permissionTimer: Timer?
    private var displayLink: CADisplayLink?
    private var mouseMonitor: Any?
    private var idleTicks = 0

    private var refcon: UnsafeMutableRawPointer {
        Unmanaged.passUnretained(self).toOpaque()
    }


    func start() {
        if AXIsProcessTrusted() {
            beginTracking()
        } else {
            requestPermission()
        }
    }

    private func requestPermission() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)

        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, AXIsProcessTrusted() else { return }
                self.permissionTimer?.invalidate()
                self.permissionTimer = nil
                self.beginTracking()
            }
        }
    }

    private func beginTracking() {
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(self, selector: #selector(applicationDidLaunch(_:)),
                           name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        center.addObserver(self, selector: #selector(applicationDidTerminate(_:)),
                           name: NSWorkspace.didTerminateApplicationNotification, object: nil)
        center.addObserver(self, selector: #selector(applicationDidActivate(_:)),
                           name: NSWorkspace.didActivateApplicationNotification, object: nil)

        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { [weak self] _ in
            MainActor.assumeIsolated { self?.handleMouseDrag() }
        }

        if let simulator = NSRunningApplication
            .runningApplications(withBundleIdentifier: Self.simulatorBundleID).first {
            attach(to: simulator)
        }
    }

    func moveSimulatorWindow(byX dx: CGFloat) {
        guard let trackedWindow, let axFrame = frame(of: trackedWindow) else { return }

        var origin = CGPoint(x: axFrame.minX + dx, y: axFrame.minY)
        guard let value = AXValueCreate(.cgPoint, &origin) else { return }

        AXUIElementSetAttributeValue(trackedWindow, kAXPositionAttribute as CFString, value)
        updateTrackedFrame()
    }


    @objc private func applicationDidLaunch(_ notification: Notification) {
        guard let app = simulatorApp(from: notification) else { return }
        attach(to: app)
    }

    @objc private func applicationDidTerminate(_ notification: Notification) {
        guard simulatorApp(from: notification) != nil else { return }
        detach()
        report(nil)
    }

    @objc private func applicationDidActivate(_ notification: Notification) {
        refresh()
    }

    private func simulatorApp(from notification: Notification) -> NSRunningApplication? {
        let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        return app?.bundleIdentifier == Self.simulatorBundleID ? app : nil
    }


    private func attach(to app: NSRunningApplication) {
        detach()

        var newObserver: AXObserver?
        let result = AXObserverCreate(app.processIdentifier, { _, _, notification, refcon in
            guard let refcon else { return }
            let tracker = Unmanaged<SimulatorWindowTracker>.fromOpaque(refcon).takeUnretainedValue()
            let name = notification as String
            MainActor.assumeIsolated { tracker.handle(name) }
        }, &newObserver)

        guard result == .success, let newObserver else { return }

        let element = AXUIElementCreateApplication(app.processIdentifier)
        Self.appNotifications.forEach {
            AXObserverAddNotification(newObserver, element, $0 as CFString, refcon)
        }
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(newObserver), .commonModes)

        observer = newObserver
        appElement = element
        refresh()
    }

    private func detach() {
        stopLiveTracking()
        if let observer {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)
        }
        observer = nil
        appElement = nil
        trackedWindow = nil
        trackedWindowID = nil
    }

    private func observe(_ window: AXUIElement) {
        guard let observer else { return }

        if let trackedWindow {
            Self.windowNotifications.forEach {
                AXObserverRemoveNotification(observer, trackedWindow, $0 as CFString)
            }
        }
        Self.windowNotifications.forEach {
            AXObserverAddNotification(observer, window, $0 as CFString, refcon)
        }
        trackedWindow = window

        var windowID: CGWindowID = 0
        trackedWindowID = _AXUIElementGetWindow(window, &windowID) == .success ? windowID : nil
    }

    private func handle(_ notification: String) {
        switch notification {
        case kAXMovedNotification, kAXResizedNotification:
            updateTrackedFrame()
            startLiveTracking()
        default:
            refresh()
        }
    }

    private func handleMouseDrag() {
        guard isSimulatorInFocus, trackedWindow != nil else { return }
        startLiveTracking()
    }


    private func startLiveTracking() {
        idleTicks = 0
        guard displayLink == nil else { return }

        let link = NSScreen.main?.displayLink(target: self, selector: #selector(displayLinkDidFire(_:)))
        link?.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        link?.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopLiveTracking() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func displayLinkDidFire(_ link: CADisplayLink) {
        idleTicks = updateTrackedFrame() ? 0 : idleTicks + 1
        if idleTicks >= Self.idleTicksBeforeStop {
            stopLiveTracking()
        }
    }


    private func refresh() {
        guard isSimulatorInFocus,
              let appElement,
              let window = currentWindow(of: appElement) else {
            report(nil)
            return
        }

        if trackedWindow.map({ !CFEqual($0, window) }) ?? true {
            observe(window)
        }

        let isMinimized: Bool = attribute(kAXMinimizedAttribute, of: window) ?? false
        guard !isMinimized, let axFrame = frame(of: window) else {
            report(nil)
            return
        }

        report(cocoaFrame(fromAX: axFrame))
    }

    @discardableResult
    private func updateTrackedFrame() -> Bool {
        guard isSimulatorInFocus, let trackedWindow else { return false }

        let topLeftFrame = trackedWindowID.flatMap { windowServerFrame(of: $0) } ?? frame(of: trackedWindow)
        guard let topLeftFrame, let frame = cocoaFrame(fromAX: topLeftFrame) else { return false }
        return report(frame)
    }

    private func windowServerFrame(of windowID: CGWindowID) -> CGRect? {
        guard let info = CGWindowListCopyWindowInfo(.optionIncludingWindow, windowID) as? [[String: Any]],
              let bounds = info.first?[kCGWindowBounds as String] as? NSDictionary else { return nil }
        return CGRect(dictionaryRepresentation: bounds as CFDictionary)
    }

    private var isSimulatorInFocus: Bool {
        let front = NSWorkspace.shared.frontmostApplication
        return front?.bundleIdentifier == Self.simulatorBundleID || front == NSRunningApplication.current
    }

    private func currentWindow(of app: AXUIElement) -> AXUIElement? {
        if let focused: AXUIElement = attribute(kAXFocusedWindowAttribute, of: app) { return focused }
        if let main: AXUIElement = attribute(kAXMainWindowAttribute, of: app) { return main }
        let windows: [AXUIElement]? = attribute(kAXWindowsAttribute, of: app)
        return windows?.first
    }

    private func frame(of window: AXUIElement) -> CGRect? {
        guard let positionValue: AXValue = attribute(kAXPositionAttribute, of: window),
              let sizeValue: AXValue = attribute(kAXSizeAttribute, of: window) else { return nil }

        var origin = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(positionValue, .cgPoint, &origin),
              AXValueGetValue(sizeValue, .cgSize, &size) else { return nil }

        return CGRect(origin: origin, size: size)
    }

    private func attribute<T>(_ name: String, of element: AXUIElement) -> T? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value as? T
    }

    private func cocoaFrame(fromAX rect: CGRect) -> CGRect? {
        guard let primaryScreen = NSScreen.screens.first else { return nil }
        return CGRect(
            x: rect.minX,
            y: primaryScreen.frame.maxY - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    @discardableResult
    private func report(_ frame: CGRect?) -> Bool {
        guard frame != lastFrame else { return false }
        lastFrame = frame
        onFrameChange?(frame)
        return true
    }
}
