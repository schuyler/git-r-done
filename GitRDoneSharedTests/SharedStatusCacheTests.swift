//
//  SharedStatusCacheTests.swift
//  GitRDoneSharedTests
//

import Testing
@testable import GitRDoneShared

struct SharedStatusCacheTests {

    @Test func summaries_initiallyEmpty() {
        let cache = SharedStatusCache(suiteName: nil) // Use standard UserDefaults for testing
        cache.clear() // Ensure clean state
        #expect(cache.summaries.isEmpty)
    }

    @Test func update_addsSummary() {
        let cache = SharedStatusCache(suiteName: nil)
        cache.clear()
        let summary = RepoStatusSummary(path: "/test/repo", status: .modified)
        cache.update(summary)
        #expect(cache.summaries.count == 1)
        #expect(cache.summaries.first?.path == "/test/repo")
    }

    @Test func update_replacesSummaryForSamePath() {
        let cache = SharedStatusCache(suiteName: nil)
        cache.clear()
        cache.update(RepoStatusSummary(path: "/test/repo", status: .modified))
        cache.update(RepoStatusSummary(path: "/test/repo", status: .clean))
        #expect(cache.summaries.count == 1)
        #expect(cache.summaries.first?.status == .clean)
    }

    @Test func remove_deletesSummary() {
        let cache = SharedStatusCache(suiteName: nil)
        cache.clear()
        cache.update(RepoStatusSummary(path: "/test/repo", status: .modified))
        cache.remove(path: "/test/repo")
        #expect(cache.summaries.isEmpty)
    }

    @Test func summaryForPath_returnsCorrectSummary() {
        let cache = SharedStatusCache(suiteName: nil)
        cache.clear()
        cache.update(RepoStatusSummary(path: "/test/repo1", status: .modified))
        cache.update(RepoStatusSummary(path: "/test/repo2", status: .clean))
        let summary = cache.summary(for: "/test/repo1")
        #expect(summary?.status == .modified)
    }

    @Test func summaryForPath_returnsNilForUnknownPath() {
        let cache = SharedStatusCache(suiteName: nil)
        cache.clear()
        #expect(cache.summary(for: "/unknown") == nil)
    }
}
