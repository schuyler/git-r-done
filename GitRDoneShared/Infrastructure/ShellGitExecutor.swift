//
//  ShellGitExecutor.swift
//  GitRDoneShared
//

import Foundation

public final class ShellGitExecutor: GitExecuting {

    private let gitPath: String?

    public init() {
        self.gitPath = Self.findGit()
    }

    public func isGitAvailable() -> Bool {
        gitPath != nil
    }

    public func execute(_ arguments: [String], in directory: String, timeout: TimeInterval) -> ShellResult {
        guard let gitPath = gitPath else {
            Log.git.error("Git not found")
            return .gitNotFound
        }

        Log.git.debug("Executing: git \(arguments.joined(separator: " ")) in \(directory)")

        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: gitPath)
        process.arguments = arguments
        process.currentDirectoryURL = URL(fileURLWithPath: directory)
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            Log.git.error("Failed to start process: \(error.localizedDescription)")
            return .failure(error.localizedDescription)
        }

        // Read pipes asynchronously to prevent deadlock when pipe buffer fills
        var stdoutData = Data()
        var stderrData = Data()
        let readGroup = DispatchGroup()

        readGroup.enter()
        DispatchQueue.global().async {
            stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            readGroup.leave()
        }

        readGroup.enter()
        DispatchQueue.global().async {
            stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            readGroup.leave()
        }

        let semaphore = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in semaphore.signal() }

        let waitResult = semaphore.wait(timeout: .now() + timeout)

        if waitResult == .timedOut {
            Log.git.error("Command timed out after \(timeout)s")
            process.terminate()
            // Wait for reads to complete even on timeout
            readGroup.wait()
            return .timedOut
        }

        // Wait for reads to complete
        readGroup.wait()

        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""

        let result = ShellResult(
            exitCode: process.terminationStatus,
            stdout: stdout,
            stderr: stderr,
            stdoutData: stdoutData
        )

        if !result.success {
            Log.git.warning("Command failed with exit code \(result.exitCode): \(stderr)")
        }

        return result
    }

    private static func findGit() -> String? {
        let candidates = [
            "/usr/bin/git",
            "/usr/local/bin/git",
            "/opt/homebrew/bin/git"
        ]

        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                Log.git.info("Found git at \(path)")
                return path
            }
        }

        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["git"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !path.isEmpty {
                    Log.git.info("Found git via which: \(path)")
                    return path
                }
            }
        } catch {
            // Ignore
        }

        Log.git.error("Git not found in any known location")
        return nil
    }
}
