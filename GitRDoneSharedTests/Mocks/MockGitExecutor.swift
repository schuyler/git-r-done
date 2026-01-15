import Foundation
@testable import GitRDoneShared

final class MockGitExecutor: GitExecuting {

    var isGitAvailableResult = true
    var stubbedResults: [[String]: ShellResult] = [:]
    var executedCommands: [(arguments: [String], directory: String, timeout: TimeInterval)] = []

    func isGitAvailable() -> Bool {
        isGitAvailableResult
    }

    func execute(_ arguments: [String], in directory: String, timeout: TimeInterval) -> ShellResult {
        executedCommands.append((arguments, directory, timeout))

        if let result = stubbedResults[arguments] {
            return result
        }

        return .success()
    }

    func stub(_ arguments: [String], result: ShellResult) {
        stubbedResults[arguments] = result
    }

    func stubStatus(_ output: String) {
        stub(["status", "--porcelain=v2"], result: .success(output))
    }

    func stubPull(_ output: String, success: Bool = true) {
        stub(["pull"], result: success ? .success(output) : .failure(output))
    }
}
