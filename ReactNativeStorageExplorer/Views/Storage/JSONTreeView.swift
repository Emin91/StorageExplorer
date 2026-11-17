//
//  JSONTreeView.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import SwiftUI

struct JSONTreeView: View {
    let value: JSONValue
    var searchQuery = ""
    var searchExpandedPaths: Set<String> = []
    var flashingPaths: Set<String> = []
    var flashColor: Color = .orange
    var currentMatchPath: String?

    var body: some View {
        JSONNodeView(
            label: nil,
            value: value,
            path: JSONValue.rootPath,
            depth: 0,
            context: JSONTreeContext(
                searchQuery: searchQuery,
                searchExpandedPaths: searchExpandedPaths,
                flashingPaths: flashingPaths,
                flashColor: flashColor,
                currentMatchPath: currentMatchPath
            )
        )
        .font(.system(.callout, design: .monospaced))
        .textSelection(.enabled)
    }
}

private struct JSONTreeContext {
    let searchQuery: String
    let searchExpandedPaths: Set<String>
    let flashingPaths: Set<String>
    let flashColor: Color
    let currentMatchPath: String?
}

private struct JSONNodeView: View {
    let label: String?
    let value: JSONValue
    let path: String
    let depth: Int
    let context: JSONTreeContext

    @State private var userExpanded: Bool?

    private static let initiallyExpandedDepth = 2
    private static let indent: CGFloat = 16
    private static let guideOffset: CGFloat = 4

    private var isExpanded: Binding<Bool> {
        Binding(
            get: {
                context.searchExpandedPaths.contains(path)
                    || (userExpanded ?? (depth < Self.initiallyExpandedDepth))
            },
            set: { userExpanded = $0 }
        )
    }

    var body: some View {
        if let children = value.children {
            DisclosureGroup(isExpanded: isExpanded) {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        JSONNodeView(
                            label: child.label,
                            value: child.value,
                            path: JSONValue.path(path, child.label),
                            depth: depth + 1,
                            context: context
                        )
                    }
                }
                .padding(.leading, Self.indent)
                .background(alignment: .leading) {
                    Rectangle()
                        .fill(JSONColors.guide(forDepth: depth))
                        .frame(width: 1.5)
                        .padding(.leading, Self.guideOffset)
                }
            } label: {
                HStack(spacing: 6) {
                    labelText
                    Text(value.summary)
                        .foregroundStyle(.secondary)
                    if case .encodedJSON = value {
                        Text("JSON string")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                            .background(Color.primary.opacity(0.08), in: Capsule())
                    }
                }
                .background(rowBackground)
                .id(path)
            }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                labelText
                scalarText
            }
            .background(rowBackground)
            .id(path)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var rowBackground: some View {
        let isCurrentMatch = context.currentMatchPath == path
        return RoundedRectangle(cornerRadius: 4)
            .fill(context.flashColor.opacity(context.flashingPaths.contains(path) ? 0.35 : 0))
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.orange, lineWidth: isCurrentMatch ? 1.5 : 0)
            }
            .padding(-2)
    }

    @ViewBuilder
    private var labelText: some View {
        if let label {
            Text(AttributedString("\(label):", highlighting: context.searchQuery))
                .foregroundStyle(JSONColors.key)
        }
    }

    private var scalarText: Text {
        let query = context.searchQuery
        return switch value {
        case .string(let string):
            Text(AttributedString("\"\(string)\"", highlighting: query)).foregroundStyle(JSONColors.string)
        case .number(let number):
            Text(AttributedString(number, highlighting: query)).foregroundStyle(JSONColors.number)
        case .bool, .null:
            Text(AttributedString(value.scalarText ?? "", highlighting: query)).foregroundStyle(JSONColors.literal)
        case .object, .array, .encodedJSON:
            Text(value.summary)
        }
    }
}

private enum JSONColors {
    static let key = Color.cyan
    static let string = Color.orange
    static let number = Color.purple
    static let literal = Color.pink

    private static let guides: [Color] = [.cyan, .purple, .orange, .green, .pink, .yellow]

    static func guide(forDepth depth: Int) -> Color {
        guides[depth % guides.count].opacity(0.45)
    }
}
