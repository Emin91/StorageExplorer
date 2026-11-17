//
//  StorageSort.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

struct StorageSort: Equatable {
    enum Column: Equatable {
        case key
        case type
        case size
        case modified
    }

    let column: Column
    let isAscending: Bool

    static func next(after sort: StorageSort?, clicking column: Column) -> StorageSort? {
        guard let sort, sort.column == column else { return StorageSort(column: column, isAscending: true) }
        return sort.isAscending ? StorageSort(column: column, isAscending: false) : nil
    }

    func sorted(_ items: [StorageItem]) -> [StorageItem] {
        var groupRanks: [String?: Int] = [:]
        for item in items where groupRanks[item.group] == nil {
            groupRanks[item.group] = groupRanks.count
        }

        return items.enumerated()
            .sorted { lhs, rhs in
                let lhsGroup = groupRanks[lhs.element.group] ?? 0
                let rhsGroup = groupRanks[rhs.element.group] ?? 0
                if lhsGroup != rhsGroup { return lhsGroup < rhsGroup }

                switch compare(lhs.element, rhs.element) {
                case .orderedAscending: return true
                case .orderedDescending: return false
                case .orderedSame: return lhs.offset < rhs.offset
                }
            }
            .map(\.element)
    }

    private func compare(_ lhs: StorageItem, _ rhs: StorageItem) -> ComparisonResult {
        if column == .modified, (lhs.modifiedAt == nil) != (rhs.modifiedAt == nil) {
            return lhs.modifiedAt == nil ? .orderedDescending : .orderedAscending
        }

        let result: ComparisonResult = switch column {
        case .key: lhs.key.localizedStandardCompare(rhs.key)
        case .type: lhs.type.title.localizedStandardCompare(rhs.type.title)
        case .size: Self.compare(lhs.size, rhs.size)
        case .modified: Self.compare(lhs.modifiedAt ?? .distantPast, rhs.modifiedAt ?? .distantPast)
        }
        return isAscending ? result : result.reversed
    }

    private static func compare<T: Comparable>(_ lhs: T, _ rhs: T) -> ComparisonResult {
        lhs < rhs ? .orderedAscending : (lhs > rhs ? .orderedDescending : .orderedSame)
    }
}

private extension ComparisonResult {
    var reversed: ComparisonResult {
        switch self {
        case .orderedAscending: .orderedDescending
        case .orderedDescending: .orderedAscending
        case .orderedSame: .orderedSame
        }
    }
}
