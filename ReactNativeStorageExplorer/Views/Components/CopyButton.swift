//
//  CopyButton.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import SwiftUI

struct CopyButton: View {
    let title: String
    let text: String

    @State private var didCopy = false

    var body: some View {
        Button {
            Pasteboard.copy(text)
            didCopy = true
        } label: {
            Label(title, systemImage: didCopy ? "checkmark" : "doc.on.doc")
                .contentTransition(.symbolEffect(.replace))
                .foregroundStyle(.orange)
        }
        .buttonStyle(.borderless)
        .help(title)
        .task(id: didCopy) {
            guard didCopy else { return }
            try? await Task.sleep(for: .seconds(1.2))
            didCopy = false
        }
    }
}
