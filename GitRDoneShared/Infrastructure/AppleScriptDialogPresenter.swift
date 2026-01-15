//
//  AppleScriptDialogPresenter.swift
//  GitRDoneShared
//

import Foundation

public final class AppleScriptDialogPresenter: DialogPresenting {

    public init() {}

    public func promptForCommitMessage() -> String? {
        let script = """
        tell application "System Events"
            activate
            set dialogResult to display dialog "Enter a commit message:" default answer "" buttons {"Cancel", "Commit"} default button "Commit" with title "Git-R-Done"
            if button returned of dialogResult is "Commit" then
                return text returned of dialogResult
            else
                return ""
            end if
        end tell
        """

        guard let result = runAppleScript(script), !result.isEmpty else {
            return nil
        }
        return result
    }

    public func confirm(message: String, confirmButton: String) -> Bool {
        let escapedMessage = escapeForAppleScript(message)
        let escapedButton = escapeForAppleScript(confirmButton)
        let script = """
        tell application "System Events"
            activate
            set dialogResult to display dialog "\(escapedMessage)" buttons {"Cancel", "\(escapedButton)"} default button "\(escapedButton)" with title "Git-R-Done"
            return button returned of dialogResult
        end tell
        """

        guard let result = runAppleScript(script) else {
            return false
        }
        return result == confirmButton
    }

    public func showConflictReport(resolutions: [ConflictResolution]) {
        var fileList = ""
        for r in resolutions {
            let escaped = escapeForAppleScript("\(r.originalFile) -> \(r.backupFile)")
            fileList += "  - \(escaped)\n"
        }

        let message = """
        Pull completed with conflicts.

        The following files were changed both locally and remotely. Your local versions have been saved:

        \(fileList)
        Please review and reconcile these files, then delete the conflict copies when you're done.
        """

        let escapedMessage = escapeForAppleScript(message)
        let script = """
        tell application "System Events"
            activate
            display dialog "\(escapedMessage)" buttons {"OK"} default button "OK" with title "Git-R-Done: Conflicts Resolved"
        end tell
        """

        _ = runAppleScript(script)
    }

    public func showError(_ message: String) {
        let escapedMessage = escapeForAppleScript(message)
        let script = """
        tell application "System Events"
            activate
            display dialog "\(escapedMessage)" buttons {"OK"} default button "OK" with title "Git-R-Done: Error" with icon stop
        end tell
        """

        _ = runAppleScript(script)
    }

    public func showInfo(_ message: String) {
        let escapedMessage = escapeForAppleScript(message)
        let script = """
        tell application "System Events"
            activate
            display dialog "\(escapedMessage)" buttons {"OK"} default button "OK" with title "Git-R-Done"
        end tell
        """

        _ = runAppleScript(script)
    }

    private func escapeForAppleScript(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    private func runAppleScript(_ script: String) -> String? {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            Log.finder.error("AppleScript failed: \(error.localizedDescription)")
            return nil
        }

        guard process.terminationStatus == 0 else {
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
