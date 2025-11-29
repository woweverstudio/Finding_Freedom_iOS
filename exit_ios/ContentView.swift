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
    case record = "기록"
}

/// 앱 메인 컨텐츠 뷰
/// 온보딩 완료 여부에 따라 온보딩 또는 메인 탭 화면을 표시
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
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

/// 메인 탭 뷰 (대시보드 + 기록)
struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()
    @State private var hideAmounts = false
    @State private var selectedTab: MainTab = .dashboard
    
    var body: some View {
        ZStack {
            // 배경
            LinearGradient.exitBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 커스텀 탭 바
                customTabBar
                
                // 탭 컨텐츠
                TabView(selection: $selectedTab) {
                    DashboardView(viewModel: viewModel, hideAmounts: $hideAmounts)
                        .tag(MainTab.dashboard)
                    
                    RecordTabView(viewModel: viewModel)
                        .tag(MainTab.record)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // 플로팅 버튼 공간
                Spacer()
                    .frame(height: 80)
            }
            
            // 하단 플로팅 버튼
            VStack {
                Spacer()
                floatingActionButtons
            }
        }
        .onAppear {
            viewModel.configure(with: modelContext)
        }
        .fullScreenCover(isPresented: $viewModel.showDepositSheet) {
            DepositSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showAssetUpdateSheet) {
            AssetUpdateSheet(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $viewModel.showScenarioSheet) {
            ScenarioSettingsView(viewModel: viewModel)
        }
    }
    
    // MARK: - Custom Tab Bar
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: ExitSpacing.xs) {
                        Text(tab.rawValue)
                            .font(.Exit.body)
                            .fontWeight(selectedTab == tab ? .bold : .medium)
                            .foregroundStyle(selectedTab == tab ? Color.Exit.accent : Color.Exit.secondaryText)
                        
                        // 인디케이터
                        Rectangle()
                            .fill(selectedTab == tab ? Color.Exit.accent : Color.clear)
                            .frame(height: 3)
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, ExitSpacing.xl)
        .padding(.top, ExitSpacing.md)
        .background(Color.Exit.background)
    }
    
    // MARK: - Floating Action Buttons
    
    private var floatingActionButtons: some View {
        HStack(spacing: ExitSpacing.md) {
            // 자산 변동 업데이트 (좌측)
            Button {
                if let lastUpdate = viewModel.monthlyUpdates.first {
                    viewModel.totalAssetsInput = lastUpdate.totalAssets
                    viewModel.selectedAssetTypes = Set(lastUpdate.assetTypes)
                } else if let scenario = viewModel.activeScenario {
                    viewModel.totalAssetsInput = scenario.currentNetAssets
                }
                viewModel.showAssetUpdateSheet = true
            } label: {
                HStack(spacing: ExitSpacing.xs) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14, weight: .semibold))
                    Text("자산 업데이트")
                        .font(.Exit.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color.Exit.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.Exit.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: ExitRadius.md)
                        .stroke(Color.Exit.divider, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            
            // 입금하기 (우측)
            Button {
                viewModel.depositAmount = 0
                viewModel.depositDate = Date()
                viewModel.showDepositSheet = true
            } label: {
                HStack(spacing: ExitSpacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("입금하기")
                        .font(.Exit.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(LinearGradient.exitAccent)
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
                .exitButtonShadow()
            }
            .buttonStyle(.plain)
        }
        .padding(ExitSpacing.md)
        .background(
            LinearGradient(
                colors: [Color.Exit.background.opacity(0), Color.Exit.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
            .allowsHitTesting(false)
        )
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
