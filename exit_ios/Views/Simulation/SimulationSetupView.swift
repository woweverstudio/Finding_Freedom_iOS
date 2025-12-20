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
    
    // MARK: - Editing States
    
    @State private var editingCurrentAsset: Double = 0
    @State private var editingMonthlyInvestment: Double = 500_000
    @State private var editingMonthlyIncome: Double = 3_000_000
    @State private var editingPreReturnRate: Double = 6.5
    @State private var editingPostReturnRate: Double = 4.0
    @State private var spendingRatio: Double = 1.0
    @State private var failureThreshold: Double = 1.1
    
    // Amount Edit Sheet
    @State private var showAmountEditSheet: AmountEditType? = nil
    
    var body: some View {
        ZStack {
            Color.Exit.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 헤더
                header
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ExitSpacing.lg) {
                        // 기본 설정 섹션
                        basicSettingsSection
                        
                        // 수익률 설정 섹션
                        returnRateSection
                        
                        // 생활비 사용 비율 섹션
                        spendingRatioSection
                        
                        // 실패 조건 섹션
                        failureThresholdSection
                        
                        // 시뮬레이션 요약
                        simulationSummary
                    }
                    .padding(.vertical, ExitSpacing.lg)
                }
                
                // 시작 버튼
                startButton
            }
        }
        .onAppear {
            syncEditingValues()
        }
        .fullScreenCover(item: $showAmountEditSheet) { type in
            AmountEditSheet(
                type: type,
                initialValue: initialValueForType(type),
                onConfirm: { newValue in
                    applyAmountChange(type: type, value: newValue)
                    showAmountEditSheet = nil
                },
                onDismiss: {
                    showAmountEditSheet = nil
                }
            )
        }
    }
    
    // MARK: - Amount Edit Helpers
    
    private func initialValueForType(_ type: AmountEditType) -> Double {
        switch type {
        case .currentAsset:
            return editingCurrentAsset
        case .monthlyInvestment:
            return editingMonthlyInvestment
        case .desiredMonthlyIncome:
            return editingMonthlyIncome
        }
    }
    
    private func applyAmountChange(type: AmountEditType, value: Double) {
        switch type {
        case .currentAsset:
            editingCurrentAsset = value
        case .monthlyInvestment:
            editingMonthlyInvestment = value
        case .desiredMonthlyIncome:
            editingMonthlyIncome = value
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
    
    // MARK: - Basic Settings Section
    
    private var basicSettingsSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            sectionHeader("기본 설정")
            
            VStack(spacing: ExitSpacing.md) {
                // 현재 자산
                amountEditRow(
                    label: "현재 자산",
                    value: editingCurrentAsset,
                    formatter: { ExitNumberFormatter.formatToEokManWon($0) },
                    color: Color.Exit.primaryText,
                    editType: .currentAsset
                )
                
                // 매월 투자금액
                amountEditRow(
                    label: "매월 투자금액",
                    value: editingMonthlyInvestment,
                    formatter: { ExitNumberFormatter.formatToManWon($0) },
                    color: Color.Exit.positive,
                    editType: .monthlyInvestment
                )
                
                // 은퇴 후 희망 월수입
                amountEditRow(
                    label: "은퇴 후 월수입",
                    value: editingMonthlyIncome,
                    formatter: { ExitNumberFormatter.formatToManWon($0) },
                    color: Color.Exit.accent,
                    editType: .desiredMonthlyIncome
                )
            }
            .padding(ExitSpacing.md)
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        }
        .padding(.horizontal, ExitSpacing.lg)
    }
    
    // MARK: - Amount Edit Row
    
    private func amountEditRow(
        label: String,
        value: Double,
        formatter: @escaping (Double) -> String,
        color: Color,
        editType: AmountEditType
    ) -> some View {
        HStack {
            // 라벨
            Text(label)
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            
            Spacer()
            
            // 값 + 편집 버튼
            HStack(spacing: ExitSpacing.sm) {
                // 현재 값
                Text(formatter(value))
                    .font(.Exit.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
                
                // 편집 버튼 (수익률 +/- 버튼과 동일한 스타일)
                Button {
                    HapticService.shared.soft()
                    showAmountEditSheet = editType
                } label: {
                    Text("편집")
                        .font(.Exit.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(color)
                        .padding(.horizontal, ExitSpacing.md)
                        .padding(.vertical, ExitSpacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: ExitRadius.sm)
                                .fill(color.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Return Rate Section
    
    private var returnRateSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            sectionHeader("수익률 설정")
            
            VStack(spacing: ExitSpacing.md) {
                // 은퇴 전 수익률
                rateSliderWithButtons(
                    label: "은퇴 전 수익률",
                    value: $editingPreReturnRate,
                    minValue: 0.5,
                    maxValue: 30.0,
                    step: 0.5,
                    color: Color.Exit.accent
                )
                
                // 은퇴 후 수익률
                rateSliderWithButtons(
                    label: "은퇴 후 수익률",
                    value: $editingPostReturnRate,
                    minValue: 0.5,
                    maxValue: 30.0,
                    step: 0.5,
                    color: Color.Exit.caution
                )
            }
            .padding(ExitSpacing.md)
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        }
        .padding(.horizontal, ExitSpacing.lg)
    }
    
    // MARK: - Rate Slider with Buttons
    
    private func rateSliderWithButtons(
        label: String,
        value: Binding<Double>,
        minValue: Double,
        maxValue: Double,
        step: Double,
        color: Color
    ) -> some View {
        VStack(spacing: ExitSpacing.xs) {
            // 라벨 + 값 + 버튼
            HStack {
                // 라벨
                Text(label)
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                Spacer()
                
                // +/- 버튼과 값
                HStack(spacing: ExitSpacing.sm) {
                    // - 버튼
                    rateButton(
                        text: "−",
                        enabled: value.wrappedValue > minValue,
                        color: color
                    ) {
                        value.wrappedValue = max(value.wrappedValue - step, minValue)
                    }
                    
                    // 현재 값
                    Text(String(format: "%.1f%%", value.wrappedValue))
                        .font(.Exit.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(color)
                        .frame(width: 52)
                    
                    // + 버튼
                    rateButton(
                        text: "+",
                        enabled: value.wrappedValue < maxValue,
                        color: color
                    ) {
                        value.wrappedValue = min(value.wrappedValue + step, maxValue)
                    }
                }
            }
            
            // 슬라이더
            Slider(value: value, in: minValue...maxValue, step: step)
                .tint(color)
        }
    }
    
    // MARK: - Rate Button
    
    private func rateButton(
        text: String,
        enabled: Bool,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            HapticService.shared.soft()
            action()
        } label: {
            Text(text)
                .font(.Exit.body)
                .fontWeight(.bold)
                .foregroundStyle(enabled ? color : Color.Exit.tertiaryText)
                .padding(.horizontal, ExitSpacing.md)
                .padding(.vertical, ExitSpacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: ExitRadius.sm)
                        .fill(enabled ? color.opacity(0.15) : Color.Exit.divider.opacity(0.5))
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
    
    // MARK: - Spending Ratio Section
    
    private var spendingRatioSection: some View {
        let actualSpending = editingMonthlyIncome * spendingRatio
        
        return VStack(alignment: .leading, spacing: ExitSpacing.md) {
            VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                sectionHeader("생활비 사용 비율")
                
                Text("은퇴 후 희망 월수입 중 실제로 사용할 비율을 설정합니다")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
                    .padding(.horizontal, ExitSpacing.lg)
            }
            
            VStack(spacing: ExitSpacing.sm) {
                // 생활비 비율 선택 버튼들
                HStack(spacing: ExitSpacing.sm) {
                    spendingRatioOption(0.5, label: "50%")
                    spendingRatioOption(0.7, label: "70%")
                    spendingRatioOption(0.85, label: "85%")
                    spendingRatioOption(1.0, label: "100%")
                }
                
                // 현재 설정 예시
                HStack(spacing: ExitSpacing.xs) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    Text("월 \(ExitNumberFormatter.formatToManWon(editingMonthlyIncome)) × \(String(format: "%.0f", spendingRatio * 100))% = \(ExitNumberFormatter.formatToManWon(actualSpending)) 사용")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    Spacer()
                }
            }
            .padding(ExitSpacing.md)
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        }
        .padding(.horizontal, ExitSpacing.lg)
    }
    
    private func spendingRatioOption(_ value: Double, label: String) -> some View {
        let isSelected = abs(spendingRatio - value) < 0.01
        
        return Button {
            HapticService.shared.soft()
            withAnimation(.easeInOut(duration: 0.2)) {
                spendingRatio = value
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
                        ? AnyShapeStyle(Color.Exit.positive)
                        : AnyShapeStyle(Color.Exit.background)
                )
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: ExitRadius.sm)
                        .stroke(isSelected ? Color.clear : Color.Exit.divider, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Failure Threshold Section
    
    private var failureThresholdSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                sectionHeader("실패 조건")
                
                Text("목표 기간의 몇 %를 초과하면 실패로 판정할지 설정합니다")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
                    .padding(.horizontal, ExitSpacing.lg)
            }
            
            VStack(spacing: ExitSpacing.sm) {
                // 실패 조건 선택 버튼들
                HStack(spacing: ExitSpacing.sm) {
                    failureOption(1.0, label: "100%")
                    failureOption(1.1, label: "110%")
                    failureOption(1.3, label: "130%")
                    failureOption(1.5, label: "150%")
                }
                
                // 현재 설정 예시
                let originalMonths = calculateOriginalMonths()
                let failureMonths = Int(Double(originalMonths) * failureThreshold)
                
                if originalMonths > 0 {
                    HStack(spacing: ExitSpacing.xs) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.Exit.secondaryText)
                        
                        Text("목표 \(formatPeriod(originalMonths)) → \(formatPeriod(failureMonths)) 초과 시 실패")
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.secondaryText)
                        
                        Spacer()
                    }
                }
            }
            .padding(ExitSpacing.md)
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
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
                        : AnyShapeStyle(Color.Exit.background)
                )
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: ExitRadius.sm)
                        .stroke(isSelected ? Color.clear : Color.Exit.divider, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Simulation Summary
    
    private var simulationSummary: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            sectionHeader("시뮬레이션 정보")
            
            let targetAsset = RetirementCalculator.calculateTargetAssets(
                desiredMonthlyIncome: editingMonthlyIncome,
                postRetirementReturnRate: editingPostReturnRate
            )
            let preVolatility = SimulationViewModel.calculateVolatility(for: editingPreReturnRate)
            let postVolatility = SimulationViewModel.calculateVolatility(for: editingPostReturnRate)
            
            VStack(spacing: ExitSpacing.sm) {
                summaryRow("목표 자산", ExitNumberFormatter.formatToEokManWon(targetAsset), valueColor: Color.Exit.accent)
                summaryRow("은퇴 전 변동성", String(format: "%.0f%%", preVolatility))
                summaryRow("은퇴 후 변동성", String(format: "%.0f%%", postVolatility))
                
                Divider()
                    .background(Color.Exit.divider)
                
                HStack(spacing: ExitSpacing.xs) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.Exit.tertiaryText)
                    
                    Text("변동성은 목표 수익률 기반으로 자동 계산됩니다")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.tertiaryText)
                }
            }
            .padding(ExitSpacing.md)
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        }
        .padding(.horizontal, ExitSpacing.lg)
    }
    
    // MARK: - Start Button
    
    private var startButton: some View {
        Button {
            applySettingsAndStart()
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
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.Exit.caption)
            .foregroundStyle(Color.Exit.secondaryText)
            .padding(.horizontal, ExitSpacing.lg)
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
    
    // MARK: - Helper Methods
    
    private func syncEditingValues() {
        editingCurrentAsset = appState.currentAssetAmount
        failureThreshold = viewModel.failureThresholdMultiplier
        spendingRatio = viewModel.spendingRatio
        
        guard let profile = appState.userProfile else { return }
        editingMonthlyInvestment = profile.monthlyInvestment
        editingMonthlyIncome = profile.desiredMonthlyIncome
        editingPreReturnRate = profile.preRetirementReturnRate
        editingPostReturnRate = profile.postRetirementReturnRate
    }
    
    private func applySettingsAndStart() {
        // 1. 자산 업데이트
        appState.updateCurrentAsset(editingCurrentAsset)
        
        // 2. 설정 업데이트 (물가 상승률 포함)
        appState.updateSettings(
            desiredMonthlyIncome: editingMonthlyIncome,
            monthlyInvestment: editingMonthlyInvestment,
            preRetirementReturnRate: editingPreReturnRate,
            postRetirementReturnRate: editingPostReturnRate
        )
        
        // 3. 실패 조건 저장
        viewModel.updateFailureThreshold(failureThreshold)
        
        // 4. 생활비 사용 비율 저장
        viewModel.updateSpendingRatio(spendingRatio)
        
        // 5. 변동성 자동 계산 (목표 수익률 기반)
        let autoVolatility = SimulationViewModel.calculateVolatility(for: editingPreReturnRate)
        viewModel.updateVolatility(autoVolatility)
        
        // 6. 데이터 로드 및 시뮬레이션 시작
        viewModel.loadData()
        viewModel.refreshSimulation()
        
        // 7. 화면 전환
        onStart()
    }
    
    private func calculateOriginalMonths() -> Int {
        let targetAsset = RetirementCalculator.calculateTargetAssets(
            desiredMonthlyIncome: editingMonthlyIncome,
            postRetirementReturnRate: editingPostReturnRate
        )
        
        return RetirementCalculator.calculateMonthsToRetirement(
            currentAssets: editingCurrentAsset,
            targetAssets: targetAsset,
            monthlyInvestment: editingMonthlyInvestment,
            annualReturnRate: editingPreReturnRate
        )
    }
    
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
