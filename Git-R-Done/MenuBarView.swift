//
//  MenuBarView.swift
//  Git-R-Done
//
//  Created by Schuyler Erle on 1/14/26.
//

import SwiftUI
import GitRDoneShared

struct MenuBarView: View {
    @State private var repositories: [WatchedRepository] = RepoConfiguration.shared.repositories
    @State private var settings: AppSettings = SettingsStore.shared.settings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("Git-R-Done")
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            // Repositories section
            Text("Watched Repositories:")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 4)

            if repositories.isEmpty {
                Text("No repositories")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
            } else {
                ForEach(repositories) { repo in
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.blue)
                        Text(repo.displayName)
                            .lineLimit(1)
                        Spacer()
                        Button(action: { removeRepository(repo) }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                }
            }

            Button(action: addRepository) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Repository...")
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            Divider()
                .padding(.vertical, 4)

            // Settings section
            Toggle("Auto-push after commit", isOn: $settings.autoPushEnabled)
                .onChange(of: settings.autoPushEnabled) { _, _ in
                    saveSettings()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 2)

            Divider()
                .padding(.vertical, 4)

            // Footer
            Button("About Git-R-Done") {
                NSWorkspace.shared.open(URL(string: "https://github.com/schuyler/git-r-done")!)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
        .frame(width: 280)
        .padding(.vertical, 4)
        .onReceive(NotificationCenter.default.publisher(for: .repositoriesDidChange)) { _ in
            repositories = RepoConfiguration.shared.repositories
        }
        .onReceive(NotificationCenter.default.publisher(for: .settingsDidChange)) { _ in
            settings = SettingsStore.shared.settings
        }
    }

    private func addRepository() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a Git repository folder"

        if panel.runModal() == .OK, let url = panel.url {
            let gitOps = GitOperations()

            guard gitOps.isGitRepository(at: url.path) else {
                let dialog = AppleScriptDialogPresenter()
                dialog.showError("The selected folder is not a Git repository.")
                return
            }

            let repo = WatchedRepository(path: url.path)
            RepoConfiguration.shared.add(repo)
        }
    }

    private func removeRepository(_ repo: WatchedRepository) {
        RepoConfiguration.shared.remove(id: repo.id)
    }

    private func saveSettings() {
        SettingsStore.shared.update(settings)
    }
}
