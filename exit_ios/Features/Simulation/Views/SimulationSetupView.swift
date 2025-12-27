//
//  SimulationSetupView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

// MARK: - Setup Step Enum

private enum SetupStep: Int, CaseIterable {
    case basicSettings = 0
    case returnRate = 1
    case spendingRatio = 2
    case failureThreshold = 3
    
    var title: String {
        switch self {
        case .basicSettings: return "기본 설정"
        case .returnRate: return "수익률 설정"
        case .spendingRatio: return "생활비 사용 비율"
        case .failureThreshold: return "실패 조건"
        }
    }
    
    var subtitle: String {
        switch self {
        case .basicSettings: return "현재 자산과 투자 계획을 입력하세요"
        case .returnRate: return "은퇴 전후 목표 수익률을 설정하세요"
        case .spendingRatio: return "은퇴 후 사용할 생활비 비율을 선택하세요"
        case .failureThreshold: return "시뮬레이션 실패 조건을 설정하세요"
        }
    }
}

/// 시뮬레이션 시작 전 설정 화면 (4단계 스텝)
struct SimulationSetupView: View {
    @Environment(\.appState) private var appState
    @Bindable var viewModel: SimulationViewModel
    let onBack: () -> Void
    let onStart: () -> Void
    
    // MARK: - Step State
    
    @State private var currentStep: SetupStep = .basicSettings
    
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
                
                // 프로그레스 인디케이터
                progressIndicator
                    .padding(.horizontal, ExitSpacing.lg)
                    .padding(.top, ExitSpacing.md)
                
                // 컨텐츠 영역
                stepContent
                    .padding(.horizontal, ExitSpacing.lg)
                    .padding(.top, ExitSpacing.xl)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
                
                Spacer()
                
                // 하단: 네비게이션 버튼
                navigationButtons
                    .padding(.horizontal, ExitSpacing.md)
                    .padding(.bottom, ExitSpacing.lg)
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
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: ExitSpacing.sm) {
            ForEach(SetupStep.allCases, id: \.self) { step in
                Capsule()
                    .fill(step.rawValue <= currentStep.rawValue ? Color.Exit.accent : Color.Exit.divider)
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        VStack(spacing: ExitSpacing.xl) {
            // 타이틀
            VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                Text(currentStep.title)
                    .font(.Exit.title2)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Text(currentStep.subtitle)
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 스텝별 컨텐츠
            Group {
                switch currentStep {
                case .basicSettings:
                    basicSettingsContent
                case .returnRate:
                    returnRateContent
                case .spendingRatio:
                    spendingRatioContent
                case .failureThreshold:
                    failureThresholdContent
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
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
                if currentStep.rawValue > 0 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if let prevStep = SetupStep(rawValue: currentStep.rawValue - 1) {
                            currentStep = prevStep
                        }
                    }
                } else {
                    onBack()
                }
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
        .padding(ExitSpacing.md)        
    }
    
    // MARK: - Step 1: Basic Settings Content
    
    private var basicSettingsContent: some View {
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
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
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
                .font(.Exit.body)
                .foregroundStyle(Color.Exit.secondaryText)
            
            Spacer()
            
            // 값 + 편집 버튼
            HStack(spacing: ExitSpacing.sm) {
                // 현재 값
                Text(formatter(value))
                    .font(.Exit.body)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
                
                // 편집 버튼
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
        .padding(.vertical, ExitSpacing.sm)
    }
    
    // MARK: - Step 2: Return Rate Content
    
    private var returnRateContent: some View {
        VStack(spacing: ExitSpacing.lg) {
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
            
            // 시뮬레이션 정보
            VStack(spacing: ExitSpacing.sm) {
                let preVolatility = SimulationViewModel.calculateVolatility(for: editingPreReturnRate)
                let postVolatility = SimulationViewModel.calculateVolatility(for: editingPostReturnRate)
                
                HStack {
                    Text("은퇴 전 변동성")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.tertiaryText)
                    Spacer()
                    Text(String(format: "%.0f%%", preVolatility))
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.accent)
                }
                
                HStack {
                    Text("은퇴 후 변동성")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.tertiaryText)
                    Spacer()
                    Text(String(format: "%.0f%%", postVolatility))
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.caution)
                }
                
                HStack(spacing: ExitSpacing.xs) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.Exit.tertiaryText)
                    
                    Text("변동성은 목표 수익률 기반으로 자동 계산됩니다")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.tertiaryText)
                    
                    Spacer()
                }
            }
            .padding(ExitSpacing.md)
            .background(Color.Exit.secondaryCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
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
        VStack(spacing: ExitSpacing.sm) {
            // 라벨 + 값 + 버튼
            HStack {
                // 라벨
                Text(label)
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                Spacer()
                
                // +/- 버튼과 값
                HStack(spacing: ExitSpacing.sm) {
                    // - 버튼
                    rateButton(
                        icon: "minus",
                        enabled: value.wrappedValue > minValue,
                        color: color
                    ) {
                        value.wrappedValue = max(value.wrappedValue - step, minValue)
                    }
                    
                    // 현재 값
                    Text(String(format: "%.1f%%", value.wrappedValue))
                        .font(.Exit.body)
                        .fontWeight(.bold)
                        .foregroundStyle(color)
                        .frame(width: 60)
                    
                    // + 버튼
                    rateButton(
                        icon: "plus",
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
        icon: String,
        enabled: Bool,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            HapticService.shared.soft()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(enabled ? color : Color.Exit.tertiaryText)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: ExitRadius.sm)
                        .fill(enabled ? color.opacity(0.15) : Color.Exit.divider.opacity(0.5))
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
    
    // MARK: - Step 3: Spending Ratio Content
    
    private var spendingRatioContent: some View {
        let actualSpending = editingMonthlyIncome * spendingRatio
        
        return VStack(spacing: ExitSpacing.lg) {
            // 생활비 비율 선택 버튼들
            VStack(spacing: ExitSpacing.sm) {
                HStack(spacing: ExitSpacing.sm) {
                    spendingRatioOption(0.5, label: "50%")
                    spendingRatioOption(0.7, label: "70%")
                }
                HStack(spacing: ExitSpacing.sm) {
                    spendingRatioOption(0.85, label: "85%")
                    spendingRatioOption(1.0, label: "100%")
                }
            }
            
            // 현재 설정 예시
            VStack(spacing: ExitSpacing.sm) {
                HStack(spacing: ExitSpacing.sm) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.Exit.accent)
                    
                    Text("예상 월 생활비")
                        .font(.Exit.body)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    Spacer()
                    
                    Text(ExitNumberFormatter.formatToManWon(actualSpending))
                        .font(.Exit.body)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.Exit.positive)
                }
                
                Text("월 \(ExitNumberFormatter.formatToManWon(editingMonthlyIncome)) × \(String(format: "%.0f", spendingRatio * 100))%")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.tertiaryText)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(ExitSpacing.md)
            .background(Color.Exit.secondaryCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
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
                .font(.Exit.title3)
                .fontWeight(isSelected ? .bold : .medium)
                .foregroundStyle(isSelected ? .white : Color.Exit.secondaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    isSelected
                        ? AnyShapeStyle(Color.Exit.positive)
                        : AnyShapeStyle(Color.Exit.background)
                )
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: ExitRadius.md)
                        .stroke(isSelected ? Color.clear : Color.Exit.divider, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Step 4: Failure Threshold Content
    
    private var failureThresholdContent: some View {
        VStack(spacing: ExitSpacing.lg) {
            // 실패 조건 선택 버튼들
            VStack(spacing: ExitSpacing.sm) {
                HStack(spacing: ExitSpacing.sm) {
                    failureOption(1.0, label: "100%", description: "엄격")
                    failureOption(1.1, label: "110%", description: "기본")
                }
                HStack(spacing: ExitSpacing.sm) {
                    failureOption(1.3, label: "130%", description: "여유")
                    failureOption(1.5, label: "150%", description: "느긋")
                }
            }
            
            // 현재 설정 예시
            let originalMonths = calculateOriginalMonths()
            let failureMonths = Int(Double(originalMonths) * failureThreshold)
            
            if originalMonths > 0 {
                VStack(spacing: ExitSpacing.sm) {
                    HStack {
                        Text("목표 달성 기간")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.tertiaryText)
                        Spacer()
                        Text(formatPeriod(originalMonths))
                            .font(.Exit.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.Exit.accent)
                    }
                    
                    HStack {
                        Text("실패 판정 기준")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.tertiaryText)
                        Spacer()
                        Text("\(formatPeriod(failureMonths)) 초과")
                            .font(.Exit.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.Exit.warning)
                    }
                }
                .padding(ExitSpacing.md)
                .background(Color.Exit.secondaryCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
            }
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
    }
    
    private func failureOption(_ value: Double, label: String, description: String) -> some View {
        let isSelected = abs(failureThreshold - value) < 0.01
        
        return Button {
            HapticService.shared.soft()
            withAnimation(.easeInOut(duration: 0.2)) {
                failureThreshold = value
            }
        } label: {
            VStack(spacing: ExitSpacing.xs) {
                Text(label)
                    .font(.Exit.title3)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundStyle(isSelected ? .white : Color.Exit.primaryText)
                
                Text(description)
                    .font(.Exit.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : Color.Exit.tertiaryText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(
                isSelected
                    ? AnyShapeStyle(Color.Exit.accent)
                    : AnyShapeStyle(Color.Exit.background)
            )
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: ExitRadius.md)
                    .stroke(isSelected ? Color.clear : Color.Exit.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: ExitSpacing.md) {
            if currentStep == .failureThreshold {
                // 마지막 스텝: 시뮬레이션 시작 버튼
                ExitCTAButton(
                    title: "시뮬레이션 시작",
                    icon: "play.fill",
                    action: applySettingsAndStart
                )
            } else {
                ExitButton(
                    title: "다음",
                    style: .primary,
                    size: .large,
                    action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if let nextStep = SetupStep(rawValue: currentStep.rawValue + 1) {
                                currentStep = nextStep
                            }
                        }
                    }
                )
            }
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
        // 설정 업데이트 (자산 포함)
        appState.updateSettings(
            desiredMonthlyIncome: editingMonthlyIncome,
            currentNetAssets: editingCurrentAsset,
            monthlyInvestment: editingMonthlyInvestment,
            preRetirementReturnRate: editingPreReturnRate,
            postRetirementReturnRate: editingPostReturnRate
        )
        
        // 실패 조건 저장
        viewModel.updateFailureThreshold(failureThreshold)
        
        // 생활비 사용 비율 저장
        viewModel.updateSpendingRatio(spendingRatio)
        
        // 변동성 자동 계산 (목표 수익률 기반)
        let autoVolatility = SimulationViewModel.calculateVolatility(for: editingPreReturnRate)
        viewModel.updateVolatility(autoVolatility)
        
        // 데이터 로드 및 시뮬레이션 시작
        viewModel.loadData()
        viewModel.refreshSimulation()
        
        // 화면 전환
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
