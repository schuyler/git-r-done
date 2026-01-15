//
//  Log.swift
//  GitRDoneShared
//

import Foundation
import os.log

public enum Log {
    private static let subsystem = "info.schuyler.gitrdone"

    public static let git = Logger(subsystem: subsystem, category: "git")
    public static let status = Logger(subsystem: subsystem, category: "status")
    public static let finder = Logger(subsystem: subsystem, category: "finder")
    public static let config = Logger(subsystem: subsystem, category: "config")
    public static let conflict = Logger(subsystem: subsystem, category: "conflict")
}
