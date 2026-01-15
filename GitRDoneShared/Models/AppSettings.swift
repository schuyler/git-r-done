//
//  AppSettings.swift
//  GitRDoneShared
//

import Foundation

public struct AppSettings: Codable, Equatable {
    public var notificationsEnabled: Bool
    public var autoPushEnabled: Bool
    public var hasCompletedOnboarding: Bool

    public init(
        notificationsEnabled: Bool = true,
        autoPushEnabled: Bool = true,
        hasCompletedOnboarding: Bool = false
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.autoPushEnabled = autoPushEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}
