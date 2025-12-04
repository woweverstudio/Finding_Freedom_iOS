//
//  DashboardView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 대시보드 탭 (메인 홈 화면)
struct DashboardView: View {
    @Environment(\.appState) private var appState
    @State private var showFormulaSheet = false
    @State private var scrollOffset: CGFloat = 0
    
    /// 스크롤 20pt 이상이면 컴팩트 모드
    private var isHeaderCompact: Bool {
        scrollOffset > 20
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 헤더 (스크롤에 따라 컴팩트 모드 전환)
            PlanHeaderView(
                scenario: appState.activeScenario,
                currentAssetAmount: appState.currentAssetAmount,
                hideAmounts: appState.hideAmounts,
                isCompact: isHeaderCompact,
                onScenarioTap: {
                    appState.showScenarioSheet = true
                }
            )
            
            // 스크롤 컨텐츠
            ScrollViewReader { scrollProxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ExitSpacing.lg) {
                        // D-DAY 헤더
                        dDayHeader
                            .id("top")  // 스크롤 최상단 ID
                        
                        // 진행률 섹션
                        progressSection
                        
                        // 시나리오 조정 안내 (10년 이상 남았을 때만 표시)
                        scenarioHintCard
                        
                        // 시나리오 탭
                        ScenarioTabBar(
                            scenarios: appState.scenarios,
                            selectedScenario: appState.activeScenario,
                            onSelect: { scenario in
                                withAnimation {
                                    appState.selectScenario(scenario)
                                }
                            },
                            onSettings: {
                                appState.showScenarioSheet = true
                            }
                        )
                        
                        // 시나리오 설정값 테이블
                        scenarioSettingsCard
                        
                        // 계산방법 보기 버튼
                        calculateFomulaButton
                    }
                    .padding(.vertical, ExitSpacing.lg)
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { _, newValue in
                    scrollOffset = newValue
                }
                .onChange(of: appState.showScenarioSheet) { _, isShowing in
                    // 시나리오 시트가 닫힐 때 스크롤 최상단으로
                    if !isShowing {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            scrollProxy.scrollTo("top", anchor: .top)
                        }
                    }
                }
            }
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
            if let result = appState.retirementResult {
                if result.monthsToRetirement == 0 {
                    Text("은퇴 가능합니다! 🎉")
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
            if let result = appState.retirementResult {
                ZStack(alignment: .bottom) {
                    ProgressRingView(
                        progress: appState.progressValue,
                        currentAmount: ExitNumberFormatter.formatToEokManWon(result.currentAssets),
                        targetAmount: ExitNumberFormatter.formatToEokManWon(result.targetAssets),
                        percentText: ExitNumberFormatter.formatPercentInt(result.progressPercent),
                        hideAmounts: appState.hideAmounts
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
            CalculationFormulaSheet()
        }
    }
    
    // MARK: - Scenario Hint Card
    
    @ViewBuilder
    private var scenarioHintCard: some View {
        // 10년(120개월) 이상 남았을 때만 표시
        if let result = appState.retirementResult, result.monthsToRetirement >= 120 {
            Button {
                appState.showScenarioSheet = true
            } label: {
                HStack(spacing: ExitSpacing.md) {
                    // 아이콘
                    ZStack {
                        Circle()
                            .fill(Color.Exit.accent.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.Exit.accent)
                    }
                    
                    // 텍스트
                    VStack(alignment: .leading, spacing: 2) {
                        Text("시간을 앞당길 수 있어요!")
                            .font(.Exit.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.Exit.primaryText)
                        
                        Text("시나리오 설정을 조정해서 탈출 시점을 당겨보세요")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.Exit.tertiaryText)
                }
                .padding(ExitSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: ExitRadius.lg)
                        .fill(Color.Exit.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: ExitRadius.lg)
                                .stroke(Color.Exit.accent.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, ExitSpacing.md)
        }
    }
    
    // MARK: - Amount Visibility Toggle
    
    private var amountVisibilityToggle: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                appState.hideAmounts.toggle()
            }
        } label: {
            Text(appState.hideAmounts ? "금액 보기" : "금액 숨김")
                .font(.Exit.caption2)
                .fontWeight(.medium)
                .foregroundStyle(appState.hideAmounts ? Color.Exit.accent : Color.Exit.tertiaryText)
                .padding(.horizontal, ExitSpacing.md)
                .padding(.vertical, ExitSpacing.sm)
                .background(
                    Capsule()
                        .fill(Color.Exit.cardBackground)
                        .overlay(
                            Capsule()
                                .stroke(appState.hideAmounts ? Color.Exit.accent : Color.Exit.divider, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
    
    private var detailedCalculationCard: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            if let scenario = appState.activeScenario, let result = appState.retirementResult {
                // 현재 자산 / 목표 자산 (1줄 유지, 자동 축소)
                AssetProgressRow(
                    currentAssets: ExitNumberFormatter.formatToEokManWon(result.currentAssets),
                    targetAssets: ExitNumberFormatter.formatToEokManWon(result.targetAssets),
                    percent: ExitNumberFormatter.formatPercentInt(result.progressPercent),
                    isHidden: appState.hideAmounts
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
                            Text(String(format: "%.1f%%", scenario.postRetirementReturnRate))
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
            if let scenario = appState.activeScenario, let result = appState.retirementResult {
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
                }
                
                Divider()
                    .background(Color.Exit.divider)
                
                // 설정값 테이블
                VStack(spacing: ExitSpacing.sm) {
                    // 현재 순자산 (실제 자산 + 오프셋)
                    ScenarioSettingRow(
                        label: "현재 순자산",
                        value: ExitNumberFormatter.formatToEokManWon(result.currentAssets),
                        isHidden: appState.hideAmounts
                    )
                    
                    // 가정 금액이 있으면 상세 표시
                    if scenario.assetOffset != 0 {
                        ScenarioSettingRow(
                            label: "  └ 실제 자산",
                            value: ExitNumberFormatter.formatToEokManWon(appState.currentAssetAmount),
                            isHidden: appState.hideAmounts,
                            valueColor: Color.Exit.secondaryText
                        )
                        ScenarioSettingRow(
                            label: "  └ 가정 금액",
                            value: (scenario.assetOffset >= 0 ? "+" : "") + ExitNumberFormatter.formatToEokManWon(scenario.assetOffset),
                            valueColor: scenario.assetOffset >= 0 ? Color.Exit.positive : Color.Exit.warning
                        )
                    }
                    
                    ScenarioSettingRow(
                        label: "은퇴 후 희망 월수입",
                        value: ExitNumberFormatter.formatToManWon(scenario.desiredMonthlyIncome)
                    )
                    
                    ScenarioSettingRow(
                        label: "매월 목표 투자금액",
                        value: ExitNumberFormatter.formatToManWon(scenario.monthlyInvestment),
                        valueColor: Color.Exit.positive
                    )
                    
                    ScenarioSettingRow(
                        label: "은퇴 전 연 목표 수익률",
                        value: String(format: "%.1f%%", scenario.preRetirementReturnRate),
                        valueColor: Color.Exit.accent
                    )
                    
                    Divider()
                        .background(Color.Exit.divider)
                        .padding(.vertical, ExitSpacing.xs)
                    
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
                
                // 시나리오 수정 버튼
                Button {
                    appState.showScenarioSheet = true
                } label: {
                    HStack(spacing: ExitSpacing.sm) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 14, weight: .medium))
                        Text("시나리오 수정하기")
                            .font(.Exit.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(Color.Exit.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ExitSpacing.sm)
                    .background(Color.Exit.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
                }
                .buttonStyle(.plain)
                .padding(.top, ExitSpacing.sm)
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
        DashboardView()
    }
    .preferredColorScheme(.dark)
    .environment(\.appState, AppStateManager())
}
