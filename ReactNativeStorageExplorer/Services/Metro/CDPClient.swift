//
//  CDPClient.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation
import Network

actor CDPClient {
    private static let responseTimeout: Duration = .seconds(5)
    private static let maximumMessageSize = 64 * 1024 * 1024

    private let connection: NWConnection
    private let queue = DispatchQueue(label: "dev.eminzeynalov.StorageExplorer.CDPClient")
    private var nextMessageID = 0
    private var pendingResponses: [Int: CheckedContinuation<Data, Error>] = [:]
    private(set) var isClosed = false

    init(url: URL) {
        let webSocketOptions = NWProtocolWebSocket.Options()
        webSocketOptions.autoReplyPing = true
        webSocketOptions.maximumMessageSize = Self.maximumMessageSize
        webSocketOptions.setAdditionalHeaders([("Origin", Self.origin(for: url))])

        let parameters = NWParameters.tcp
        parameters.defaultProtocolStack.applicationProtocols.insert(webSocketOptions, at: 0)
        connection = NWConnection(to: .url(url), using: parameters)
    }

    private static func origin(for url: URL) -> String {
        let loopbackHosts: Set<String> = ["localhost", "127.0.0.1", "::1", "[::1]"]
        let urlHost = url.host() ?? "localhost"
        let host = loopbackHosts.contains(urlHost) ? "127.0.0.1" : urlHost
        let port = url.port.map { ":\($0)" } ?? ""
        return "http://\(host)\(port)"
    }

    func connect() {
        connection.stateUpdateHandler = { [weak self] state in
            Task { await self?.handle(state) }
        }
        connection.start(queue: queue)
        receiveNextMessage()
    }

    func close() {
        connection.cancel()
        failAll(with: MetroBridgeError.connectionClosed())
    }

    func evaluate(_ expression: String) async throws -> String? {
        guard !isClosed else { throw MetroBridgeError.connectionClosed() }

        nextMessageID += 1
        let id = nextMessageID
        let message: [String: Any] = [
            "id": id,
            "method": "Runtime.evaluate",
            "params": ["expression": expression, "returnByValue": true]
        ]
        let data = try JSONSerialization.data(withJSONObject: message)

        let response = try await withCheckedThrowingContinuation { continuation in
            pendingResponses[id] = continuation
            send(data, id: id)
            Task {
                try? await Task.sleep(for: Self.responseTimeout)
                self.expire(id)
            }
        }
        return try Self.value(fromResponse: response)
    }

    private func send(_ data: Data, id: Int) {
        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "cdp", metadata: [metadata])
        connection.send(content: data, contentContext: context, isComplete: true, completion: .contentProcessed { [weak self] error in
            guard let error else { return }
            Task { await self?.failRequest(id, reason: error.localizedDescription) }
        })
    }

    private func failRequest(_ id: Int, reason: String) {
        pendingResponses.removeValue(forKey: id)?.resume(throwing: MetroBridgeError.connectionClosed(reason: reason))
    }

    private func receiveNextMessage() {
        connection.receiveMessage { [weak self] data, context, _, error in
            let metadata = context?.protocolMetadata(definition: NWProtocolWebSocket.definition)
                as? NWProtocolWebSocket.Metadata
            let opcode = metadata?.opcode
            let closeReason = Self.description(of: metadata?.closeCode)
            Task { await self?.handleMessage(data, opcode: opcode, closeReason: closeReason, error: error) }
        }
    }

    private func handleMessage(
        _ data: Data?,
        opcode: NWProtocolWebSocket.Opcode?,
        closeReason: String?,
        error: NWError?
    ) {
        guard !isClosed else { return }
        if let error {
            failAll(with: MetroBridgeError.connectionClosed(reason: error.localizedDescription))
            return
        }
        if opcode == .close {
            failAll(with: MetroBridgeError.connectionClosed(reason: closeReason))
            connection.cancel()
            return
        }
        if let data, opcode == .text || opcode == .binary {
            deliver(data)
        }
        receiveNextMessage()
    }

    private func handle(_ state: NWConnection.State) {
        switch state {
        case .failed(let error), .waiting(let error):
            failAll(with: MetroBridgeError.connectionClosed(reason: error.localizedDescription))
            connection.cancel()
        case .cancelled:
            failAll(with: MetroBridgeError.connectionClosed())
        default:
            break
        }
    }

    private static func description(of closeCode: NWProtocolWebSocket.CloseCode?) -> String? {
        switch closeCode {
        case .protocolCode(let code): "code \(code.rawValue)"
        case .applicationCode(let code), .privateCode(let code): "code \(code)"
        case nil: nil
        @unknown default: nil
        }
    }

    private func deliver(_ data: Data) {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = object["id"] as? Int else { return }
        pendingResponses.removeValue(forKey: id)?.resume(returning: data)
    }

    private func expire(_ id: Int) {
        pendingResponses.removeValue(forKey: id)?.resume(throwing: MetroBridgeError.timeout)
    }

    private func failAll(with error: Error) {
        guard !isClosed else { return }
        isClosed = true
        let continuations = pendingResponses.values
        pendingResponses.removeAll()
        continuations.forEach { $0.resume(throwing: error) }
    }

    private static func value(fromResponse data: Data) throws -> String? {
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw MetroBridgeError.evaluationFailed("Unexpected response")
        }
        if let error = object["error"] as? [String: Any] {
            throw MetroBridgeError.evaluationFailed(error["message"] as? String ?? "Unknown error")
        }

        let result = object["result"] as? [String: Any]
        if let exception = result?["exceptionDetails"] as? [String: Any] {
            let description = (exception["exception"] as? [String: Any])?["description"] as? String
            throw MetroBridgeError.evaluationFailed(description ?? exception["text"] as? String ?? "JS exception")
        }
        return (result?["result"] as? [String: Any])?["value"] as? String
    }
}
