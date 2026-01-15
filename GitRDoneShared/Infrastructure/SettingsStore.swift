//
//  SettingsStore.swift
//  GitRDoneShared
//

import Foundation

public final class SettingsStore: SettingsStoring {

    public static let shared = SettingsStore()

    private let suiteName = "group.info.schuyler.gitrdone"
    private let settingsKey = "appSettings"
    private let queue = DispatchQueue(label: "info.schuyler.gitrdone.settings")

    private lazy var defaults: UserDefaults = {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("App Group '\(suiteName)' not configured. Add it in Signing & Capabilities.")
        }
        return defaults
    }()

    private var _settings: AppSettings = AppSettings()

    public var settings: AppSettings {
        queue.sync { _settings }
    }

    private init() {
        load()
    }

    public func load() {
        queue.sync { [self] in
            guard let data = defaults.data(forKey: settingsKey),
                  let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
            else {
                _settings = AppSettings()
                Log.config.info("No saved settings found, using defaults")
                return
            }
            _settings = settings
            Log.config.info("Loaded settings")
        }
    }

    public func update(_ settings: AppSettings) {
        queue.async { [self] in
            _settings = settings
            save()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .settingsDidChange, object: nil)
            }
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(_settings) else {
            Log.config.error("Failed to encode settings")
            return
        }
        defaults.set(data, forKey: settingsKey)
        Log.config.info("Saved settings")
    }
}

public extension Notification.Name {
    static let settingsDidChange = Notification.Name("info.schuyler.gitrdone.settingsDidChange")
    static let repositoriesDidChange = Notification.Name("info.schuyler.gitrdone.repositoriesDidChange")
    static let statusCacheDidChange = Notification.Name("info.schuyler.gitrdone.statusCacheDidChange")
}
