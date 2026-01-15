//
//  ConflictResolution.swift
//  GitRDoneShared
//

import Foundation

public struct ConflictResolution: Equatable {
    public let originalFile: String
    public let backupFile: String
    public let backupPath: String

    public init(originalFile: String, backupFile: String, backupPath: String) {
        self.originalFile = originalFile
        self.backupFile = backupFile
        self.backupPath = backupPath
    }
}
