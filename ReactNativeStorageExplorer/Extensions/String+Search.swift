//
//  String+Search.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

extension String {
    private static let searchOptions: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]

    func matches(_ query: String) -> Bool {
        range(of: query, options: Self.searchOptions) != nil
    }

    func ranges(matching query: String) -> [Range<String.Index>] {
        guard !query.isEmpty else { return [] }

        var ranges: [Range<String.Index>] = []
        var searchStart = startIndex
        while let range = range(of: query, options: Self.searchOptions, range: searchStart..<endIndex) {
            ranges.append(range)
            searchStart = range.upperBound
        }
        return ranges
    }
}
