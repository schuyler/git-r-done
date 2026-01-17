//
//  SettingsView.swift
//  Git-R-Done
//

import SwiftUI
import GitRDoneShared

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var editingId: UUID?
    @State private var editingName: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Repositories section header
            Text("Watched Repositories:")
                .font(.headline)

            // Repository table
            GroupBox {
                if viewModel.repositories.isEmpty {
                    Text("No repositories")
                        .foregroundColor(.secondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 0) {
                        // Table header
                        HStack(spacing: 0) {
                            Text("Name")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(width: 140, alignment: .leading)
                            Text("Path")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer()
                                .frame(width: 30)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)

                        Divider()

                        // Table rows
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(viewModel.repositories) { repo in
                                    RepositoryRow(
                                        repo: repo,
                                        isEditing: editingId == repo.id,
                                        editingName: $editingName,
                                        onStartEditing: {
                                            editingId = repo.id
                                            editingName = repo.displayName
                                        },
                                        onCommitEditing: {
                                            viewModel.updateDisplayName(for: repo.id, name: editingName)
                                            editingId = nil
                                        },
                                        onCancelEditing: {
                                            editingId = nil
                                        },
                                        onRemove: {
                                            viewModel.removeRepository(id: repo.id)
                                        }
                                    )

                                    if repo.id != viewModel.repositories.last?.id {
                                        Divider()
                                    }
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
        .frame(minWidth: 450, minHeight: 300)
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
        panel.allowsMultipleSelection = true
        panel.message = "Select one or more Git repository folders"

        if panel.runModal() == .OK {
            viewModel.addRepositories(urls: panel.urls)
        }
    }
}

// MARK: - Repository Row

private struct RepositoryRow: View {
    let repo: WatchedRepository
    let isEditing: Bool
    @Binding var editingName: String
    let onStartEditing: () -> Void
    let onCommitEditing: () -> Void
    let onCancelEditing: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Name column (editable)
            if isEditing {
                TextField("Name", text: $editingName)
                    .textFieldStyle(.plain)
                    .frame(width: 130)
                    .onSubmit { onCommitEditing() }
                    .onExitCommand { onCancelEditing() }
            } else {
                Text(repo.displayName)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(width: 130, alignment: .leading)
                    .onTapGesture(count: 2) { onStartEditing() }
                    .help("Double-click to edit")
            }
            Spacer()
                .frame(width: 10)

            // Path column (read-only)
            Text(abbreviatedPath(repo.path))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .help(repo.path)

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Remove repository")
            .accessibilityLabel("Remove \(repo.displayName)")
            .frame(width: 30)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    /// Abbreviates path with ~ for home directory
    private func abbreviatedPath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}

#Preview {
    SettingsView()
}
