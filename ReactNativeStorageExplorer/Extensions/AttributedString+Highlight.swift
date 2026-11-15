//
//  AttributedString+Highlight.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import SwiftUI

extension AttributedString {
    init(_ text: String, highlighting query: String) {
        self.init(text)

        for range in text.ranges(matching: query) {
            guard let attributedRange = Range(range, in: self) else { continue }
            self[attributedRange].backgroundColor = .yellow.opacity(0.35)
            self[attributedRange].foregroundColor = .primary
        }
    }
}
