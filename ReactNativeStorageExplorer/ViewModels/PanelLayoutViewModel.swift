//
//  PanelLayoutViewModel.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Combine
import Foundation

@MainActor
final class PanelLayoutViewModel: ObservableObject {
    private static let positionKey = "panelPosition"
    private static let handleTabHintCompletedKey = "onboarding.handleTabHintCompleted"

    @Published var position: PanelPosition {
        didSet { UserDefaults.standard.set(position.rawValue, forKey: Self.positionKey) }
    }

    @Published var isDetached = false

    @Published var isHidden: Bool {
        didSet {
            if !isHidden {
                completeHandleTabHint()
            }
        }
    }

    @Published private(set) var showsHandleTabHint: Bool

    @Published var isCollapsed = false

    @Published var headerHeight: CGFloat = 40

    init() {
        let storedValue = UserDefaults.standard.string(forKey: Self.positionKey)
        position = storedValue.flatMap(PanelPosition.init(rawValue:)) ?? .topRight

        let isFirstLaunch = !UserDefaults.standard.bool(forKey: Self.handleTabHintCompletedKey)
        showsHandleTabHint = isFirstLaunch
        isHidden = isFirstLaunch
    }

    private func completeHandleTabHint() {
        guard showsHandleTabHint else { return }
        showsHandleTabHint = false
        UserDefaults.standard.set(true, forKey: Self.handleTabHintCompletedKey)
    }
}
