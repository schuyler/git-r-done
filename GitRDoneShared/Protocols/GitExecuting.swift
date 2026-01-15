//
//  GitExecuting.swift
//  GitRDoneShared
//

import Foundation

public struct ShellResult: Equatable {
    public let exitCode: Int32
    public let stdout: String
    public let stderr: String

    public var success: Bool { exitCode == 0 }

    public init(exitCode: Int32, stdout: String, stderr: String) {
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
    }

    public static func success(_ stdout: String = "") -> ShellResult {
        ShellResult(exitCode: 0, stdout: stdout, stderr: "")
    }

    public static func failure(_ stderr: String, exitCode: Int32 = 1) -> ShellResult {
        ShellResult(exitCode: exitCode, stdout: "", stderr: stderr)
    }

    public static let timedOut = ShellResult(exitCode: -1, stdout: "", stderr: "Operation timed out")
    public static let gitNotFound = ShellResult(exitCode: -2, stdout: "", stderr: "Git is not installed")
}

public protocol GitExecuting {
    func execute(_ arguments: [String], in directory: String, timeout: TimeInterval) -> ShellResult
    func isGitAvailable() -> Bool
}

public extension GitExecuting {
    func execute(_ arguments: [String], in directory: String) -> ShellResult {
        execute(arguments, in: directory, timeout: 30)
    }
}
