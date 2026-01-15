//
//  AppDelegate.swift
//  Git-R-Done
//
//  Created by Schuyler Erle on 1/14/26.
//

import AppKit
import GitRDoneShared

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register for Services
        NSApp.servicesProvider = ServicesProvider()
        NSUpdateDynamicServices()

        // Request notification permission
        UserNotificationSender().requestPermission()
    }
}

// MARK: - Services Provider

class ServicesProvider: NSObject {

    @objc func addRepository(_ pboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let items = pboard.readObjects(forClasses: [NSURL.self]) as? [URL],
              let url = items.first else {
            error.pointee = "No folder selected" as NSString
            return
        }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            error.pointee = "Selection is not a folder" as NSString
            return
        }

        let gitOps = GitOperations()

        guard gitOps.isGitRepository(at: url.path) else {
            let dialog = AppleScriptDialogPresenter()
            dialog.showError("The selected folder is not a Git repository.")
            return
        }

        let repo = WatchedRepository(path: url.path)
        RepoConfiguration.shared.add(repo)

        let notifier = UserNotificationSender()
        notifier.send(title: "Git-R-Done", body: "Now watching \(repo.displayName)")
    }
}
