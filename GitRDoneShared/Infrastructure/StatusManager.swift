//
//  StatusManager.swift
//  GitRDoneShared
//

import Foundation

public final class StatusManager: StatusManaging {

    // MARK: - Static Methods

    /// Converts an absolute file path to a path relative to the repository root.
    /// - Parameters:
    ///   - filePath: The absolute file path
    ///   - repoPath: The repository root path
    /// - Returns: The relative path, or the original path if not related
    public static func makeRelativePath(_ filePath: String, relativeTo repoPath: String) -> String {
        guard filePath.hasPrefix(repoPath) else {
            return filePath
        }

        if filePath == repoPath {
            return ""
        }

        // Drop repoPath plus the trailing "/"
        let relativePath = String(filePath.dropFirst(repoPath.count + 1))
        return relativePath
    }

    // MARK: - Properties

    private let gitOps: GitOperations
    private let queue = DispatchQueue(label: "info.schuyler.gitrdone.statusmanager")
    private var cache: [String: RepoStatus] = [:]
    private var pendingRefreshes: Set<String> = []
    private var trackedURLs: [String: Set<URL>] = [:]

    public var onBadgeUpdate: ((URL, String) -> Void)?

    public init(gitOps: GitOperations = GitOperations()) {
        self.gitOps = gitOps
    }

    public func getCachedStatus(for repoPath: String) -> RepoStatus? {
        queue.sync { cache[repoPath] }
    }

    public func trackURL(_ url: URL, for repoPath: String) {
        queue.async { [self] in
            var urls = trackedURLs[repoPath] ?? Set()
            urls.insert(url)
            trackedURLs[repoPath] = urls
        }
    }

    public func queueRefresh(for repoPath: String) {
        queue.async { [self] in
            guard !pendingRefreshes.contains(repoPath) else { return }
            pendingRefreshes.insert(repoPath)

            // Debounce: wait 500ms before refreshing
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.performRefresh(for: repoPath)
            }
        }
    }

    public func invalidate(repoPath: String) {
        queue.async { [self] in
            cache.removeValue(forKey: repoPath)
            Log.status.info("Invalidated cache for \(repoPath)")
        }
        queueRefresh(for: repoPath)
    }

    public func performAction(in repoPath: String, action: @escaping () -> Void) {
        queue.async { [weak self] in
            action()
            // Invalidate after action completes
            self?.invalidate(repoPath: repoPath)
        }
    }

    private func performRefresh(for repoPath: String) {
        queue.async { [self] in
            pendingRefreshes.remove(repoPath)
        }

        Log.status.debug("Refreshing status for \(repoPath)")

        let result = gitOps.getStatus(in: repoPath)

        switch result {
        case .success(let statuses):
            var files: [String: GitFileStatus] = [:]
            for status in statuses {
                files[status.path] = status
            }

            let repoStatus = RepoStatus(repoPath: repoPath, files: files)

            queue.async { [self] in
                cache[repoPath] = repoStatus
                Log.status.info("Updated cache for \(repoPath): \(files.count) files")

                // Notify about all tracked URLs
                if let urls = trackedURLs[repoPath] {
                    for url in urls {
                        let badge = getBadgeIdentifier(for: url, repoPath: repoPath, status: repoStatus)
                        DispatchQueue.main.async { [self] in
                            onBadgeUpdate?(url, badge)
                        }
                    }
                }
            }

        case .failure(let error):
            Log.status.error("Failed to get status for \(repoPath): \(error.localizedDescription)")
        }
    }

    public func getBadgeIdentifier(for url: URL, repoPath: String, status: RepoStatus? = nil) -> String {
        let repoStatus = status ?? queue.sync { cache[repoPath] }

        guard let repoStatus = repoStatus else {
            return ""
        }

        let filePath = url.path
        let relativePath = Self.makeRelativePath(filePath, relativeTo: repoPath)

        // Check if this is a file
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory)

        if isDirectory.boolValue {
            // For directories, aggregate status of all files within
            return getDirectoryBadge(relativePath: relativePath, status: repoStatus)
        } else {
            // For files, return direct status
            if let fileStatus = repoStatus.status(for: relativePath) {
                return BadgePriority(from: fileStatus).badgeIdentifier
            }
            return ""
        }
    }

    private func getDirectoryBadge(relativePath: String, status: RepoStatus) -> String {
        var highestPriority = BadgePriority.clean

        let prefix = relativePath.isEmpty ? "" : relativePath + "/"

        for (path, fileStatus) in status.files {
            if relativePath.isEmpty || path.hasPrefix(prefix) {
                let priority = BadgePriority(from: fileStatus)
                if priority > highestPriority {
                    highestPriority = priority
                }
            }
        }

        return highestPriority.badgeIdentifier
    }
}
