//
//  HomeView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI
import SwiftData

/// 홈 화면 (메인 대시보드)
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()
    
    var body: some View {
        ZStack {
            // 배경
            LinearGradient.exitBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: ExitSpacing.lg) {
                    // D-DAY 헤더
                    dDayHeader
                    
                    // 진행률 링 차트
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
                    
                    // 액션 버튼들
                    actionButtons
                    
                    // 안전 점수 카드
                    SafetyScoreCard(
                        totalScore: viewModel.totalSafetyScore,
                        scoreChange: viewModel.safetyScoreChangeText,
                        details: viewModel.safetyScoreDetails
                    )
                    .padding(.horizontal, ExitSpacing.md)
                }
                .padding(.vertical, ExitSpacing.lg)
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
    
    // MARK: - D-DAY Header
    
    private var dDayHeader: some View {
        VStack(spacing: ExitSpacing.md) {
            Text(viewModel.dDayMainText)
                .font(.Exit.largeTitle)
                .foregroundStyle(Color.Exit.primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            
            Text(viewModel.dDaySubText)
                .font(.Exit.body)
                .foregroundStyle(Color.Exit.secondaryText)
                .multilineTextAlignment(.center)
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
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: ExitSpacing.md) {
            if let scenario = viewModel.activeScenario, let result = viewModel.retirementResult {
                ProgressRingView(
                    progress: viewModel.progressValue,
                    currentAmount: ExitNumberFormatter.formatToEokManWon(scenario.currentNetAssets),
                    targetAmount: ExitNumberFormatter.formatToEokManWon(result.targetAssets),
                    percentText: ExitNumberFormatter.formatPercentInt(result.progressPercent)
                )
                .frame(width: 220, height: 220)
            } else {
                ProgressRingView(
                    progress: 0,
                    currentAmount: "0만원",
                    targetAmount: "계산 중...",
                    percentText: "0%"
                )
                .frame(width: 220, height: 220)
            }
            
            // 자세히 보기 버튼
            Button {
                // 상세 정보 표시 (추후 구현)
            } label: {
                HStack(spacing: ExitSpacing.xs) {
                    Text("자세히 보기")
                    Image(systemName: "chevron.down")
                }
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: ExitSpacing.md) {
            // 입금하고 기간 줄이기
            Button {
                viewModel.depositAmount = 0
                viewModel.passiveIncomeAmount = 0
                viewModel.showDepositSheet = true
            } label: {
                Text("입금하고 기간 줄이기")
                    .exitPrimaryButton()
            }
            
            // 자산 변동 업데이트
            Button {
                if let lastUpdate = viewModel.monthlyUpdates.first {
                    viewModel.totalAssetsInput = lastUpdate.totalAssets
                    viewModel.selectedAssetTypes = Set(lastUpdate.assetTypes)
                } else if let scenario = viewModel.activeScenario {
                    viewModel.totalAssetsInput = scenario.currentNetAssets
                }
                viewModel.showAssetUpdateSheet = true
            } label: {
                Text("자산 변동 업데이트")
                    .exitSecondaryButton()
            }
        }
        .padding(.horizontal, ExitSpacing.md)
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
                // 헤더
                sheetHeader(title: "입금하고 기간 줄이기")
                
                ScrollView {
                    VStack(spacing: ExitSpacing.xl) {
                        // 투자·저축 입금액
                        VStack(spacing: ExitSpacing.sm) {
                            Text("이번 달 투자·저축 입금액")
                                .font(.Exit.body)
                                .foregroundStyle(Color.Exit.secondaryText)
                            
                            Text(ExitNumberFormatter.formatToEokManWon(viewModel.depositAmount))
                                .font(.Exit.numberDisplay)
                                .foregroundStyle(Color.Exit.primaryText)
                        }
                        
                        // 패시브인컴 입력 토글
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
                
                // 키보드
                CustomNumberKeyboard(
                    value: showPassiveIncomeInput ? $viewModel.passiveIncomeAmount : $viewModel.depositAmount
                )
                
                // 확인 버튼
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
            
            // 균형을 위한 투명 버튼
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
                // 헤더
                sheetHeader(title: "자산 변동 업데이트")
                
                ScrollView {
                    VStack(spacing: ExitSpacing.xl) {
                        // 현재 총 투자 가능 자산
                        VStack(spacing: ExitSpacing.sm) {
                            Text("현재 총 투자 가능 자산")
                                .font(.Exit.body)
                                .foregroundStyle(Color.Exit.secondaryText)
                            
                            Text(ExitNumberFormatter.formatToEokManWon(viewModel.totalAssetsInput))
                                .font(.Exit.numberDisplay)
                                .foregroundStyle(Color.Exit.primaryText)
                        }
                        
                        // 자산 종류 선택 토글
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
                
                // 키보드
                CustomNumberKeyboard(
                    value: $viewModel.totalAssetsInput,
                    showNegativeToggle: true
                )
                
                // 확인 버튼
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

