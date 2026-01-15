# Testing Strategy

Testing uses XCTest for unit and integration tests, with mock objects to isolate components. Shared tests validate git operations; app tests validate UI logic.

## Mock Objects

Mock objects track method calls and return stub data, enabling tests to run without actual git operations or user interaction.

### MockGitExecutor

Simulates the `GitExecutor` interface for testing `GitOperations`.

**Key features:**
- `stubbedResults`: Maps command argument arrays to `ShellResult`
- `executedCommands`: Records all executed commands with directory and timeout
- `stub(_:result:)`: Sets result for a specific command
- `stubStatus(_:)`: Convenience for `status --porcelain=v2` output
- `stubPull(_:success:)`: Convenience for pull command results

### MockDialogPresenter

Simulates the `DialogPresenter` interface for testing user interactions.

**Key features:**
- `commitMessageToReturn`: Configurable commit message for prompt tests
- `confirmResult`: Boolean return value for confirmation dialogs
- Tracks all prompts, confirmations, and messages shown

### MockStatusManager

Simulates the `StatusManager` interface for testing status caching and invalidation.

**Key features:**
- `cachedStatuses`: Maps repo paths to `RepoStatus`
- `trackURL(_:for:)`: Records tracked URLs
- `queueRefresh(for:)`: Records queued refresh operations
- `performAction(in:action:)`: Executes actions synchronously (not in background)

### MockNotificationSender

Simulates the `NotificationSender` interface for testing notifications.

**Key features:**
- `sentNotifications`: Tracks all sent notifications with title, body, and priority flag

### SettingsViewModel Mocks

Four new mocks test the app-layer settings UI logic.

**MockRepoConfiguration**: Tracks added/removed repositories and validates paths.

**MockSettingsStore**: Records all settings updates; initial settings are mutable.

**MockGitValidator**: Returns true for paths in `validPaths` set.

**MockErrorPresenter**: Collects all error messages displayed.

---

## Unit Tests

Unit tests validate individual components with mocks.

### GitStatusParserTests

Tests `GitStatusParser.parse()` with porcelain v2 output.

**Ordinary entries**: Modified (staged/unstaged), added, deleted, renamed

**Untracked files**: With/without spaces in path

**Ignored files**: Marked with `!` prefix

**Unmerged/conflicted**: Parse conflict markers

**Multiple files**: Aggregate multiple status lines

**Edge cases**: Empty output, whitespace-only, invalid lines

### GitOperationsTests

Tests `GitOperations` delegating to mock executor.

**Availability**: Git availability check and error handling

**Repository detection**: `isGitRepository()` with success/failure

**Status parsing**: Output parsing, timeouts

**Staging**: Correct `git add` command with path

**Committing**: Correct `git commit` command with message

**Pull detection**: Success, conflicts, conflict file extraction

**Conflict resolution**: `acceptTheirs()` executes checkout then add

### ConflictHandlerTests

Tests `ConflictHandler.resolveConflicts()` and backup naming.

**Backup naming**:
- Simple files: `file.txt` → `file (Conflict 2025-01-14 15.30.45).txt`
- Subdirectories: Preserves path structure
- No extension: `Makefile` → `Makefile (Conflict ...)`
- Multiple extensions: `archive.tar.gz` → `archive.tar (Conflict ...).gz`

**Backup creation**: Creates file with local content, stages resolution

**Unique names**: Multiple files on same day get unique timestamps

### BadgeResolverTests

Tests `BadgeResolver.badge()` for file and directory status indicators.

**File badges**: Untracked, modified, staged, conflict, clean

**Directory badges**: Aggregates worst status of contained files

**Precedence**: Conflict > Staged > Modified > Untracked > Clean

**Root directory**: Badge for repo root shows worst status in repo

### StatusManagerTests

Tests `StatusManager.makeRelativePath()` utility.

**Basic path**: Removes repo prefix, preserves structure

**Root file**: File in repo root returns just filename

**Unrelated paths**: Returns absolute path if not under repo

**Exact match**: Repo path matching itself returns empty string

---

## Integration Tests

Integration tests use actual git operations in temporary test repositories.

### GitOperationsIntegrationTests

Tests `GitOperations` with real git commands.

**Setup**: Creates temporary test repository with `git init`

**Repository detection**: `isGitRepository()` on test repo

**Untracked detection**: Status correctly marks created files as untracked

**Staging workflow**: `stage()` updates file status to staged

**Full workflow**: Create → untracked → stage → staged → commit → clean → modify → modified

### ConflictResolutionIntegrationTests

Tests `ConflictHandler` with real git and file operations.

**Backup creation**: Conflict resolution preserves local content in backup file

**Unique names**: Multiple files on same day get different backup filenames

**Backup existence**: Verifies backup files physically exist on disk

---

## App Layer Tests

SettingsViewModelTests validate the settings UI without mocking app dependencies.

### Repository Management

**Adding valid repo**: Valid git repository is added to configuration

**Adding invalid repo**: Non-git folder shows error message

**Duplicate rejection**: Adding existing repo again is ignored

**Removal**: Repository removal calls configuration remove method

### Settings Persistence

**Auto-push toggle**: Toggling `autoPushEnabled` persists to store

**Repositories list**: `repositories` property reflects configuration state

### Refresh

**Safe refresh**: `refresh()` completes without error or side effects

---

## Test Files

- `/Users/sderle/code/git-r-done/Git-R-Done/GitRDoneSharedTests/Mocks/MockGitExecutor.swift`
- `/Users/sderle/code/git-r-done/Git-R-Done/GitRDoneSharedTests/Mocks/MockDialogPresenter.swift`
- `/Users/sderle/code/git-r-done/Git-R-Done/GitRDoneSharedTests/Mocks/MockStatusManager.swift`
- `/Users/sderle/code/git-r-done/Git-R-Done/GitRDoneSharedTests/Mocks/MockNotificationSender.swift`
- `/Users/sderle/code/git-r-done/Git-R-Done/GitRDoneSharedTests/GitStatusParserTests.swift`
- `/Users/sderle/code/git-r-done/Git-R-Done/GitRDoneSharedTests/GitOperationsTests.swift`
- `/Users/sderle/code/git-r-done/Git-R-Done/GitRDoneSharedTests/ConflictHandlerTests.swift`
- `/Users/sderle/code/git-r-done/Git-R-Done/GitRDoneSharedTests/BadgeResolverTests.swift`
- `/Users/sderle/code/git-r-done/Git-R-Done/GitRDoneSharedTests/StatusManagerTests.swift`
- `/Users/sderle/code/git-r-done/Git-R-Done/GitRDoneSharedTests/GitOperationsIntegrationTests.swift`
- `/Users/sderle/code/git-r-done/Git-R-Done/GitRDoneSharedTests/ConflictResolutionIntegrationTests.swift`
- `/Users/sderle/code/git-r-done/Git-R-Done/Git-R-DoneTests/SettingsViewModelTests.swift`
