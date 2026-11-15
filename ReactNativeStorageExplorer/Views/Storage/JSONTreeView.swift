//
//  JSONTreeView.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import SwiftUI

struct JSONTreeView: View {
    let value: JSONValue

    var body: some View {
        JSONNodeView(label: nil, value: value, depth: 0)
            .font(.system(.callout, design: .monospaced))
            .textSelection(.enabled)
    }
}

private struct JSONNodeView: View {
    let label: String?
    let value: JSONValue
    let depth: Int

    @State private var isExpanded: Bool

    private static let initiallyExpandedDepth = 2
    private static let indent: CGFloat = 14

    init(label: String?, value: JSONValue, depth: Int) {
        self.label = label
        self.value = value
        self.depth = depth
        _isExpanded = State(initialValue: depth < Self.initiallyExpandedDepth)
    }

    var body: some View {
        if let children = value.children {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                    JSONNodeView(label: child.label, value: child.value, depth: depth + 1)
                        .padding(.leading, Self.indent)
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
            }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                labelText
                scalarText
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var labelText: some View {
        if let label {
            Text("\(label):")
                .foregroundStyle(JSONColors.key)
        }
    }

    private var scalarText: Text {
        switch value {
        case .string(let string): Text("\"\(string)\"").foregroundStyle(JSONColors.string)
        case .number(let number): Text(number).foregroundStyle(JSONColors.number)
        case .bool(let bool): Text(bool ? "true" : "false").foregroundStyle(JSONColors.literal)
        case .null: Text("null").foregroundStyle(JSONColors.literal)
        case .object, .array, .encodedJSON: Text(value.summary)
        }
    }
}

private enum JSONColors {
    static let key = Color.cyan
    static let string = Color.orange
    static let number = Color.purple
    static let literal = Color.pink
}
