//
//  RepoConfiguration.swift
//  GitRDoneShared
//

import Foundation

public final class RepoConfiguration: RepoConfiguring {

    public static let shared = RepoConfiguration()

    private let suiteName = "group.info.schuyler.gitrdone"
    private let reposKey = "watchedRepositories"
    private let queue = DispatchQueue(label: "info.schuyler.gitrdone.repoconfig")

    private lazy var defaults: UserDefaults = {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("App Group '\(suiteName)' not configured. Add it in Signing & Capabilities.")
        }
        return defaults
    }()

    private var _repositories: [WatchedRepository] = []

    public var repositories: [WatchedRepository] {
        queue.sync { _repositories }
    }

    private init() {
        load()
    }

    public func load() {
        queue.sync { [self] in
            guard let data = defaults.data(forKey: reposKey),
                  let repos = try? JSONDecoder().decode([WatchedRepository].self, from: data)
            else {
                _repositories = []
                Log.config.info("No saved repositories found")
                return
            }
            _repositories = repos
            Log.config.info("Loaded \(repos.count) repositories")
        }
    }

    public func add(_ repo: WatchedRepository) {
        queue.async { [self] in
            guard !_repositories.contains(where: { $0.path == repo.path }) else {
                Log.config.warning("Repository already exists: \(repo.path)")
                return
            }
            _repositories.append(repo)
            save()
            Log.config.info("Added repository: \(repo.path)")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .repositoriesDidChange, object: nil)
            }
        }
    }

    public func remove(id: UUID) {
        queue.async { [self] in
            _repositories.removeAll { $0.id == id }
            save()
            Log.config.info("Removed repository with id: \(id)")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .repositoriesDidChange, object: nil)
            }
        }
    }

    public func remove(path: String) {
        queue.async { [self] in
            _repositories.removeAll { $0.path == path }
            save()
            Log.config.info("Removed repository at path: \(path)")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .repositoriesDidChange, object: nil)
            }
        }
    }

    public func contains(path: String) -> Bool {
        let normalized = (path as NSString).standardizingPath
        return queue.sync { _repositories.contains { $0.path == normalized } }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(self._repositories) else {
            Log.config.error("Failed to encode repositories")
            return
        }
        self.defaults.set(data, forKey: self.reposKey)
        Log.config.info("Saved \(self._repositories.count) repositories")
    }
}
