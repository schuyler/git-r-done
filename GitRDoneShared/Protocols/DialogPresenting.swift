//
//  DialogPresenting.swift
//  GitRDoneShared
//

import Foundation

public protocol DialogPresenting {
    func promptForCommitMessage() -> String?
    func confirm(message: String, confirmButton: String) -> Bool
    func showConflictReport(resolutions: [ConflictResolution])
    func showError(_ message: String)
    func showInfo(_ message: String)
}
