# 1. Project Configuration

## 1.1 Xcode Project Structure

```
Git-R-Done/
├── Git-R-Done.xcodeproj
├── Git-R-Done/                       # Main app target
│   ├── Git_R_DoneApp.swift
│   ├── AppDelegate.swift
│   ├── ContentView.swift
│   ├── OnboardingView.swift
│   ├── SettingsView.swift            # Settings window UI
│   ├── SettingsViewModel.swift       # Settings business logic
│   └── Resources/
├── GitRDoneExtension/                # Finder Sync Extension
│   └── FinderSync.swift
├── GitRDoneShared/                   # Shared framework
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
├── Git-R-DoneTests/
├── GitRDoneSharedTests/
└── Git-R-DoneUITests/
```

## 1.2 Targets

| Target | Type | Bundle ID | Dependencies |
|--------|------|-----------|--------------|
| Git-R-Done | macOS App | `info.schuyler.gitrdone` | GitRDoneShared |
| GitRDoneExtension | Finder Sync Extension | `info.schuyler.gitrdone.extension` | GitRDoneShared |
| GitRDoneShared | Framework | `info.schuyler.gitrdone.shared` | — |
| Git-R-DoneTests | Unit Test Bundle | `info.schuyler.gitrdone.tests` | GitRDoneShared |
| GitRDoneSharedTests | Unit Test Bundle | `info.schuyler.gitrdone.shared.tests` | GitRDoneShared |
| Git-R-DoneUITests | UI Test Bundle | `info.schuyler.gitrdone.uitests` | Git-R-Done |

## 1.3 App Groups

**App Group Identifier:** `group.info.schuyler.gitrdone`

Used for:
- Shared UserDefaults suite
- Communication between main app and extension

## 1.4 Entitlements

### Git-R-Done (Main App)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
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

### GitRDoneExtension

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
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

## 1.5 Info.plist — Main App

Required keys for main app:

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
<string>Git-R-Done uses AppleScript to display dialogs
for commit messages and notifications.</string>
```

## 1.6 Info.plist — Extension

Extension configuration:

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.FinderSync</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).FinderSync</string>
</dict>
```
