import Foundation
@testable import GitRDoneShared

final class MockNotificationSender: NotificationSending {

    var sentNotifications: [(title: String, body: String)] = []

    func send(title: String, body: String) {
        sentNotifications.append((title, body))
    }
}
