//
//  JSONValue+Paths.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

extension JSONValue {
    nonisolated static let rootPath = ""
    private nonisolated static let pathSeparator = "\u{1F}"

    static func path(_ parent: String, _ label: String) -> String {
        parent + pathSeparator + label
    }

    func value(at path: String) -> JSONValue? {
        path.components(separatedBy: Self.pathSeparator)
            .dropFirst()
            .reduce(Optional(self)) { node, label in
                node?.children?.first { $0.label == label }?.value
            }
    }

    var scalarText: String? {
        switch self {
        case .string(let string): string
        case .number(let number): number
        case .bool(let bool): bool ? "true" : "false"
        case .null: "null"
        case .object, .array, .encodedJSON: nil
        }
    }

    static func changedPaths(from old: JSONValue?, to new: JSONValue, path: String = rootPath) -> Set<String> {
        guard let old else { return [path] }
        guard old != new else { return [] }

        guard let oldChildren = old.children, let newChildren = new.children else {
            return [path]
        }

        let oldValues = Dictionary(oldChildren.map { ($0.label, $0.value) }, uniquingKeysWith: { first, _ in first })
        return newChildren.reduce(into: [path]) { result, child in
            result.formUnion(changedPaths(from: oldValues[child.label], to: child.value, path: Self.path(path, child.label)))
        }
    }

    struct SearchResult {
        var matches: Set<String> = []
        var orderedMatches: [String] = []
        var expandedPaths: Set<String> = []

        mutating func addMatch(_ path: String) {
            if matches.insert(path).inserted {
                orderedMatches.append(path)
            }
        }
    }

    func search(_ query: String) -> SearchResult {
        var result = SearchResult()
        guard !query.isEmpty else { return result }
        _ = collectMatches(of: query, path: Self.rootPath, into: &result)
        return result
    }

    private func collectMatches(of query: String, path: String, into result: inout SearchResult) -> Bool {
        guard let children else {
            guard let text = scalarText, text.matches(query) else { return false }
            result.addMatch(path)
            return true
        }

        var containsMatch = false
        for child in children {
            let childPath = Self.path(path, child.label)
            var childMatches = false
            if child.label.matches(query) {
                result.addMatch(childPath)
                childMatches = true
            }
            if child.value.collectMatches(of: query, path: childPath, into: &result) {
                childMatches = true
            }
            containsMatch = containsMatch || childMatches
        }

        if containsMatch {
            result.expandedPaths.insert(path)
        }
        return containsMatch
    }
}
