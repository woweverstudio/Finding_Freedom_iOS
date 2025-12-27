//
//  ContentView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI
import SwiftData

/// 메인 탭 종류
enum MainTab: String, CaseIterable {
    case dashboard = "홈"
    case simulation = "시뮬레이션"
    case portfolio = "포트폴리오"
    case menu = "메뉴"
    
    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .simulation: return "chart.line.uptrend.xyaxis"
        case .portfolio: return "chart.pie.fill"
        case .menu: return "line.3.horizontal"
        }
    }
}

/// 앱 메인 컨텐츠 뷰
/// 온보딩 완료 여부에 따라 온보딩 또는 메인 탭 화면을 표시
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appState) private var appState
    @Query private var userProfiles: [UserProfile]
    
    /// 온보딩 완료 여부
    private var hasCompletedOnboarding: Bool {
        userProfiles.first?.hasCompletedOnboarding ?? false
    }
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }        
        .onAppear {
            appState.configure(with: modelContext)
        }
    }
}

/// 메인 탭 뷰 (대시보드 + 시뮬레이션 + 포트폴리오 + 메뉴)
/// 구조: 상단 PlanHeader + 중앙 컨텐츠(스크롤) + 하단 탭바
struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appState) private var appState
    @State private var simulationViewModel = SimulationViewModel()
    @State private var portfolioViewModel = PortfolioViewModel()
    @State private var menuViewModel = MenuViewModel()
    @State private var shouldNavigateToWelcome = false
    
    // @Observable 객체에서 바인딩을 사용하려면 @Bindable 필요
    private var bindableAppState: Bindable<AppStateManager> {
        Bindable(appState)
    }
    
    var body: some View {
        TabView(selection: bindableAppState.selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: MainTab.dashboard.icon)
                    Text(MainTab.dashboard.rawValue)
                }
                .tag(MainTab.dashboard)
            
            SimulationView(viewModel: simulationViewModel)
                .tabItem {
                    Image(systemName: MainTab.simulation.icon)
                    Text(MainTab.simulation.rawValue)
                }
                .tag(MainTab.simulation)
            
            PortfolioView(viewModel: portfolioViewModel)
                .tabItem {
                    Image(systemName: MainTab.portfolio.icon)
                    Text(MainTab.portfolio.rawValue)
                }
                .tag(MainTab.portfolio)
            
            MenuView(viewModel: menuViewModel, shouldNavigateToWelcome: $shouldNavigateToWelcome)
                .tabItem {
                    Image(systemName: MainTab.menu.icon)
                    Text(MainTab.menu.rawValue)
                }
                .tag(MainTab.menu)
        }
        .tabViewStyle(.sidebarAdaptable)
        .tint(Color.Exit.accent)
        .onAppear {
            // 온보딩 완료 후 또는 앱 재진입 시 데이터 로드
            appState.loadData()
            simulationViewModel.configure(with: modelContext)
            menuViewModel.configure(with: modelContext)
        }
        .onChange(of: shouldNavigateToWelcome) { _, newValue in
            // 데이터 삭제 후 앱 재시작을 위해 UserProfile을 다시 체크
            // ContentView에서 hasCompletedOnboarding을 확인하므로 자동으로 WelcomeView로 이동
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            UserProfile.self,
            DepositReminder.self
        ], inMemory: true)
        .environment(\.appState, AppStateManager())
}
