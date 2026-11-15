//
//  WindowConfigurator.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import AppKit
import SwiftUI

struct WindowConfigurator: NSViewRepresentable {
    let configure: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = WindowObservingView()
        view.onWindowChange = configure
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? WindowObservingView)?.applyConfiguration()
    }
}

private final class WindowObservingView: NSView {
    var onWindowChange: ((NSWindow) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyConfiguration()
    }

    func applyConfiguration() {
        DispatchQueue.main.async { [weak self] in
            guard let self, let window = self.window else { return }
            self.onWindowChange?(window)
        }
    }
}
