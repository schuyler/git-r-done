//
//  UserNotificationSender.swift
//  GitRDoneShared
//

import Foundation
import UserNotifications

public final class UserNotificationSender: NotificationSending {

    public init() {}

    public func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                Log.finder.error("Notification permission error: \(error.localizedDescription)")
            }
            Log.finder.info("Notification permission granted: \(granted)")
        }
    }

    public func send(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Log.finder.error("Failed to post notification: \(error.localizedDescription)")
            }
        }
    }
}
