//
//  DialogPresenting.swift
//  GitRDoneShared
//

import Foundation

/// Protocol for presenting dialogs to the user (commit messages, confirmations, errors)
public protocol DialogPresenting: ErrorPresenting {
    func promptForCommitMessage() -> String?
    func confirm(message: String, confirmButton: String) -> Bool
    func showConflictReport(resolutions: [ConflictResolution])
    func showInfo(_ message: String)
}
