//
//  ContentView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI
import SwiftData

/// 앱 메인 컨텐츠 뷰
/// 온보딩 완료 여부에 따라 온보딩 또는 홈 화면을 표시
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    
    /// 온보딩 완료 여부
    private var hasCompletedOnboarding: Bool {
        userProfiles.first?.hasCompletedOnboarding ?? false
    }
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                HomeView()
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            UserProfile.self,
            Scenario.self,
            MonthlyUpdate.self
        ], inMemory: true)
}
