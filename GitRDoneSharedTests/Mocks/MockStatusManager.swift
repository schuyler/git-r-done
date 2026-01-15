import Foundation
@testable import GitRDoneShared

final class MockStatusManager: StatusManaging {

    var cachedStatuses: [String: RepoStatus] = [:]
    var trackedURLs: [(URL, String)] = []
    var refreshedRepoPaths: [String] = []
    var invalidatedRepoPaths: [String] = []
    var performedActions: [String] = []

    var onBadgeUpdate: ((URL, String) -> Void)?

    func getCachedStatus(for repoPath: String) -> RepoStatus? {
        cachedStatuses[repoPath]
    }

    func trackURL(_ url: URL, for repoPath: String) {
        trackedURLs.append((url, repoPath))
    }

    func queueRefresh(for repoPath: String) {
        refreshedRepoPaths.append(repoPath)
    }

    func invalidate(repoPath: String) {
        invalidatedRepoPaths.append(repoPath)
    }

    func performAction(in repoPath: String, action: @escaping () -> Void) {
        performedActions.append(repoPath)
        action()
    }
}
