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

    @State private var mode: Mode = .tree

    private var json: JSONValue? {
        JSONValue(parsing: item.value).flatMap { $0.children == nil ? nil : $0 }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            valueContainer
                .padding(12)
        }
    }

    private var valueContainer: some View {
        GeometryReader { proxy in
            ScrollView(json != nil && mode == .tree ? [.vertical, .horizontal] : .vertical) {
                content
                    .padding(12)
                    .padding(.trailing, 28)
                    .frame(minWidth: proxy.size.width, minHeight: proxy.size.height, alignment: .topLeading)
            }
        }
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .topTrailing) {
            CopyButton(title: "Copy Value", text: item.value)
                .labelStyle(.iconOnly)
                .padding(8)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
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
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
    }

    @ViewBuilder
    private var content: some View {
        if let json, mode == .tree {
            JSONTreeView(value: json)
        } else {
            Text(json != nil ? prettyPrinted(item.value) : item.value)
                .font(.system(.callout, design: .monospaced))
                .textSelection(.enabled)
        }
    }

    private func prettyPrinted(_ text: String) -> String {
        guard let object = try? JSONSerialization.jsonObject(with: Data(text.utf8)),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]) else {
            return text
        }
        return String(decoding: data, as: UTF8.self)
    }
}
