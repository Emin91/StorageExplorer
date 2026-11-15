//
//  ByteReader.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

nonisolated struct ByteReader {
    private let bytes: [UInt8]
    private var position: Int

    init<Bytes: Collection<UInt8>>(_ bytes: Bytes) {
        self.bytes = Array(bytes)
        self.position = 0
    }

    var isAtEnd: Bool { position >= bytes.count }
    var remainingCount: Int { bytes.count - position }

    mutating func readVarint() -> Int? {
        var result = 0
        var shift = 0
        while position < bytes.count, shift < 35 {
            let byte = bytes[position]
            position += 1
            result |= Int(byte & 0x7F) << shift
            if byte & 0x80 == 0 {
                return result
            }
            shift += 7
        }
        return nil
    }

    mutating func readBytes(count: Int) -> [UInt8]? {
        guard count >= 0, count <= remainingCount else { return nil }
        defer { position += count }
        return Array(bytes[position..<position + count])
    }
}
