import Foundation
@testable import GitRDoneShared

final class MockDialogPresenter: DialogPresenting {

    var commitMessageToReturn: String? = "Test commit"
    var confirmResult = true

    var promptedForCommitMessage = false
    var confirmMessages: [String] = []
    var conflictReportsShown: [[ConflictResolution]] = []
    var errorsShown: [String] = []
    var infosShown: [String] = []

    func promptForCommitMessage() -> String? {
        promptedForCommitMessage = true
        return commitMessageToReturn
    }

    func confirm(message: String, confirmButton: String) -> Bool {
        confirmMessages.append(message)
        return confirmResult
    }

    func showConflictReport(resolutions: [ConflictResolution]) {
        conflictReportsShown.append(resolutions)
    }

    func showError(_ message: String) {
        errorsShown.append(message)
    }

    func showInfo(_ message: String) {
        infosShown.append(message)
    }
}
