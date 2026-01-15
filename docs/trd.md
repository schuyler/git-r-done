# Git-R-Done — Technical Requirements Document v3

## 1. Project Configuration

### 1.1 Xcode Project Structure

```
Git-R-Done/
├── Git-R-Done.xcodeproj
├── Git-R-Done/                       # Main app target
│   ├── App/
│   │   ├── GitRDoneApp.swift
│   │   ├── AppDelegate.swift
│   │   └── OnboardingWindow.swift
│   ├── MenuBar/
│   │   ├── MenuBarController.swift
│   │   ├── MenuBarView.swift
│   │   └── RepoListView.swift
│   ├── Services/
│   │   └── ServicesProvider.swift
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   └── InfoPlist.strings
│   ├── Info.plist
│   └── Git_R_Done.entitlements
├── GitRDoneExtension/                # Finder Sync Extension target
│   ├── FinderSync.swift
│   ├── Info.plist
│   └── GitRDoneExtension.entitlements
├── Shared/                           # Shared framework target
│   ├── Protocols/
│   │   ├── GitExecuting.swift
│   │   ├── FileManaging.swift
│   │   ├── DialogPresenting.swift
│   │   └── NotificationSending.swift
│   ├── Models/
│   │   ├── WatchedRepository.swift
│   │   ├── GitFileStatus.swift
│   │   ├── GitError.swift
│   │   └── AppSettings.swift
│   ├── Git/
│   │   ├── GitOperations.swift
│   │   ├── GitStatusParser.swift
│   │   └── ConflictHandler.swift
│   ├── Infrastructure/
│   │   ├── ShellGitExecutor.swift
│   │   ├── AppleScriptDialogPresenter.swift
│   │   ├── UserNotificationSender.swift
│   │   ├── RepoConfiguration.swift
│   │   ├── SettingsStore.swift
│   │   └── StatusManager.swift
│   ├── Utilities/
│   │   ├── BadgeResolver.swift
│   │   ├── FSEventsWatcher.swift
│   │   └── Log.swift
│   └── Shared.h
├── Tests/
│   ├── Mocks/
│   │   ├── MockGitExecutor.swift
│   │   ├── MockDialogPresenter.swift
│   │   ├── MockNotificationSender.swift
│   │   └── MockStatusManager.swift
│   ├── GitStatusParserTests.swift
│   ├── GitOperationsTests.swift
│   ├── ConflictHandlerTests.swift
│   ├── BadgeResolverTests.swift
│   └── StatusManagerTests.swift
└── IntegrationTests/
    ├── GitOperationsIntegrationTests.swift
    └── ConflictResolutionIntegrationTests.swift
```

### 1.2 Targets

| Target | Type | Bundle ID | Dependencies |
|--------|------|-----------|--------------|
| Git-R-Done | App | `info.schuyler.gitrdone` | Shared |
| GitRDoneExtension | Finder Sync Extension | `info.schuyler.gitrdone.extension` | Shared |
| Shared | Framework | `info.schuyler.gitrdone.shared` | — |
| Tests | Unit Test Bundle | `info.schuyler.gitrdone.tests` | Shared |
| IntegrationTests | Unit Test Bundle | `info.schuyler.gitrdone.integrationtests` | Shared |

### 1.3 App Groups

**App Group Identifier:** `group.info.schuyler.gitrdone`

Used for:
- Shared UserDefaults suite
- Communication between main app and extension

### 1.4 Entitlements

**Git-R-Done (Main App):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.automation.apple-events</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.info.schuyler.gitrdone</string>
    </array>
</dict>
</plist>
```

**GitRDoneExtension:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.automation.apple-events</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.info.schuyler.gitrdone</string>
    </array>
</dict>
</plist>
```

### 1.5 Info.plist — Main App

```xml
<key>LSUIElement</key>
<true/>

<key>NSServices</key>
<array>
    <dict>
        <key>NSMenuItem</key>
        <dict>
            <key>default</key>
            <string>Add to Git-R-Done</string>
        </dict>
        <key>NSMessage</key>
        <string>addRepository</string>
        <key>NSPortName</key>
        <string>Git-R-Done</string>
        <key>NSSendTypes</key>
        <array>
            <string>NSFilenamesPboardType</string>
            <string>public.file-url</string>
        </array>
    </dict>
</array>

<key>NSAppleEventsUsageDescription</key>
<string>Git-R-Done uses AppleScript to display dialogs for commit messages and notifications.</string>
```

### 1.6 Info.plist — Extension

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.FinderSync</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).FinderSync</string>
</dict>
```

---

## 2. Logging

All components use a centralized logging facility for debugging and diagnostics.

### 2.1 Log.swift

```swift
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

// Usage:
// Log.git.info("Executing: git \(arguments.joined(separator: " "))")
// Log.git.error("Command failed: \(stderr)")
// Log.status.debug("Cache hit for \(repoPath)")
```

---

## 3. Protocols

### 3.1 GitExecuting

```swift
import Foundation

struct ShellResult: Equatable {
    let exitCode: Int32
    let stdout: String
    let stderr: String
    
    var success: Bool { exitCode == 0 }
    
    static func success(_ stdout: String = "") -> ShellResult {
        ShellResult(exitCode: 0, stdout: stdout, stderr: "")
    }
    
    static func failure(_ stderr: String, exitCode: Int32 = 1) -> ShellResult {
        ShellResult(exitCode: exitCode, stdout: "", stderr: stderr)
    }
    
    static let timedOut = ShellResult(exitCode: -1, stdout: "", stderr: "Operation timed out")
    static let gitNotFound = ShellResult(exitCode: -2, stdout: "", stderr: "Git is not installed")
}

protocol GitExecuting {
    func execute(_ arguments: [String], in directory: String, timeout: TimeInterval) -> ShellResult
    func isGitAvailable() -> Bool
}

extension GitExecuting {
    func execute(_ arguments: [String], in directory: String) -> ShellResult {
        execute(arguments, in: directory, timeout: 30)
    }
}
```

### 3.2 DialogPresenting

```swift
import Foundation

protocol DialogPresenting {
    func promptForCommitMessage() -> String?
    func confirm(message: String, confirmButton: String) -> Bool
    func showConflictReport(resolutions: [ConflictResolution])
    func showError(_ message: String)
    func showInfo(_ message: String)
}
```

### 3.3 NotificationSending

```swift
import Foundation

protocol NotificationSending {
    func send(title: String, body: String)
    func sendAlways(title: String, body: String)
}
```

### 3.4 StatusManaging

```swift
import Foundation

protocol StatusManaging: AnyObject {
    func getCachedStatus(for repoPath: String) -> RepoStatus?
    func trackURL(_ url: URL, for repoPath: String)
    func queueRefresh(for repoPath: String)
    func invalidate(repoPath: String)
    func performAction(in repoPath: String, action: @escaping () -> Void)
    
    var onBadgeUpdate: ((URL, String) -> Void)? { get set }
}
```

---

## 4. Data Models

### 4.1 WatchedRepository

```swift
import Foundation

struct WatchedRepository: Codable, Identifiable, Equatable {
    let id: UUID
    let path: String
    let displayName: String
    let dateAdded: Date
    
    var url: URL {
        URL(fileURLWithPath: path)
    }
    
    init(id: UUID = UUID(), path: String, dateAdded: Date = Date()) {
        self.id = id
        self.path = (path as NSString).standardizingPath
        self.displayName = URL(fileURLWithPath: path).lastPathComponent
        self.dateAdded = dateAdded
    }
}
```

### 4.2 GitFileStatus

```swift
import Foundation

enum GitStatusCode: Equatable {
    case untracked
    case modified
    case added
    case deleted
    case renamed
    case copied
    case unmerged
    case ignored
    case clean
    
    init(character: Character) {
        switch character {
        case "?": self = .untracked
        case "M": self = .modified
        case "A": self = .added
        case "D": self = .deleted
        case "R": self = .renamed
        case "C": self = .copied
        case "U": self = .unmerged
        case "!": self = .ignored
        case ".", " ": self = .clean  // Git uses space for clean, dot in some contexts
        default: self = .clean
        }
    }
}

struct GitFileStatus: Equatable {
    let path: String
    let indexStatus: GitStatusCode
    let worktreeStatus: GitStatusCode
    
    var isUntracked: Bool {
        indexStatus == .untracked && worktreeStatus == .untracked
    }
    
    var isModified: Bool {
        worktreeStatus == .modified || worktreeStatus == .added || worktreeStatus == .deleted
    }
    
    var isStaged: Bool {
        switch indexStatus {
        case .modified, .added, .deleted, .renamed, .copied:
            return true
        default:
            return false
        }
    }
    
    var hasConflict: Bool {
        indexStatus == .unmerged || worktreeStatus == .unmerged
    }
}
```

### 4.3 RepoStatus

```swift
import Foundation

struct RepoStatus: Equatable {
    let repoPath: String
    let files: [String: GitFileStatus]
    let timestamp: Date
    
    func status(for relativePath: String) -> GitFileStatus? {
        files[relativePath]
    }
}
```

### 4.4 GitError

```swift
import Foundation

enum GitError: Error, Equatable {
    case notARepository
    case gitNotInstalled
    case commandFailed(String)
    case pushFailed(String)
    case pullFailed(String)
    case timedOut
    case repoNotAccessible(String)
    
    var localizedDescription: String {
        switch self {
        case .notARepository:
            return "Not a Git repository"
        case .gitNotInstalled:
            return "Git is not installed. Please install Xcode Command Line Tools or Git from git-scm.com"
        case .commandFailed(let msg):
            return "Git command failed: \(msg)"
        case .pushFailed(let msg):
            return "Push failed: \(msg)"
        case .pullFailed(let msg):
            return "Pull failed: \(msg)"
        case .timedOut:
            return "Operation timed out"
        case .repoNotAccessible(let path):
            return "Repository not accessible: \(path)"
        }
    }
}
```

### 4.5 PullResult

```swift
import Foundation

struct PullResult: Equatable {
    let success: Bool
    let conflicts: [String]
    let updatedFiles: [String]
    
    static func success(updatedFiles: [String] = []) -> PullResult {
        PullResult(success: true, conflicts: [], updatedFiles: updatedFiles)
    }
    
    static func conflicts(_ files: [String]) -> PullResult {
        PullResult(success: false, conflicts: files, updatedFiles: [])
    }
}
```

### 4.6 ConflictResolution

```swift
import Foundation

struct ConflictResolution: Equatable {
    let originalFile: String
    let backupFile: String
    let backupPath: String
}
```

### 4.7 AppSettings

```swift
import Foundation

struct AppSettings: Codable, Equatable {
    var notificationsEnabled: Bool
    var autoPushEnabled: Bool
    var hasCompletedOnboarding: Bool
    
    init(
        notificationsEnabled: Bool = true,
        autoPushEnabled: Bool = true,
        hasCompletedOnboarding: Bool = false
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.autoPushEnabled = autoPushEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}
```

### 4.8 BadgePriority

```swift
import Foundation

enum BadgePriority: Int, Comparable {
    case clean = 0
    case untracked = 1
    case staged = 2
    case modified = 3
    case conflict = 4
    
    static func < (lhs: BadgePriority, rhs: BadgePriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    var badgeIdentifier: String {
        switch self {
        case .clean: return ""
        case .untracked: return "Untracked"
        case .staged: return "Staged"
        case .modified: return "Modified"
        case .conflict: return "Conflict"
        }
    }
    
    init(from status: GitFileStatus) {
        if status.hasConflict {
            self = .conflict
        } else if status.isModified {
            self = .modified
        } else if status.isStaged {
            self = .staged
        } else if status.isUntracked {
            self = .untracked
        } else {
            self = .clean
        }
    }
}
```

---

## 5. Infrastructure

### 5.1 ShellGitExecutor

```swift
import Foundation

final class ShellGitExecutor: GitExecuting {
    
    private let gitPath: String?
    
    init() {
        // Find git at init time
        self.gitPath = Self.findGit()
    }
    
    func isGitAvailable() -> Bool {
        gitPath != nil
    }
    
    func execute(_ arguments: [String], in directory: String, timeout: TimeInterval) -> ShellResult {
        guard let gitPath = gitPath else {
            Log.git.error("Git not found")
            return .gitNotFound
        }
        
        Log.git.debug("Executing: git \(arguments.joined(separator: " ")) in \(directory)")
        
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: gitPath)
        process.arguments = arguments
        process.currentDirectoryURL = URL(fileURLWithPath: directory)
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        do {
            try process.run()
        } catch {
            Log.git.error("Failed to start process: \(error.localizedDescription)")
            return .failure(error.localizedDescription)
        }
        
        // Wait with timeout
        let semaphore = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in semaphore.signal() }
        
        let waitResult = semaphore.wait(timeout: .now() + timeout)
        
        if waitResult == .timedOut {
            Log.git.error("Command timed out after \(timeout)s")
            process.terminate()
            return .timedOut
        }
        
        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        
        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""
        
        let result = ShellResult(
            exitCode: process.terminationStatus,
            stdout: stdout,
            stderr: stderr
        )
        
        if !result.success {
            Log.git.warning("Command failed with exit code \(result.exitCode): \(stderr)")
        }
        
        return result
    }
    
    private static func findGit() -> String? {
        // Check common locations
        let candidates = [
            "/usr/bin/git",
            "/usr/local/bin/git",
            "/opt/homebrew/bin/git"
        ]
        
        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                Log.git.info("Found git at \(path)")
                return path
            }
        }
        
        // Try which
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["git"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !path.isEmpty {
                    Log.git.info("Found git via which: \(path)")
                    return path
                }
            }
        } catch {
            // Ignore
        }
        
        Log.git.error("Git not found in any known location")
        return nil
    }
}
```

### 5.2 AppleScriptDialogPresenter

```swift
import Foundation

final class AppleScriptDialogPresenter: DialogPresenting {
    
    func promptForCommitMessage() -> String? {
        let script = """
        tell application "System Events"
            activate
            set dialogResult to display dialog "Enter a commit message:" default answer "" buttons {"Cancel", "Commit"} default button "Commit" with title "Git-R-Done"
            if button returned of dialogResult is "Commit" then
                return text returned of dialogResult
            else
                return ""
            end if
        end tell
        """
        
        guard let result = runAppleScript(script), !result.isEmpty else {
            return nil
        }
        return result
    }
    
    func confirm(message: String, confirmButton: String) -> Bool {
        let escapedMessage = escapeForAppleScript(message)
        let escapedButton = escapeForAppleScript(confirmButton)
        let script = """
        tell application "System Events"
            activate
            set dialogResult to display dialog "\(escapedMessage)" buttons {"Cancel", "\(escapedButton)"} default button "\(escapedButton)" with title "Git-R-Done"
            return button returned of dialogResult
        end tell
        """
        
        guard let result = runAppleScript(script) else {
            return false
        }
        return result == confirmButton
    }
    
    func showConflictReport(resolutions: [ConflictResolution]) {
        var fileList = ""
        for r in resolutions {
            let escaped = escapeForAppleScript("\(r.originalFile) → \(r.backupFile)")
            fileList += "• \(escaped)\n"
        }
        
        let message = """
        Pull completed with conflicts.

        The following files were changed both locally and remotely. Your local versions have been saved:

        \(fileList)
        Please review and reconcile these files, then delete the conflict copies when you're done.
        """
        
        let escapedMessage = escapeForAppleScript(message)
        let script = """
        tell application "System Events"
            activate
            display dialog "\(escapedMessage)" buttons {"OK"} default button "OK" with title "Git-R-Done: Conflicts Resolved"
        end tell
        """
        
        _ = runAppleScript(script)
    }
    
    func showError(_ message: String) {
        let escapedMessage = escapeForAppleScript(message)
        let script = """
        tell application "System Events"
            activate
            display dialog "\(escapedMessage)" buttons {"OK"} default button "OK" with title "Git-R-Done: Error" with icon stop
        end tell
        """
        
        _ = runAppleScript(script)
    }
    
    func showInfo(_ message: String) {
        let escapedMessage = escapeForAppleScript(message)
        let script = """
        tell application "System Events"
            activate
            display dialog "\(escapedMessage)" buttons {"OK"} default button "OK" with title "Git-R-Done"
        end tell
        """
        
        _ = runAppleScript(script)
    }
    
    private func escapeForAppleScript(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
    
    private func runAppleScript(_ script: String) -> String? {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            Log.finder.error("AppleScript failed: \(error.localizedDescription)")
            return nil
        }
        
        guard process.terminationStatus == 0 else {
            return nil
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
```

### 5.3 UserNotificationSender

```swift
import Foundation
import UserNotifications

final class UserNotificationSender: NotificationSending {
    
    private let settingsStore: SettingsStore
    
    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                Log.finder.error("Notification permission error: \(error.localizedDescription)")
            }
            Log.finder.info("Notification permission granted: \(granted)")
        }
    }
    
    func send(title: String, body: String) {
        guard settingsStore.settings.notificationsEnabled else { return }
        postNotification(title: title, body: body)
    }
    
    func sendAlways(title: String, body: String) {
        postNotification(title: title, body: body)
    }
    
    private func postNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Log.finder.error("Failed to post notification: \(error.localizedDescription)")
            }
        }
    }
}
```

### 5.4 RepoConfiguration

```swift
import Foundation

final class RepoConfiguration {
    
    static let shared = RepoConfiguration()
    
    private let suiteName = "group.info.schuyler.gitrdone"
    private let reposKey = "watchedRepositories"
    private let queue = DispatchQueue(label: "info.schuyler.gitrdone.repoconfig")
    
    private var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName)!
    }
    
    private var _repositories: [WatchedRepository] = []
    
    var repositories: [WatchedRepository] {
        queue.sync { _repositories }
    }
    
    private init() {
        load()
    }
    
    func load() {
        queue.async { [self] in
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
    
    func add(_ repo: WatchedRepository) {
        queue.async { [self] in
            guard !_repositories.contains(where: { $0.path == repo.path }) else {
                Log.config.warning("Repository already exists: \(repo.path)")
                return
            }
            _repositories.append(repo)
            save()
            Log.config.info("Added repository: \(repo.path)")
            NotificationCenter.default.post(name: .repositoriesDidChange, object: nil)
        }
    }
    
    func remove(id: UUID) {
        queue.async { [self] in
            _repositories.removeAll { $0.id == id }
            save()
            Log.config.info("Removed repository with id: \(id)")
            NotificationCenter.default.post(name: .repositoriesDidChange, object: nil)
        }
    }
    
    func remove(path: String) {
        queue.async { [self] in
            _repositories.removeAll { $0.path == path }
            save()
            Log.config.info("Removed repository at path: \(path)")
            NotificationCenter.default.post(name: .repositoriesDidChange, object: nil)
        }
    }
    
    func contains(path: String) -> Bool {
        let normalized = (path as NSString).standardizingPath
        return queue.sync { _repositories.contains { $0.path == normalized } }
    }
    
    func validateRepositories(using gitOps: GitOperations) {
        queue.async { [self] in
            var removedAny = false
            _repositories.removeAll { repo in
                let exists = FileManager.default.fileExists(atPath: repo.path)
                let isRepo = exists && gitOps.isGitRepository(at: repo.path)
                if !isRepo {
                    Log.config.warning("Removing invalid repository: \(repo.path) (exists: \(exists))")
                    removedAny = true
                    return true
                }
                return false
            }
            
            if removedAny {
                save()
                NotificationCenter.default.post(name: .repositoriesDidChange, object: nil)
            }
        }
    }
    
    private func save() {
        // Must be called on queue
        guard let data = try? JSONEncoder().encode(_repositories) else {
            Log.config.error("Failed to encode repositories")
            return
        }
        defaults.set(data, forKey: reposKey)
    }
}

extension Notification.Name {
    static let repositoriesDidChange = Notification.Name("info.schuyler.gitrdone.repositoriesDidChange")
}
```

### 5.5 SettingsStore

```swift
import Foundation

final class SettingsStore {
    
    static let shared = SettingsStore()
    
    private let suiteName = "group.info.schuyler.gitrdone"
    private let settingsKey = "appSettings"
    private let queue = DispatchQueue(label: "info.schuyler.gitrdone.settings")
    
    private var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName)!
    }
    
    private var _settings: AppSettings
    
    var settings: AppSettings {
        get { queue.sync { _settings } }
        set {
            queue.async { [self] in
                _settings = newValue
                save()
            }
        }
    }
    
    private init() {
        if let data = defaults.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            _settings = settings
        } else {
            _settings = AppSettings()
        }
    }
    
    private func save() {
        guard let data = try? JSONEncoder().encode(_settings) else { return }
        defaults.set(data, forKey: settingsKey)
    }
}
```

### 5.6 StatusManager (Thread-Safe Async Status)

```swift
import Foundation
import FinderSync

final class StatusManager: StatusManaging {
    
    // MARK: - Queues
    
    /// Protects all mutable state
    private let stateQueue = DispatchQueue(label: "info.schuyler.gitrdone.status.state")
    
    /// Executes git commands off main thread
    private let gitQueue = DispatchQueue(label: "info.schuyler.gitrdone.status.git", qos: .userInitiated)
    
    // MARK: - State (protected by stateQueue)
    
    private var cache: [String: RepoStatus] = [:]
    private var requestedURLs: [String: Set<URL>] = [:]
    private var refreshInProgress: Set<String> = []
    
    // MARK: - Dependencies
    
    private let gitOps: GitOperations
    private let repoConfig: RepoConfiguration
    
    // MARK: - Callbacks
    
    var onBadgeUpdate: ((URL, String) -> Void)?
    
    // MARK: - Init
    
    init(gitOps: GitOperations, repoConfig: RepoConfiguration) {
        self.gitOps = gitOps
        self.repoConfig = repoConfig
    }
    
    // MARK: - Public Interface
    
    func getCachedStatus(for repoPath: String) -> RepoStatus? {
        stateQueue.sync { cache[repoPath] }
    }
    
    func trackURL(_ url: URL, for repoPath: String) {
        stateQueue.async {
            self.requestedURLs[repoPath, default: []].insert(url)
        }
    }
    
    func queueRefresh(for repoPath: String) {
        stateQueue.async {
            self._queueRefresh(for: repoPath)
        }
    }
    
    func invalidate(repoPath: String) {
        stateQueue.async {
            Log.status.debug("Invalidating cache for \(repoPath)")
            self.cache.removeValue(forKey: repoPath)
            self._queueRefresh(for: repoPath)
        }
    }
    
    func performAction(in repoPath: String, action: @escaping () -> Void) {
        gitQueue.async {
            action()
        }
    }
    
    // MARK: - Private (must be called on stateQueue)
    
    private func _queueRefresh(for repoPath: String) {
        // Already on stateQueue
        guard !refreshInProgress.contains(repoPath) else {
            Log.status.debug("Refresh already in progress for \(repoPath)")
            return
        }
        
        // Validate repo still exists
        guard FileManager.default.fileExists(atPath: repoPath) else {
            Log.status.warning("Repository no longer exists: \(repoPath)")
            repoConfig.remove(path: repoPath)
            return
        }
        
        refreshInProgress.insert(repoPath)
        Log.status.debug("Starting refresh for \(repoPath)")
        
        gitQueue.async { [weak self] in
            guard let self = self else { return }
            
            let result = self.gitOps.status(for: repoPath, timeout: 10)
            
            self.stateQueue.async {
                self.refreshInProgress.remove(repoPath)
                
                switch result {
                case .success(let status):
                    Log.status.info("Refreshed status for \(repoPath): \(status.files.count) files")
                    self.cache[repoPath] = status
                    self._pushBadges(for: repoPath, status: status)
                    
                case .failure(let error):
                    Log.status.error("Failed to refresh \(repoPath): \(error.localizedDescription)")
                    // Keep stale cache if we have one
                }
                
                // Clear tracked URLs after push (Finder will re-request if still visible)
                self.requestedURLs.removeValue(forKey: repoPath)
            }
        }
    }
    
    private func _pushBadges(for repoPath: String, status: RepoStatus) {
        // Already on stateQueue
        guard let urls = requestedURLs[repoPath] else { return }
        
        Log.status.debug("Pushing badges for \(urls.count) URLs in \(repoPath)")
        
        for url in urls {
            let relativePath = Self.makeRelativePath(url.path, relativeTo: repoPath)
            let badge = BadgeResolver.badge(for: relativePath, in: status, isDirectory: url.hasDirectoryPath)
            
            DispatchQueue.main.async { [weak self] in
                self?.onBadgeUpdate?(url, badge)
            }
        }
    }
    
    // MARK: - Helpers
    
    static func makeRelativePath(_ absolutePath: String, relativeTo repoPath: String) -> String {
        guard absolutePath.hasPrefix(repoPath) else { return absolutePath }
        var relative = String(absolutePath.dropFirst(repoPath.count))
        if relative.hasPrefix("/") {
            relative = String(relative.dropFirst())
        }
        return relative
    }
}
```

---

## 6. Git Operations

### 6.1 GitStatusParser

```swift
import Foundation

enum GitStatusParser {
    
    static func parse(_ output: String) -> [String: GitFileStatus] {
        var statuses: [String: GitFileStatus] = [:]
        
        for line in output.components(separatedBy: .newlines) where !line.isEmpty {
            if let status = parseLine(line) {
                statuses[status.path] = status
            }
        }
        
        return statuses
    }
    
    private static func parseLine(_ line: String) -> GitFileStatus? {
        guard let firstChar = line.first else { return nil }
        
        switch firstChar {
        case "1":
            return parseOrdinaryEntry(line)
        case "2":
            return parseRenamedEntry(line)
        case "u":
            return parseUnmergedEntry(line)
        case "?":
            return parseUntrackedEntry(line)
        case "!":
            return parseIgnoredEntry(line)
        default:
            return nil
        }
    }
    
    // Format: 1 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <path>
    private static func parseOrdinaryEntry(_ line: String) -> GitFileStatus? {
        let parts = line.split(separator: " ", maxSplits: 8, omittingEmptySubsequences: false)
        guard parts.count >= 9 else { return nil }
        
        let xy = String(parts[1])
        guard xy.count >= 2 else { return nil }
        
        let indexChar = xy[xy.startIndex]
        let worktreeChar = xy[xy.index(after: xy.startIndex)]
        let path = String(parts[8])
        
        return GitFileStatus(
            path: path,
            indexStatus: GitStatusCode(character: indexChar),
            worktreeStatus: GitStatusCode(character: worktreeChar)
        )
    }
    
    // Format: 2 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <X><score> <path><tab><origPath>
    private static func parseRenamedEntry(_ line: String) -> GitFileStatus? {
        let parts = line.split(separator: " ", maxSplits: 9, omittingEmptySubsequences: false)
        guard parts.count >= 10 else { return nil }
        
        let xy = String(parts[1])
        guard xy.count >= 2 else { return nil }
        
        let indexChar = xy[xy.startIndex]
        let worktreeChar = xy[xy.index(after: xy.startIndex)]
        
        var pathPart = String(parts[9])
        if let tabIndex = pathPart.firstIndex(of: "\t") {
            pathPart = String(pathPart[..<tabIndex])
        }
        
        return GitFileStatus(
            path: pathPart,
            indexStatus: GitStatusCode(character: indexChar),
            worktreeStatus: GitStatusCode(character: worktreeChar)
        )
    }
    
    // Format: u <XY> <sub> <m1> <m2> <m3> <mW> <h1> <h2> <h3> <path>
    private static func parseUnmergedEntry(_ line: String) -> GitFileStatus? {
        let parts = line.split(separator: " ", maxSplits: 10, omittingEmptySubsequences: false)
        guard parts.count >= 11 else { return nil }
        
        let path = String(parts[10])
        
        return GitFileStatus(
            path: path,
            indexStatus: .unmerged,
            worktreeStatus: .unmerged
        )
    }
    
    // Format: ? <path>
    private static func parseUntrackedEntry(_ line: String) -> GitFileStatus? {
        guard line.count > 2 else { return nil }
        let path = String(line.dropFirst(2))
        return GitFileStatus(path: path, indexStatus: .untracked, worktreeStatus: .untracked)
    }
    
    // Format: ! <path>
    private static func parseIgnoredEntry(_ line: String) -> GitFileStatus? {
        guard line.count > 2 else { return nil }
        let path = String(line.dropFirst(2))
        return GitFileStatus(path: path, indexStatus: .ignored, worktreeStatus: .ignored)
    }
}
```

### 6.2 GitOperations

```swift
import Foundation

final class GitOperations {
    
    private let executor: GitExecuting
    
    init(executor: GitExecuting = ShellGitExecutor()) {
        self.executor = executor
    }
    
    // MARK: - Validation
    
    func isGitAvailable() -> Bool {
        executor.isGitAvailable()
    }
    
    func isGitRepository(at path: String) -> Bool {
        let result = executor.execute(["rev-parse", "--git-dir"], in: path, timeout: 5)
        return result.success
    }
    
    func repositoryRoot(for path: String) -> String? {
        let result = executor.execute(["rev-parse", "--show-toplevel"], in: path, timeout: 5)
        guard result.success else { return nil }
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Status
    
    func status(for repoPath: String, timeout: TimeInterval = 30) -> Result<RepoStatus, GitError> {
        guard executor.isGitAvailable() else {
            return .failure(.gitNotInstalled)
        }
        
        let result = executor.execute(["status", "--porcelain=v2"], in: repoPath, timeout: timeout)
        
        if result == .timedOut {
            return .failure(.timedOut)
        }
        
        guard result.success else {
            return .failure(.commandFailed(result.stderr))
        }
        
        let files = GitStatusParser.parse(result.stdout)
        let status = RepoStatus(repoPath: repoPath, files: files, timestamp: Date())
        return .success(status)
    }

    /// Gets file content from a specific git ref (e.g., HEAD, origin/main)
    /// Used by ConflictHandler to extract clean local version during merge conflicts
    func getFileContent(ref: String, file: String, in repoPath: String) -> Result<Data, GitError> {
        let result = executor.execute(["show", "\(ref):\(file)"], in: repoPath)
        if result.success {
            if let data = result.stdout.data(using: .utf8) {
                return .success(data)
            } else {
                return .failure(.commandFailed("Failed to decode file content"))
            }
        } else {
            return .failure(.commandFailed(result.stderr))
        }
    }

    // MARK: - Staging
    
    func stage(file: String, in repoPath: String) -> Result<Void, GitError> {
        let result = executor.execute(["add", "--", file], in: repoPath)
        guard result.success else {
            return .failure(.commandFailed(result.stderr))
        }
        return .success(())
    }
    
    func unstage(file: String, in repoPath: String) -> Result<Void, GitError> {
        // Try restore --staged first (works for previously committed files)
        let result = executor.execute(["restore", "--staged", "--", file], in: repoPath)
        if result.success {
            return .success(())
        }

        // Fallback to rm --cached for newly added files that were never committed
        let rmResult = executor.execute(["rm", "--cached", "--", file], in: repoPath)
        guard rmResult.success else {
            return .failure(.commandFailed(result.stderr))
        }
        return .success(())
    }
    
    func stageAll(in repoPath: String) -> Result<Void, GitError> {
        let result = executor.execute(["add", "-A"], in: repoPath)
        guard result.success else {
            return .failure(.commandFailed(result.stderr))
        }
        return .success(())
    }
    
    // MARK: - Commit
    
    func commit(message: String, in repoPath: String) -> Result<Void, GitError> {
        let result = executor.execute(["commit", "-m", message], in: repoPath)
        guard result.success else {
            return .failure(.commandFailed(result.stderr))
        }
        return .success(())
    }
    
    func commitMerge(in repoPath: String) -> Result<Void, GitError> {
        let result = executor.execute(["commit", "--no-edit"], in: repoPath)
        guard result.success else {
            return .failure(.commandFailed(result.stderr))
        }
        return .success(())
    }
    
    // MARK: - Push/Pull
    
    func push(in repoPath: String, timeout: TimeInterval = 60) -> Result<Void, GitError> {
        let result = executor.execute(["push"], in: repoPath, timeout: timeout)
        
        if result == .timedOut {
            return .failure(.timedOut)
        }
        
        guard result.success else {
            return .failure(.pushFailed(result.stderr))
        }
        return .success(())
    }
    
    func pull(in repoPath: String, timeout: TimeInterval = 60) -> Result<PullResult, GitError> {
        let result = executor.execute(["pull"], in: repoPath, timeout: timeout)
        
        if result == .timedOut {
            return .failure(.timedOut)
        }
        
        // Check for conflicts
        if !result.success && result.stdout.contains("CONFLICT") {
            let conflicts = parseConflictedFiles(from: result.stdout)
            return .success(.conflicts(conflicts))
        }
        
        guard result.success else {
            return .failure(.pullFailed(result.stderr))
        }
        
        let updated = parseUpdatedFiles(from: result.stdout)
        return .success(.success(updatedFiles: updated))
    }
    
    // MARK: - Revert
    
    func revert(file: String, in repoPath: String) -> Result<Void, GitError> {
        let result = executor.execute(["restore", "--", file], in: repoPath)
        guard result.success else {
            return .failure(.commandFailed(result.stderr))
        }
        return .success(())
    }
    
    // MARK: - Conflict Resolution
    
    func acceptTheirs(file: String, in repoPath: String) -> Result<Void, GitError> {
        let checkout = executor.execute(["checkout", "--theirs", "--", file], in: repoPath)
        guard checkout.success else {
            return .failure(.commandFailed(checkout.stderr))
        }
        
        let add = executor.execute(["add", "--", file], in: repoPath)
        guard add.success else {
            return .failure(.commandFailed(add.stderr))
        }
        
        return .success(())
    }
    
    // MARK: - Parsing
    
    private func parseConflictedFiles(from output: String) -> [String] {
        var conflicts: [String] = []
        let pattern = #"CONFLICT \([^)]+\): Merge conflict in (.+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        
        let range = NSRange(output.startIndex..., in: output)
        let matches = regex.matches(in: output, range: range)
        
        for match in matches {
            if let range = Range(match.range(at: 1), in: output) {
                conflicts.append(String(output[range]))
            }
        }
        
        return conflicts
    }
    
    private func parseUpdatedFiles(from output: String) -> [String] {
        var files: [String] = []
        for line in output.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.contains("|") {
                if let file = trimmed.split(separator: "|").first {
                    files.append(file.trimmingCharacters(in: .whitespaces))
                }
            }
        }
        return files
    }
}
```

### 6.3 ConflictHandler

```swift
import Foundation

final class ConflictHandler {
    
    private let gitOps: GitOperations
    private let fileManager: FileManager
    
    init(gitOps: GitOperations, fileManager: FileManager = .default) {
        self.gitOps = gitOps
        self.fileManager = fileManager
    }
    
    func resolveConflicts(
        files: [String],
        in repoPath: String,
        date: Date = Date()
    ) -> Result<[ConflictResolution], Error> {
        let timestamp = formatTimestamp(date)
        var resolutions: [ConflictResolution] = []
        
        for file in files {
            do {
                let resolution = try resolveConflict(file: file, in: repoPath, timestamp: timestamp)
                resolutions.append(resolution)
                Log.conflict.info("Resolved conflict for \(file) → \(resolution.backupFile)")
            } catch {
                Log.conflict.error("Failed to resolve conflict for \(file): \(error.localizedDescription)")
                // Attempt to clean up any already-created backups
                cleanupResolutions(resolutions, in: repoPath)
                return .failure(error)
            }
        }
        
        return .success(resolutions)
    }
    
    func completeMerge(in repoPath: String) -> Result<Void, GitError> {
        gitOps.commitMerge(in: repoPath)
    }
    
    // MARK: - Private
    
    private func resolveConflict(file: String, in repoPath: String, timestamp: String) throws -> ConflictResolution {
        let absolutePath = (repoPath as NSString).appendingPathComponent(file)
        let tempPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(UUID().uuidString)

        // 1. Get clean local version from HEAD (not the conflicted working copy)
        // During a merge conflict, the working file contains conflict markers.
        // We use `git show HEAD:<file>` to get the clean local version.
        let contentResult = gitOps.getFileContent(ref: "HEAD", file: file, in: repoPath)
        guard case .success(let contentData) = contentResult else {
            throw GitError.commandFailed("Failed to get local version from HEAD")
        }
        try contentData.write(to: URL(fileURLWithPath: tempPath))

        // 2. Accept remote version
        let acceptResult = gitOps.acceptTheirs(file: file, in: repoPath)
        if case .failure(let error) = acceptResult {
            try? fileManager.removeItem(atPath: tempPath)
            throw error
        }
        
        // 3. Generate unique backup filename
        let backupName = generateUniqueBackupName(for: file, in: repoPath, timestamp: timestamp)
        let backupAbsolutePath = (repoPath as NSString).appendingPathComponent(backupName)
        
        // 4. Move local version back as backup
        try fileManager.moveItem(atPath: tempPath, toPath: backupAbsolutePath)
        
        return ConflictResolution(
            originalFile: file,
            backupFile: backupName,
            backupPath: backupAbsolutePath
        )
    }
    
    private func cleanupResolutions(_ resolutions: [ConflictResolution], in repoPath: String) {
        for resolution in resolutions {
            try? fileManager.removeItem(atPath: resolution.backupPath)
        }
    }
    
    /// Format: "2025-01-14 15.30.45" (colons replaced for filesystem safety)
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        return formatter.string(from: date)
    }
    
    /// Generate backup filename, ensuring uniqueness
    /// "document.xlsx" -> "document (Conflict 2025-01-14 15.30.45).xlsx"
    func generateBackupName(for file: String, timestamp: String) -> String {
        let url = URL(fileURLWithPath: file)
        let directory = (file as NSString).deletingLastPathComponent
        let name = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        
        let newName: String
        if ext.isEmpty {
            newName = "\(name) (Conflict \(timestamp))"
        } else {
            newName = "\(name) (Conflict \(timestamp)).\(ext)"
        }
        
        if directory.isEmpty || directory == "." {
            return newName
        } else {
            return (directory as NSString).appendingPathComponent(newName)
        }
    }
    
    /// Generate unique backup name, appending counter if necessary
    private func generateUniqueBackupName(for file: String, in repoPath: String, timestamp: String) -> String {
        let baseName = generateBackupName(for: file, timestamp: timestamp)
        let baseAbsolutePath = (repoPath as NSString).appendingPathComponent(baseName)
        
        if !fileManager.fileExists(atPath: baseAbsolutePath) {
            return baseName
        }
        
        // File exists, append counter
        let url = URL(fileURLWithPath: baseName)
        let directory = (baseName as NSString).deletingLastPathComponent
        let nameWithoutExt = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        
        for counter in 2...100 {
            let numberedName: String
            if ext.isEmpty {
                numberedName = "\(nameWithoutExt) \(counter)"
            } else {
                numberedName = "\(nameWithoutExt) \(counter).\(ext)"
            }
            
            let fullName: String
            if directory.isEmpty || directory == "." {
                fullName = numberedName
            } else {
                fullName = (directory as NSString).appendingPathComponent(numberedName)
            }
            
            let fullPath = (repoPath as NSString).appendingPathComponent(fullName)
            if !fileManager.fileExists(atPath: fullPath) {
                return fullName
            }
        }
        
        // Fallback with UUID (should never happen)
        Log.conflict.warning("Could not generate unique name after 100 attempts for \(file)")
        return generateBackupName(for: file, timestamp: "\(timestamp) \(UUID().uuidString.prefix(8))")
    }
}
```

---

## 7. Badge Resolution

### 7.1 BadgeResolver

```swift
import Foundation

enum BadgeResolver {
    
    static func badge(for relativePath: String, in status: RepoStatus?, isDirectory: Bool) -> String {
        guard let status = status else { return "" }
        
        if isDirectory {
            return directoryBadge(for: relativePath, in: status)
        } else {
            return fileBadge(for: relativePath, in: status)
        }
    }
    
    private static func fileBadge(for relativePath: String, in status: RepoStatus) -> String {
        guard let fileStatus = status.files[relativePath] else { return "" }
        return BadgePriority(from: fileStatus).badgeIdentifier
    }
    
    private static func directoryBadge(for relativePath: String, in status: RepoStatus) -> String {
        let prefix = relativePath.isEmpty ? "" : relativePath + "/"
        
        let worstPriority = status.files
            .filter { key, _ in
                if relativePath.isEmpty {
                    return true
                } else {
                    return key.hasPrefix(prefix)
                }
            }
            .map { _, value in BadgePriority(from: value) }
            .max() ?? .clean
        
        return worstPriority.badgeIdentifier
    }
}
```

---

## 8. FSEvents Watcher

### 8.1 FSEventsWatcher

```swift
import Foundation

final class FSEventsWatcher {
    
    private var stream: FSEventStreamRef?
    private let callback: () -> Void
    private var debounceWorkItem: DispatchWorkItem?
    private let debounceInterval: TimeInterval
    private let callbackQueue: DispatchQueue
    
    init(
        debounceInterval: TimeInterval = 0.5,
        callbackQueue: DispatchQueue = .main,
        callback: @escaping () -> Void
    ) {
        self.debounceInterval = debounceInterval
        self.callbackQueue = callbackQueue
        self.callback = callback
    }
    
    deinit {
        stop()
    }
    
    func watch(paths: [String]) {
        stop()
        
        guard !paths.isEmpty else { return }
        
        var context = FSEventStreamContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()
        
        let callback: FSEventStreamCallback = { _, info, numEvents, eventPaths, _, _ in
            guard let info = info else { return }
            let watcher = Unmanaged<FSEventsWatcher>.fromOpaque(info).takeUnretainedValue()
            watcher.handleEvent()
        }
        
        stream = FSEventStreamCreate(
            nil,
            callback,
            &context,
            paths as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            debounceInterval / 2,  // FSEvents has its own latency, we debounce additionally
            UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)
        )
        
        guard let stream = stream else {
            Log.status.error("Failed to create FSEventStream for \(paths)")
            return
        }
        
        FSEventStreamSetDispatchQueue(stream, DispatchQueue.global(qos: .utility))
        FSEventStreamStart(stream)
        
        Log.status.info("Started watching \(paths.count) paths")
    }
    
    func stop() {
        debounceWorkItem?.cancel()
        debounceWorkItem = nil
        
        guard let stream = stream else { return }
        
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
        
        Log.status.debug("Stopped FSEventStream")
    }
    
    private func handleEvent() {
        debounceWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.callback()
        }
        
        debounceWorkItem = workItem
        callbackQueue.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
    }
}
```

---

## 9. Finder Sync Extension

### 9.1 FinderSync

The extension is manually tested. We do not attempt to inject dependencies since the system instantiates this class.

```swift
import Cocoa
import FinderSync

class FinderSync: FIFinderSync {
    
    // MARK: - Dependencies (Production instances)
    
    private let gitOps = GitOperations()
    private let conflictHandler: ConflictHandler
    private let dialogs: DialogPresenting = AppleScriptDialogPresenter()
    private let notifications: NotificationSending
    private let repoConfig = RepoConfiguration.shared
    private let settingsStore = SettingsStore.shared
    private let statusManager: StatusManager
    
    // MARK: - State
    
    private var watchers: [String: FSEventsWatcher] = [:]
    
    // MARK: - Init
    
    override init() {
        self.conflictHandler = ConflictHandler(gitOps: gitOps)
        self.notifications = UserNotificationSender(settingsStore: settingsStore)
        self.statusManager = StatusManager(gitOps: gitOps, repoConfig: repoConfig)
        
        super.init()
        
        // Check Git availability
        if !gitOps.isGitAvailable() {
            Log.finder.error("Git is not available")
            // Will show error on first action
        }
        
        registerBadges()
        setupStatusManager()
        updateWatchedDirectories()
        
        // Validate repos on launch
        repoConfig.validateRepositories(using: gitOps)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(repositoriesChanged),
            name: .repositoriesDidChange,
            object: nil
        )
    }
    
    private func registerBadges() {
        let controller = FIFinderSyncController.default()
        
        controller.setBadgeImage(
            Self.badgeImage(systemName: "questionmark.circle.fill", color: .systemGray),
            label: "Untracked",
            forBadgeIdentifier: "Untracked"
        )
        
        controller.setBadgeImage(
            Self.badgeImage(systemName: "circle.fill", color: .systemOrange),
            label: "Modified",
            forBadgeIdentifier: "Modified"
        )
        
        controller.setBadgeImage(
            Self.badgeImage(systemName: "checkmark.circle.fill", color: .systemGreen),
            label: "Staged",
            forBadgeIdentifier: "Staged"
        )
        
        controller.setBadgeImage(
            Self.badgeImage(systemName: "exclamationmark.triangle.fill", color: .systemRed),
            label: "Conflict",
            forBadgeIdentifier: "Conflict"
        )
    }
    
    private static func badgeImage(systemName: String, color: NSColor) -> NSImage {
        let image = NSImage(systemSymbolName: systemName, accessibilityDescription: nil)!
        let config = NSImage.SymbolConfiguration(paletteColors: [color])
        return image.withSymbolConfiguration(config)!
    }
    
    private func setupStatusManager() {
        statusManager.onBadgeUpdate = { [weak self] url, badge in
            FIFinderSyncController.default().setBadgeIdentifier(badge, for: url)
        }
    }
    
    // MARK: - Configuration
    
    @objc private func repositoriesChanged() {
        Log.finder.info("Repositories changed, updating watched directories")
        updateWatchedDirectories()
    }
    
    private func updateWatchedDirectories() {
        let repos = repoConfig.repositories
        let urls = Set(repos.map { URL(fileURLWithPath: $0.path) })
        FIFinderSyncController.default().directoryURLs = urls
        
        let currentPaths = Set(watchers.keys)
        let newPaths = Set(repos.map { $0.path })
        
        // Remove old watchers
        for path in currentPaths.subtracting(newPaths) {
            watchers.removeValue(forKey: path)
            statusManager.invalidate(repoPath: path)
        }
        
        // Add new watchers
        for path in newPaths.subtracting(currentPaths) {
            let watcher = FSEventsWatcher { [weak self] in
                self?.statusManager.invalidate(repoPath: path)
            }
            watcher.watch(paths: [path])
            watchers[path] = watcher
        }
        
        Log.finder.info("Now watching \(newPaths.count) repositories")
    }
    
    // MARK: - FIFinderSync
    
    override func beginObservingDirectory(at url: URL) {
        if let repoPath = findRepoPath(containing: url.path) {
            statusManager.queueRefresh(for: repoPath)
        }
    }
    
    override func endObservingDirectory(at url: URL) {
        // Nothing needed
    }
    
    override func requestBadgeIdentifier(for url: URL) {
        guard let repoPath = findRepoPath(containing: url.path) else { return }
        
        // Track this URL for later updates
        statusManager.trackURL(url, for: repoPath)
        
        // Return cached value immediately if available
        if let cached = statusManager.getCachedStatus(for: repoPath) {
            let relativePath = StatusManager.makeRelativePath(url.path, relativeTo: repoPath)
            let badge = BadgeResolver.badge(for: relativePath, in: cached, isDirectory: url.hasDirectoryPath)
            FIFinderSyncController.default().setBadgeIdentifier(badge, for: url)
        }
        
        // Queue refresh (will push badge when ready)
        statusManager.queueRefresh(for: repoPath)
    }
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "Git-R-Done")
        
        guard let target = FIFinderSyncController.default().targetedURL(),
              let selected = FIFinderSyncController.default().selectedItemURLs()
        else {
            return menu
        }
        
        let isDirectory = target.hasDirectoryPath
        let isSingleFile = !isDirectory && selected.count == 1
        
        if isSingleFile {
            menu.addItem(withTitle: "Stage", action: #selector(stageAction(_:)), keyEquivalent: "")
            menu.addItem(withTitle: "Unstage", action: #selector(unstageAction(_:)), keyEquivalent: "")
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "Commit...", action: #selector(commitFileAction(_:)), keyEquivalent: "")
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "Revert", action: #selector(revertAction(_:)), keyEquivalent: "")
        } else {
            menu.addItem(withTitle: "Pull", action: #selector(pullAction(_:)), keyEquivalent: "")
            menu.addItem(withTitle: "Push", action: #selector(pushAction(_:)), keyEquivalent: "")
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "Commit All...", action: #selector(commitAllAction(_:)), keyEquivalent: "")
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "Refresh Status", action: #selector(refreshAction(_:)), keyEquivalent: "")
        }
        
        return menu
    }
    
    // MARK: - Actions
    
    private func ensureGitAvailable() -> Bool {
        guard gitOps.isGitAvailable() else {
            dialogs.showError(GitError.gitNotInstalled.localizedDescription)
            return false
        }
        return true
    }
    
    @objc func stageAction(_ sender: AnyObject) {
        guard ensureGitAvailable() else { return }
        guard let urls = FIFinderSyncController.default().selectedItemURLs() else { return }
        
        for url in urls {
            guard let repoPath = findRepoPath(containing: url.path) else { continue }
            let relativePath = StatusManager.makeRelativePath(url.path, relativeTo: repoPath)
            
            statusManager.performAction(in: repoPath) { [gitOps, statusManager] in
                _ = gitOps.stage(file: relativePath, in: repoPath)
                statusManager.invalidate(repoPath: repoPath)
            }
        }
    }
    
    @objc func unstageAction(_ sender: AnyObject) {
        guard ensureGitAvailable() else { return }
        guard let urls = FIFinderSyncController.default().selectedItemURLs() else { return }
        
        for url in urls {
            guard let repoPath = findRepoPath(containing: url.path) else { continue }
            let relativePath = StatusManager.makeRelativePath(url.path, relativeTo: repoPath)
            
            statusManager.performAction(in: repoPath) { [gitOps, statusManager] in
                _ = gitOps.unstage(file: relativePath, in: repoPath)
                statusManager.invalidate(repoPath: repoPath)
            }
        }
    }
    
    @objc func commitFileAction(_ sender: AnyObject) {
        guard ensureGitAvailable() else { return }
        guard let url = FIFinderSyncController.default().selectedItemURLs()?.first,
              let repoPath = findRepoPath(containing: url.path)
        else { return }
        
        let relativePath = StatusManager.makeRelativePath(url.path, relativeTo: repoPath)
        let repoName = URL(fileURLWithPath: repoPath).lastPathComponent
        
        guard let message = dialogs.promptForCommitMessage(), !message.isEmpty else { return }
        
        statusManager.performAction(in: repoPath) { [gitOps, settingsStore, notifications, dialogs, statusManager] in
            // Stage
            let stageResult = gitOps.stage(file: relativePath, in: repoPath)
            if case .failure(let error) = stageResult {
                DispatchQueue.main.async { dialogs.showError(error.localizedDescription) }
                return
            }
            
            // Commit
            let commitResult = gitOps.commit(message: message, in: repoPath)
            if case .failure(let error) = commitResult {
                DispatchQueue.main.async { dialogs.showError(error.localizedDescription) }
                return
            }
            
            // Push if enabled
            if settingsStore.settings.autoPushEnabled {
                let pushResult = gitOps.push(in: repoPath)
                switch pushResult {
                case .success:
                    notifications.send(title: "Git-R-Done", body: "Pushed to \(repoName)")
                case .failure(let error):
                    // Commit succeeded but push failed - notify clearly
                    notifications.sendAlways(
                        title: "Git-R-Done",
                        body: "Committed but push failed for \(repoName): \(error.localizedDescription). Changes are saved locally."
                    )
                }
            }
            
            statusManager.invalidate(repoPath: repoPath)
        }
    }
    
    @objc func commitAllAction(_ sender: AnyObject) {
        guard ensureGitAvailable() else { return }
        guard let url = FIFinderSyncController.default().targetedURL(),
              let repoPath = findRepoPath(containing: url.path)
        else { return }
        
        let repoName = URL(fileURLWithPath: repoPath).lastPathComponent
        
        guard let message = dialogs.promptForCommitMessage(), !message.isEmpty else { return }
        
        statusManager.performAction(in: repoPath) { [gitOps, settingsStore, notifications, dialogs, statusManager] in
            // Stage all
            let stageResult = gitOps.stageAll(in: repoPath)
            if case .failure(let error) = stageResult {
                DispatchQueue.main.async { dialogs.showError(error.localizedDescription) }
                return
            }
            
            // Commit
            let commitResult = gitOps.commit(message: message, in: repoPath)
            if case .failure(let error) = commitResult {
                DispatchQueue.main.async { dialogs.showError(error.localizedDescription) }
                return
            }
            
            // Push if enabled
            if settingsStore.settings.autoPushEnabled {
                let pushResult = gitOps.push(in: repoPath)
                switch pushResult {
                case .success:
                    notifications.send(title: "Git-R-Done", body: "Pushed to \(repoName)")
                case .failure(let error):
                    notifications.sendAlways(
                        title: "Git-R-Done",
                        body: "Committed but push failed for \(repoName): \(error.localizedDescription). Changes are saved locally."
                    )
                }
            }
            
            statusManager.invalidate(repoPath: repoPath)
        }
    }
    
    @objc func revertAction(_ sender: AnyObject) {
        guard ensureGitAvailable() else { return }
        guard let url = FIFinderSyncController.default().selectedItemURLs()?.first,
              let repoPath = findRepoPath(containing: url.path)
        else { return }
        
        let relativePath = StatusManager.makeRelativePath(url.path, relativeTo: repoPath)
        
        guard dialogs.confirm(
            message: "Are you sure you want to revert \"\(relativePath)\"?\n\nYour changes will be permanently lost.",
            confirmButton: "Revert"
        ) else { return }
        
        statusManager.performAction(in: repoPath) { [gitOps, statusManager] in
            _ = gitOps.revert(file: relativePath, in: repoPath)
            statusManager.invalidate(repoPath: repoPath)
        }
    }
    
    @objc func pullAction(_ sender: AnyObject) {
        guard ensureGitAvailable() else { return }
        guard let url = FIFinderSyncController.default().targetedURL(),
              let repoPath = findRepoPath(containing: url.path)
        else { return }
        
        let repoName = URL(fileURLWithPath: repoPath).lastPathComponent
        
        statusManager.performAction(in: repoPath) { [gitOps, conflictHandler, notifications, dialogs, statusManager] in
            let pullResult = gitOps.pull(in: repoPath)
            
            switch pullResult {
            case .success(let result):
                if result.conflicts.isEmpty {
                    if !result.updatedFiles.isEmpty {
                        let noun = result.updatedFiles.count == 1 ? "file" : "files"
                        notifications.send(
                            title: "Git-R-Done",
                            body: "Pulled \(result.updatedFiles.count) updated \(noun) from \(repoName)"
                        )
                    }
                } else {
                    // Handle conflicts
                    let resolveResult = conflictHandler.resolveConflicts(files: result.conflicts, in: repoPath)
                    
                    switch resolveResult {
                    case .success(let resolutions):
                        _ = conflictHandler.completeMerge(in: repoPath)
                        notifications.sendAlways(
                            title: "Git-R-Done",
                            body: "Conflicts in \(repoName) — local copies saved"
                        )
                        DispatchQueue.main.async {
                            dialogs.showConflictReport(resolutions: resolutions)
                        }
                        
                    case .failure(let error):
                        DispatchQueue.main.async {
                            dialogs.showError("Failed to resolve conflicts: \(error.localizedDescription)")
                        }
                    }
                }
                
            case .failure(let error):
                notifications.sendAlways(
                    title: "Git-R-Done",
                    body: "Failed to pull \(repoName): \(error.localizedDescription)"
                )
            }
            
            statusManager.invalidate(repoPath: repoPath)
        }
    }
    
    @objc func pushAction(_ sender: AnyObject) {
        guard ensureGitAvailable() else { return }
        guard let url = FIFinderSyncController.default().targetedURL(),
              let repoPath = findRepoPath(containing: url.path)
        else { return }
        
        let repoName = URL(fileURLWithPath: repoPath).lastPathComponent
        
        statusManager.performAction(in: repoPath) { [gitOps, notifications] in
            let result = gitOps.push(in: repoPath)
            
            switch result {
            case .success:
                notifications.send(title: "Git-R-Done", body: "Pushed to \(repoName)")
            case .failure(let error):
                notifications.sendAlways(
                    title: "Git-R-Done",
                    body: "Failed to push \(repoName): \(error.localizedDescription)"
                )
            }
        }
    }
    
    @objc func refreshAction(_ sender: AnyObject) {
        guard let url = FIFinderSyncController.default().targetedURL(),
              let repoPath = findRepoPath(containing: url.path)
        else { return }
        
        statusManager.invalidate(repoPath: repoPath)
    }
    
    // MARK: - Helpers
    
    private func findRepoPath(containing path: String) -> String? {
        for repo in repoConfig.repositories {
            if path == repo.path || path.hasPrefix(repo.path + "/") {
                return repo.path
            }
        }
        return nil
    }
}
```

---

## 10. Test Mocks

### 10.1 MockGitExecutor

```swift
import Foundation
@testable import Shared

final class MockGitExecutor: GitExecuting {
    
    var isGitAvailableResult = true
    var stubbedResults: [[String]: ShellResult] = [:]
    var executedCommands: [(arguments: [String], directory: String, timeout: TimeInterval)] = []
    
    func isGitAvailable() -> Bool {
        isGitAvailableResult
    }
    
    func execute(_ arguments: [String], in directory: String, timeout: TimeInterval) -> ShellResult {
        executedCommands.append((arguments, directory, timeout))
        
        // Look up by exact argument array (not joined string)
        if let result = stubbedResults[arguments] {
            return result
        }
        
        return .success()
    }
    
    func stub(_ arguments: [String], result: ShellResult) {
        stubbedResults[arguments] = result
    }
    
    func stubStatus(_ output: String) {
        stub(["status", "--porcelain=v2"], result: .success(output))
    }
    
    func stubPull(_ output: String, success: Bool = true) {
        stub(["pull"], result: success ? .success(output) : .failure(output))
    }
}
```

### 10.2 MockDialogPresenter

```swift
import Foundation
@testable import Shared

final class MockDialogPresenter: DialogPresenting {
    
    var commitMessageToReturn: String? = "Test commit"
    var confirmResult = true
    
    var promptedForCommitMessage = false
    var confirmMessages: [String] = []
    var conflictReportsShown: [[ConflictResolution]] = []
    var errorsShown: [String] = []
    var infosShown: [String] = []
    
    func promptForCommitMessage() -> String? {
        promptedForCommitMessage = true
        return commitMessageToReturn
    }
    
    func confirm(message: String, confirmButton: String) -> Bool {
        confirmMessages.append(message)
        return confirmResult
    }
    
    func showConflictReport(resolutions: [ConflictResolution]) {
        conflictReportsShown.append(resolutions)
    }
    
    func showError(_ message: String) {
        errorsShown.append(message)
    }
    
    func showInfo(_ message: String) {
        infosShown.append(message)
    }
}
```

### 10.3 MockNotificationSender

```swift
import Foundation
@testable import Shared

final class MockNotificationSender: NotificationSending {
    
    var sentNotifications: [(title: String, body: String, always: Bool)] = []
    
    func send(title: String, body: String) {
        sentNotifications.append((title, body, false))
    }
    
    func sendAlways(title: String, body: String) {
        sentNotifications.append((title, body, true))
    }
}
```

### 10.4 MockStatusManager

```swift
import Foundation
@testable import Shared

final class MockStatusManager: StatusManaging {
    
    var cachedStatuses: [String: RepoStatus] = [:]
    var trackedURLs: [(URL, String)] = []
    var refreshedRepoPaths: [String] = []
    var invalidatedRepoPaths: [String] = []
    var performedActions: [String] = []
    
    var onBadgeUpdate: ((URL, String) -> Void)?
    
    func getCachedStatus(for repoPath: String) -> RepoStatus? {
        cachedStatuses[repoPath]
    }
    
    func trackURL(_ url: URL, for repoPath: String) {
        trackedURLs.append((url, repoPath))
    }
    
    func queueRefresh(for repoPath: String) {
        refreshedRepoPaths.append(repoPath)
    }
    
    func invalidate(repoPath: String) {
        invalidatedRepoPaths.append(repoPath)
    }
    
    func performAction(in repoPath: String, action: @escaping () -> Void) {
        performedActions.append(repoPath)
        action()  // Execute synchronously for tests
    }
}
```

---

## 11. Unit Tests

### 11.1 GitStatusParserTests

```swift
import XCTest
@testable import Shared

final class GitStatusParserTests: XCTestCase {
    
    // MARK: - Ordinary Entries
    
    func test_parseModifiedUnstaged() {
        let output = "1 .M N... 100644 100644 100644 abc123 def456 README.md"
        let result = GitStatusParser.parse(output)
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result["README.md"]?.indexStatus, .clean)
        XCTAssertEqual(result["README.md"]?.worktreeStatus, .modified)
        XCTAssertTrue(result["README.md"]?.isModified ?? false)
        XCTAssertFalse(result["README.md"]?.isStaged ?? true)
    }
    
    func test_parseModifiedStaged() {
        let output = "1 M. N... 100644 100644 100644 abc123 def456 README.md"
        let result = GitStatusParser.parse(output)
        
        XCTAssertEqual(result["README.md"]?.indexStatus, .modified)
        XCTAssertEqual(result["README.md"]?.worktreeStatus, .clean)
        XCTAssertTrue(result["README.md"]?.isStaged ?? false)
    }
    
    func test_parseStagedAndModified() {
        let output = "1 MM N... 100644 100644 100644 abc123 def456 README.md"
        let result = GitStatusParser.parse(output)
        
        XCTAssertTrue(result["README.md"]?.isStaged ?? false)
        XCTAssertTrue(result["README.md"]?.isModified ?? false)
    }
    
    func test_parseAdded() {
        let output = "1 A. N... 000000 100644 100644 0000000 abc123 newfile.txt"
        let result = GitStatusParser.parse(output)
        
        XCTAssertEqual(result["newfile.txt"]?.indexStatus, .added)
        XCTAssertTrue(result["newfile.txt"]?.isStaged ?? false)
    }
    
    func test_parseDeleted() {
        let output = "1 D. N... 100644 000000 000000 abc123 0000000 deleted.txt"
        let result = GitStatusParser.parse(output)
        
        XCTAssertEqual(result["deleted.txt"]?.indexStatus, .deleted)
    }
    
    // MARK: - Untracked
    
    func test_parseUntracked() {
        let output = "? newfile.txt"
        let result = GitStatusParser.parse(output)
        
        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result["newfile.txt"]?.isUntracked ?? false)
    }
    
    func test_parseUntrackedWithSpaces() {
        let output = "? path/to/my file.txt"
        let result = GitStatusParser.parse(output)
        
        XCTAssertTrue(result["path/to/my file.txt"]?.isUntracked ?? false)
    }
    
    // MARK: - Ignored
    
    func test_parseIgnored() {
        let output = "! ignored.log"
        let result = GitStatusParser.parse(output)
        
        XCTAssertEqual(result["ignored.log"]?.indexStatus, .ignored)
    }
    
    // MARK: - Unmerged
    
    func test_parseUnmerged() {
        let output = "u UU N... 100644 100644 100644 100644 abc123 def456 ghi789 conflicted.txt"
        let result = GitStatusParser.parse(output)
        
        XCTAssertTrue(result["conflicted.txt"]?.hasConflict ?? false)
    }
    
    // MARK: - Renamed
    
    func test_parseRenamed() {
        let output = "2 R. N... 100644 100644 100644 abc123 def456 R100 new.txt\told.txt"
        let result = GitStatusParser.parse(output)
        
        XCTAssertEqual(result["new.txt"]?.indexStatus, .renamed)
    }
    
    // MARK: - Multiple Files
    
    func test_parseMultiple() {
        let output = """
        1 .M N... 100644 100644 100644 abc123 def456 modified.txt
        1 A. N... 000000 100644 100644 0000000 abc123 added.txt
        ? untracked.txt
        """
        let result = GitStatusParser.parse(output)
        
        XCTAssertEqual(result.count, 3)
    }
    
    // MARK: - Edge Cases
    
    func test_parseEmpty() {
        let result = GitStatusParser.parse("")
        XCTAssertTrue(result.isEmpty)
    }
    
    func test_parseWhitespaceOnly() {
        let result = GitStatusParser.parse("   \n\n   ")
        XCTAssertTrue(result.isEmpty)
    }
    
    func test_parseInvalidLine() {
        let result = GitStatusParser.parse("X invalid")
        XCTAssertTrue(result.isEmpty)
    }
}
```

### 11.2 GitOperationsTests

```swift
import XCTest
@testable import Shared

final class GitOperationsTests: XCTestCase {
    
    var mockExecutor: MockGitExecutor!
    var gitOps: GitOperations!
    
    override func setUp() {
        super.setUp()
        mockExecutor = MockGitExecutor()
        gitOps = GitOperations(executor: mockExecutor)
    }
    
    // MARK: - Availability
    
    func test_isGitAvailable_delegatesToExecutor() {
        mockExecutor.isGitAvailableResult = false
        XCTAssertFalse(gitOps.isGitAvailable())
        
        mockExecutor.isGitAvailableResult = true
        XCTAssertTrue(gitOps.isGitAvailable())
    }
    
    func test_status_returnsGitNotInstalled_whenUnavailable() {
        mockExecutor.isGitAvailableResult = false
        
        let result = gitOps.status(for: "/repo")
        
        guard case .failure(let error) = result else {
            XCTFail("Expected failure")
            return
        }
        XCTAssertEqual(error, .gitNotInstalled)
    }
    
    // MARK: - isGitRepository
    
    func test_isGitRepository_returnsTrue_whenSuccess() {
        mockExecutor.stub(["rev-parse", "--git-dir"], result: .success(".git"))
        
        XCTAssertTrue(gitOps.isGitRepository(at: "/path/to/repo"))
    }
    
    func test_isGitRepository_returnsFalse_whenFailure() {
        mockExecutor.stub(["rev-parse", "--git-dir"], result: .failure("fatal: not a git repository"))
        
        XCTAssertFalse(gitOps.isGitRepository(at: "/path/to/not-repo"))
    }
    
    // MARK: - status
    
    func test_status_parsesOutput() {
        mockExecutor.stubStatus("? untracked.txt\n1 .M N... 100644 100644 100644 abc def modified.txt")
        
        let result = gitOps.status(for: "/repo")
        
        guard case .success(let status) = result else {
            XCTFail("Expected success")
            return
        }
        
        XCTAssertEqual(status.files.count, 2)
    }
    
    func test_status_returnsTimedOut() {
        mockExecutor.stub(["status", "--porcelain=v2"], result: .timedOut)
        
        let result = gitOps.status(for: "/repo")
        
        guard case .failure(let error) = result else {
            XCTFail("Expected failure")
            return
        }
        XCTAssertEqual(error, .timedOut)
    }
    
    // MARK: - stage
    
    func test_stage_executesCorrectCommand() {
        mockExecutor.stub(["add", "--", "file.txt"], result: .success())
        
        _ = gitOps.stage(file: "file.txt", in: "/repo")
        
        XCTAssertEqual(mockExecutor.executedCommands.count, 1)
        XCTAssertEqual(mockExecutor.executedCommands[0].arguments, ["add", "--", "file.txt"])
        XCTAssertEqual(mockExecutor.executedCommands[0].directory, "/repo")
    }
    
    // MARK: - commit
    
    func test_commit_executesWithMessage() {
        mockExecutor.stub(["commit", "-m", "My commit message"], result: .success())
        
        _ = gitOps.commit(message: "My commit message", in: "/repo")
        
        XCTAssertEqual(mockExecutor.executedCommands.last?.arguments, ["commit", "-m", "My commit message"])
    }
    
    // MARK: - pull
    
    func test_pull_returnsSuccess() {
        mockExecutor.stubPull(" file1.txt | 5 +++++\n file2.txt | 3 +++")
        
        let result = gitOps.pull(in: "/repo")
        
        guard case .success(let pullResult) = result else {
            XCTFail("Expected success")
            return
        }
        
        XCTAssertTrue(pullResult.success)
        XCTAssertEqual(pullResult.updatedFiles, ["file1.txt", "file2.txt"])
    }
    
    func test_pull_detectsConflicts() {
        mockExecutor.stub(["pull"], result: ShellResult(
            exitCode: 1,
            stdout: "CONFLICT (content): Merge conflict in file1.txt\nCONFLICT (content): Merge conflict in file2.txt",
            stderr: ""
        ))
        
        let result = gitOps.pull(in: "/repo")
        
        guard case .success(let pullResult) = result else {
            XCTFail("Expected success with conflicts")
            return
        }
        
        XCTAssertFalse(pullResult.success)
        XCTAssertEqual(pullResult.conflicts, ["file1.txt", "file2.txt"])
    }
    
    // MARK: - acceptTheirs
    
    func test_acceptTheirs_executesCheckoutThenAdd() {
        mockExecutor.stub(["checkout", "--theirs", "--", "file.txt"], result: .success())
        mockExecutor.stub(["add", "--", "file.txt"], result: .success())
        
        let result = gitOps.acceptTheirs(file: "file.txt", in: "/repo")
        
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(mockExecutor.executedCommands.count, 2)
        XCTAssertEqual(mockExecutor.executedCommands[0].arguments, ["checkout", "--theirs", "--", "file.txt"])
        XCTAssertEqual(mockExecutor.executedCommands[1].arguments, ["add", "--", "file.txt"])
    }
}

extension Result {
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}
```

### 11.3 ConflictHandlerTests

```swift
import XCTest
@testable import Shared

final class ConflictHandlerTests: XCTestCase {
    
    var mockExecutor: MockGitExecutor!
    var gitOps: GitOperations!
    var handler: ConflictHandler!
    var tempDir: String!
    
    override func setUp() {
        super.setUp()
        mockExecutor = MockGitExecutor()
        gitOps = GitOperations(executor: mockExecutor)
        handler = ConflictHandler(gitOps: gitOps)
        
        // Create temp directory for file operations
        tempDir = (NSTemporaryDirectory() as NSString).appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        if let tempDir = tempDir {
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        super.tearDown()
    }
    
    // MARK: - generateBackupName
    
    func test_generateBackupName_simple() {
        let result = handler.generateBackupName(for: "document.xlsx", timestamp: "2025-01-14 15.30.45")
        XCTAssertEqual(result, "document (Conflict 2025-01-14 15.30.45).xlsx")
    }
    
    func test_generateBackupName_withSubdirectory() {
        let result = handler.generateBackupName(for: "path/to/document.xlsx", timestamp: "2025-01-14 15.30.45")
        XCTAssertEqual(result, "path/to/document (Conflict 2025-01-14 15.30.45).xlsx")
    }
    
    func test_generateBackupName_noExtension() {
        let result = handler.generateBackupName(for: "Makefile", timestamp: "2025-01-14 15.30.45")
        XCTAssertEqual(result, "Makefile (Conflict 2025-01-14 15.30.45)")
    }
    
    func test_generateBackupName_multipleExtensions() {
        let result = handler.generateBackupName(for: "archive.tar.gz", timestamp: "2025-01-14 15.30.45")
        XCTAssertEqual(result, "archive.tar (Conflict 2025-01-14 15.30.45).gz")
    }
    
    // MARK: - resolveConflicts
    
    func test_resolveConflicts_createsBackup() {
        // Setup: Create a file to conflict (so fileExists check passes)
        let filePath = (tempDir as NSString).appendingPathComponent("test.txt")
        try! "local content".write(toFile: filePath, atomically: true, encoding: .utf8)

        // Stub git show HEAD:test.txt to return the clean local content
        mockExecutor.stub(["show", "HEAD:test.txt"], result: .success("local content"))
        mockExecutor.stub(["checkout", "--theirs", "--", "test.txt"], result: .success())
        mockExecutor.stub(["add", "--", "test.txt"], result: .success())
        
        let fixedDate = Date(timeIntervalSince1970: 1736870400) // 2025-01-14 12:00:00 UTC
        
        let result = handler.resolveConflicts(files: ["test.txt"], in: tempDir, date: fixedDate)
        
        guard case .success(let resolutions) = result else {
            XCTFail("Expected success")
            return
        }
        
        XCTAssertEqual(resolutions.count, 1)
        XCTAssertEqual(resolutions[0].originalFile, "test.txt")
        XCTAssertTrue(resolutions[0].backupFile.contains("Conflict"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: resolutions[0].backupPath))
    }
    
    func test_resolveConflicts_handlesMultipleConflictsOnSameDay() {
        // Setup: Create files (so fileExists checks pass)
        let file1Path = (tempDir as NSString).appendingPathComponent("test.txt")
        let file2Path = (tempDir as NSString).appendingPathComponent("test2.txt")
        try! "content1".write(toFile: file1Path, atomically: true, encoding: .utf8)
        try! "content2".write(toFile: file2Path, atomically: true, encoding: .utf8)

        // Stub git show commands to return clean local content
        mockExecutor.stub(["show", "HEAD:test.txt"], result: .success("content1"))
        mockExecutor.stub(["show", "HEAD:test2.txt"], result: .success("content2"))
        mockExecutor.stub(["checkout", "--theirs", "--", "test.txt"], result: .success())
        mockExecutor.stub(["add", "--", "test.txt"], result: .success())
        mockExecutor.stub(["checkout", "--theirs", "--", "test2.txt"], result: .success())
        mockExecutor.stub(["add", "--", "test2.txt"], result: .success())
        
        let result = handler.resolveConflicts(files: ["test.txt", "test2.txt"], in: tempDir)
        
        guard case .success(let resolutions) = result else {
            XCTFail("Expected success")
            return
        }
        
        XCTAssertEqual(resolutions.count, 2)
        // Both should have unique names (timestamp includes time)
        XCTAssertNotEqual(resolutions[0].backupPath, resolutions[1].backupPath)
    }
}
```

### 11.4 BadgeResolverTests

```swift
import XCTest
@testable import Shared

final class BadgeResolverTests: XCTestCase {
    
    // MARK: - File Badges
    
    func test_fileBadge_nilStatus() {
        let result = BadgeResolver.badge(for: "file.txt", in: nil, isDirectory: false)
        XCTAssertEqual(result, "")
    }
    
    func test_fileBadge_unknownFile() {
        let status = RepoStatus(repoPath: "/repo", files: [:], timestamp: Date())
        let result = BadgeResolver.badge(for: "unknown.txt", in: status, isDirectory: false)
        XCTAssertEqual(result, "")
    }
    
    func test_fileBadge_untracked() {
        let status = RepoStatus(
            repoPath: "/repo",
            files: ["file.txt": GitFileStatus(path: "file.txt", indexStatus: .untracked, worktreeStatus: .untracked)],
            timestamp: Date()
        )
        
        let result = BadgeResolver.badge(for: "file.txt", in: status, isDirectory: false)
        XCTAssertEqual(result, "Untracked")
    }
    
    func test_fileBadge_modified() {
        let status = RepoStatus(
            repoPath: "/repo",
            files: ["file.txt": GitFileStatus(path: "file.txt", indexStatus: .clean, worktreeStatus: .modified)],
            timestamp: Date()
        )
        
        let result = BadgeResolver.badge(for: "file.txt", in: status, isDirectory: false)
        XCTAssertEqual(result, "Modified")
    }
    
    func test_fileBadge_staged() {
        let status = RepoStatus(
            repoPath: "/repo",
            files: ["file.txt": GitFileStatus(path: "file.txt", indexStatus: .added, worktreeStatus: .clean)],
            timestamp: Date()
        )
        
        let result = BadgeResolver.badge(for: "file.txt", in: status, isDirectory: false)
        XCTAssertEqual(result, "Staged")
    }
    
    func test_fileBadge_conflict() {
        let status = RepoStatus(
            repoPath: "/repo",
            files: ["file.txt": GitFileStatus(path: "file.txt", indexStatus: .unmerged, worktreeStatus: .unmerged)],
            timestamp: Date()
        )
        
        let result = BadgeResolver.badge(for: "file.txt", in: status, isDirectory: false)
        XCTAssertEqual(result, "Conflict")
    }
    
    // MARK: - Directory Badges
    
    func test_directoryBadge_empty() {
        let status = RepoStatus(
            repoPath: "/repo",
            files: ["other/file.txt": GitFileStatus(path: "other/file.txt", indexStatus: .modified, worktreeStatus: .clean)],
            timestamp: Date()
        )
        
        let result = BadgeResolver.badge(for: "subdir", in: status, isDirectory: true)
        XCTAssertEqual(result, "")
    }
    
    func test_directoryBadge_aggregatesWorstStatus() {
        let status = RepoStatus(
            repoPath: "/repo",
            files: [
                "subdir/clean.txt": GitFileStatus(path: "subdir/clean.txt", indexStatus: .clean, worktreeStatus: .clean),
                "subdir/modified.txt": GitFileStatus(path: "subdir/modified.txt", indexStatus: .clean, worktreeStatus: .modified),
                "subdir/untracked.txt": GitFileStatus(path: "subdir/untracked.txt", indexStatus: .untracked, worktreeStatus: .untracked)
            ],
            timestamp: Date()
        )
        
        let result = BadgeResolver.badge(for: "subdir", in: status, isDirectory: true)
        XCTAssertEqual(result, "Modified")
    }
    
    func test_directoryBadge_conflictWins() {
        let status = RepoStatus(
            repoPath: "/repo",
            files: [
                "subdir/modified.txt": GitFileStatus(path: "subdir/modified.txt", indexStatus: .clean, worktreeStatus: .modified),
                "subdir/conflict.txt": GitFileStatus(path: "subdir/conflict.txt", indexStatus: .unmerged, worktreeStatus: .unmerged)
            ],
            timestamp: Date()
        )
        
        let result = BadgeResolver.badge(for: "subdir", in: status, isDirectory: true)
        XCTAssertEqual(result, "Conflict")
    }
    
    func test_rootDirectoryBadge() {
        let status = RepoStatus(
            repoPath: "/repo",
            files: [
                "file1.txt": GitFileStatus(path: "file1.txt", indexStatus: .untracked, worktreeStatus: .untracked),
                "subdir/file2.txt": GitFileStatus(path: "subdir/file2.txt", indexStatus: .clean, worktreeStatus: .modified)
            ],
            timestamp: Date()
        )
        
        let result = BadgeResolver.badge(for: "", in: status, isDirectory: true)
        XCTAssertEqual(result, "Modified")
    }
}
```

### 11.5 StatusManagerTests

```swift
import XCTest
@testable import Shared

final class StatusManagerTests: XCTestCase {
    
    // MARK: - makeRelativePath
    
    func test_makeRelativePath_basic() {
        let result = StatusManager.makeRelativePath("/repo/subdir/file.txt", relativeTo: "/repo")
        XCTAssertEqual(result, "subdir/file.txt")
    }
    
    func test_makeRelativePath_rootFile() {
        let result = StatusManager.makeRelativePath("/repo/file.txt", relativeTo: "/repo")
        XCTAssertEqual(result, "file.txt")
    }
    
    func test_makeRelativePath_notRelated() {
        let result = StatusManager.makeRelativePath("/other/file.txt", relativeTo: "/repo")
        XCTAssertEqual(result, "/other/file.txt")
    }
    
    func test_makeRelativePath_exactMatch() {
        let result = StatusManager.makeRelativePath("/repo", relativeTo: "/repo")
        XCTAssertEqual(result, "")
    }
}
```

---

## 12. Integration Tests

### 12.1 GitOperationsIntegrationTests

```swift
import XCTest
@testable import Shared

final class GitOperationsIntegrationTests: XCTestCase {
    
    var testRepoPath: String!
    var gitOps: GitOperations!
    
    override func setUp() {
        super.setUp()
        gitOps = GitOperations(executor: ShellGitExecutor())
        
        guard gitOps.isGitAvailable() else {
            XCTFail("Git not available")
            return
        }
        
        testRepoPath = createTestRepository()
    }
    
    override func tearDown() {
        if let path = testRepoPath {
            try? FileManager.default.removeItem(atPath: path)
        }
        super.tearDown()
    }
    
    private func createTestRepository() -> String {
        let tempDir = NSTemporaryDirectory()
        let repoPath = (tempDir as NSString).appendingPathComponent(UUID().uuidString)
        
        try? FileManager.default.createDirectory(atPath: repoPath, withIntermediateDirectories: true)
        
        let executor = ShellGitExecutor()
        _ = executor.execute(["init"], in: repoPath, timeout: 10)
        _ = executor.execute(["config", "user.email", "test@example.com"], in: repoPath, timeout: 5)
        _ = executor.execute(["config", "user.name", "Test User"], in: repoPath, timeout: 5)
        // Configure merge strategy for pull (required by git 2.27+)
        _ = executor.execute(["config", "pull.rebase", "false"], in: repoPath, timeout: 5)

        return repoPath
    }
    
    private func createFile(_ name: String, content: String = "test") {
        let path = (testRepoPath as NSString).appendingPathComponent(name)
        let dir = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? content.write(toFile: path, atomically: true, encoding: .utf8)
    }
    
    // MARK: - Tests
    
    func test_isGitRepository() {
        XCTAssertTrue(gitOps.isGitRepository(at: testRepoPath))
        XCTAssertFalse(gitOps.isGitRepository(at: NSTemporaryDirectory()))
    }
    
    func test_status_detectsUntracked() {
        createFile("untracked.txt")
        
        let result = gitOps.status(for: testRepoPath)
        guard case .success(let status) = result else {
            XCTFail("Expected success")
            return
        }
        
        XCTAssertTrue(status.files["untracked.txt"]?.isUntracked ?? false)
    }
    
    func test_stageAndStatus() {
        createFile("staged.txt")
        _ = gitOps.stage(file: "staged.txt", in: testRepoPath)
        
        let result = gitOps.status(for: testRepoPath)
        guard case .success(let status) = result else {
            XCTFail("Expected success")
            return
        }
        
        XCTAssertTrue(status.files["staged.txt"]?.isStaged ?? false)
    }
    
    func test_fullWorkflow() {
        // 1. Create and verify untracked
        createFile("workflow.txt", content: "initial")
        var status = try! gitOps.status(for: testRepoPath).get()
        XCTAssertTrue(status.files["workflow.txt"]?.isUntracked ?? false)
        
        // 2. Stage and verify
        _ = gitOps.stage(file: "workflow.txt", in: testRepoPath)
        status = try! gitOps.status(for: testRepoPath).get()
        XCTAssertTrue(status.files["workflow.txt"]?.isStaged ?? false)
        
        // 3. Commit and verify clean
        _ = gitOps.commit(message: "Add workflow.txt", in: testRepoPath)
        status = try! gitOps.status(for: testRepoPath).get()
        XCTAssertNil(status.files["workflow.txt"])
        
        // 4. Modify and verify
        createFile("workflow.txt", content: "modified")
        status = try! gitOps.status(for: testRepoPath).get()
        XCTAssertTrue(status.files["workflow.txt"]?.isModified ?? false)
    }
}
```

### 12.2 ConflictResolutionIntegrationTests

```swift
import XCTest
@testable import Shared

final class ConflictResolutionIntegrationTests: XCTestCase {
    
    var testRepoPath: String!
    var gitOps: GitOperations!
    var conflictHandler: ConflictHandler!
    
    override func setUp() {
        super.setUp()
        gitOps = GitOperations(executor: ShellGitExecutor())
        conflictHandler = ConflictHandler(gitOps: gitOps)
        
        guard gitOps.isGitAvailable() else {
            XCTFail("Git not available")
            return
        }
        
        testRepoPath = createTestRepository()
    }
    
    override func tearDown() {
        if let path = testRepoPath {
            try? FileManager.default.removeItem(atPath: path)
        }
        super.tearDown()
    }
    
    private func createTestRepository() -> String {
        let tempDir = NSTemporaryDirectory()
        let repoPath = (tempDir as NSString).appendingPathComponent(UUID().uuidString)
        
        try? FileManager.default.createDirectory(atPath: repoPath, withIntermediateDirectories: true)
        
        let executor = ShellGitExecutor()
        _ = executor.execute(["init"], in: repoPath, timeout: 10)
        _ = executor.execute(["config", "user.email", "test@example.com"], in: repoPath, timeout: 5)
        _ = executor.execute(["config", "user.name", "Test User"], in: repoPath, timeout: 5)
        // Configure merge strategy for pull (required by git 2.27+)
        _ = executor.execute(["config", "pull.rebase", "false"], in: repoPath, timeout: 5)

        return repoPath
    }
    
    private func createFile(_ name: String, content: String) {
        let path = (testRepoPath as NSString).appendingPathComponent(name)
        try? content.write(toFile: path, atomically: true, encoding: .utf8)
    }
    
    private func readFile(_ name: String) -> String? {
        let path = (testRepoPath as NSString).appendingPathComponent(name)
        return try? String(contentsOfFile: path, encoding: .utf8)
    }
    
    // MARK: - Tests
    
    func test_resolveConflicts_preservesLocalContent() {
        // Setup: Create initial committed file
        createFile("document.txt", content: "original")
        _ = gitOps.stage(file: "document.txt", in: testRepoPath)
        _ = gitOps.commit(message: "Initial", in: testRepoPath)
        
        // Simulate local changes
        createFile("document.txt", content: "local changes")
        
        // Resolve as if "theirs" won
        // (In real scenario, git pull would create this state)
        let result = conflictHandler.resolveConflicts(
            files: ["document.txt"],
            in: testRepoPath
        )
        
        guard case .success(let resolutions) = result else {
            XCTFail("Expected success: \(result)")
            return
        }
        
        // Verify backup was created with local content
        XCTAssertEqual(resolutions.count, 1)
        let backupContent = readFile(resolutions[0].backupFile)
        XCTAssertEqual(backupContent, "local changes")
    }
    
    func test_resolveConflicts_uniqueNamesForMultipleSameDay() {
        // Create two files
        createFile("file1.txt", content: "content1")
        createFile("file2.txt", content: "content2")
        _ = gitOps.stage(file: "file1.txt", in: testRepoPath)
        _ = gitOps.stage(file: "file2.txt", in: testRepoPath)
        _ = gitOps.commit(message: "Initial", in: testRepoPath)
        
        createFile("file1.txt", content: "local1")
        createFile("file2.txt", content: "local2")
        
        let result = conflictHandler.resolveConflicts(
            files: ["file1.txt", "file2.txt"],
            in: testRepoPath
        )
        
        guard case .success(let resolutions) = result else {
            XCTFail("Expected success")
            return
        }
        
        XCTAssertEqual(resolutions.count, 2)
        XCTAssertNotEqual(resolutions[0].backupPath, resolutions[1].backupPath)
        
        // Both backups should exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: resolutions[0].backupPath))
        XCTAssertTrue(FileManager.default.fileExists(atPath: resolutions[1].backupPath))
    }
}
```

---

## 13. Main App

*(Main app implementation largely unchanged. See PRD for UI mockups. Key points:)*

- Uses `RepoConfiguration.shared` and `SettingsStore.shared`
- Validates Git availability on launch, shows error if missing
- Services handler validates repos before adding
- Menu bar popover for repo management

---

## 14. Build & Distribution

### 14.1 Build Configuration

- **Debug:** Local development, no signing
- **Release:** Signed with Developer ID, hardened runtime

### 14.2 Notarization

```bash
# Archive
xcodebuild archive -scheme "Git-R-Done" -archivePath ./build/Git-R-Done.xcarchive

# Export
xcodebuild -exportArchive \
  -archivePath ./build/Git-R-Done.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist

# Notarize
xcrun notarytool submit ./build/Git-R-Done.app.zip \
  --apple-id "your@email.com" \
  --team-id "TEAMID" \
  --password "app-specific-password" \
  --wait

# Staple
xcrun stapler staple ./build/Git-R-Done.app
```

### 14.3 Distribution

Create DMG containing:
- Git-R-Done.app
- Applications alias
- README.txt (requirements: Git, credentials)
- LICENSE.txt

---

## 15. Summary of Changes from v2

| Issue | Fix |
|-------|-----|
| Fake testable initializer in FinderSync | Removed; accept manual testing |
| Combine for repo list | Removed; simple properties + NotificationCenter |
| `GitStatusCode` used `"."` for clean | Fixed: accepts both `"."` and `" "` |
| AppleScript escaping broken | Fixed escaping function |
| Conflict filename collision | Added timestamp with time component + counter fallback |
| No thread safety on cache | `StatusManager` with dispatch queues |
| Synchronous Git calls blocking Finder | Fully async badge updates |
| No timeout on Git commands | Added configurable timeout with semaphore |
| No logging | Added OSLog via `Log` enum |
| Mock stub key used joined string | Fixed: use argument array directly |
| `DateProviding`/`UUIDProviding` protocols | Removed; use default parameters |
| No Git availability check | Added `isGitAvailable()` check |
| Push failure after commit unclear | Improved error message |
| No repo validation on launch | Added `validateRepositories()` |
| Missing conflict integration tests | Added `ConflictResolutionIntegrationTests` |
