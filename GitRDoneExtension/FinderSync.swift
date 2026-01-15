//
//  FinderSync.swift
//  GitRDoneExtension
//
//  Created by Schuyler Erle on 1/14/26.
//

import Cocoa
import FinderSync
import GitRDoneShared

class FinderSync: FIFinderSync {

    private let gitOps = GitOperations()
    private let statusManager = StatusManager()
    private let dialogPresenter = AppleScriptDialogPresenter()
    private let notifier = UserNotificationSender()
    private let conflictHandler: ConflictHandler

    override init() {
        self.conflictHandler = ConflictHandler(gitOps: gitOps)
        super.init()

        Log.finder.info("FinderSync launched from \(Bundle.main.bundlePath)")

        setupBadges()
        updateWatchedDirectories()

        // Listen for repository changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(repositoriesDidChange),
            name: .repositoriesDidChange,
            object: nil
        )

        // Set up badge update callback
        statusManager.onBadgeUpdate = { [weak self] url, badge in
            FIFinderSyncController.default().setBadgeIdentifier(badge, for: url)
        }
    }

    private func setupBadges() {
        let controller = FIFinderSyncController.default()

        // Untracked - gray question mark
        if let image = NSImage(systemSymbolName: "questionmark.circle", accessibilityDescription: "Untracked") {
            controller.setBadgeImage(image.tinted(with: .systemGray), label: "Untracked", forBadgeIdentifier: "Untracked")
        }

        // Modified - orange dot
        if let image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: "Modified") {
            controller.setBadgeImage(image.tinted(with: .systemOrange), label: "Modified", forBadgeIdentifier: "Modified")
        }

        // Staged - green checkmark
        if let image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Staged") {
            controller.setBadgeImage(image.tinted(with: .systemGreen), label: "Staged", forBadgeIdentifier: "Staged")
        }

        // Conflict - red exclamation
        if let image = NSImage(systemSymbolName: "exclamationmark.circle.fill", accessibilityDescription: "Conflict") {
            controller.setBadgeImage(image.tinted(with: .systemRed), label: "Conflict", forBadgeIdentifier: "Conflict")
        }
    }

    @objc private func repositoriesDidChange() {
        updateWatchedDirectories()
    }

    private func updateWatchedDirectories() {
        let repos = RepoConfiguration.shared.repositories
        let urls = Set(repos.map { $0.url })
        FIFinderSyncController.default().directoryURLs = urls
        Log.finder.info("Watching \(urls.count) directories")
    }

    // MARK: - Finder Sync Protocol

    override func beginObservingDirectory(at url: URL) {
        Log.finder.debug("Begin observing: \(url.path)")
        if let repoPath = findRepoPath(for: url) {
            statusManager.queueRefresh(for: repoPath)
        }
    }

    override func endObservingDirectory(at url: URL) {
        Log.finder.debug("End observing: \(url.path)")
    }

    override func requestBadgeIdentifier(for url: URL) {
        guard let repoPath = findRepoPath(for: url) else {
            return
        }

        statusManager.trackURL(url, for: repoPath)
        let badge = statusManager.getBadgeIdentifier(for: url, repoPath: repoPath)
        FIFinderSyncController.default().setBadgeIdentifier(badge, for: url)
    }

    // MARK: - Toolbar

    override var toolbarItemName: String {
        "Git-R-Done"
    }

    override var toolbarItemToolTip: String {
        "Git-R-Done: Git operations for this folder"
    }

    override var toolbarItemImage: NSImage {
        NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Git-R-Done")
            ?? NSImage(named: NSImage.cautionName)!
    }

    // MARK: - Context Menu

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "Git-R-Done")

        guard let target = FIFinderSyncController.default().targetedURL(),
              let _ = findRepoPath(for: target) else {
            return menu
        }

        let items = FIFinderSyncController.default().selectedItemURLs() ?? []
        let isFile = items.count == 1 && !isDirectory(items.first!)

        if isFile {
            // File actions
            menu.addItem(withTitle: "Stage", action: #selector(stageAction(_:)), keyEquivalent: "")
            menu.addItem(withTitle: "Unstage", action: #selector(unstageAction(_:)), keyEquivalent: "")
            menu.addItem(withTitle: "Commit...", action: #selector(commitFileAction(_:)), keyEquivalent: "")
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "Revert", action: #selector(revertAction(_:)), keyEquivalent: "")
        } else {
            // Folder actions
            menu.addItem(withTitle: "Pull", action: #selector(pullAction(_:)), keyEquivalent: "")
            menu.addItem(withTitle: "Push", action: #selector(pushAction(_:)), keyEquivalent: "")
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "Commit All...", action: #selector(commitAllAction(_:)), keyEquivalent: "")
        }

        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Refresh Status", action: #selector(refreshAction(_:)), keyEquivalent: "")

        return menu
    }

    // MARK: - Actions

    @objc func stageAction(_ sender: AnyObject?) {
        guard let items = FIFinderSyncController.default().selectedItemURLs(),
              let url = items.first,
              let repoPath = findRepoPath(for: url) else { return }

        let relativePath = getRelativePath(url, in: repoPath)

        statusManager.performAction(in: repoPath) { [gitOps, dialogPresenter] in
            let result = gitOps.stage(file: relativePath, in: repoPath)
            if case .failure(let error) = result {
                dialogPresenter.showError(error.localizedDescription)
            }
        }
    }

    @objc func unstageAction(_ sender: AnyObject?) {
        guard let items = FIFinderSyncController.default().selectedItemURLs(),
              let url = items.first,
              let repoPath = findRepoPath(for: url) else { return }

        let relativePath = getRelativePath(url, in: repoPath)

        statusManager.performAction(in: repoPath) { [gitOps, dialogPresenter] in
            let result = gitOps.unstage(file: relativePath, in: repoPath)
            if case .failure(let error) = result {
                dialogPresenter.showError(error.localizedDescription)
            }
        }
    }

    @objc func commitFileAction(_ sender: AnyObject?) {
        guard let items = FIFinderSyncController.default().selectedItemURLs(),
              let url = items.first,
              let repoPath = findRepoPath(for: url) else { return }

        guard let message = dialogPresenter.promptForCommitMessage(), !message.isEmpty else {
            return
        }

        let relativePath = getRelativePath(url, in: repoPath)
        let repoName = gitOps.getRepoName(at: repoPath)
        let autoPush = SettingsStore.shared.settings.autoPushEnabled

        statusManager.performAction(in: repoPath) { [gitOps, dialogPresenter, notifier] in
            let result = gitOps.commitFile(relativePath, message: message, in: repoPath)
            if case .failure(let error) = result {
                dialogPresenter.showError(error.localizedDescription)
                return
            }

            if autoPush {
                let pushResult = gitOps.push(in: repoPath)
                switch pushResult {
                case .success:
                    notifier.send(title: "Git-R-Done", body: "Pushed to \(repoName)")
                case .failure(let error):
                    notifier.send(title: "Push Failed", body: error.localizedDescription)
                }
            }
        }
    }

    @objc func revertAction(_ sender: AnyObject?) {
        guard let items = FIFinderSyncController.default().selectedItemURLs(),
              let url = items.first,
              let repoPath = findRepoPath(for: url) else { return }

        let relativePath = getRelativePath(url, in: repoPath)

        guard dialogPresenter.confirm(
            message: "Are you sure you want to revert \"\(url.lastPathComponent)\"? This will discard all local changes.",
            confirmButton: "Revert"
        ) else { return }

        statusManager.performAction(in: repoPath) { [gitOps, dialogPresenter] in
            let result = gitOps.revert(file: relativePath, in: repoPath)
            if case .failure(let error) = result {
                dialogPresenter.showError(error.localizedDescription)
            }
        }
    }

    @objc func pullAction(_ sender: AnyObject?) {
        guard let target = FIFinderSyncController.default().targetedURL(),
              let repoPath = findRepoPath(for: target) else { return }

        let repoName = gitOps.getRepoName(at: repoPath)

        statusManager.performAction(in: repoPath) { [gitOps, conflictHandler, dialogPresenter, notifier] in
            let result = gitOps.pull(in: repoPath)

            switch result {
            case .success(let pullResult):
                if !pullResult.conflicts.isEmpty {
                    // Handle conflicts
                    let resolveResult = conflictHandler.resolveConflicts(files: pullResult.conflicts, in: repoPath)
                    switch resolveResult {
                    case .success(let resolutions):
                        notifier.send(title: "Conflicts in \(repoName)", body: "Local copies saved")
                        dialogPresenter.showConflictReport(resolutions: resolutions)
                    case .failure(let error):
                        dialogPresenter.showError("Failed to resolve conflicts: \(error.localizedDescription)")
                    }
                } else if !pullResult.updatedFiles.isEmpty {
                    notifier.send(title: "Git-R-Done", body: "Pulled \(pullResult.updatedFiles.count) updated files from \(repoName)")
                }

            case .failure(let error):
                notifier.send(title: "Pull Failed", body: error.localizedDescription)
            }
        }
    }

    @objc func pushAction(_ sender: AnyObject?) {
        guard let target = FIFinderSyncController.default().targetedURL(),
              let repoPath = findRepoPath(for: target) else { return }

        let repoName = gitOps.getRepoName(at: repoPath)

        statusManager.performAction(in: repoPath) { [gitOps, notifier] in
            let result = gitOps.push(in: repoPath)
            switch result {
            case .success:
                notifier.send(title: "Git-R-Done", body: "Pushed to \(repoName)")
            case .failure(let error):
                notifier.send(title: "Push Failed", body: error.localizedDescription)
            }
        }
    }

    @objc func commitAllAction(_ sender: AnyObject?) {
        guard let target = FIFinderSyncController.default().targetedURL(),
              let repoPath = findRepoPath(for: target) else { return }

        guard let message = dialogPresenter.promptForCommitMessage(), !message.isEmpty else {
            return
        }

        let repoName = gitOps.getRepoName(at: repoPath)
        let autoPush = SettingsStore.shared.settings.autoPushEnabled

        statusManager.performAction(in: repoPath) { [gitOps, dialogPresenter, notifier] in
            let result = gitOps.commitAll(message: message, in: repoPath)
            if case .failure(let error) = result {
                dialogPresenter.showError(error.localizedDescription)
                return
            }

            if autoPush {
                let pushResult = gitOps.push(in: repoPath)
                switch pushResult {
                case .success:
                    notifier.send(title: "Git-R-Done", body: "Pushed to \(repoName)")
                case .failure(let error):
                    notifier.send(title: "Push Failed", body: error.localizedDescription)
                }
            }
        }
    }

    @objc func refreshAction(_ sender: AnyObject?) {
        guard let target = FIFinderSyncController.default().targetedURL(),
              let repoPath = findRepoPath(for: target) else { return }

        statusManager.invalidate(repoPath: repoPath)
    }

    // MARK: - Helpers

    private func findRepoPath(for url: URL) -> String? {
        let repos = RepoConfiguration.shared.repositories
        for repo in repos {
            if url.path.hasPrefix(repo.path) {
                return repo.path
            }
        }
        return nil
    }

    private func getRelativePath(_ url: URL, in repoPath: String) -> String {
        String(url.path.dropFirst(repoPath.count + 1))
    }

    private func isDirectory(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        return isDir.boolValue
    }
}

// MARK: - NSImage Extension

extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let image = self.copy() as! NSImage
        image.lockFocus()
        color.set()
        let rect = NSRect(origin: .zero, size: image.size)
        rect.fill(using: .sourceAtop)
        image.unlockFocus()
        return image
    }
}

