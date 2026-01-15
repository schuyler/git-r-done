# Git-R-Done

A macOS Finder extension for Git operations. Stage, commit, push, and pull directly from the Finder context menu.

## Features

- **Finder badges** show file status (modified, staged, untracked, conflict)
- **Context menu** for git operations on files and folders
- **Automatic conflict resolution** with local backup copies
- **Menu bar app** for managing watched repositories

## Installation

1. Build and run in Xcode
2. Enable the Finder extension in System Settings → Privacy & Security → Extensions → Added Extensions
3. Add repositories via the menu bar icon

## Usage

**Right-click files:**
- Stage / Unstage (supports multiple selection)
- Commit (single file)
- Revert (single file)

**Right-click folders:**
- Pull / Push
- Commit All

## Requirements

- macOS 15.0+
- Git (via Xcode Command Line Tools or standalone)

## License

MIT
