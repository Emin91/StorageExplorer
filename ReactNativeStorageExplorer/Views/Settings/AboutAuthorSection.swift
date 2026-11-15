//
//  AboutAuthorSection.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import SwiftUI

struct AboutAuthorSection: View {
    private struct Contact: Identifiable {
        let title: String
        let handle: String
        let systemImage: String
        let url: URL

        var id: String { title }
    }

    private let contacts = [
        Contact(
            title: "Telegram",
            handle: "@emin91zeynalov",
            systemImage: "paperplane",
            url: URL(string: "https://t.me/emin91zeynalov")!
        ),
        Contact(
            title: "GitHub",
            handle: "Emin91",
            systemImage: "chevron.left.forwardslash.chevron.right",
            url: URL(string: "https://github.com/Emin91")!
        ),
        Contact(
            title: "LinkedIn",
            handle: "emin91zeynalov",
            systemImage: "person.crop.square",
            url: URL(string: "https://www.linkedin.com/in/emin91zeynalov/")!
        )
    ]

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var build: String {
        guard let executableURL = Bundle.main.executableURL,
              let buildDate = try? executableURL.resourceValues(forKeys: [.contentModificationDateKey])
                .contentModificationDate else { return "—" }

        return String(Int(buildDate.timeIntervalSince1970))
    }

    var body: some View {
        Section("About the Author") {
            LabeledContent("Version") {
                Text(version)
                    .monospacedDigit()
            }
            LabeledContent("Build") {
                Text(build)
                    .monospacedDigit()
            }
            LabeledContent("Author", value: "Emin Zeynalov")

            ForEach(contacts) { contact in
                LabeledContent {
                    Link(contact.handle, destination: contact.url)
                } label: {
                    Label(contact.title, systemImage: contact.systemImage)
                }
            }
        }
    }
}
