//
//  Item.swift
//  DCC Weekly Activities TV
//
//  Created by Amit Kamat on 10/02/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
