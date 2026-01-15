//
//  Log.swift
//  GitRDoneShared
//

import Foundation
import os.log

enum Log {
    private static let subsystem = "info.schuyler.gitrdone"

    static let git = Logger(subsystem: subsystem, category: "git")
    static let status = Logger(subsystem: subsystem, category: "status")
    static let finder = Logger(subsystem: subsystem, category: "finder")
    static let config = Logger(subsystem: subsystem, category: "config")
    static let conflict = Logger(subsystem: subsystem, category: "conflict")
}
