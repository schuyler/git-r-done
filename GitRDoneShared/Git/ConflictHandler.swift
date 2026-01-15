//
//  ConflictHandler.swift
//  GitRDoneShared
//

import Foundation

public final class ConflictHandler {

    private let gitOps: GitOperations
    private let fileManager: FileManager
    private let dateFormatter: DateFormatter

    public init(gitOps: GitOperations = GitOperations(), fileManager: FileManager = .default) {
        self.gitOps = gitOps
        self.fileManager = fileManager

        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd"
    }

    /// Resolves conflicts using "Keep Both" strategy:
    /// 1. Save local version as "filename (Conflict YYYY-MM-DD).ext"
    /// 2. Accept remote version (theirs)
    /// 3. Complete merge
    /// Returns list of conflict resolutions for user notification
    public func resolveConflicts(_ files: [String], in repoPath: String) -> Result<[ConflictResolution], GitError> {
        var resolutions: [ConflictResolution] = []

        for file in files {
            let fullPath = (repoPath as NSString).appendingPathComponent(file)

            // Save local version with conflict suffix
            if let backupResult = saveLocalCopy(originalPath: fullPath, repoPath: repoPath) {
                resolutions.append(backupResult)
            }
        }

        // Accept remote versions and complete merge
        let result = gitOps.acceptTheirsAndComplete(files: files, in: repoPath)
        if case .failure(let error) = result {
            Log.conflict.error("Failed to complete merge: \(error.localizedDescription)")
            return .failure(error)
        }

        // Copy backup files back into repo as untracked files
        for resolution in resolutions {
            let destPath = (repoPath as NSString).appendingPathComponent(resolution.backupFile)
            do {
                try fileManager.copyItem(atPath: resolution.backupPath, toPath: destPath)
                try fileManager.removeItem(atPath: resolution.backupPath)
                Log.conflict.info("Restored local copy: \(resolution.backupFile)")
            } catch {
                Log.conflict.error("Failed to restore local copy: \(error.localizedDescription)")
            }
        }

        return .success(resolutions)
    }

    private func saveLocalCopy(originalPath: String, repoPath: String) -> ConflictResolution? {
        guard fileManager.fileExists(atPath: originalPath) else {
            Log.conflict.warning("File does not exist for backup: \(originalPath)")
            return nil
        }

        let url = URL(fileURLWithPath: originalPath)
        let filename = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        let dateString = dateFormatter.string(from: Date())

        let backupFilename: String
        if ext.isEmpty {
            backupFilename = "\(filename) (Conflict \(dateString))"
        } else {
            backupFilename = "\(filename) (Conflict \(dateString)).\(ext)"
        }

        // Save to temp directory first
        let tempDir = fileManager.temporaryDirectory
        let tempPath = tempDir.appendingPathComponent(UUID().uuidString).path

        do {
            try fileManager.copyItem(atPath: originalPath, toPath: tempPath)
            Log.conflict.info("Saved local copy to temp: \(tempPath)")

            let relativePath = String(originalPath.dropFirst(repoPath.count + 1))
            let relativeDir = (relativePath as NSString).deletingLastPathComponent
            let backupRelativePath = relativeDir.isEmpty ? backupFilename : (relativeDir as NSString).appendingPathComponent(backupFilename)

            return ConflictResolution(
                originalFile: (relativePath as NSString).lastPathComponent,
                backupFile: backupFilename,
                backupPath: tempPath
            )
        } catch {
            Log.conflict.error("Failed to save local copy: \(error.localizedDescription)")
            return nil
        }
    }
}
