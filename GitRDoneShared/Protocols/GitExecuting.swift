//
//  GitExecuting.swift
//  GitRDoneShared
//

import Foundation

public struct ShellResult: Equatable, Sendable {
    public let exitCode: Int32
    public let stdout: String
    public let stderr: String
    /// Raw stdout data - use for binary content that may be corrupted by UTF-8 conversion
    public let stdoutData: Data

    public var success: Bool { exitCode == 0 }

    public init(exitCode: Int32, stdout: String, stderr: String, stdoutData: Data = Data()) {
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
        self.stdoutData = stdoutData
    }

    public static func success(_ stdout: String = "") -> ShellResult {
        ShellResult(exitCode: 0, stdout: stdout, stderr: "", stdoutData: stdout.data(using: .utf8) ?? Data())
    }

    public static func failure(_ stderr: String, exitCode: Int32 = 1) -> ShellResult {
        ShellResult(exitCode: exitCode, stdout: "", stderr: stderr, stdoutData: Data())
    }

    public static let timedOut = ShellResult(exitCode: -1, stdout: "", stderr: "Operation timed out", stdoutData: Data())
    public static let gitNotFound = ShellResult(exitCode: -2, stdout: "", stderr: "Git is not installed", stdoutData: Data())
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
