//
//  MetroBridgeError.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

nonisolated enum MetroBridgeError: LocalizedError, Sendable {
    case metroNotRunning(port: Int)
    case appNotFound(bundleID: String)
    case reduxStoreNotFound
    case zustandStoresNotFound
    case timeout
    case evaluationFailed(String)
    case connectionClosed(reason: String? = nil)

    var errorDescription: String? {
        switch self {
        case .metroNotRunning(let port):
            "Metro isn't running on localhost:\(port). Start the app in debug mode (npx react-native start / npx expo start)."
        case .appNotFound(let bundleID):
            "\(bundleID) isn't connected to Metro. Make sure it's a debug build running with Hermes."
        case .reduxStoreNotFound:
            "No Redux store found. Wrap the app in <Provider store={store}> or add `if (__DEV__) global.__STORAGE_EXPLORER_STORE__ = store`."
        case .zustandStoresNotFound:
            "No Zustand stores found. Add `if (__DEV__) global.__STORAGE_EXPLORER_ZUSTAND__ = { auth: useAuthStore }`."
        case .timeout:
            "The app didn't respond. It may be paused in a debugger."
        case .evaluationFailed(let message):
            "Couldn't read the app state: \(message)"
        case .connectionClosed(let reason):
            if let reason {
                "The connection to the app was closed (\(reason)). Reconnecting…"
            } else {
                "The connection to the app was closed. Reconnecting…"
            }
        }
    }
}
