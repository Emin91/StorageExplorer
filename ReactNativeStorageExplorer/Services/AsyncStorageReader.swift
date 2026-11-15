//
//  AsyncStorageReader.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import CryptoKit
import Foundation

nonisolated struct AsyncStorageReader {
    @concurrent
    func readItems(in directoryURL: URL) async throws -> [StorageItem] {
        let manifestURL = directoryURL.appending(path: "manifest.json")
        guard FileManager.default.fileExists(atPath: manifestURL.path(percentEncoded: false)) else { return [] }

        let data = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode([String: String?].self, from: data)

        return manifest
            .map { key, inlineValue in
                if let inlineValue {
                    return StorageItem(key: key, value: inlineValue)
                }
                let overflow = overflowValue(for: key, in: directoryURL)
                return StorageItem(key: key, value: overflow?.value ?? "", modifiedAt: overflow?.modifiedAt)
            }
            .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
    }

    private func overflowValue(for key: String, in directoryURL: URL) -> (value: String, modifiedAt: Date?)? {
        let fileName = Insecure.MD5.hash(data: Data(key.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        let fileURL = directoryURL.appending(path: fileName)

        guard let value = try? String(contentsOf: fileURL, encoding: .utf8) else { return nil }
        let modifiedAt = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
        return (value, modifiedAt)
    }
}
