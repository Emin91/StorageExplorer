//
//  StatisticsView.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Charts
import SwiftUI

struct StatisticsView: View {
    @ObservedObject var viewModel: StatisticsViewModel
    let plugins: [StoragePlugin]
    let onBack: () -> Void
    let onSelect: (StoragePlugin) -> Void

    @State private var isRevealed = false
    @State private var hoveredPlugin: StoragePlugin?

    private struct Entry: Identifiable, Equatable {
        let plugin: StoragePlugin
        let keyCount: Int
        let size: Int
        var id: StoragePlugin { plugin }
    }

    private var entries: [Entry] {
        plugins.map { plugin in
            let summary = viewModel.summary(for: plugin)
            return Entry(plugin: plugin, keyCount: summary.keyCount, size: summary.size)
        }
    }

    private var maxSize: Int {
        entries.map(\.size).max() ?? 0
    }

    private var totalKeys: Int {
        entries.reduce(0) { $0 + $1.keyCount }
    }

    private var totalSize: Int {
        entries.reduce(0) { $0 + $1.size }
    }

    private let barGradient = LinearGradient(
        colors: [Color(red: 1, green: 0.70, blue: 0.25), .orange],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            chart
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            Divider()
            footer
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.2).delay(0.1)) {
                isRevealed = true
            }
        }
    }

    private var header: some View {
        ZStack {
            Label("Statistics", systemImage: "chart.bar.fill")
                .font(.headline)

            HStack {
                BackButton("Back", action: onBack)
                Spacer()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private var chart: some View {
        Chart(entries) { entry in
            BarMark(
                x: .value("Plugin", entry.plugin.title),
                y: .value("Size", isRevealed ? barHeight(for: entry) : 0),
                width: .ratio(0.6)
            )
            .foregroundStyle(barGradient)
            .cornerRadius(8)
            .opacity(hoveredPlugin == nil || hoveredPlugin == entry.plugin ? 1 : 0.45)
            .annotation(position: .top, spacing: 6) {
                VStack(spacing: 1) {
                    Text(entry.size.formattedByteCount)
                        .font(.callout.weight(.semibold))
                        .monospacedDigit()
                    Text("^[\(entry.keyCount) key](inflect: true)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .contentTransition(.numericText())
                .opacity(isRevealed ? 1 : 0)
                .scaleEffect(hoveredPlugin == entry.plugin ? 1.08 : 1, anchor: .bottom)
            }
            .annotation(position: .bottom, spacing: 6) {
                Text(entry.plugin.title)
                    .font(.callout.weight(hoveredPlugin == entry.plugin ? .semibold : .medium))
                    .foregroundStyle(hoveredPlugin == entry.plugin ? Color.orange : Color.primary)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .chartYScale(domain: 0...Double(max(maxSize, 1)) * 1.3)
        .chartYAxis(.hidden)
        .chartXAxis(.hidden)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            setHoveredPlugin(plugin(at: location, proxy: proxy, geometry: geometry))
                        case .ended:
                            setHoveredPlugin(nil)
                        }
                    }
                    .onTapGesture { location in
                        if let plugin = plugin(at: location, proxy: proxy, geometry: geometry) {
                            onSelect(plugin)
                        }
                    }
                    .pointerStyle(hoveredPlugin != nil ? .link : nil)
            }
        }
        .padding(.bottom, 18)
        .animation(.spring(duration: 0.5, bounce: 0.2), value: entries)

    }

    private var footer: some View {
        HStack {
            Text("Total")
                .foregroundStyle(.secondary)
            Spacer()
            Text("^[\(totalKeys) key](inflect: true) · \(totalSize.formattedByteCount)")
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.default, value: totalSize)
        }
        .font(.callout)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func setHoveredPlugin(_ plugin: StoragePlugin?) {
        guard plugin != hoveredPlugin else { return }
        let animation: Animation = plugin == nil
            ? .easeInOut(duration: 0.7)
            : .easeOut(duration: 0.4)
        withAnimation(animation) {
            hoveredPlugin = plugin
        }
    }

    private func plugin(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) -> StoragePlugin? {
        guard let plotFrame = proxy.plotFrame else { return nil }
        let x = location.x - geometry[plotFrame].origin.x
        guard let title: String = proxy.value(atX: x) else { return nil }
        return entries.first { $0.plugin.title == title }?.plugin
    }

    private func barHeight(for entry: Entry) -> Double {
        guard entry.size > 0 else { return 0 }
        return max(Double(entry.size), Double(maxSize) * 0.02)
    }
}
