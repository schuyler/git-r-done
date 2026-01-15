# Git Operations

## GitStatusParser

Parses `git status --porcelain=v2` output into file status dictionaries.

**Format entries:**
- `1`: Ordinary file changes (path, index status, worktree status)
- `2`: Renamed files (includes original and new paths)
- `u`: Unmerged files (conflict markers present)
- `?`: Untracked files
- `!`: Ignored files

**API:**
```swift
static func parse(_ output: String) -> [String: GitFileStatus]
```

Returns dictionary mapping file paths to `GitFileStatus` objects containing `indexStatus` and `worktreeStatus`.

---

## GitOperations

Executes git commands and returns structured results. Conforms to `GitValidating` protocol for validation operations.

**Dependencies:**
- `executor: GitExecuting` - shell command executor (injectable for testing)

### Validation

```swift
func isGitAvailable() -> Bool
func isGitRepository(at path: String) -> Bool
func repositoryRoot(for path: String) -> String?
```

### Status

```swift
func status(for repoPath: String, timeout: TimeInterval = 30) -> Result<RepoStatus, GitError>
```

Returns `RepoStatus` with parsed file statuses and timestamp. Fails with `.timedOut` or `.commandFailed` errors.

### File Operations

```swift
func getFileContent(ref: String, file: String, in repoPath: String) -> Result<Data, GitError>
```

Retrieves file content from a git reference (e.g., `HEAD`, `origin/main`). Used by `ConflictHandler` to extract clean local versions during merge conflicts.

**Staging:**
```swift
func stage(file: String, in repoPath: String) -> Result<Void, GitError>
func unstage(file: String, in repoPath: String) -> Result<Void, GitError>
func stageAll(in repoPath: String) -> Result<Void, GitError>
```

`unstage()` tries `git restore --staged` first, then falls back to `git rm --cached` for newly added files.

### Commits

```swift
func commit(message: String, in repoPath: String) -> Result<Void, GitError>
func commitMerge(in repoPath: String) -> Result<Void, GitError>
```

### Push/Pull

```swift
func push(in repoPath: String, timeout: TimeInterval = 60) -> Result<Void, GitError>
func pull(in repoPath: String, timeout: TimeInterval = 60) -> Result<PullResult, GitError>
```

`pull()` detects merge conflicts in output and returns `.conflicts([String])` result. Falls back to `.success(updatedFiles: [String])` on clean pull.

### Revert

```swift
func revert(file: String, in repoPath: String) -> Result<Void, GitError>
```

Discards local changes via `git restore`.

### Conflict Resolution

```swift
func acceptTheirs(file: String, in repoPath: String) -> Result<Void, GitError>
```

Accepts remote version and stages the file.

### Parsing Helpers

- `parseConflictedFiles(from: String) -> [String]` - Extracts conflicted file paths from pull output using regex
- `parseUpdatedFiles(from: String) -> [String]` - Extracts updated file paths from pull output

---

## ConflictHandler

Resolves merge conflicts by accepting remote versions and backing up local versions.

**Dependencies:**
- `gitOps: GitOperations`
- `fileManager: FileManager` (default: `.default`)

### API

```swift
func resolveConflicts(files: [String], in repoPath: String, date: Date = Date()) -> Result<[ConflictResolution], Error>
func completeMerge(in repoPath: String) -> Result<Void, GitError>
```

### Conflict Resolution Process

For each conflicted file:
1. Get clean local version from `HEAD` using `git show HEAD:<file>`
2. Accept remote version via `acceptTheirs()`
3. Generate unique backup filename
4. Move local version to backup path

**Example backup name:** `document.xlsx` → `document (Conflict 2025-01-14 15.30.45).xlsx`

If a backup already exists, appends counter: `document (Conflict 2025-01-14 15.30.45) 2.xlsx`

On failure, cleans up all already-created backups before returning error.

### Backup Naming

```swift
func generateBackupName(for file: String, timestamp: String) -> String
```

- Preserves file extension
- Handles nested directories
- Timestamp format: `"yyyy-MM-dd HH.mm.ss"` (colons replaced with periods for filesystem safety)

---

## BadgeResolver

Determines git status badges for files and directories.

**API:**
```swift
static func badge(for relativePath: String, in status: RepoStatus?, isDirectory: Bool) -> String
```

Returns badge identifier from `BadgePriority` enum.

### Logic

**For files:** Returns badge for exact path match in status.

**For directories:** Aggregates all files under directory prefix and returns badge for worst priority found (highest value in enum). Root directory includes all files if `relativePath` is empty.

---

## FSEventsWatcher

Monitors filesystem changes at specified paths and debounces callbacks.

**Dependencies:**
- macOS FSEvents framework (system-level file system event API)
- GCD dispatch queues

### Configuration

```swift
init(
    debounceInterval: TimeInterval = 0.5,
    callbackQueue: DispatchQueue = .main,
    callback: @escaping () -> Void
)
```

### API

```swift
func watch(paths: [String])
func stop()
```

**Watch setup:**
- Creates FSEventStream with file-level events flag
- Sets dispatch queue to `DispatchQueue.global(qos: .utility)`
- Debounces callbacks using `DispatchWorkItem` (additional debouncing beyond FSEvents' native latency)

**Event handling:**
- Cancels pending work item on new event
- Schedules callback after debounce interval
- Logs stream creation/cleanup

**Cleanup:**
- Cancels pending work item
- Stops and invalidates FSEventStream
- Releases stream reference

---

## Error Handling

All git operations return `Result<Success, GitError>` with error cases:

- `.gitNotInstalled` - git command not available
- `.timedOut` - operation exceeded timeout
- `.commandFailed(String)` - command failed (includes stderr)
- `.pushFailed(String)` - push-specific failure
- `.pullFailed(String)` - pull-specific failure

Conflict handler catches file system and git errors during resolution.

---

## Timeout Defaults

- Status: 30 seconds
- Push/Pull: 60 seconds
- Repository validation: 5 seconds

FSEvents uses additional debouncing (default 0.5 seconds) beyond native latency.
