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

#### Menu Bar Interface

The menu bar displays:
- Settings... (⌘,) - Opens the settings window
- About Git-R-Done - Shows the standard macOS about panel
- Quit Git-R-Done (⌘Q) - Terminates the application

#### Settings View

`SettingsView` displays:
- List of watched repositories with remove buttons
- "Add Repository..." button that opens a folder picker
- Auto-push toggle for enabling automatic push after commits
- Notified of external changes via `repositoriesDidChange` and `settingsDidChange` notifications

#### Settings View Model

`SettingsViewModel` uses protocol-based dependency injection for testability:

```swift
init(
    repoConfiguration: RepoConfiguring = RepoConfiguration.shared,
    settingsStore: SettingsStoring = SettingsStore.shared,
    gitValidator: GitValidating = GitOperations(),
    errorPresenter: ErrorPresenting = AppleScriptDialogPresenter()
)
```

Responsibilities:
- Expose repositories from `RepoConfiguration`
- Manage auto-push setting via `SettingsStore`
- Validate Git repositories before adding
- Handle repository add/remove operations
- Respond to external data changes via `refresh()` method

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
