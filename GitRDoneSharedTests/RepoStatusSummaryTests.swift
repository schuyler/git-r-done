//
//  RepoStatusSummaryTests.swift
//  GitRDoneSharedTests
//

import Testing
import Foundation
@testable import GitRDoneShared

struct RepoStatusSummaryTests {

    // MARK: - Init Tests

    @Test func initWithDefaults_setsCommitsAheadToZero() {
        let summary = RepoStatusSummary(path: "/test/repo", status: .clean)
        #expect(summary.commitsAhead == 0)
    }

    @Test func initWithDefaults_setsUpdatedAtToNow() {
        let before = Date()
        let summary = RepoStatusSummary(path: "/test/repo", status: .clean)
        let after = Date()
        #expect(summary.updatedAt >= before)
        #expect(summary.updatedAt <= after)
    }

    @Test func initWithAllParameters_setsAllValues() {
        let testDate = Date(timeIntervalSince1970: 1000)
        let summary = RepoStatusSummary(
            path: "/my/repo",
            status: .modified,
            commitsAhead: 5,
            updatedAt: testDate
        )
        #expect(summary.path == "/my/repo")
        #expect(summary.status == .modified)
        #expect(summary.commitsAhead == 5)
        #expect(summary.updatedAt == testDate)
    }

    // Note: displayName was removed from RepoStatusSummary.
    // Display names are now stored in WatchedRepository and looked up via
    // RepoConfiguration.repository(for:)?.displayName

    // MARK: - Codable Tests

    @Test func codableRoundTrip_preservesAllProperties() throws {
        let testDate = Date(timeIntervalSince1970: 1234567890)
        let original = RepoStatusSummary(
            path: "/test/path",
            status: .ahead,
            commitsAhead: 3,
            updatedAt: testDate
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(original)
        let decoded = try decoder.decode(RepoStatusSummary.self, from: encoded)

        #expect(decoded.path == original.path)
        #expect(decoded.status == original.status)
        #expect(decoded.commitsAhead == original.commitsAhead)
        #expect(decoded.updatedAt == original.updatedAt)
    }

    @Test func codableRoundTrip_withDifferentStatuses() throws {
        let statuses: [BadgePriority] = [.clean, .ahead, .untracked, .staged, .modified, .conflict]

        for status in statuses {
            let original = RepoStatusSummary(path: "/repo", status: status)
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(RepoStatusSummary.self, from: encoded)
            #expect(decoded.status == original.status)
        }
    }

    // MARK: - Equatable Tests

    @Test func equatable_identicalSummariesAreEqual() {
        let date = Date(timeIntervalSince1970: 1000)
        let summary1 = RepoStatusSummary(path: "/repo", status: .modified, commitsAhead: 2, updatedAt: date)
        let summary2 = RepoStatusSummary(path: "/repo", status: .modified, commitsAhead: 2, updatedAt: date)
        #expect(summary1 == summary2)
    }

    @Test func equatable_differentPathsAreNotEqual() {
        let date = Date(timeIntervalSince1970: 1000)
        let summary1 = RepoStatusSummary(path: "/repo1", status: .clean, commitsAhead: 0, updatedAt: date)
        let summary2 = RepoStatusSummary(path: "/repo2", status: .clean, commitsAhead: 0, updatedAt: date)
        #expect(summary1 != summary2)
    }

    @Test func equatable_differentStatusesAreNotEqual() {
        let date = Date(timeIntervalSince1970: 1000)
        let summary1 = RepoStatusSummary(path: "/repo", status: .clean, commitsAhead: 0, updatedAt: date)
        let summary2 = RepoStatusSummary(path: "/repo", status: .modified, commitsAhead: 0, updatedAt: date)
        #expect(summary1 != summary2)
    }

    @Test func equatable_differentCommitsAheadAreNotEqual() {
        let date = Date(timeIntervalSince1970: 1000)
        let summary1 = RepoStatusSummary(path: "/repo", status: .ahead, commitsAhead: 1, updatedAt: date)
        let summary2 = RepoStatusSummary(path: "/repo", status: .ahead, commitsAhead: 5, updatedAt: date)
        #expect(summary1 != summary2)
    }

    @Test func equatable_differentDatesAreNotEqual() {
        let summary1 = RepoStatusSummary(path: "/repo", status: .clean, commitsAhead: 0, updatedAt: Date(timeIntervalSince1970: 1000))
        let summary2 = RepoStatusSummary(path: "/repo", status: .clean, commitsAhead: 0, updatedAt: Date(timeIntervalSince1970: 2000))
        #expect(summary1 != summary2)
    }
}
