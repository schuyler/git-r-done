//
//  SharedStatusCache.swift
//  GitRDoneShared
//

import Foundation

public final class SharedStatusCache: StatusCaching {

    public static let shared = SharedStatusCache()

    private let suiteName: String?
    private let cacheKey = "repoStatusSummaries"
    private let queue = DispatchQueue(label: "info.schuyler.gitrdone.statuscache")

    private lazy var defaults: UserDefaults = {
        if let suiteName = suiteName {
            guard let defaults = UserDefaults(suiteName: suiteName) else {
                fatalError("App Group '\(suiteName)' not configured.")
            }
            return defaults
        }
        return UserDefaults.standard
    }()

    private var _summaries: [RepoStatusSummary] = []

    public var summaries: [RepoStatusSummary] {
        queue.sync { _summaries }
    }

    public init(suiteName: String? = "group.info.schuyler.gitrdone") {
        self.suiteName = suiteName
        load()
    }

    public func load() {
        queue.sync { [self] in
            guard let data = defaults.data(forKey: cacheKey),
                  let summaries = try? JSONDecoder().decode([RepoStatusSummary].self, from: data)
            else {
                _summaries = []
                return
            }
            _summaries = summaries
        }
    }

    public func update(_ summary: RepoStatusSummary) {
        queue.sync { [self] in
            _summaries.removeAll { $0.path == summary.path }
            _summaries.append(summary)
            save()
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .statusCacheDidChange, object: nil)
        }
    }

    public func remove(path: String) {
        queue.sync { [self] in
            _summaries.removeAll { $0.path == path }
            save()
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .statusCacheDidChange, object: nil)
        }
    }

    public func summary(for path: String) -> RepoStatusSummary? {
        queue.sync { _summaries.first { $0.path == path } }
    }

    public func clear() {
        queue.sync { [self] in
            _summaries = []
            defaults.removeObject(forKey: cacheKey)
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(self._summaries) else {
            return
        }
        self.defaults.set(data, forKey: self.cacheKey)
    }
}
