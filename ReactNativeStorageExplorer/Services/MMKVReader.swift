//
//  MMKVReader.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

nonisolated struct MMKVReader {
    private static let defaultInstanceID = "mmkv.default"
    private static let headerSize = 4

    private enum MetaInfo {
        static let versionOffset = 4
        static let actualSizeOffset = 28
        static let actualSizeVersion = 3
    }

    @concurrent
    func readItems(in directoryURL: URL) async throws -> [StorageItem] {
        let instanceURLs = try FileManager.default
            .contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            .filter { $0.pathExtension != "crc" }

        return try instanceURLs
            .flatMap(items(inInstanceAt:))
            .sorted {
                ($0.namespace ?? "", $0.key.lowercased()) < ($1.namespace ?? "", $1.key.lowercased())
            }
    }

    private func items(inInstanceAt url: URL) throws -> [StorageItem] {
        let data = try Data(contentsOf: url)
        let metaData = try? Data(contentsOf: url.appendingPathExtension("crc"))
        guard let records = records(in: data, actualSize: actualSize(data: data, metaData: metaData)) else { return [] }

        let instanceID = url.lastPathComponent
        let namespace = instanceID == Self.defaultInstanceID ? nil : instanceID

        return records.map { key, rawValue in
            let decoded = decodeValue(rawValue)
            return StorageItem(key: key, value: decoded.text, namespace: namespace, type: decoded.type)
        }
    }

    private func actualSize(data: Data, metaData: Data?) -> Int {
        if let metaData,
           metaData.count >= MetaInfo.actualSizeOffset + 4,
           readUInt32(metaData, at: MetaInfo.versionOffset) >= MetaInfo.actualSizeVersion {
            return readUInt32(metaData, at: MetaInfo.actualSizeOffset)
        }
        return data.count >= Self.headerSize ? readUInt32(data, at: 0) : 0
    }

    private func readUInt32(_ data: Data, at offset: Int) -> Int {
        let start = data.startIndex + offset
        return data[start..<start + 4].enumerated().reduce(0) { $0 | Int($1.element) << (8 * $1.offset) }
    }

    private func records(in data: Data, actualSize: Int) -> [String: [UInt8]]? {
        guard actualSize > 0 else { return [:] }
        guard actualSize <= data.count - Self.headerSize else { return nil }

        var reader = ByteReader(data.dropFirst(Self.headerSize).prefix(actualSize))
        guard reader.readVarint() != nil else { return nil }

        var records: [String: [UInt8]] = [:]
        while !reader.isAtEnd {
            guard let keyLength = reader.readVarint(),
                  let keyBytes = reader.readBytes(count: keyLength),
                  let key = String(bytes: keyBytes, encoding: .utf8),
                  let valueLength = reader.readVarint(),
                  let value = reader.readBytes(count: valueLength) else { return nil }

            records[key] = value.isEmpty ? nil : value
        }
        return records
    }

    private func decodeValue(_ bytes: [UInt8]) -> (text: String, type: StorageValueType?) {
        var reader = ByteReader(bytes)
        if let length = reader.readVarint(),
           length == reader.remainingCount,
           let stringBytes = reader.readBytes(count: length),
           let string = String(bytes: stringBytes, encoding: .utf8) {
            return (string, nil)
        }

        if bytes.count == 8 {
            let bits = bytes.enumerated().reduce(UInt64(0)) { $0 | UInt64($1.element) << (8 * UInt64($1.offset)) }
            return (format(Double(bitPattern: bits)), .number)
        }

        if bytes.count == 1, bytes[0] <= 1 {
            return (bytes[0] == 1 ? "true" : "false", .boolean)
        }

        return (bytes.map { String(format: "%02x", $0) }.joined(separator: " "), .binary)
    }

    private func format(_ number: Double) -> String {
        if number.rounded() == number, abs(number) < 1e15 {
            return String(Int64(number))
        }
        return String(number)
    }
}
