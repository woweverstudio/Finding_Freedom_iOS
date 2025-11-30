//
//  DashboardView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 대시보드 탭 (메인 홈 화면)
struct DashboardView: View {
    @Bindable var viewModel: HomeViewModel
    @Binding var hideAmounts: Bool
    @State private var showFormulaSheet = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
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
                    
                    // 계산방법 보기 버튼
                    calculateFomulaButton                    
                    
                    // 플로팅 버튼 공간
                    Spacer()
                        .frame(height: 80)
                }
                .padding(.vertical, ExitSpacing.lg)
            }
            
            // 플로팅 액션 버튼
            FloatingActionButtons(viewModel: viewModel)
        }
    }
    
    // MARK: - D-DAY Header
    
    private var dDayHeader: some View {
        VStack(spacing: ExitSpacing.md) {
            dDayMainTitle
        }
        .padding(.vertical, ExitSpacing.lg)
        .padding(.horizontal, ExitSpacing.md)
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
                        .font(.Exit.title2)
                        .foregroundStyle(Color.Exit.primaryText)
                } else {
                    VStack(spacing: ExitSpacing.sm) {
                        Text("회사 탈출까지")
                            .font(.Exit.body)
                            .foregroundStyle(Color.Exit.secondaryText)
                        
                        Text(result.dDayString)
                            .font(.Exit.title2)
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
            if let result = viewModel.retirementResult {
                ZStack(alignment: .bottom) {
                    ProgressRingView(
                        progress: viewModel.progressValue,
                        currentAmount: ExitNumberFormatter.formatToEokManWon(result.currentAssets),
                        targetAmount: ExitNumberFormatter.formatToEokManWon(result.targetAssets),
                        percentText: ExitNumberFormatter.formatPercentInt(result.progressPercent),
                        hideAmounts: hideAmounts
                    )
                    .frame(width: 200, height: 200)
                    
                    HStack {
                        Spacer()
                        // 금액 숨김 토글 (우측 하단)
                        amountVisibilityToggle
                    }
                }
            }
            
            // 상세 계산 설명
            detailedCalculationCard
        }
        .padding(.horizontal, ExitSpacing.md)
        .sheet(isPresented: $showFormulaSheet) {
            CalculationFormulaSheet(viewModel: viewModel)
        }
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
                .padding(.horizontal, ExitSpacing.md)
                .padding(.vertical, ExitSpacing.sm)
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
                    currentAssets: ExitNumberFormatter.formatToEokManWon(result.currentAssets),
                    targetAssets: ExitNumberFormatter.formatToEokManWon(result.targetAssets),
                    percent: ExitNumberFormatter.formatPercentInt(result.progressPercent),
                    isHidden: hideAmounts
                )
                
                Divider()
                    .background(Color.Exit.divider)
                
                // 설명 텍스트
                if result.monthsToRetirement <= 0 {
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
                            Text("연복리 수익률 ")
                                .foregroundStyle(Color.Exit.secondaryText)
                            Text(String(format: "%.1f%%", scenario.preRetirementReturnRate))
                                .foregroundStyle(Color.Exit.accent)
                                .fontWeight(.semibold)
                            Text("로 투자해야 합니다.")
                                .foregroundStyle(Color.Exit.secondaryText)
                        }
                        .font(.Exit.subheadline)
                        
                    }
                } else {
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
                                .foregroundStyle(Color.Exit.accent)
                                .fontWeight(.bold)
                            Text(" 남았습니다.")
                                .font(.Exit.subheadline)
                                .foregroundStyle(Color.Exit.secondaryText)
                        }
                    }
                }
            }
        }
        .padding(ExitSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
    }
    
    // MARK: - Scenario Settings Card
    
    private var scenarioSettingsCard: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            if let scenario = viewModel.activeScenario, let result = viewModel.retirementResult {
                // 헤더
                HStack {
                    Text("시나리오")
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
                    
                    Button {
                        viewModel.showScenarioSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("수정")
                                .font(.Exit.caption)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(Color.Exit.tertiaryText)
                    }
                    .buttonStyle(.plain)
                }
                
                Divider()
                    .background(Color.Exit.divider)
                
                // 설정값 테이블
                VStack(spacing: ExitSpacing.sm) {
                    ScenarioSettingRow(
                        label: "은퇴 후 희망 월수입",
                        value: ExitNumberFormatter.formatToManWon(scenario.desiredMonthlyIncome)
                    )
                    
                    // 현재 순자산 (실제 자산 + 오프셋)
                    ScenarioSettingRow(
                        label: "현재 순자산",
                        value: ExitNumberFormatter.formatToEokManWon(result.currentAssets),
                        isHidden: hideAmounts
                    )
                    
                    // 가정 금액이 있으면 상세 표시
                    if scenario.assetOffset != 0 {
                        ScenarioSettingRow(
                            label: "  └ 실제 자산",
                            value: ExitNumberFormatter.formatToEokManWon(viewModel.currentAssetAmount),
                            isHidden: hideAmounts,
                            valueColor: Color.Exit.secondaryText
                        )
                        ScenarioSettingRow(
                            label: "  └ 가정 금액",
                            value: (scenario.assetOffset >= 0 ? "+" : "") + ExitNumberFormatter.formatToEokManWon(scenario.assetOffset),
                            valueColor: scenario.assetOffset >= 0 ? Color.Exit.positive : Color.Exit.warning
                        )
                    }
                    
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
    
    private var calculateFomulaButton: some View {
        // 계산방법 보기 버튼
        Button {
            showFormulaSheet = true
        } label: {
            Text("계산방법 보기")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.tertiaryText)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        DashboardView(viewModel: HomeViewModel(), hideAmounts: .constant(false))
    }
    .preferredColorScheme(.dark)
}
