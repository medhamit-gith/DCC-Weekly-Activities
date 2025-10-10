//
//  Item.swift
//  DCC-Weekly-Activities
//
//  Created by Amit Kamat on 10/10/2025.
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
