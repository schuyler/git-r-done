//
//  NotificationSending.swift
//  GitRDoneShared
//

import Foundation

public protocol NotificationSending {
    func send(title: String, body: String)
}
