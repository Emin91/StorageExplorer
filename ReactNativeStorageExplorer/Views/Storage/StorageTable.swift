//
//  StorageTable.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import AppKit
import SwiftUI

struct StorageTable: View {
    let items: [StorageItem]
    var keyHighlight = ""
    var valueHighlight = ""
    @Binding var sort: StorageSort?
    var onSelect: (StorageItem) -> Void = { _ in }

    @AppStorage(StorageColumn.LayoutKey.keyWidth) private var keyWidth: Double = 130
    @AppStorage(StorageColumn.LayoutKey.typeWidth) private var typeWidth: Double = 52
    @AppStorage(StorageColumn.LayoutKey.sizeWidth) private var sizeWidth: Double = 76
    @AppStorage(StorageColumn.LayoutKey.modifiedWidth) private var modifiedWidth: Double = 60

    @AppStorage(StorageColumn.LayoutKey.hiddenColumns) private var hiddenColumnsValue = ""

    private func isVisible(_ column: StorageColumn) -> Bool {
        !StorageColumn.hiddenColumns(from: hiddenColumnsValue).contains(column)
    }

    @State private var resizeStartWidth: Double?
    @State private var hoveredItemID: StorageItem.ID?
    @AppStorage(AppSettings.Key.highlightsChanges) private var highlightsChanges = AppSettings.Defaults.highlightsChanges
    @AppStorage(AppSettings.Key.highlightColor) private var highlightColor = AppSettings.Defaults.highlightColor
    @AppStorage(AppSettings.Key.highlightDuration) private var highlightDuration = AppSettings.Defaults.highlightDuration

    @State private var flashingItemIDs: Set<StorageItem.ID> = []
    @State private var knownModificationDates: [StorageItem.ID: Date] = [:]

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
        .animation(.easeInOut(duration: 0.25), value: hiddenColumnsValue)
    }

    private var minimumContentWidth: CGFloat {
        let optionalWidths: [StorageColumn: CGFloat] = [
            .value: Layout.minValueWidth,
            .type: CGFloat(typeWidth),
            .size: CGFloat(sizeWidth),
            .modified: CGFloat(modifiedWidth)
        ]
        let visibleWidths: [CGFloat] = [Layout.numberColumnWidth, CGFloat(keyWidth)]
            + StorageColumn.allCases.filter(isVisible).compactMap { optionalWidths[$0] }

        let columnsWidth: CGFloat = visibleWidths.reduce(0, +)
        let spacing: CGFloat = Layout.columnSpacing * CGFloat(visibleWidths.count - 1)
        let padding: CGFloat = Layout.rowPadding.leading + Layout.rowPadding.trailing + Layout.outerPadding * 2
        return columnsWidth + spacing + padding
    }

    private var header: some View {
        columns(number: "#") {
            sortableTitle("Key", column: .key)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .trailing) {
                    resizeHandle(width: $keyWidth, range: Layout.keyWidthRange, growsTowardsTrailing: true)
                }
        } value: {
            Text("Value")
        } type: {
            sortableTitle("Type", column: .type)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .leading) {
                    resizeHandle(width: $typeWidth, range: Layout.detailWidthRange, growsTowardsTrailing: false)
                }
        } size: {
            sortableTitle("Size", column: .size)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .leading) {
                    resizeHandle(width: $sizeWidth, range: Layout.detailWidthRange, growsTowardsTrailing: false)
                }
        } modified: {
            sortableTitle("Modified", column: .modified)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .leading) {
                    resizeHandle(width: $modifiedWidth, range: Layout.detailWidthRange, growsTowardsTrailing: false)
                }
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, Layout.outerPadding)
        .padding(.trailing, legacyScrollerWidth)
    }

    private var legacyScrollerWidth: CGFloat {
        NSScroller.preferredScrollerStyle == .legacy
            ? NSScroller.scrollerWidth(for: .regular, scrollerStyle: .legacy)
            : 0
    }

    private func sortableTitle(_ title: String, column: StorageSort.Column) -> some View {
        let isSorted = sort?.column == column

        return Button {
            sort = StorageSort.next(after: sort, clicking: column)
        } label: {
            HStack(spacing: 3) {
                Text(title)
                if isSorted, let sort {
                    Image(systemName: sort.isAscending ? "chevron.up" : "chevron.down")
                        .font(.caption2.weight(.bold))
                }
            }
            .foregroundStyle(isSorted ? .primary : .secondary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Sort by \(title)")
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

                    if let group = item.group, index == 0 || items[index - 1].group != group {
                        groupHeader(group, isFirst: index == 0)
                    }

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
                        .background(
                            RoundedRectangle(cornerRadius: Layout.rowCornerRadius)
                                .fill(highlightColor.color.opacity(flashingItemIDs.contains(item.id) ? 0.35 : 0))
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
        .onChange(of: items, initial: true) { _, newItems in
            flashChangedRows(in: newItems)
        }
    }

    private enum Flash {
        static let maxChangeAge: TimeInterval = 3
    }

    private func flashChangedRows(in newItems: [StorageItem]) {
        let freshnessLimit = Date().addingTimeInterval(-Flash.maxChangeAge)
        let changedIDs = newItems
            .filter { item in
                guard let modifiedAt = item.modifiedAt else { return false }
                return modifiedAt > freshnessLimit && knownModificationDates[item.id] != modifiedAt
            }
            .map(\.id)

        knownModificationDates = Dictionary(
            newItems.compactMap { item in item.modifiedAt.map { (item.id, $0) } },
            uniquingKeysWith: { first, _ in first }
        )

        guard highlightsChanges, !changedIDs.isEmpty else { return }
        withAnimation(.easeOut(duration: 0.15)) {
            flashingItemIDs.formUnion(changedIDs)
        }
        Task {
            try? await Task.sleep(for: .seconds(highlightDuration))
            withAnimation(.easeOut(duration: 0.8)) {
                flashingItemIDs.subtract(changedIDs)
            }
        }
    }

    private func groupHeader(_ group: String, isFirst: Bool) -> some View {
        HStack(spacing: 6) {
            Text(group)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(items.filter { $0.group == group }.count)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.horizontal, Layout.rowPadding.leading)
        .padding(.top, isFirst ? 2 : 12)
        .padding(.bottom, 2)
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
            Text(AttributedString(item.preview, highlighting: valueHighlight))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .help(item.preview)
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
            if isVisible(.value) {
                key()
                    .frame(width: keyWidth, alignment: .leading)
                value()
                    .frame(minWidth: Layout.minValueWidth, maxWidth: .infinity, alignment: .leading)
            } else {
                key()
                    .frame(minWidth: keyWidth, maxWidth: .infinity, alignment: .leading)
            }
            if isVisible(.type) {
                type()
                    .frame(width: typeWidth, alignment: .leading)
            }
            if isVisible(.size) {
                size()
                    .frame(width: sizeWidth, alignment: .leading)
            }
            if isVisible(.modified) {
                modified()
                    .frame(width: modifiedWidth, alignment: .leading)
            }
        }
        .lineLimit(1)
        .padding(Layout.rowPadding)
    }
}

#Preview {
    StorageTable(
        items: [
            StorageItem(key: "@lab/counter", value: "539", modifiedAt: .now),
            StorageItem(key: "@lab/theme", value: "dark"),
            StorageItem(key: "@lab/favorites", value: #"["Banana","Cherry"]"#)
        ],
        sort: .constant(nil)
    )
    .frame(width: 440, height: 240)
}
