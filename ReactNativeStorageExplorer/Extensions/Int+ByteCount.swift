//
//  Int+ByteCount.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

extension Int {
    var formattedByteCount: String {
        formatted(.byteCount(style: .memory, spellsOutZero: false))
    }
}
