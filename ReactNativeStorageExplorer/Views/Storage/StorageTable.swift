//
//  StorageTable.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import SwiftUI

struct StorageTable: View {
    let items: [StorageItem]
    var keyHighlight = ""
    var valueHighlight = ""
    var onSelect: (StorageItem) -> Void = { _ in }

    @AppStorage("storageTable.keyWidth") private var keyWidth: Double = 130
    @AppStorage("storageTable.typeWidth") private var typeWidth: Double = 52
    @AppStorage("storageTable.sizeWidth") private var sizeWidth: Double = 56
    @AppStorage("storageTable.modifiedWidth") private var modifiedWidth: Double = 60

    @State private var resizeStartWidth: Double?
    @State private var hoveredItemID: StorageItem.ID?

    private enum Layout {
        static let keyWidthRange: ClosedRange<Double> = 60...400
        static let detailWidthRange: ClosedRange<Double> = 36...160
        static let minValueWidth: CGFloat = 100
        static let numberColumnWidth: CGFloat = 24
        static let columnSpacing: CGFloat = 16
        static let resizeHandleWidth: CGFloat = 9
        static let rowPadding = EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 28)
        static let rowSpacing: CGFloat = 4
        static let rowCornerRadius: CGFloat = 6
        static let outerPadding: CGFloat = 8
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal) {
                VStack(spacing: 0) {
                    header
                    Divider()
                    rows
                }
                .frame(width: max(geometry.size.width, minimumContentWidth), height: geometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        }
    }

    private var minimumContentWidth: CGFloat {
        let columnsWidth = Layout.numberColumnWidth + keyWidth + Layout.minValueWidth + typeWidth + sizeWidth + modifiedWidth
        return columnsWidth
            + Layout.columnSpacing * 5
            + Layout.rowPadding.leading + Layout.rowPadding.trailing
            + Layout.outerPadding * 2
    }


    private var header: some View {
        columns(number: "#") {
            Text("Key")
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .trailing) {
                    resizeHandle(width: $keyWidth, range: Layout.keyWidthRange, growsTowardsTrailing: true)
                }
        } value: {
            Text("Value")
        } type: {
            Text("Type")
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .leading) {
                    resizeHandle(width: $typeWidth, range: Layout.detailWidthRange, growsTowardsTrailing: false)
                }
        } size: {
            Text("Size")
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .leading) {
                    resizeHandle(width: $sizeWidth, range: Layout.detailWidthRange, growsTowardsTrailing: false)
                }
        } modified: {
            Text("Modified")
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .leading) {
                    resizeHandle(width: $modifiedWidth, range: Layout.detailWidthRange, growsTowardsTrailing: false)
                }
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, Layout.outerPadding)
    }

    private func resizeHandle(width: Binding<Double>, range: ClosedRange<Double>, growsTowardsTrailing: Bool) -> some View {
        Rectangle()
            .fill(.clear)
            .frame(width: Layout.resizeHandleWidth)
            .frame(maxHeight: .infinity)
            .overlay {
                Rectangle()
                    .fill(.separator)
                    .frame(width: 1, height: 12)
            }
            .contentShape(Rectangle())
            .pointerStyle(.columnResize)
            .offset(x: (growsTowardsTrailing ? 1 : -1) * Layout.columnSpacing / 2)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { drag in
                        let startWidth = resizeStartWidth ?? width.wrappedValue
                        resizeStartWidth = startWidth
                        let delta = growsTowardsTrailing ? drag.translation.width : -drag.translation.width
                        width.wrappedValue = min(max(startWidth + delta, range.lowerBound), range.upperBound)
                    }
                    .onEnded { _ in
                        resizeStartWidth = nil
                    }
            )
    }


    private var rows: some View {
        ScrollView {
            LazyVStack(spacing: Layout.rowSpacing) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    let isHovered = hoveredItemID == item.id

                    row(for: item, number: index + 1)
                        .overlay(alignment: .trailing) {
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(isHovered ? .primary : .tertiary)
                                .padding(.trailing, 10)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: Layout.rowCornerRadius)
                                .fill(Color.primary.opacity(rowOpacity(index: index, isHovered: isHovered)))
                        )
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            hoveredItemID = hovering ? item.id : (hoveredItemID == item.id ? nil : hoveredItemID)
                        }
                        .pointerStyle(.link)
                        .simultaneousGesture(TapGesture().onEnded { onSelect(item) })
                        .contextMenu { rowMenu(for: item) }
                        .help("Click to view the full value")
                }
            }
            .padding(Layout.outerPadding)
        }
    }

    private func rowOpacity(index: Int, isHovered: Bool) -> Double {
        if isHovered { return 0.14 }
        return index.isMultiple(of: 2) ? 0.08 : 0.05
    }

    private func row(for item: StorageItem, number: Int) -> some View {
        columns(number: "\(number)") {
            VStack(alignment: .leading, spacing: 1) {
                Text(AttributedString(item.key, highlighting: keyHighlight))
                    .textSelection(.enabled)
                if let namespace = item.namespace {
                    Text(namespace)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
                .help(item.key)
        } value: {
            Text(AttributedString(item.value, highlighting: valueHighlight))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .help(item.value)
        } type: {
            Text(item.type.title)
                .foregroundStyle(.secondary)
        } size: {
            Text(item.size.formattedByteCount)
                .foregroundStyle(.secondary)
        } modified: {
            modifiedText(for: item.modifiedAt)
                .foregroundStyle(.secondary)
        }
        .font(.callout)
    }

    @ViewBuilder
    private func rowMenu(for item: StorageItem) -> some View {
        Button("Show Value") { onSelect(item) }
        Divider()
        Button("Copy Key") { Pasteboard.copy(item.key) }
        Button("Copy Value") { Pasteboard.copy(item.value) }
        Button("Copy Key and Value") { Pasteboard.copy("\(item.key): \(item.value)") }
    }

    @ViewBuilder
    private func modifiedText(for date: Date?) -> some View {
        if let date {
            Text(date, format: .dateTime.hour().minute().second())
                .help(date.formatted(date: .abbreviated, time: .standard))
        } else {
            Text("—")
                .help("Unknown: AsyncStorage doesn't store modification dates. Changes are tracked while the app is running.")
        }
    }


    private func columns(
        number: String,
        @ViewBuilder key: () -> some View,
        @ViewBuilder value: () -> some View,
        @ViewBuilder type: () -> some View,
        @ViewBuilder size: () -> some View,
        @ViewBuilder modified: () -> some View
    ) -> some View {
        HStack(spacing: Layout.columnSpacing) {
            Text(number)
                .monospacedDigit()
                .foregroundStyle(.tertiary)
                .frame(width: Layout.numberColumnWidth, alignment: .trailing)
            key()
                .frame(width: keyWidth, alignment: .leading)
            value()
                .frame(minWidth: Layout.minValueWidth, maxWidth: .infinity, alignment: .leading)
            type()
                .frame(width: typeWidth, alignment: .leading)
            size()
                .frame(width: sizeWidth, alignment: .leading)
            modified()
                .frame(width: modifiedWidth, alignment: .leading)
        }
        .lineLimit(1)
        .padding(Layout.rowPadding)
    }
}

#Preview {
    StorageTable(items: [
        StorageItem(key: "@lab/counter", value: "539", modifiedAt: .now),
        StorageItem(key: "@lab/theme", value: "dark"),
        StorageItem(key: "@lab/favorites", value: #"["Banana","Cherry"]"#)
    ])
    .frame(width: 440, height: 240)
}
