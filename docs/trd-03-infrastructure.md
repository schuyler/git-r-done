# Infrastructure Layer Documentation

## Overview

The infrastructure layer provides foundational services for Git operations, user interaction, notifications, and persistent storage. These components abstract system-level concerns from the business logic.

## ShellGitExecutor

`ShellGitExecutor` implements `GitExecuting` and manages Git command execution through the system shell.

**Responsibilities:**
- Locate Git executable on system initialization
- Execute Git commands with arguments in specified directory
- Enforce configurable timeouts for long-running operations
- Collect stdout, stderr, and exit codes
- Log all operations for debugging

**Implementation Notes:**

The executor searches for Git in this order:
1. Common installation paths: `/usr/bin/git`, `/usr/local/bin/git`, `/opt/homebrew/bin/git`
2. System `which` command as fallback

Each command execution:
- Runs in a separate process with isolated pipes for stdout/stderr
- Uses a `DispatchSemaphore` to enforce timeouts without blocking the calling thread
- Logs warnings for failed commands and errors for missing Git
- Returns a `ShellResult` containing exit code and output regardless of success

**Example Usage:**

```swift
let executor = ShellGitExecutor()
if executor.isGitAvailable() {
    let result = executor.execute(
        ["log", "--oneline"],
        in: "/path/to/repo",
        timeout: 10
    )
    if result.success {
        print(result.stdout)
    }
}
```

## AppleScriptDialogPresenter

`AppleScriptDialogPresenter` implements `DialogPresenting` (which inherits from `ErrorPresenting`) and presents user dialogs through the macOS AppleScript bridge.

**Responsibilities:**
- Prompt users for commit messages via dialog box
- Display confirmation dialogs with custom button labels
- Show conflict resolution reports with file backups
- Display error and info messages with appropriate icons

**Implementation Notes:**

All dialog strings are escaped for AppleScript syntax before execution to prevent injection attacks. Dialogs are presented synchronously using `osascript` and block until the user responds.

The `showConflictReport` method formats resolutions as a bulleted list and informs users that local versions were saved as backups.

**Example Usage:**

```swift
let presenter = AppleScriptDialogPresenter()

// Prompt for commit message
if let message = presenter.promptForCommitMessage() {
    // User entered a message
}

// Confirmation dialog
let shouldContinue = presenter.confirm(
    message: "Push changes?",
    confirmButton: "Push"
)

// Error display
presenter.showError("Operation failed: unable to access repository")
```

## UserNotificationSender

`UserNotificationSender` implements `NotificationSending` and sends macOS user notifications to the user.

**Responsibilities:**
- Request user permission for notifications
- Send notifications with title and body

**Implementation Notes:**

Notifications are controlled via System Settings (macOS user notification settings). The sender itself does not check any app-level `notificationsEnabled` setting—all permission management is delegated to the operating system.

The `send()` method posts notifications immediately via `UNUserNotificationCenter`. Each notification uses a unique identifier and triggers with sound.

**Example Usage:**

```swift
let sender = UserNotificationSender()
sender.requestPermission()

// Send notification
sender.send(
    title: "Pull Complete",
    body: "Successfully pulled 3 commits"
)
```

## RepoConfiguration

`RepoConfiguration` implements `RepoConfiguring` and manages the list of watched repositories.

**Responsibilities:**
- Persist watched repositories to App Group UserDefaults
- Load repositories on initialization
- Add/remove repositories by path or UUID
- Provide thread-safe access to repository list
- Publish change notifications

**Thread Safety:**

All mutations use `DispatchQueue.async` with `queue.sync` for reads. Notification posting occurs on the main thread via `DispatchQueue.main.async` to ensure observers can perform UI updates.

**Implementation Notes:**

Repositories are stored as JSON in the shared App Group container. Path normalization occurs at storage time using `NSString.standardizingPath`.

The `load()` method is called during initialization and reloads the repository list on demand. Repository validation against the filesystem can be performed separately through `GitOperations`.

**Example Usage:**

```swift
let config = RepoConfiguration.shared
config.add(WatchedRepository(path: "/path/to/repo"))

if config.contains(path: "/path/to/repo") {
    // Repository is tracked
}

// Observe changes
NotificationCenter.default.addObserver(
    forName: .repositoriesDidChange,
    object: nil,
    queue: .main
) { _ in
    // Repositories changed
}
```

## SettingsStore

`SettingsStore` implements `SettingsStoring` and manages app-level settings.

**Responsibilities:**
- Persist `AppSettings` to App Group UserDefaults
- Load settings on initialization
- Provide thread-safe read access via property
- Publish change notifications on update

**Thread Safety:**

Read access uses `queue.sync` to ensure the most current value. Updates use `queue.async` to avoid blocking the caller during encoding and persistence.

**Implementation Notes:**

Settings are stored as JSON in the shared App Group container. If decoding fails at startup, default settings are created. The `update()` method posts a notification on the main thread to allow UI updates in response to setting changes.

**Example Usage:**

```swift
let store = SettingsStore.shared
let current = store.settings

// Update settings
var updated = current
updated.someOption = true
store.update(updated)

// Observe changes
NotificationCenter.default.addObserver(
    forName: .settingsDidChange,
    object: nil,
    queue: .main
) { _ in
    // Settings changed
}
```

## StatusManager

`StatusManager` implements `StatusManaging` and manages cached Git status for repositories with concurrent refresh operations.

**Responsibilities:**
- Maintain in-memory cache of repository status
- Execute Git status commands on background queue
- Track which file URLs are awaiting status badges
- Debounce concurrent refresh requests for the same repository
- Validate repositories before refresh and remove invalid ones
- Push badge updates to registered callbacks

**Thread Safety:**

A dedicated `stateQueue` protects all mutable state (cache, tracked URLs, in-progress refreshes). The `gitQueue` executes Git commands with `.userInitiated` QoS. Badge callbacks run on the main thread.

**Implementation Notes:**

When multiple refresh requests arrive for the same repository, only the first is queued; subsequent requests are ignored until the refresh completes. This prevents redundant Git invocations.

Repository validity is checked before refresh—if the path no longer exists, the repository is removed from configuration. Relative path computation handles edge cases like symlinks.

**Example Usage:**

```swift
let manager = StatusManager(
    gitOps: gitOps,
    repoConfig: config
)

// Register callback for badge updates
manager.onBadgeUpdate = { url, badge in
    // Update badge for URL
}

// Track file URL and queue refresh
manager.trackURL(fileURL, for: repoPath)
manager.queueRefresh(for: repoPath)

// Retrieve cached status
if let status = manager.getCachedStatus(for: repoPath) {
    // Use cached status
}

// Invalidate cache and refresh
manager.invalidate(repoPath: repoPath)
```

## Protocols and Conformance

**DialogPresenting** inherits from `ErrorPresenting` and defines the complete UI dialog contract:
- `promptForCommitMessage() -> String?`
- `confirm(message:confirmButton:) -> Bool`
- `showConflictReport(resolutions:)`
- `showInfo(_:)` (from `DialogPresenting`)
- `showError(_:)` (from `ErrorPresenting`)

**RepoConfiguring** defines the repository configuration contract:
- `repositories: [WatchedRepository]` (read-only)
- `add(_:)`
- `remove(id:)` and `remove(path:)`
- `contains(path:) -> Bool`

**SettingsStoring** defines the settings storage contract:
- `settings: AppSettings` (read-only)
- `update(_:)`

## Notifications

The infrastructure layer publishes these notifications:

- **repositoriesDidChange**: Posted on main thread when repositories are added/removed
- **settingsDidChange**: Posted on main thread when settings are updated

Observers should register on the main queue to safely perform UI updates.
