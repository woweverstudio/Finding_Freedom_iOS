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
    
    var body: some View {
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
                        .offset(x: 30, y: 10)
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
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        DashboardView(viewModel: HomeViewModel(), hideAmounts: .constant(false))
    }
    .preferredColorScheme(.dark)
}

