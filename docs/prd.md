# Git-R-Done — Product Requirements Document

## Overview

Git-R-Done is a lightweight macOS application that integrates Git version control directly into Finder. It provides visual status indicators (badges) on files and folders, and exposes common Git operations through Finder's right-click context menu.

The goal is to make Git accessible to non-technical users who are using Git-backed repositories (e.g., GitLab, Gitea, GitHub) as shared document stores, without requiring them to learn command-line tools or heavyweight Git GUIs. Think of it as a self-hosted, FOSS alternative to Dropbox — but with Git's versioning and audit trail underneath.

## Target Users

- Non-developer staff at organizations using Git/GitLab for document versioning
- Users comfortable with basic file management but unfamiliar with Git concepts
- Teams that want "Dropbox-like" sync semantics with Git's versioning and audit trail

## Goals

1. **Minimal learning curve** — Users should understand the interface within minutes
2. **Non-intrusive** — Lives entirely in Finder and menu bar; no separate app window for daily use
3. **Reliable** — Shells out to system `git`, inheriting existing credentials and config
4. **Lightweight** — Low resource footprint; no background daemons beyond the Finder extension
5. **FOSS** — MIT or BSD licensed, freely distributable

## Non-Goals

- Full Git GUI functionality (history browsing, diffing, branch visualization, merge resolution)
- Git hosting service integrations (GitLab MRs, GitHub PRs, issues, etc.)
- Built-in credential management (relies on system Git credential helpers)
- Branch switching or multi-remote support (v1 assumes single remote, default branch)
- App Store distribution (avoids sandboxing constraints)
- Support for macOS versions prior to Ventura (13.0)

## Architecture

```
Git-R-Done.app/
├── Git-R-Done/                   # Main application (menu bar)
│   ├── Git_R_DoneApp.swift       # App entry, menu bar setup
│   ├── SettingsView.swift        # Settings window UI
│   ├── SettingsViewModel.swift   # Settings business logic
│   ├── AppDelegate.swift         # App delegate, Services handler
│   ├── OnboardingView.swift      # First-launch instructions
│   └── Assets.xcassets/
├── GitRDoneExtension/            # Finder Sync Extension
│   ├── FinderSync.swift          # FIFinderSync subclass
│   └── GitRDoneExtension.entitlements
├── GitRDoneShared/               # Shared framework
│   ├── Git/
│   │   ├── GitOperations.swift   # Shell wrapper for git CLI
│   │   ├── GitStatusParser.swift # Parse git status output
│   │   └── ConflictHandler.swift # Conflict resolution logic
│   ├── Infrastructure/
│   │   ├── StatusManager.swift   # Per-repo status caching
│   │   ├── SharedStatusCache.swift # App Groups status persistence
│   │   ├── RepoConfiguration.swift # Watched repo list
│   │   ├── UserNotificationSender.swift # macOS notifications
│   │   └── AppleScriptDialogPresenter.swift # Dialog invocation
│   ├── Models/                   # Data types
│   └── Protocols/                # Abstraction interfaces
└── Git-R-Done.entitlements
```

**Bundle ID:** `info.schuyler.gitrdone`

### Component Responsibilities

**Main App (Menu Bar):**
- Lives in menu bar; no Dock icon, no standalone window (except first-launch and settings)
- First-launch onboarding window (enable extension in System Settings)
- Menu bar dropdown menu showing repository status, Settings, About, Quit
- Settings window for managing watched repositories and auto-push toggle
- Register and handle macOS Services for adding repos
- Persist configuration via App Groups (shared UserDefaults suite)
- Read repository status from shared cache to display in menu

**Finder Sync Extension:**
- Register watched directories with Finder
- Provide badge icons for file/folder Git status
- Provide context menu items for Git operations
- Execute Git operations via shared GitOperations module
- Trigger AppleScript dialogs for user input (commit messages, conflict reports)
- Post macOS notifications for operation results
- Write repository status to shared cache for main app consumption

**Shared Framework (GitRDoneShared):**
- `GitOperations`: Executes `git` CLI commands, parses output
- `GitStatusParser`: Parses `git status --porcelain=v2` output
- `StatusManager`: Caches `git status` results, invalidates on FSEvents or manual refresh
- `SharedStatusCache`: Persists aggregate repo status to App Groups for main app
- `RepoConfiguration`: Reads/writes App Group UserDefaults
- `ConflictHandler`: Implements "Keep Both" conflict resolution strategy
- `UserNotificationSender`: Posts macOS User Notifications
- `AppleScriptDialogPresenter`: Displays AppleScript dialogs, returns user input

### Communication Model

- **App → Extension:** App Group shared UserDefaults (repo list, preferences)
- **Extension → App:** App Group shared UserDefaults (repository status cache)
- **User input:** AppleScript `display dialog` for commit messages and conflict reports

## User Interface

### Menu Bar Menu

```
┌─────────────────────────────┐
│ ● ProjectX                  │
│ ✓ TeamDocs                  │
│ ! SharedRepo                │
├─────────────────────────────┤
│ + Add Repository...         │
│ Settings...            ⌘,  │
├─────────────────────────────┤
│ About Git-R-Done            │
│ Quit Git-R-Done        ⌘Q  │
└─────────────────────────────┘
```

The menu bar dropdown displays watched repositories with status indicators:

| Icon | Color | Status | Meaning |
|------|-------|--------|---------|
| ⋯ | Gray | Pending | Status not yet loaded |
| ✓ | Green | Clean | In sync with remote |
| ↑ | Blue | Ahead | Local commits to push |
| ? | Gray | Untracked | New files not tracked |
| ● | Yellow | Staged | Files staged, not committed |
| ● | Orange | Modified | Unstaged changes |
| ! | Red | Conflict | Merge conflicts |

Each repository shows its aggregate status (worst-case wins). Clicking a repository opens it in Finder.

**Empty state** (no repositories configured):
```
┌─────────────────────────────┐
│ No repositories             │
│ Add one in Settings...      │
├─────────────────────────────┤
│ + Add Repository...         │
│ Settings...            ⌘,  │
├─────────────────────────────┤
│ About Git-R-Done            │
│ Quit Git-R-Done        ⌘Q  │
└─────────────────────────────┘
```

### Settings Window

```
┌─────────────────────────────────────────┐
│ Git-R-Done Settings                     │
├─────────────────────────────────────────┤
│ Watched Repositories:                   │
│ ┌─────────────────────────────────────┐ │
│ │ 📁 Documents/ProjectX            ✕  │ │
│ │ 📁 Shared/TeamDocs               ✕  │ │
│ └─────────────────────────────────────┘ │
│ [+ Add Repository...]                   │
│                                         │
│ ☑ Auto-push after commit                │
└─────────────────────────────────────────┘
```

- Repository list shows folder paths with remove (✕) buttons
- "Add Repository..." opens folder picker, validates Git repo
- Notifications are controlled via System Settings (not in-app)

### First-Launch Onboarding

On first launch, display a one-time window with:
1. Brief explanation of what Git-R-Done does
2. Instructions to enable the Finder extension (with button to open System Settings → Privacy & Security → Extensions → Finder)
3. Prompt to add first repository
4. "Don't show again" / "Get Started" buttons

After onboarding, the app runs as menu bar only.

## User Flows

### First Launch

1. User opens Git-R-Done.app
2. Onboarding window appears (one-time)
3. User clicks button to open System Settings
4. User enables "Git-R-Done" in Finder extensions
5. User returns to onboarding, clicks "Add Repository..."
6. User selects a Git repo folder
7. Onboarding closes; app moves to menu bar
8. Finder now shows badges on files in the repo

### Adding a Repository — Via Services Menu

1. User right-clicks any folder in Finder
2. Selects Services → "Add to Git-R-Done"
3. Git-R-Done validates it's a Git repo (`git rev-parse --git-dir`)
4. If valid: repo added to watched list, notification confirms
5. If not a Git repo: dialog explaining the folder is not a Git repository

### Adding a Repository — Via Menu Bar

1. User clicks Git-R-Done icon in menu bar
2. Clicks "+ Add Repository..."
3. Folder picker appears; user selects repo root
4. App validates it's a Git repo
5. Repo added to watched list; extension begins monitoring

### Daily Use — Committing Changes

1. User edits a document in a watched repo
2. Finder shows "modified" badge on the file
3. User right-clicks file → Git-R-Done → "Commit..."
4. AppleScript dialog appears prompting for commit message
5. User enters message, clicks OK
6. Git-R-Done stages the file, commits with message, and pushes (if auto-push enabled)
7. Badge updates to "clean" state
8. Notification: "Pushed to [repo name]" (if enabled)

### Daily Use — Pulling Updates (No Conflicts)

1. User right-clicks anywhere in repo → Git-R-Done → "Pull"
2. Extension runs `git pull`
3. On success with changes: notification "Pulled N updated files from [repo name]"
4. On success with no changes: silent
5. Badges update to reflect any changed files

### Daily Use — Pulling Updates (With Conflicts)

1. User right-clicks anywhere in repo → Git-R-Done → "Pull"
2. Extension runs `git pull`, conflicts detected
3. For each conflicted file:
   a. Copy local working tree version to temporary location (outside repo)
   b. Accept remote version: `git checkout --theirs <file> && git add <file>`
4. Complete the merge commit (only remote versions committed)
5. Copy local versions back into repo as `filename (Conflict YYYY-MM-DD HH.mm.ss).ext`
6. Local copies are now **untracked** (not staged, not committed)
7. Notification: "Conflicts in [repo name] — local copies saved" (always shown)
8. Display AppleScript dialog:
   ```
   Pull completed with conflicts.

   The following files were changed both locally and remotely.
   Your local versions have been saved:

     - Budget.xlsx -> Budget (Conflict 2025-01-14 15.30.45).xlsx
     - Notes.docx -> Notes (Conflict 2025-01-14 15.30.45).docx

   Please review and reconcile these files, then delete the
   conflict copies when you're done.

   [OK]
   ```
9. Conflict copies show gray "untracked" badge as visual reminder

### Reconciling Conflicts

1. User sees untracked `(Conflict ...)` files with gray badge
2. User opens both versions in their native application (Word, Excel, etc.)
3. User manually merges content as appropriate
4. User deletes the `(Conflict ...)` copy
5. User commits the reconciled file via Git-R-Done

## Feature Details

### Finder Badges

| Status | Badge | Source |
|--------|-------|--------|
| Untracked | Gray ? | `git status`: `?` |
| Modified (unstaged) | Orange dot | `git status`: `M` (worktree) |
| Staged | Yellow dot | `git status`: `M`/`A` (index) |
| Conflict | Red ! | `git status`: `U` |
| Clean | None (no badge) | No status entry |
| Ignored | None (no badge) | Not tracked |

Folder badges reflect aggregate status of contents (worst-case wins: conflict > modified > staged > untracked > clean).

### Repository Status

In addition to file-level badges, Git-R-Done tracks repository-level status:

| Status | Meaning | Source |
|--------|---------|--------|
| Pending | Status not yet loaded | Initial state before first scan |
| Clean | In sync with remote | No local changes, not ahead/behind |
| Ahead | Local commits to push | `git status`: `branch.ab +N` |
| Has changes | Files modified/staged/untracked | Aggregate of file statuses |
| Conflict | Unresolved merge conflicts | Any file with conflict status |

Priority (worst-case wins): conflict > modified > staged > untracked > ahead > clean > pending

### Context Menu Actions

**On files:**
- **Stage** — `git add <file>`
- **Unstage** — `git restore --staged <file>`
- **Commit...** — Stage + commit (+ push if auto-push enabled), with dialog for message
- **Revert** — `git restore <file>` (with confirmation dialog)

**On folders (including repo root):**
- **Pull** — `git pull` (with conflict handling as described above)
- **Push** — `git push`
- **Commit All...** — `git add -A && git commit` (+ push if auto-push enabled)
- **Refresh Status** — Force cache invalidation and re-read

### macOS Services

Git-R-Done registers the following Services:

- **Add to Git-R-Done** — Accepts: folders. Validates as Git repo and adds to watched list.

### Notifications

| Event | Notification Text |
|-------|-------------------|
| Push succeeded | "Pushed to [repo name]" |
| Pull succeeded (no changes) | *(silent)* |
| Pull succeeded (with changes) | "Pulled N updated files from [repo name]" |
| Pull succeeded (with conflicts) | "Conflicts in [repo name] — local copies saved" |
| Push failed | "Failed to push [repo name]: [reason]" |
| Pull failed | "Failed to pull [repo name]: [reason]" |
| Repo added | "Now watching [repo name]" |

Notifications are controlled via System Settings → Notifications → Git-R-Done.

### Settings

| Setting | Description | Default |
|---------|-------------|---------|
| Auto-push after commit | Automatically push after each commit | On |

## Technical Decisions

### Menu Bar App (LSUIElement)

The app sets `LSUIElement = YES` in Info.plist, making it a menu bar-only application with no Dock icon. This matches the "invisible helper" model appropriate for a Finder integration.

First-launch onboarding uses a temporary window that closes after setup.

### Git CLI over libgit2

Rationale:
- Inherits user's existing Git configuration and credentials
- SSH keys, macOS Keychain, credential helpers all work automatically
- Simpler implementation; no native library binding
- Users can debug issues with same `git` commands

### Single Remote, Default Branch

Git-R-Done assumes:
- One remote (`origin`)
- User works on their default branch (typically `main`)
- `git push` and `git pull` with no arguments

This matches how most non-developers use Git-as-document-storage. If the repo is configured with tracking branches (standard for cloned repos), Git handles the details automatically.

### AppleScript Dialogs

Finder Sync Extensions have limited UI capabilities. Rather than complex XPC handoff to the main app, we use `osascript` to invoke AppleScript dialogs:

```swift
func promptForCommitMessage() -> String? {
    let script = """
    display dialog "Enter a commit message:" default answer "" buttons {"Cancel", "Commit"} default button "Commit" with title "Git-R-Done"
    """
    // Execute via Process, parse result
}
```

This provides a native-feeling modal dialog without architectural complexity.

### Conflict Resolution Strategy: "Keep Both"

Non-technical users cannot be expected to understand Git merge conflicts or use tools like FileMerge. Git-R-Done uses a "Keep Both" strategy:

1. Remote version wins (becomes the committed file)
2. Local version preserved as untracked `filename (Conflict YYYY-MM-DD HH.mm.ss).ext`
3. User reconciles manually in their native application
4. No data loss; no Git knowledge required

**Design decisions:**
- Timestamp naming (date + time) ensures unique filenames even for multiple conflicts on the same day
- Conflict copies are **not** auto-committed (prevents accidental push of backup files)
- Conflict copies are **not** added to `.gitignore` (untracked badge serves as visual reminder)
- Users may configure per-repo `.gitignore` patterns if desired

### FSEvents for Status Invalidation

Use `FSEvents` to watch repo directories. On any change:
1. Mark repo cache as stale
2. On next badge request, re-run `git status --porcelain=v2`
3. Debounce rapid changes (e.g., 500ms delay)

### Status Caching

Finder's `FIFinderSync` requests badges synchronously and frequently. We must:
- Cache `git status` output per repo
- Return cached badges immediately
- Refresh cache asynchronously on FSEvents
- Provide manual "Refresh" context menu option as fallback

### Shared Status Cache

The Finder extension computes aggregate repository status (worst-case file status plus branch ahead/behind info) and persists it to App Groups. This allows the main app to display repository status in the menu bar without running its own `git status` queries.

Data stored per repository:
- Repository path
- Aggregate status (clean/ahead/untracked/staged/modified/conflict)
- Commits ahead of remote (for "Ahead" status)
- Last updated timestamp

The extension updates this cache after each status refresh. The main app reads from the cache when building the menu bar dropdown.

## Distribution

- **Direct download** from project website / GitHub releases
- **Notarized** with Apple Developer ID for Gatekeeper approval
- **No sandbox** — required for arbitrary filesystem access and shell execution
- **Hardened runtime** with exceptions for:
  - `com.apple.security.automation.apple-events` (AppleScript dialogs)

## Requirements

- macOS 13.0 (Ventura) or later
- Git installed and in PATH (typically via Xcode CLT or Homebrew)
- Existing Git credentials configured (SSH key or credential helper)

## Future Considerations (Post-v1)

- Branch switching via context menu
- Multiple remote support
- Simple history view ("Show Recent Commits")
- Stash support
- `.gitignore` management ("Ignore This File")
- Localization
- "Open in GitLab/GitHub" context menu action
- Automatic cleanup reminders for old `(Conflict ...)` files
