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
    case record = "기록"
    case menu = "메뉴"
    
    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .simulation: return "chart.line.uptrend.xyaxis"
        case .record: return "calendar"
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
        .preferredColorScheme(.dark)
        .onAppear {
            appState.configure(with: modelContext)
        }
    }
}

/// 메인 탭 뷰 (대시보드 + 기록 + 시뮬레이션 + 메뉴)
/// 구조: 상단 PlanHeader + 중앙 컨텐츠(스크롤) + 하단 탭바
struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appState) private var appState
    @State private var simulationViewModel = SimulationViewModel()
    @State private var settingsViewModel = SettingsViewModel()
    @State private var shouldNavigateToWelcome = false
    
    // @Observable 객체에서 바인딩을 사용하려면 @Bindable 필요
    private var bindableAppState: Bindable<AppStateManager> {
        Bindable(appState)
    }
    
    var body: some View {
        ZStack {
            // 탭뷰
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
                    
                    RecordTabView()
                        .tabItem {
                            Image(systemName: MainTab.record.icon)
                            Text(MainTab.record.rawValue)
                        }
                        .tag(MainTab.record)
                    
                    SettingsView(viewModel: settingsViewModel, shouldNavigateToWelcome: $shouldNavigateToWelcome)
                        .tabItem {
                            Image(systemName: MainTab.menu.icon)
                            Text(MainTab.menu.rawValue)
                        }
                        .tag(MainTab.menu)
            }
            .tabViewStyle(.sidebarAdaptable)
            .tint(Color.Exit.accent)
            
            // 입금 완료 후 자산 업데이트 확인 다이얼로그
            if appState.showAssetUpdateConfirm {
                assetUpdateConfirmOverlay
            }
        }
        .onAppear {
            simulationViewModel.configure(with: modelContext)
            settingsViewModel.configure(with: modelContext)
        }
        .onChange(of: shouldNavigateToWelcome) { _, newValue in
            // 데이터 삭제 후 앱 재시작을 위해 UserProfile을 다시 체크
            // ContentView에서 hasCompletedOnboarding을 확인하므로 자동으로 WelcomeView로 이동
        }
        .fullScreenCover(isPresented: bindableAppState.showDepositSheet) {
            DepositSheet()
        }
        .sheet(isPresented: bindableAppState.showAssetUpdateSheet) {
            AssetUpdateSheet()
        }
        .fullScreenCover(isPresented: bindableAppState.showScenarioSheet) {
            ScenarioSettingsView()
        }
    }
    
    // MARK: - Asset Update Confirm Overlay
    
    private var assetUpdateConfirmOverlay: some View {
        ZStack {
            // 딤 배경
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        appState.showAssetUpdateConfirm = false
                    }
                }
            
            // 다이얼로그
            VStack(spacing: ExitSpacing.lg) {
                // 아이콘
                ZStack {
                    Circle()
                        .fill(Color.Exit.accent.opacity(0.2))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.Exit.accent)
                }
                
                // 타이틀
                Text("입금 기록 완료!")
                    .font(.Exit.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.Exit.primaryText)
                
                // 메시지
                VStack(spacing: ExitSpacing.xs) {
                    Text("자산도 함께 업데이트할까요?")
                        .font(.Exit.body)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    HStack(spacing: ExitSpacing.xs) {
                        Text("현재 기록된 자산:")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.tertiaryText)
                        Text(ExitNumberFormatter.formatToEokManWon(appState.currentAssetAmount))
                            .font(.Exit.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.Exit.accent)
                    }
                    
                    if appState.currentAsset != nil {
                        Text("(\(appState.lastAssetUpdateText) 기준)")
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.tertiaryText)
                    }
                }
                
                // 버튼
                HStack(spacing: ExitSpacing.sm) {
                    // 나중에 버튼
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            appState.showAssetUpdateConfirm = false
                        }
                    } label: {
                        Text("나중에")
                            .font(.Exit.body)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.Exit.secondaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.Exit.secondaryCardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
                    }
                    .buttonStyle(.plain)
                    
                    // 자산 업데이트 버튼
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            appState.showAssetUpdateConfirm = false
                        }
                        // 약간의 딜레이 후 자산 업데이트 시트 표시
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            appState.totalAssetsInput = appState.currentAssetAmount
                            if let asset = appState.currentAsset {
                                appState.selectedAssetTypes = Set(asset.assetTypes)
                            }
                            appState.showAssetUpdateSheet = true
                        }
                    } label: {
                        Text("자산 업데이트")
                            .font(.Exit.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(LinearGradient.exitAccent)
                            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(ExitSpacing.lg)
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.xl))
            .padding(.horizontal, ExitSpacing.xl)
            .transition(.scale.combined(with: .opacity))
        }
        .transition(.opacity)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            UserProfile.self,
            Scenario.self,
            MonthlyUpdate.self,
            Asset.self,
            AssetSnapshot.self,
            DepositReminder.self
        ], inMemory: true)
        .environment(\.appState, AppStateManager())
}
