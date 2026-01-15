//
//  BadgeResolver.swift
//  GitRDoneShared
//

import Foundation

public enum BadgeResolver {

    public static func badge(for relativePath: String, in status: RepoStatus?, isDirectory: Bool) -> String {
        guard let status = status else { return "" }

        if isDirectory {
            return directoryBadge(for: relativePath, in: status)
        } else {
            return fileBadge(for: relativePath, in: status)
        }
    }

    private static func fileBadge(for relativePath: String, in status: RepoStatus) -> String {
        guard let fileStatus = status.files[relativePath] else { return "" }
        return BadgePriority(from: fileStatus).badgeIdentifier
    }

    private static func directoryBadge(for relativePath: String, in status: RepoStatus) -> String {
        let prefix = relativePath.isEmpty ? "" : relativePath + "/"

        let worstPriority = status.files
            .filter { key, _ in
                if relativePath.isEmpty {
                    return true
                } else {
                    return key.hasPrefix(prefix)
                }
            }
            .map { _, value in BadgePriority(from: value) }
            .max() ?? .clean

        return worstPriority.badgeIdentifier
    }
}
