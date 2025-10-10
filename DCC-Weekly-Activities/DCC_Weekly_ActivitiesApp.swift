//
//  DCC_Weekly_ActivitiesApp.swift
//  DCC-Weekly-Activities
//
//  Created by Amit Kamat on 10/10/2025.
//

import SwiftUI
import SwiftData

@main
struct DCC_Weekly_ActivitiesApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
