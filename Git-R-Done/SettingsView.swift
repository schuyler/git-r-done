//
//  SettingsView.swift
//  Git-R-Done
//

import SwiftUI
import GitRDoneShared

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Repositories section header
            Text("Watched Repositories:")
                .font(.headline)

            // Repository list
            GroupBox {
                if viewModel.repositories.isEmpty {
                    Text("No repositories")
                        .foregroundColor(.secondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(viewModel.repositories) { repo in
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.blue)
                                    Text(repo.displayName)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Spacer()
                                    Button(action: { viewModel.removeRepository(id: repo.id) }) {
                                        Image(systemName: "xmark")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Remove repository")
                                    .accessibilityLabel("Remove \(repo.displayName)")
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)

                                if repo.id != viewModel.repositories.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
            }
            .frame(minHeight: 100, maxHeight: 200)

            // Add repository button
            Button(action: addRepository) {
                HStack {
                    Image(systemName: "plus")
                        .accessibilityHidden(true)
                    Text("Add Repository...")
                }
            }

            Divider()
                .padding(.vertical, 4)

            // Auto-push toggle
            Toggle("Auto-push after commit", isOn: Binding(
                get: { viewModel.autoPushEnabled },
                set: { viewModel.autoPushEnabled = $0 }
            ))

            Spacer()
        }
        .padding(20)
        .frame(minWidth: 400, minHeight: 300)
        .onReceive(NotificationCenter.default.publisher(for: .repositoriesDidChange)) { _ in
            viewModel.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .settingsDidChange)) { _ in
            viewModel.refresh()
        }
    }

    private func addRepository() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a Git repository folder"

        if panel.runModal() == .OK, let url = panel.url {
            viewModel.addRepository(url: url)
        }
    }
}

#Preview {
    SettingsView()
}
