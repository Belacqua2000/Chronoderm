//
//  NotificationName.swift
//  Chronoderm
//
//  Created by Nick Baughan on 01/08/2020.
//  Copyright © 2020 Nick Baughan. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let newFeature = Notification.Name("newFeature")
    static let reminders = Notification.Name("reminders")
    static let createPDF = Notification.Name("createPDF")
    static let toggleComplete = Notification.Name("toggleComplete")
}
