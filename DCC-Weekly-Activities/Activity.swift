//
//  Activity.swift
//  DCC-Weekly-Activities
//
//  Activity model — shared across iOS and tvOS targets.
//

import Foundation

// MARK: - Activity Model
struct Activity: Codable, Identifiable, Hashable {
    let id: UUID
    let memberName: String
    let activityName: String
    let distance: Double // in km
    let date: Date
    let averageSpeed: Double // in km/h
    let elevationGain: Double // in meters
    let movingTime: Int // in seconds
    let type: String

    init(
        id: UUID = UUID(),
        memberName: String,
        activityName: String,
        distance: Double,
        date: Date,
        averageSpeed: Double,
        elevationGain: Double,
        movingTime: Int,
        type: String = "Ride"
    ) {
        self.id = id
        self.memberName = memberName
        self.activityName = activityName
        self.distance = distance
        self.date = date
        self.averageSpeed = averageSpeed
        self.elevationGain = elevationGain
        self.movingTime = movingTime
        self.type = type
    }
}
