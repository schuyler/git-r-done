//
//  BranchInfo.swift
//  GitRDoneShared
//

import Foundation

public struct BranchInfo: Equatable {
    public let ahead: Int
    public let behind: Int

    public init(ahead: Int = 0, behind: Int = 0) {
        self.ahead = ahead
        self.behind = behind
    }
}
