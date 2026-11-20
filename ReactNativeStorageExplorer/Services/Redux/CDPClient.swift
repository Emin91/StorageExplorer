//
//  CDPClient.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

actor CDPClient {
    private static let responseTimeout: Duration = .seconds(5)

    private let socket: URLSessionWebSocketTask
    private var nextMessageID = 0
    private var pendingResponses: [Int: CheckedContinuation<Data, Error>] = [:]
    private(set) var isClosed = false

    init(url: URL) {
        socket = URLSession.shared.webSocketTask(with: url)
        socket.maximumMessageSize = 64 * 1024 * 1024
    }

    func connect() {
        socket.resume()
        Task { await self.receiveMessages() }
    }

    func close() {
        socket.cancel(with: .goingAway, reason: nil)
        failAll(with: ReduxBridgeError.connectionClosed)
    }

    func evaluate(_ expression: String) async throws -> String? {
        guard !isClosed else { throw ReduxBridgeError.connectionClosed }

        nextMessageID += 1
        let id = nextMessageID
        let message: [String: Any] = [
            "id": id,
            "method": "Runtime.evaluate",
            "params": ["expression": expression, "returnByValue": true]
        ]
        let text = String(decoding: try JSONSerialization.data(withJSONObject: message), as: UTF8.self)

        let response = try await withCheckedThrowingContinuation { continuation in
            pendingResponses[id] = continuation
            Task { await self.send(text, id: id) }
            Task {
                try? await Task.sleep(for: Self.responseTimeout)
                self.expire(id)
            }
        }
        return try Self.value(fromResponse: response)
    }

    private func send(_ text: String, id: Int) async {
        do {
            try await socket.send(.string(text))
        } catch {
            pendingResponses.removeValue(forKey: id)?.resume(throwing: ReduxBridgeError.connectionClosed)
        }
    }

    private func receiveMessages() async {
        while !isClosed {
            do {
                let data: Data
                switch try await socket.receive() {
                case .string(let text): data = Data(text.utf8)
                case .data(let binary): data = binary
                @unknown default: continue
                }
                deliver(data)
            } catch {
                failAll(with: ReduxBridgeError.connectionClosed)
            }
        }
    }

    private func deliver(_ data: Data) {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = object["id"] as? Int else { return }
        pendingResponses.removeValue(forKey: id)?.resume(returning: data)
    }

    private func expire(_ id: Int) {
        pendingResponses.removeValue(forKey: id)?.resume(throwing: ReduxBridgeError.timeout)
    }

    private func failAll(with error: Error) {
        isClosed = true
        let continuations = pendingResponses.values
        pendingResponses.removeAll()
        continuations.forEach { $0.resume(throwing: error) }
    }

    private static func value(fromResponse data: Data) throws -> String? {
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ReduxBridgeError.evaluationFailed("Unexpected response")
        }
        if let error = object["error"] as? [String: Any] {
            throw ReduxBridgeError.evaluationFailed(error["message"] as? String ?? "Unknown error")
        }

        let result = object["result"] as? [String: Any]
        if let exception = result?["exceptionDetails"] as? [String: Any] {
            let description = (exception["exception"] as? [String: Any])?["description"] as? String
            throw ReduxBridgeError.evaluationFailed(description ?? exception["text"] as? String ?? "JS exception")
        }
        return (result?["result"] as? [String: Any])?["value"] as? String
    }
}
