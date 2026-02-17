//
//  DCC_Weekly_Activities_TVApp.swift
//  DCC Weekly Activities TV
//
//  Created by Amit Kamat on 10/02/2026.
//

import SwiftUI
import SwiftData

@main
struct DCC_Weekly_Activities_TVApp: App {
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
