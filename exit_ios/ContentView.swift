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
    case simulation = "시뮬레이션"
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

/// 메인 탭 뷰 (대시보드 + 기록 + 시뮬레이션)
struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()
    @State private var simulationViewModel = SimulationViewModel()
    @State private var settingsViewModel = SettingsViewModel()
    @State private var hideAmounts = false
    @State private var selectedTab: MainTab = .dashboard
    @State private var shouldNavigateToWelcome = false
    @State private var showSettings = false
    
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
                    
                    SimulationView(viewModel: simulationViewModel)
                        .tag(MainTab.simulation)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.none, value: selectedTab)
            }
            
            // 입금 완료 후 자산 업데이트 확인 다이얼로그
            if viewModel.showAssetUpdateConfirm {
                assetUpdateConfirmOverlay
            }
        }
        .onAppear {
            viewModel.configure(with: modelContext)
            simulationViewModel.configure(with: modelContext)
            settingsViewModel.configure(with: modelContext)
        }
        .onChange(of: shouldNavigateToWelcome) { _, newValue in
            // 데이터 삭제 후 앱 재시작을 위해 UserProfile을 다시 체크
            // ContentView에서 hasCompletedOnboarding을 확인하므로 자동으로 WelcomeView로 이동
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
            // 메인 탭들
            ForEach(MainTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: ExitSpacing.xs) {
                        Text(tab.rawValue)
                            .font(.Exit.caption)
                            .fontWeight(selectedTab == tab ? .bold : .medium)
                            .foregroundStyle(selectedTab == tab ? Color.Exit.accent : Color.Exit.secondaryText)
                        
                        // 인디케이터
                        Rectangle()
                            .fill(selectedTab == tab ? Color.Exit.accent : Color.clear)
                            .frame(height: 3)
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)
                    .animation(.easeInOut(duration: 0.2), value: selectedTab)
                }
                .buttonStyle(.plain)
            }
            
            // 설정 아이콘
            Button {
                showSettings = true
            } label: {
                VStack(spacing: ExitSpacing.xs) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 3)
                }
                .frame(width: 60)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, ExitSpacing.md)
        .padding(.top, ExitSpacing.md)
        .background(Color.Exit.background)
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: settingsViewModel, shouldNavigateToWelcome: $shouldNavigateToWelcome)
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
                        viewModel.showAssetUpdateConfirm = false
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
                        Text(ExitNumberFormatter.formatToEokManWon(viewModel.currentAssetAmount))
                            .font(.Exit.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.Exit.accent)
                    }
                    
                    if let asset = viewModel.currentAsset {
                        Text("(\(viewModel.lastAssetUpdateText) 기준)")
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.tertiaryText)
                    }
                }
                
                // 버튼
                HStack(spacing: ExitSpacing.sm) {
                    // 나중에 버튼
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.showAssetUpdateConfirm = false
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
                            viewModel.showAssetUpdateConfirm = false
                        }
                        // 약간의 딜레이 후 자산 업데이트 시트 표시
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            viewModel.totalAssetsInput = viewModel.currentAssetAmount
                            if let asset = viewModel.currentAsset {
                                viewModel.selectedAssetTypes = Set(asset.assetTypes)
                            }
                            viewModel.showAssetUpdateSheet = true
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
}
