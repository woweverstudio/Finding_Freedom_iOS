//
//  SimulationSetupView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 시뮬레이션 시작 전 설정 화면
struct SimulationSetupView: View {
    @Environment(\.appState) private var appState
    @Bindable var viewModel: SimulationViewModel
    let onBack: () -> Void
    let onStart: () -> Void
    
    @State private var selectedScenario: Scenario?
    @State private var failureThreshold: Double = 1.1
    
    var body: some View {
        ZStack {
            Color.Exit.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 헤더
                header
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ExitSpacing.xl) {
                        // 1. 시나리오 선택
                        scenarioSection
                        
                        // 2. 실패 조건 설정
                        failureThresholdSection
                        
                        // 선택된 시나리오 요약
                        if let scenario = selectedScenario {
                            scenarioSummary(scenario)
                        }
                    }
                    .padding(.vertical, ExitSpacing.lg)
                }
                
                // 시작 버튼
                startButton
            }
        }
        .onAppear {
            selectedScenario = appState.activeScenario ?? appState.scenarios.first
            failureThreshold = viewModel.failureThresholdMultiplier
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Button {
                onBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            
            Spacer()
            
            Text("시뮬레이션 설정")
                .font(.Exit.body)
                .fontWeight(.semibold)
                .foregroundStyle(Color.Exit.primaryText)
            
            Spacer()
            
            // 균형용
            Image(systemName: "chevron.left")
                .font(.system(size: 16))
                .foregroundStyle(.clear)
        }
        .padding(.horizontal, ExitSpacing.lg)
        .padding(.vertical, ExitSpacing.md)
    }
    
    // MARK: - Scenario Section
    
    private var scenarioSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            Text("시나리오")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
                .padding(.horizontal, ExitSpacing.lg)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ExitSpacing.sm) {
                    ForEach(appState.scenarios, id: \.id) { scenario in
                        scenarioChip(scenario)
                    }
                }
                .padding(.horizontal, ExitSpacing.lg)
            }
        }
    }
    
    private func scenarioChip(_ scenario: Scenario) -> some View {
        let isSelected = scenario.id == selectedScenario?.id
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedScenario = scenario
            }
        } label: {
            Text(scenario.name)
                .font(.Exit.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : Color.Exit.secondaryText)
                .padding(.horizontal, ExitSpacing.md)
                .padding(.vertical, ExitSpacing.sm)
                .background(
                    isSelected
                        ? AnyShapeStyle(LinearGradient.exitAccent)
                        : AnyShapeStyle(Color.Exit.cardBackground)
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.Exit.divider, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Failure Threshold Section
    
    private var failureThresholdSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                Text("실패 조건")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                Text("목표 기간의 몇 %를 초과하면 실패로 판정할지 설정합니다")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
            }
            
            // 실패 조건 선택 버튼들
            HStack(spacing: ExitSpacing.sm) {
                failureOption(1.1, label: "110%")
                failureOption(1.25, label: "125%")
                failureOption(1.5, label: "150%")
                failureOption(2.0, label: "200%")
            }
            
            // 현재 설정 예시
            if let scenario = selectedScenario {
                let originalMonths = calculateOriginalMonths(scenario)
                let failureMonths = Int(Double(originalMonths) * failureThreshold)
                
                if originalMonths > 0 {
                    HStack(spacing: ExitSpacing.xs) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.Exit.tertiaryText)
                        
                        Text("목표 \(formatPeriod(originalMonths)) → \(formatPeriod(failureMonths)) 초과 시 실패")
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.tertiaryText)
                    }
                    .padding(.top, ExitSpacing.xs)
                }
            }
        }
        .padding(.horizontal, ExitSpacing.lg)
    }
    
    private func failureOption(_ value: Double, label: String) -> some View {
        let isSelected = abs(failureThreshold - value) < 0.01
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                failureThreshold = value
            }
        } label: {
            Text(label)
                .font(.Exit.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : Color.Exit.secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, ExitSpacing.sm)
                .background(
                    isSelected
                        ? AnyShapeStyle(Color.Exit.accent)
                        : AnyShapeStyle(Color.Exit.cardBackground)
                )
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: ExitRadius.sm)
                        .stroke(isSelected ? Color.clear : Color.Exit.divider, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Scenario Summary
    
    private func scenarioSummary(_ scenario: Scenario) -> some View {
        let preVolatility = SimulationViewModel.calculateVolatility(for: scenario.preRetirementReturnRate)
        let postVolatility = SimulationViewModel.calculateVolatility(for: scenario.postRetirementReturnRate)
        let targetAsset = RetirementCalculator.calculateTargetAssets(
            desiredMonthlyIncome: scenario.desiredMonthlyIncome,
            postRetirementReturnRate: scenario.postRetirementReturnRate,
            inflationRate: scenario.inflationRate
        )
        
        return VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            // 기본 정보
            VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                sectionLabel("기본 정보")
                
                VStack(spacing: ExitSpacing.xs) {
                    summaryRow("현재 자산", ExitNumberFormatter.formatToEokManWon(appState.currentAssetAmount))
                    
                    if scenario.assetOffset != 0 {
                        let prefix = scenario.assetOffset > 0 ? "+" : ""
                        summaryRow("가정 금액", prefix + ExitNumberFormatter.formatToEokManWon(scenario.assetOffset), valueColor: scenario.assetOffset > 0 ? Color.Exit.positive : Color.Exit.warning)
                    }
                    
                    summaryRow("월 저축액", ExitNumberFormatter.formatToManWon(scenario.monthlyInvestment))
                    summaryRow("희망 월수입", ExitNumberFormatter.formatToManWon(scenario.desiredMonthlyIncome))
                    summaryRow("목표 자산", ExitNumberFormatter.formatToEokManWon(targetAsset), valueColor: Color.Exit.accent)
                }
                .padding(ExitSpacing.md)
                .background(Color.Exit.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
            }
            
            // 은퇴 전 시뮬레이션 조건
            VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                sectionLabel("은퇴 전 시뮬레이션")
                
                VStack(spacing: ExitSpacing.xs) {
                    summaryRow("목표 수익률", String(format: "%.1f%%", scenario.preRetirementReturnRate))
                    summaryRow("수익률 변동성", String(format: "%.0f%%", preVolatility), valueColor: Color.Exit.secondaryText)
                }
                .padding(ExitSpacing.md)
                .background(Color.Exit.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
            }
            
            // 은퇴 후 시뮬레이션 조건
            VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                sectionLabel("은퇴 후 시뮬레이션")
                
                VStack(spacing: ExitSpacing.xs) {
                    summaryRow("목표 수익률", String(format: "%.1f%%", scenario.postRetirementReturnRate))
                    summaryRow("수익률 변동성", String(format: "%.0f%%", postVolatility), valueColor: Color.Exit.secondaryText)
                    summaryRow("물가 상승률", String(format: "%.1f%%", scenario.inflationRate))
                }
                .padding(ExitSpacing.md)
                .background(Color.Exit.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
            }
        }
        .padding(.horizontal, ExitSpacing.lg)
    }
    
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.Exit.caption)
            .foregroundStyle(Color.Exit.secondaryText)
    }
    
    private func summaryRow(_ label: String, _ value: String, valueColor: Color = Color.Exit.primaryText) -> some View {
        HStack {
            Text(label)
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.tertiaryText)
            Spacer()
            Text(value)
                .font(.Exit.caption)
                .foregroundStyle(valueColor)
        }
    }
    
    // MARK: - Start Button
    
    private var startButton: some View {
        Button {
            // 1. 시나리오 선택 및 저장
            if let scenario = selectedScenario {
                appState.selectScenario(scenario)
            }
            
            // 2. 실패 조건 저장
            viewModel.updateFailureThreshold(failureThreshold)
            
            // 3. 변동성 자동 계산 (목표 수익률 기반)
            if let scenario = selectedScenario {
                let autoVolatility = SimulationViewModel.calculateVolatility(for: scenario.preRetirementReturnRate)
                viewModel.updateVolatility(autoVolatility)
            }
            
            // 4. 데이터 로드 및 시뮬레이션 시작
            viewModel.loadData()
            viewModel.refreshSimulation()
            
            // 5. 화면 전환
            onStart()
        } label: {
            HStack(spacing: ExitSpacing.sm) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14))
                Text("시뮬레이션 시작")
                    .font(.Exit.body)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, ExitSpacing.md)
            .background(LinearGradient.exitAccent)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, ExitSpacing.lg)
        .padding(.bottom, ExitSpacing.xl)
    }
    
    // MARK: - Helpers
    
    /// 기존 D-Day 계산
    private func calculateOriginalMonths(_ scenario: Scenario) -> Int {
        let effectiveAsset = scenario.effectiveAsset(with: appState.currentAssetAmount)
        let targetAsset = RetirementCalculator.calculateTargetAssets(
            desiredMonthlyIncome: scenario.desiredMonthlyIncome,
            postRetirementReturnRate: scenario.postRetirementReturnRate,
            inflationRate: scenario.inflationRate
        )
        
        return RetirementCalculator.calculateMonthsToRetirement(
            currentAssets: effectiveAsset,
            targetAssets: targetAsset,
            monthlyInvestment: scenario.monthlyInvestment,
            annualReturnRate: scenario.preRetirementReturnRate
        )
    }
    
    /// 기간 포맷
    private func formatPeriod(_ months: Int) -> String {
        let years = months / 12
        let remainingMonths = months % 12
        
        if remainingMonths == 0 {
            return "\(years)년"
        } else if years == 0 {
            return "\(remainingMonths)개월"
        } else {
            return "\(years)년 \(remainingMonths)개월"
        }
    }
}
