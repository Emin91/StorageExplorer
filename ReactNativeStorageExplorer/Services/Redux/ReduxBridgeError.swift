//
//  ReduxBridgeError.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

nonisolated enum ReduxBridgeError: LocalizedError, Sendable {
    case metroNotRunning(port: Int)
    case appNotFound(bundleID: String)
    case storeNotFound
    case timeout
    case evaluationFailed(String)
    case connectionClosed

    var errorDescription: String? {
        switch self {
        case .metroNotRunning(let port):
            "Metro isn't running on localhost:\(port). Start the app in debug mode (npx react-native start / npx expo start)."
        case .appNotFound(let bundleID):
            "\(bundleID) isn't connected to Metro. Make sure it's a debug build running with Hermes."
        case .storeNotFound:
            "No Redux store found. Wrap the app in <Provider store={store}> or add `if (__DEV__) global.__STORAGE_EXPLORER_STORE__ = store`."
        case .timeout:
            "The app didn't respond. It may be paused in a debugger."
        case .evaluationFailed(let message):
            "Couldn't read the Redux state: \(message)"
        case .connectionClosed:
            "The connection to the app was closed. Reconnecting…"
        }
    }
}
