//
//  Activity.swift
//  DCC-Weekly-Activities
//
//  Created by Amit Kamat on 10/10/2025.
//

import Foundation

struct Activity: Identifiable, Codable, Sendable {
    let id: UUID
    let memberName: String
    let activityName: String
    let distance: Double // in kilometers
    let date: Date

    init(id: UUID = UUID(), memberName: String, activityName: String, distance: Double, date: Date) {
        self.id = id
        self.memberName = memberName
        self.activityName = activityName
        self.distance = distance
        self.date = date
    }
}
