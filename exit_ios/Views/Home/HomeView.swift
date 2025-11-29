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
        ScrollView {
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
            }
            .padding(.vertical, ExitSpacing.lg)
        }
    }
    
    // MARK: - Safety Score Tab Content
    
    private var safetyScoreTabContent: some View {
        ScrollView {
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

// MARK: - Blurred Amount Text Component

/// 금액을 블러 처리하는 텍스트 컴포넌트
struct BlurredAmountText: View {
    let text: String
    let isHidden: Bool
    
    var body: some View {
        Text(text)
            .blur(radius: isHidden ? 8 : 0)
            .opacity(isHidden ? 0.6 : 1)
    }
}

/// 자산 진행률 표시 행 (자동 축소로 1줄 유지, 블러 처리)
struct AssetProgressRow: View {
    let currentAssets: String
    let targetAssets: String
    let percent: String
    let isHidden: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Text(currentAssets)
                .foregroundStyle(Color.Exit.accent)
                .blur(radius: isHidden ? 10 : 0)
            
            Text("/")
                .foregroundStyle(Color.Exit.tertiaryText)
            
            Text(targetAssets)
                .foregroundStyle(Color.Exit.primaryText)
                .blur(radius: isHidden ? 10 : 0)
            
            Text("(\(percent))")
                .foregroundStyle(Color.Exit.secondaryText)
                .blur(radius: isHidden ? 8 : 0)
        }
        .font(.Exit.title3)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .animation(.easeInOut(duration: 0.2), value: isHidden)
    }
}

// MARK: - Deposit Sheet

struct DepositSheet: View {
    @Bindable var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showPassiveIncomeInput = false
    
    var body: some View {
        ZStack {
            Color.Exit.background.ignoresSafeArea()
            
            VStack(spacing: ExitSpacing.lg) {
                sheetHeader(title: "입금하기")
                
                ScrollView {
                    VStack(spacing: ExitSpacing.xl) {
                        VStack(spacing: ExitSpacing.sm) {
                            Text("이번 달 투자·저축 입금액")
                                .font(.Exit.body)
                                .foregroundStyle(Color.Exit.secondaryText)
                            
                            Text(ExitNumberFormatter.formatToEokManWon(viewModel.depositAmount))
                                .font(.Exit.numberDisplay)
                                .foregroundStyle(Color.Exit.primaryText)
                        }
                        
                        Button {
                            withAnimation {
                                showPassiveIncomeInput.toggle()
                            }
                        } label: {
                            HStack {
                                Text("이번 달 받은 패시브인컴 총액 (선택)")
                                    .font(.Exit.subheadline)
                                    .foregroundStyle(Color.Exit.secondaryText)
                                
                                Spacer()
                                
                                Image(systemName: showPassiveIncomeInput ? "chevron.up" : "chevron.down")
                                    .foregroundStyle(Color.Exit.tertiaryText)
                            }
                            .padding(ExitSpacing.md)
                            .background(Color.Exit.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
                        }
                        .padding(.horizontal, ExitSpacing.md)
                        
                        if showPassiveIncomeInput {
                            VStack(spacing: ExitSpacing.sm) {
                                Text("배당 + 이자 + 월세 등")
                                    .font(.Exit.caption)
                                    .foregroundStyle(Color.Exit.tertiaryText)
                                
                                Text(ExitNumberFormatter.formatToManWon(viewModel.passiveIncomeAmount))
                                    .font(.Exit.title2)
                                    .foregroundStyle(Color.Exit.accent)
                            }
                        }
                    }
                    .padding(.top, ExitSpacing.lg)
                }
                
                CustomNumberKeyboard(
                    value: showPassiveIncomeInput ? $viewModel.passiveIncomeAmount : $viewModel.depositAmount
                )
                
                Button {
                    viewModel.submitDeposit()
                } label: {
                    Text("입금 완료")
                        .exitPrimaryButton(isEnabled: viewModel.depositAmount > 0)
                }
                .disabled(viewModel.depositAmount <= 0)
                .padding(.horizontal, ExitSpacing.md)
                .padding(.bottom, ExitSpacing.lg)
            }
        }
        .presentationDetents([.large])
    }
    
    private func sheetHeader(title: String) -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            
            Spacer()
            
            Text(title)
                .font(.Exit.title3)
                .foregroundStyle(Color.Exit.primaryText)
            
            Spacer()
            
            Image(systemName: "xmark")
                .font(.Exit.body)
                .foregroundStyle(.clear)
        }
        .padding(.horizontal, ExitSpacing.lg)
        .padding(.top, ExitSpacing.lg)
    }
}

// MARK: - Asset Update Sheet

struct AssetUpdateSheet: View {
    @Bindable var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAssetTypes = false
    
    var body: some View {
        ZStack {
            Color.Exit.background.ignoresSafeArea()
            
            VStack(spacing: ExitSpacing.lg) {
                sheetHeader(title: "자산 변동 업데이트")
                
                ScrollView {
                    VStack(spacing: ExitSpacing.xl) {
                        VStack(spacing: ExitSpacing.sm) {
                            Text("현재 총 투자 가능 자산")
                                .font(.Exit.body)
                                .foregroundStyle(Color.Exit.secondaryText)
                            
                            Text(ExitNumberFormatter.formatToEokManWon(viewModel.totalAssetsInput))
                                .font(.Exit.numberDisplay)
                                .foregroundStyle(Color.Exit.primaryText)
                        }
                        
                        Button {
                            withAnimation {
                                showAssetTypes.toggle()
                            }
                        } label: {
                            HStack {
                                Text("보유 자산 종류 변경")
                                    .font(.Exit.subheadline)
                                    .foregroundStyle(Color.Exit.secondaryText)
                                
                                Spacer()
                                
                                Text("\(viewModel.selectedAssetTypes.count)개 선택")
                                    .font(.Exit.caption)
                                    .foregroundStyle(Color.Exit.accent)
                                
                                Image(systemName: showAssetTypes ? "chevron.up" : "chevron.down")
                                    .foregroundStyle(Color.Exit.tertiaryText)
                            }
                            .padding(ExitSpacing.md)
                            .background(Color.Exit.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
                        }
                        .padding(.horizontal, ExitSpacing.md)
                        
                        if showAssetTypes {
                            assetTypeGrid
                        }
                    }
                    .padding(.top, ExitSpacing.lg)
                }
                
                CustomNumberKeyboard(
                    value: $viewModel.totalAssetsInput,
                    showNegativeToggle: true
                )
                
                Button {
                    viewModel.submitAssetUpdate()
                } label: {
                    Text("업데이트 완료")
                        .exitPrimaryButton()
                }
                .padding(.horizontal, ExitSpacing.md)
                .padding(.bottom, ExitSpacing.lg)
            }
        }
        .presentationDetents([.large])
    }
    
    private var assetTypeGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: ExitSpacing.sm) {
            ForEach(UserProfile.availableAssetTypes, id: \.self) { type in
                Button {
                    viewModel.toggleAssetType(type)
                } label: {
                    HStack {
                        Text(type)
                            .font(.Exit.caption)
                        Spacer()
                        if viewModel.selectedAssetTypes.contains(type) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                        }
                    }
                    .foregroundStyle(viewModel.selectedAssetTypes.contains(type) ? Color.Exit.primaryText : Color.Exit.secondaryText)
                    .padding(ExitSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: ExitRadius.sm)
                            .fill(viewModel.selectedAssetTypes.contains(type) ? Color.Exit.accent.opacity(0.2) : Color.Exit.secondaryCardBackground)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, ExitSpacing.md)
    }
    
    private func sheetHeader(title: String) -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            
            Spacer()
            
            Text(title)
                .font(.Exit.title3)
                .foregroundStyle(Color.Exit.primaryText)
            
            Spacer()
            
            Image(systemName: "xmark")
                .font(.Exit.body)
                .foregroundStyle(.clear)
        }
        .padding(.horizontal, ExitSpacing.lg)
        .padding(.top, ExitSpacing.lg)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(for: [UserProfile.self, Scenario.self, MonthlyUpdate.self], inMemory: true)
        .preferredColorScheme(.dark)
}
