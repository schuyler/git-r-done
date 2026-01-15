# Finder Sync Extension

The FinderSync extension integrates Git-R-Done with macOS Finder, displaying file status badges and providing context menu actions for Git operations directly in the file system.

## FinderSync Class

The `FinderSync` class extends `FIFinderSync` and is instantiated by the system. Dependencies are created as production instances since the system controls initialization.

### Dependencies

- `gitOps`: `GitOperations` - Executes Git commands
- `statusManager`: `StatusManager` - Tracks file status and badge updates
- `dialogPresenter`: `AppleScriptDialogPresenter` - Shows dialogs and prompts
- `notifier`: `UserNotificationSender` - Sends user notifications
- `conflictHandler`: `ConflictHandler` - Resolves merge conflicts

### Initialization

On launch, the extension:
1. Creates dependencies
2. Calls `setupBadges()` to register badge images
3. Calls `updateWatchedDirectories()` to set up file system monitoring
4. Subscribes to repository change notifications
5. Configures the status manager's badge update callback

## Badge System

Badges display file status in Finder with system symbols and colors:

- **Untracked** (gray): `questionmark.circle`
- **Modified** (orange): `circle.fill`
- **Staged** (green): `checkmark.circle.fill`
- **Conflict** (red): `exclamationmark.circle.fill`

The `setupBadges()` method registers each badge with the Finder sync controller. Badges are requested via `requestBadgeIdentifier(for:)` when Finder displays a file.

## File System Monitoring

The extension monitors registered repositories for changes:

- `beginObservingDirectory(at:)` - Called when Finder enters a directory; queues a status refresh
- `endObservingDirectory(at:)` - Called when Finder exits a directory
- `updateWatchedDirectories()` - Syncs watched directories with configured repositories

Repository changes trigger `repositoriesDidChange()`, which updates the watch list.

## Context Menu

The `menu(for:)` method builds the context menu based on the selection:

**File Actions** (when single file selected):
- Stage
- Unstage
- Commit...
- Revert

**Folder Actions** (when directory selected):
- Pull
- Push
- Commit All...

**Always available:**
- Refresh Status

## Git Operations

### Stage and Unstage

`stageAction(_:)` and `unstageAction(_:)` stage or unstage selected files. Multiple files can be selected.

### Commit File

`commitFileAction(_:)` stages and commits a single file:
1. Prompts for commit message
2. Stages the file
3. Commits with the message
4. Pushes if auto-push is enabled
5. Shows error if any step fails

### Commit All

`commitAllAction(_:)` stages all changes and commits:
1. Prompts for commit message
2. Stages all modified files
3. Commits with the message
4. Pushes if auto-push is enabled

### Revert

`revertAction(_:)` reverts a file to its committed state:
1. Shows confirmation dialog
2. Reverts the file if confirmed

### Pull

`pullAction(_:)` fetches and merges remote changes:
1. Pulls from remote
2. If conflicts occur, calls `conflictHandler.resolveConflicts(files:in:)`
3. Saves local copies of conflicted files
4. Shows conflict report dialog
5. Notifies user of result

### Push

`pushAction(_:)` pushes local commits to remote.

### Refresh Status

`refreshAction(_:)` invalidates cached status for a repository, forcing a refresh.

## Helper Methods

- `findRepoPath(for:)` - Returns the configured repository path containing a URL
- `getRelativePath(_:in:)` - Returns the path relative to a repository root
- `isDirectory(_:)` - Checks if a URL points to a directory

## Notifications

The extension sends macOS notifications for:
- Successful push/pull/commit
- Pull with updated file counts
- Merge conflicts (with local copies saved)
- Failed operations (Git errors)

## Error Handling

The extension checks Git availability before operations. If Git is not available, it shows an error dialog. Failed Git operations display error messages to the user via dialogs or notifications.

## File `/Users/sderle/code/git-r-done/Git-R-Done/GitRDoneExtension/FinderSync.swift`

Main extension class located at lines 1-365.
