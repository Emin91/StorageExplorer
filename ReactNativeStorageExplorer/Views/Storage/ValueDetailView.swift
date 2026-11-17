//
//  ValueDetailView.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import SwiftUI

struct ValueDetailView: View {
    let item: StorageItem

    private enum Mode: String, CaseIterable, Identifiable {
        case tree = "Tree"
        case raw = "Raw"

        var id: Self { self }
    }

    @AppStorage(AppSettings.Key.highlightsChanges) private var highlightsChanges = AppSettings.Defaults.highlightsChanges
    @AppStorage(AppSettings.Key.highlightColor) private var highlightColor = AppSettings.Defaults.highlightColor
    @AppStorage(AppSettings.Key.highlightDuration) private var highlightDuration = AppSettings.Defaults.highlightDuration

    @State private var mode: Mode = .tree
    @State private var json: JSONValue?
    @State private var searchText = ""
    @State private var currentMatchIndex = 0
    @State private var flashingPaths: Set<String> = []

    private var searchQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var searchResult: JSONValue.SearchResult {
        guard let json, mode == .tree else { return JSONValue.SearchResult() }
        return json.search(searchQuery)
    }

    private var currentMatchPath: String? {
        let matches = searchResult.orderedMatches
        return matches.indices.contains(currentMatchIndex) ? matches[currentMatchIndex] : nil
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            valueContainer
                .padding(12)
        }
        .onChange(of: item.value, initial: true) { oldValue, newValue in
            valueDidChange(from: oldValue, to: newValue)
        }
        .onChange(of: searchQuery) {
            currentMatchIndex = 0
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(item.key)
                    .font(.headline)
                    .textSelection(.enabled)
                    .lineLimit(2)
                if let namespace = item.namespace {
                    Text(namespace)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                        .background(Color.primary.opacity(0.08), in: Capsule())
                }
                CopyButton(title: "Copy Key", text: item.key)
                    .labelStyle(.iconOnly)
                    .font(.caption)
            }

            HStack {
                Text("\(item.type.title) · \(item.size.formattedByteCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if json != nil {
                    Picker("Mode", selection: $mode) {
                        ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .controlSize(.small)
                    .fixedSize()
                }
            }

            searchBar
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            SearchField(text: $searchText, prompt: "Search in value")
                .onSubmit { stepMatch(by: 1) }

            if !searchQuery.isEmpty, json != nil, mode == .tree {
                matchNavigator
            }
        }
    }

    private var matchNavigator: some View {
        let matchCount = searchResult.orderedMatches.count

        return HStack(spacing: 4) {
            Text(matchCount == 0 ? "No matches" : "\(currentMatchIndex + 1) of \(matchCount)")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .fixedSize()

            Button {
                stepMatch(by: -1)
            } label: {
                Image(systemName: "chevron.up")
            }
            .help("Previous Match")

            Button {
                stepMatch(by: 1)
            } label: {
                Image(systemName: "chevron.down")
            }
            .help("Next Match")
        }
        .buttonStyle(.borderless)
        .disabled(matchCount == 0)
    }

    private func scrollAnchor(forMatchAt path: String) -> UnitPoint {
        guard let text = json?.value(at: path)?.scalarText,
              let range = text.range(of: searchQuery, options: [.caseInsensitive, .diacriticInsensitive]),
              !text.isEmpty else { return .center }

        let offset = text.distance(from: text.startIndex, to: range.lowerBound)
        return UnitPoint(x: 0, y: CGFloat(offset) / CGFloat(text.count))
    }

    private func stepMatch(by offset: Int) {
        let matchCount = searchResult.orderedMatches.count
        guard matchCount > 0 else { return }
        currentMatchIndex = (currentMatchIndex + offset + matchCount) % matchCount
    }

    private var valueContainer: some View {
        GeometryReader { proxy in
            ScrollViewReader { scrollProxy in
                ScrollView(.vertical) {
                    content
                        .padding(12)
                        .padding(.trailing, 28)
                        .frame(minWidth: proxy.size.width, minHeight: proxy.size.height, alignment: .topLeading)
                }
                .onChange(of: currentMatchPath) { _, path in
                    guard let path else { return }
                    withAnimation(.easeInOut(duration: 0.25)) {
                        scrollProxy.scrollTo(path, anchor: scrollAnchor(forMatchAt: path))
                    }
                }
            }
        }
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .topTrailing) {
            CopyButton(title: "Copy Value", text: item.value)
                .labelStyle(.iconOnly)
                .padding(8)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let json, mode == .tree {
            JSONTreeView(
                value: json,
                searchQuery: searchQuery,
                searchExpandedPaths: searchResult.expandedPaths,
                flashingPaths: flashingPaths,
                flashColor: highlightColor.color,
                currentMatchPath: currentMatchPath
            )
        } else {
            Text(AttributedString(json != nil ? prettyPrinted(item.value) : item.value, highlighting: searchQuery))
                .font(.system(.callout, design: .monospaced))
                .textSelection(.enabled)
        }
    }

    private func valueDidChange(from oldValue: String, to newValue: String) {
        let newJSON = Self.parseContainer(newValue)
        defer { json = newJSON }

        guard oldValue != newValue, let oldJSON = json, let newJSON else { return }
        flash(JSONValue.changedPaths(from: oldJSON, to: newJSON))
    }

    private func flash(_ paths: Set<String>) {
        guard highlightsChanges, !paths.isEmpty else { return }

        withAnimation(.easeOut(duration: 0.15)) {
            flashingPaths.formUnion(paths)
        }
        Task {
            try? await Task.sleep(for: .seconds(highlightDuration))
            withAnimation(.easeOut(duration: 0.8)) {
                flashingPaths.subtract(paths)
            }
        }
    }

    private static func parseContainer(_ text: String) -> JSONValue? {
        JSONValue(parsing: text).flatMap { $0.children == nil ? nil : $0 }
    }

    private func prettyPrinted(_ text: String) -> String {
        guard let object = try? JSONSerialization.jsonObject(with: Data(text.utf8)),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]) else {
            return text
        }
        return String(decoding: data, as: UTF8.self)
    }
}
