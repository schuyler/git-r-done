//
//  NotificationSending.swift
//  GitRDoneShared
//

import Foundation

public protocol NotificationSending {
    func send(title: String, body: String)
    func sendAlways(title: String, body: String)
}
