# TRD-02: Protocols and Data Models

Technical Reference Documentation for Git-R-Done protocols and data models.

## 3. Protocols

### 3.1 GitExecuting

Executes Git commands with timeout support.

```swift
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

Presents user dialogs for commit messages, confirmations, conflicts, and errors. Inherits from `ErrorPresenting`.

```swift
protocol DialogPresenting: ErrorPresenting {
    func promptForCommitMessage() -> String?
    func confirm(message: String, confirmButton: String) -> Bool
    func showConflictReport(resolutions: [ConflictResolution])
    func showInfo(_ message: String)
}
```

### 3.3 ErrorPresenting

Presents error messages to the user.

```swift
protocol ErrorPresenting {
    func showError(_ message: String)
}
```

### 3.4 NotificationSending

Sends notifications with optional suppression based on user settings.

```swift
protocol NotificationSending {
    func send(title: String, body: String)
    func sendAlways(title: String, body: String)
}
```

### 3.5 StatusManaging

Manages cached repository status with refresh queueing and badge updates.

```swift
protocol StatusManaging: AnyObject {
    func getCachedStatus(for repoPath: String) -> RepoStatus?
    func trackURL(_ url: URL, for repoPath: String)
    func queueRefresh(for repoPath: String)
    func invalidate(repoPath: String)
    func performAction(in repoPath: String, action: @escaping () -> Void)

    var onBadgeUpdate: ((URL, String) -> Void)? { get set }
}
```

### 3.6 RepoConfiguring

Manages watched repository storage and lookup.

```swift
protocol RepoConfiguring {
    var repositories: [WatchedRepository] { get }
    func add(_ repo: WatchedRepository)
    func remove(id: UUID)
    func contains(path: String) -> Bool
}
```

### 3.7 SettingsStoring

Manages application settings persistence.

```swift
protocol SettingsStoring {
    var settings: AppSettings { get }
    func update(_ settings: AppSettings)
}
```

### 3.8 GitValidating

Validates whether a path is a Git repository.

```swift
protocol GitValidating {
    func isGitRepository(at path: String) -> Bool
}
```

### 3.9 StatusCaching

Manages shared repository status cache for cross-process communication.

```swift
protocol StatusCaching {
    var summaries: [RepoStatusSummary] { get }
    func update(_ summary: RepoStatusSummary)
    func remove(path: String)
    func summary(for path: String) -> RepoStatusSummary?
}
```

## 4. Data Models

### 4.1 WatchedRepository

A repository tracked by the application.

```swift
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

### 4.2 GitStatusCode

File status code from Git status output.

```swift
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
        case ".", " ": self = .clean
        default: self = .clean
        }
    }
}
```

### 4.3 GitFileStatus

File status from Git, with computed properties for common checks.

```swift
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

### 4.4 RepoStatus

Snapshot of repository file status at a point in time.

```swift
struct RepoStatus: Equatable {
    let repoPath: String
    let files: [String: GitFileStatus]
    let timestamp: Date

    func status(for relativePath: String) -> GitFileStatus? {
        files[relativePath]
    }
}
```

### 4.5 GitError

Errors from Git operations.

```swift
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

### 4.6 PullResult

Result of a Git pull operation.

```swift
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

### 4.7 ConflictResolution

Information about a resolved merge conflict.

```swift
struct ConflictResolution: Equatable {
    let originalFile: String
    let backupFile: String
    let backupPath: String
}
```

### 4.8 AppSettings

Application configuration stored locally.

```swift
struct AppSettings: Codable, Equatable {
    var autoPushEnabled: Bool
    var hasCompletedOnboarding: Bool

    init(autoPushEnabled: Bool = true, hasCompletedOnboarding: Bool = false) {
        self.autoPushEnabled = autoPushEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}
```

### 4.9 BadgePriority

Priority level for Finder badge display, ordered from lowest to highest priority.

```swift
enum BadgePriority: Int, Comparable, Codable {
    case clean = 0
    case ahead = 1
    case untracked = 2
    case staged = 3
    case modified = 4
    case conflict = 5

    static func < (lhs: BadgePriority, rhs: BadgePriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var badgeIdentifier: String {
        switch self {
        case .clean: return ""
        case .ahead: return "Ahead"
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

### 4.10 RepoStatusSummary

Aggregate repository status for menu bar display. Stored in shared App Groups for communication between Finder extension and main app.

```swift
struct RepoStatusSummary: Codable, Equatable {
    let path: String
    let status: BadgePriority
    let commitsAhead: Int
    let updatedAt: Date

    init(path: String, status: BadgePriority, commitsAhead: Int = 0, updatedAt: Date = Date()) {
        self.path = path
        self.status = status
        self.commitsAhead = commitsAhead
        self.updatedAt = updatedAt
    }

    var displayName: String {
        URL(fileURLWithPath: path).lastPathComponent
    }
}
```
