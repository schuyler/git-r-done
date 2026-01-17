# TRD Section 7: Main App & Distribution

## 13. Main App

### 13.1 Architecture

The main app is a menu bar application using SwiftUI's `MenuBarExtra` with NSMenu style. It manages watched repositories and application settings.

### 13.2 Components

#### App Entry Point

`Git_R_DoneApp` defines three scenes:

1. **Menu Bar**: Uses `MenuBarExtra` with `.menu` style (not popover)
2. **Settings Window**: Separate window for repository and preference management
3. **Onboarding Window**: First-run welcome screen

#### Menu Bar Icon

The menu bar uses a custom icon with dynamic status badge, implemented via `MenuBarIconView`:

```swift
struct MenuBarIconView: View {
    let status: BadgePriority

    var body: some View {
        Image("MenuBarIcon")
            .overlay(alignment: .topTrailing) {
                if let badgeColor = badgeColor(for: status) {
                    Circle()
                        .fill(badgeColor)
                        .frame(width: 6, height: 6)
                        .offset(x: 2, y: -2)
                }
            }
    }
}
```

**Icon Asset:**
- Location: `Assets.xcassets/MenuBarIcon.imageset/`
- Format: PDF vector (18×18pt) with SVG source
- Rendering: Template mode for automatic light/dark adaptation
- Design: Filled circle with sans-serif "R" knocked out as negative space

**Status Badge:**
The `MenuBarViewModel.aggregateStatus` property computes the worst-case status across all repositories:

```swift
var aggregateStatus: BadgePriority {
    summaries.map(\.status).max() ?? .pending
}
```

Badge colors map to `BadgePriority`:
- `.pending`, `.clean` → No badge (nil)
- `.ahead` → Blue
- `.untracked` → Gray
- `.staged` → Yellow
- `.modified` → Orange
- `.conflict` → Red

The `MenuBarExtra` uses the label closure to include the dynamic icon:

```swift
MenuBarExtra {
    // menu content
} label: {
    MenuBarIconView(status: menuViewModel.aggregateStatus)
}
```

#### Menu Bar Interface

The menu bar displays repository status and standard menu items:

**Repository Status Section:**
- Each watched repository shown with status icon and user-defined display name
- Display names are looked up from `RepoConfiguration` (not the status cache)
- Clicking a repository opens it in Finder
- Status icons indicate aggregate repository state:

| Icon | Color | Status | Meaning |
|------|-------|--------|---------|
| ✓ | Green | Clean | In sync with remote |
| ↑ | Blue | Ahead | Local commits to push |
| ? | Gray | Untracked | New files not tracked |
| ● | Yellow | Staged | Files staged, not committed |
| ● | Orange | Modified | Unstaged changes |
| ! | Red | Conflict | Merge conflicts |

**Empty State:**
When no repositories are configured, displays "No repositories" with prompt to add one in Settings.

**Standard Menu Items:**
- Settings... (⌘,) - Opens the settings window
- About Git-R-Done - Shows the standard macOS about panel
- Quit Git-R-Done (⌘Q) - Terminates the application

**Data Source:**
Repository status is read from `SharedStatusCache`, which is populated by the Finder extension. The menu observes `statusCacheDidChange` notifications to update when status changes.

#### Settings View

`SettingsView` displays repositories in a table format:

| Column | Description |
|--------|-------------|
| Name | Editable display name (double-click to edit) |
| Path | Repository path (read-only, abbreviated with `~`) |
| Remove | Button to remove repository from watch list |

**Features:**
- "Add Repository..." button opens a folder picker
- Auto-push toggle for enabling automatic push after commits
- Notified of external changes via `repositoriesDidChange` and `settingsDidChange` notifications

**Display Name Editing:**
- Double-click the Name cell to enter edit mode
- Press Enter to confirm, Escape to cancel
- Empty names revert to the default (derived from remote URL or folder name)
- Changes persist immediately via `RepoConfiguration.updateDisplayName()`

#### Settings View Model

`SettingsViewModel` uses protocol-based dependency injection for testability:

```swift
init(
    repoConfiguration: RepoConfiguring = RepoConfiguration.shared,
    settingsStore: SettingsStoring = SettingsStore.shared,
    gitValidator: GitValidating = GitOperations(),
    gitOperations: GitOperations = GitOperations(),
    errorPresenter: ErrorPresenting = AppleScriptDialogPresenter()
)
```

Responsibilities:
- Expose repositories from `RepoConfiguration`
- Manage auto-push setting via `SettingsStore`
- Validate Git repositories before adding
- Derive default display names from remote URL when adding repositories
- Handle repository add/remove operations
- Update display names via `updateDisplayName(id:name:)`
- Respond to external data changes via `refresh()` method

**Display Name Methods:**

```swift
func updateDisplayName(for id: UUID, name: String)
func defaultDisplayName(for path: String) -> String
```

`defaultDisplayName(for:)` fetches the remote URL and parses the repository name. Falls back to the folder name if no remote is configured or parsing fails.

### 13.3 Initialization Flow

1. App launches and checks onboarding status
2. If not completed, shows onboarding window
3. Displays menu bar immediately
4. App delegate validates Git availability on startup

---

## 14. Build & Distribution

### 14.1 Build Configuration

**Debug Build**
- Local development
- No code signing
- Faster compilation

**Release Build**
- Signed with Developer ID certificate
- Hardened runtime enabled
- Ready for notarization

### 14.2 Notarization Process

Apple notarization required for distribution outside the App Store.

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

# Staple ticket to app
xcrun stapler staple ./build/Git-R-Done.app
```

### 14.3 Distribution Package

Create a DMG containing:
- `Git-R-Done.app` - The application
- Applications alias - Shortcut to /Applications folder
- `README.txt` - Lists requirements (Git, stored credentials)
- `LICENSE.txt` - License file

### 14.4 System Requirements

End users must have:
- macOS 13.0 or later
- Git installed and accessible in PATH
- Git credentials configured (token or SSH key)
- For commits: Git user name and email configured
