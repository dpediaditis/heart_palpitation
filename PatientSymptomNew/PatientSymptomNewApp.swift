//
//  PatientSymptomNewApp.swift
//  PatientSymptomNew
//
//  Created by HARSIMRAN KAUR on 2025-04-28.
//

import SwiftUI
import SwiftData

@main
struct PatientSymptomNewApp: App {
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
