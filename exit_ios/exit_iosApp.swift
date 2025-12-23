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
            MonthlyUpdate.self,
            Asset.self,
            AssetSnapshot.self,
            DepositReminder.self
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
    
    /// 전역 앱 상태 관리자
    @State private var appStateManager = AppStateManager()
    
    /// 인앱결제 서비스
    @State private var storeKitService = StoreKitService()
    
    init() {
        // 앱 실행 기록 (리뷰 요청 조건 추적용)
        Task { @MainActor in
            ReviewService.shared.recordAppLaunch()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environment(\.appState, appStateManager)
                .environment(\.storeService, storeKitService)
        }
        .modelContainer(sharedModelContainer)
    }
}
