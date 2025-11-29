//
//  HomeView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI
import SwiftData

/// 탭 종류
enum HomeTab: String, CaseIterable {
    case home = "홈"
    case safetyScore = "안전점수"
}

/// 홈 화면 (메인 대시보드)
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()
    @State private var hideAmounts = false
    @State private var selectedTab: HomeTab = .home
    
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
                    homeTabContent
                        .tag(HomeTab.home)
                    
                    safetyScoreTabContent
                        .tag(HomeTab.safetyScore)
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
        .sheet(isPresented: $viewModel.showDepositSheet) {
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
            ForEach(HomeTab.allCases, id: \.self) { tab in
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
    
    // MARK: - Home Tab Content
    
    private var homeTabContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: ExitSpacing.lg) {
                // D-DAY 헤더
                dDayHeader
                
                // 진행률 섹션
                progressSection
                
                // 시나리오 탭
                ScenarioTabBar(
                    scenarios: viewModel.scenarios,
                    selectedScenario: viewModel.activeScenario,
                    onSelect: { scenario in
                        withAnimation {
                            viewModel.selectScenario(scenario)
                        }
                    },
                    onSettings: {
                        viewModel.showScenarioSheet = true
                    }
                )
                
                // 시나리오 설정값 테이블
                scenarioSettingsCard
            }
            .padding(.vertical, ExitSpacing.lg)
        }
    }
    
    // MARK: - Safety Score Tab Content
    
    private var safetyScoreTabContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: ExitSpacing.lg) {
                SafetyScoreCard(
                    totalScore: viewModel.totalSafetyScore,
                    scoreChange: viewModel.safetyScoreChangeText,
                    details: viewModel.safetyScoreDetails,
                    alwaysExpanded: true
                )
                .padding(.horizontal, ExitSpacing.md)
            }
            .padding(.vertical, ExitSpacing.lg)
        }
    }
    
    // MARK: - Scenario Settings Card
    
    private var scenarioSettingsCard: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            if let scenario = viewModel.activeScenario {
                // 헤더
                HStack {
                    Text("시나리오 설정")
                        .font(.Exit.subheadline)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    Spacer()
                    
                    Text(scenario.name)
                        .font(.Exit.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.Exit.accent)
                        .padding(.horizontal, ExitSpacing.sm)
                        .padding(.vertical, ExitSpacing.xs)
                        .background(
                            Capsule()
                                .fill(Color.Exit.accent.opacity(0.15))
                        )
                }
                
                Divider()
                    .background(Color.Exit.divider)
                
                // 설정값 테이블
                VStack(spacing: ExitSpacing.sm) {
                    ScenarioSettingRow(
                        label: "은퇴 후 희망 월수입",
                        value: ExitNumberFormatter.formatToManWon(scenario.desiredMonthlyIncome)
                    )
                    
                    ScenarioSettingRow(
                        label: "현재 순자산",
                        value: ExitNumberFormatter.formatToEokManWon(scenario.currentNetAssets),
                        isHidden: hideAmounts
                    )
                    
                    ScenarioSettingRow(
                        label: "매월 목표 투자금액",
                        value: ExitNumberFormatter.formatToManWon(scenario.monthlyInvestment)
                    )
                    
                    Divider()
                        .background(Color.Exit.divider)
                        .padding(.vertical, ExitSpacing.xs)
                    
                    ScenarioSettingRow(
                        label: "은퇴 전 연 목표 수익률",
                        value: String(format: "%.1f%%", scenario.preRetirementReturnRate),
                        valueColor: Color.Exit.accent
                    )
                    
                    ScenarioSettingRow(
                        label: "은퇴 후 연 목표 수익률",
                        value: String(format: "%.1f%%", scenario.postRetirementReturnRate),
                        valueColor: Color.Exit.accent
                    )
                    
                    ScenarioSettingRow(
                        label: "예상 물가 상승률",
                        value: String(format: "%.1f%%", scenario.inflationRate),
                        valueColor: Color.Exit.caution
                    )
                }
            }
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // MARK: - D-DAY Header
    
    private var dDayHeader: some View {
        VStack(spacing: ExitSpacing.md) {
            dDayMainTitle
        }
        .padding(ExitSpacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: ExitRadius.xl)
                .fill(LinearGradient.exitCard)
                .exitCardShadow()
        )
        .padding(.horizontal, ExitSpacing.md)
    }
    
    private var dDayMainTitle: some View {
        Group {
            if let result = viewModel.retirementResult {
                if result.monthsToRetirement == 0 {
                    Text("이미 은퇴 가능합니다! 🎉")
                        .font(.Exit.title)
                        .foregroundStyle(Color.Exit.accent)
                } else {
                    VStack(spacing: ExitSpacing.xs) {
                        Text("회사 탈출까지")
                            .font(.Exit.body)
                            .foregroundStyle(Color.Exit.secondaryText)
                        
                        Text(result.dDayString)
                            .font(.Exit.title)
                            .foregroundStyle(Color.Exit.accent)
                            .fontWeight(.heavy)
                        
                        Text("남았습니다.")
                            .font(.Exit.body)
                            .foregroundStyle(Color.Exit.secondaryText)
                    }
                }
            } else {
                Text("계산 중...")
                    .font(.Exit.title2)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
        }
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: ExitSpacing.lg) {
            // 진행률 링 차트 + 토글 버튼
            if let scenario = viewModel.activeScenario, let result = viewModel.retirementResult {
                ZStack(alignment: .bottomTrailing) {
                    ProgressRingView(
                        progress: viewModel.progressValue,
                        currentAmount: ExitNumberFormatter.formatToEokManWon(scenario.currentNetAssets),
                        targetAmount: ExitNumberFormatter.formatToEokManWon(result.targetAssets),
                        percentText: ExitNumberFormatter.formatPercentInt(result.progressPercent),
                        hideAmounts: hideAmounts
                    )
                    .frame(width: 200, height: 200)
                    
                    // 금액 숨김 토글 (우측 하단)
                    amountVisibilityToggle
                        .offset(x: 10, y: 10)
                }
            }
            
            // 상세 계산 설명
            detailedCalculationCard
        }
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // MARK: - Amount Visibility Toggle
    
    private var amountVisibilityToggle: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                hideAmounts.toggle()
            }
        } label: {
            Text(hideAmounts ? "금액 보기" : "금액 숨김")
                .font(.Exit.caption2)
                .fontWeight(.medium)
                .foregroundStyle(hideAmounts ? Color.Exit.accent : Color.Exit.tertiaryText)
                .padding(.horizontal, ExitSpacing.sm)
                .padding(.vertical, ExitSpacing.xs)
                .background(
                    Capsule()
                        .fill(Color.Exit.cardBackground)
                        .overlay(
                            Capsule()
                                .stroke(hideAmounts ? Color.Exit.accent : Color.Exit.divider, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
    
    private var detailedCalculationCard: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            if let scenario = viewModel.activeScenario, let result = viewModel.retirementResult {
                // 현재 자산 / 목표 자산 (1줄 유지, 자동 축소)
                AssetProgressRow(
                    currentAssets: ExitNumberFormatter.formatToEokManWon(scenario.currentNetAssets),
                    targetAssets: ExitNumberFormatter.formatToEokManWon(result.targetAssets),
                    percent: ExitNumberFormatter.formatPercentInt(result.progressPercent),
                    isHidden: hideAmounts
                )
                
                Divider()
                    .background(Color.Exit.divider)
                
                // 설명 텍스트
                VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                    HStack(spacing: 0) {
                        Text("매월 ")
                            .foregroundStyle(Color.Exit.secondaryText)
                        Text(ExitNumberFormatter.formatToManWon(scenario.desiredMonthlyIncome))
                            .foregroundStyle(Color.Exit.accent)
                            .fontWeight(.semibold)
                        Text("의 현금흐름을 만들기 위해")
                            .foregroundStyle(Color.Exit.secondaryText)
                    }
                    .font(.Exit.subheadline)
                    
                    HStack(spacing: 0) {
                        Text("매월 ")
                            .foregroundStyle(Color.Exit.secondaryText)
                        Text(ExitNumberFormatter.formatToManWon(scenario.monthlyInvestment))
                            .foregroundStyle(Color.Exit.accent)
                            .fontWeight(.semibold)
                        Text("씩 연복리 ")
                            .foregroundStyle(Color.Exit.secondaryText)
                        Text(String(format: "%.1f%%", scenario.preRetirementReturnRate))
                            .foregroundStyle(Color.Exit.accent)
                            .fontWeight(.semibold)
                        Text("로 투자하면")
                            .foregroundStyle(Color.Exit.secondaryText)
                    }
                    .font(.Exit.subheadline)
                    
                    HStack(spacing: 0) {
                        Text(result.dDayString)
                            .font(.Exit.title3)
                            .foregroundStyle(Color.Exit.accent)
                            .fontWeight(.bold)
                        Text(" 남았습니다.")
                            .font(.Exit.subheadline)
                            .foregroundStyle(Color.Exit.secondaryText)
                    }
                }
            }
        }
        .padding(ExitSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
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
                viewModel.passiveIncomeAmount = 0
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
        .padding(.horizontal, ExitSpacing.md)
        .padding(.bottom, ExitSpacing.lg)
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

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(for: [UserProfile.self, Scenario.self, MonthlyUpdate.self], inMemory: true)
        .preferredColorScheme(.dark)
}
