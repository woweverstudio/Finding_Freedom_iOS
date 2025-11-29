//
//  exit_iosApp.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI
import SwiftData

@main
struct exit_iosApp: App {
    /// SwiftData 모델 컨테이너
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            Scenario.self,
            MonthlyUpdate.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }
}
