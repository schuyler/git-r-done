//
//  BadgePriorityTests.swift
//  GitRDoneSharedTests
//

import Testing
import Foundation
@testable import GitRDoneShared

struct BadgePriorityTests {

    // MARK: - Raw Value Tests

    @Test func pendingHasRawValueNegativeOne() {
        #expect(BadgePriority.pending.rawValue == -1)
    }

    @Test func aheadHasCorrectRawValue() {
        #expect(BadgePriority.ahead.rawValue == 1)
    }

    @Test func cleanHasRawValueZero() {
        #expect(BadgePriority.clean.rawValue == 0)
    }

    @Test func untrackedHasRawValueTwo() {
        #expect(BadgePriority.untracked.rawValue == 2)
    }

    @Test func stagedHasRawValueThree() {
        #expect(BadgePriority.staged.rawValue == 3)
    }

    @Test func modifiedHasRawValueFour() {
        #expect(BadgePriority.modified.rawValue == 4)
    }

    @Test func conflictHasRawValueFive() {
        #expect(BadgePriority.conflict.rawValue == 5)
    }

    // MARK: - Priority Ordering Tests

    @Test func priorityOrdering_pendingIsLessThanClean() {
        #expect(BadgePriority.pending < BadgePriority.clean)
    }

    @Test func priorityOrdering_cleanIsLessThanAhead() {
        #expect(BadgePriority.clean < BadgePriority.ahead)
    }

    @Test func priorityOrdering_aheadIsLessThanUntracked() {
        #expect(BadgePriority.ahead < BadgePriority.untracked)
    }

    @Test func priorityOrdering_untrackedIsLessThanStaged() {
        #expect(BadgePriority.untracked < BadgePriority.staged)
    }

    @Test func priorityOrdering_stagedIsLessThanModified() {
        #expect(BadgePriority.staged < BadgePriority.modified)
    }

    @Test func priorityOrdering_modifiedIsLessThanConflict() {
        #expect(BadgePriority.modified < BadgePriority.conflict)
    }

    @Test func priorityOrdering_fullChain() {
        #expect(BadgePriority.pending < BadgePriority.clean)
        #expect(BadgePriority.clean < BadgePriority.ahead)
        #expect(BadgePriority.ahead < BadgePriority.untracked)
        #expect(BadgePriority.untracked < BadgePriority.staged)
        #expect(BadgePriority.staged < BadgePriority.modified)
        #expect(BadgePriority.modified < BadgePriority.conflict)
    }

    // MARK: - Badge Identifier Tests

    @Test func pendingBadgeIdentifierReturnsEmptyString() {
        #expect(BadgePriority.pending.badgeIdentifier == "")
    }

    @Test func aheadBadgeIdentifierReturnsAhead() {
        #expect(BadgePriority.ahead.badgeIdentifier == "Ahead")
    }

    @Test func cleanBadgeIdentifierReturnsEmptyString() {
        #expect(BadgePriority.clean.badgeIdentifier == "")
    }

    @Test func untrackedBadgeIdentifierReturnsUntracked() {
        #expect(BadgePriority.untracked.badgeIdentifier == "Untracked")
    }

    @Test func stagedBadgeIdentifierReturnsStaged() {
        #expect(BadgePriority.staged.badgeIdentifier == "Staged")
    }

    @Test func modifiedBadgeIdentifierReturnsModified() {
        #expect(BadgePriority.modified.badgeIdentifier == "Modified")
    }

    @Test func conflictBadgeIdentifierReturnsConflict() {
        #expect(BadgePriority.conflict.badgeIdentifier == "Conflict")
    }

    // MARK: - Codable Tests

    @Test func codableRoundTrip_pending() throws {
        let original = BadgePriority.pending
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BadgePriority.self, from: encoded)
        #expect(decoded == original)
    }

    @Test func codableRoundTrip_clean() throws {
        let original = BadgePriority.clean
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BadgePriority.self, from: encoded)
        #expect(decoded == original)
    }

    @Test func codableRoundTrip_ahead() throws {
        let original = BadgePriority.ahead
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BadgePriority.self, from: encoded)
        #expect(decoded == original)
    }

    @Test func codableRoundTrip_untracked() throws {
        let original = BadgePriority.untracked
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BadgePriority.self, from: encoded)
        #expect(decoded == original)
    }

    @Test func codableRoundTrip_conflict() throws {
        let original = BadgePriority.conflict
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BadgePriority.self, from: encoded)
        #expect(decoded == original)
    }

    @Test func codableRoundTrip_allCases() throws {
        let allCases: [BadgePriority] = [.pending, .clean, .ahead, .untracked, .staged, .modified, .conflict]
        for original in allCases {
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(BadgePriority.self, from: encoded)
            #expect(decoded == original)
        }
    }
}
