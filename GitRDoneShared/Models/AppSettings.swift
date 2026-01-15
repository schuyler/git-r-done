//
//  AppSettings.swift
//  GitRDoneShared
//

import Foundation

public struct AppSettings: Codable, Equatable {
    public var autoPushEnabled: Bool
    public var hasCompletedOnboarding: Bool

    public init(
        autoPushEnabled: Bool = true,
        hasCompletedOnboarding: Bool = false
    ) {
        self.autoPushEnabled = autoPushEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}
