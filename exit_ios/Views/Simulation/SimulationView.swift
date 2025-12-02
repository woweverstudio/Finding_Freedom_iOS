//
//  SimulationView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 시뮬레이션 탭 메인 뷰
struct SimulationView: View {
    @Bindable var viewModel: SimulationViewModel
    @State private var showSettingsSheet = false
    
    var body: some View {
        ZStack {
            if viewModel.isSimulating {
                // 로딩 화면
                loadingView
            } else if let result = viewModel.displayResult {
                // 결과 화면
                resultsView(result: result)
            } else {
                // 초기 화면
                SimulationEmptyView(
                    scenario: viewModel.activeScenario,
                    currentAssetAmount: viewModel.currentAssetAmount,
                    onStart: { viewModel.refreshSimulation() }
                )
            }
        }
        .sheet(isPresented: $showSettingsSheet) {
            SimulationSettingsSheet(viewModel: viewModel)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: ExitSpacing.xl) {
            Spacer()
            
            // 아이콘
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundStyle(Color.Exit.accent)
            
            // 제목
            Text("시뮬레이션 진행 중")
                .font(.Exit.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.Exit.primaryText)
            
            // 시뮬레이션 단계
            Text(viewModel.simulationPhase.description)
                .font(.Exit.body)
                .foregroundStyle(Color.Exit.secondaryText)
            
            // 진행률 바
            VStack(spacing: ExitSpacing.sm) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.Exit.divider)
                            .frame(height: 16)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.Exit.accent)
                            .frame(
                                width: geometry.size.width * viewModel.simulationProgress,
                                height: 16
                            )
                            .animation(.easeInOut(duration: 0.2), value: viewModel.simulationProgress)
                    }
                }
                .frame(height: 16)
                
                Text("\(Int(viewModel.simulationProgress * 100))%")
                    .font(.Exit.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.accent)
            }
            .padding(.horizontal, ExitSpacing.xxl)
            
            // 설명
            Text("20,000가지 미래를 시뮬레이션하고 있습니다")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            
            Spacer()
        }
    }
    
    // MARK: - Results View
    
    private func resultsView(result: MonteCarloResult) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: ExitSpacing.lg) {
                // 1. 성공률 카드
                SuccessRateCard(
                    result: result,
                    originalDDayMonths: viewModel.originalDDayMonths,
                    failureThresholdMultiplier: viewModel.failureThresholdMultiplier,
                    scenario: viewModel.activeScenario,
                    currentAssetAmount: viewModel.currentAssetAmount,
                    effectiveVolatility: viewModel.effectiveVolatility
                )
                
                // 2. 자산 변화 예측 차트 + FIRE 달성 시점 비교
                if let paths = result.representativePaths,
                   let scenario = viewModel.activeScenario {
                    AssetPathChart(
                        paths: paths,
                        scenario: scenario,
                        result: result,
                        originalDDayMonths: viewModel.originalDDayMonths,
                        currentAssetAmount: viewModel.currentAssetAmount,
                        effectiveVolatility: viewModel.effectiveVolatility
                    )
                }
                
                // 3. 목표 달성 시점 분포 차트
                DistributionChart(
                    yearDistributionData: viewModel.yearDistributionData,
                    result: result,
                    scenario: viewModel.activeScenario,
                    currentAssetAmount: viewModel.currentAssetAmount,
                    effectiveVolatility: viewModel.effectiveVolatility
                )
                
                // 4. 은퇴 후 단기(1~10년) 자산 변화
                if let retirementResult = viewModel.retirementResult,
                   let scenario = viewModel.activeScenario {
                    RetirementShortTermChart(result: retirementResult, scenario: scenario)
                }
                
                // 5. 은퇴 후 장기(40년) 자산 변화 예측
                if let retirementResult = viewModel.retirementResult,
                   let scenario = viewModel.activeScenario {
                    RetirementProjectionChart(result: retirementResult, scenario: scenario)
                }
                
                // 6. 시뮬레이션 상세 카드
                if let scenario = viewModel.activeScenario {
                    StatisticsCard(
                        result: result,
                        scenario: scenario,
                        effectiveVolatility: viewModel.effectiveVolatility
                    )
                }
                
                // 7. 시뮬레이션 정보 카드
                if let scenario = viewModel.activeScenario {
                    SimulationInfoCard(
                        scenario: scenario,
                        currentAssetAmount: viewModel.currentAssetAmount,
                        effectiveVolatility: viewModel.effectiveVolatility,
                        totalSimulations: result.totalSimulations
                    )
                }
                
                // 8. 액션 버튼들
                actionButtons                
            }
            .padding(.vertical, ExitSpacing.lg)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: ExitSpacing.md) {
            // 설정 버튼
            Button {
                showSettingsSheet = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.Exit.accent)
                    .frame(width: 56, height: 56)
                    .background(Color.Exit.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: ExitRadius.lg)
                            .stroke(Color.Exit.accent.opacity(0.3), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            
            // 다시 시뮬레이션 버튼
            Button {
                viewModel.refreshSimulation()
            } label: {
                HStack(spacing: ExitSpacing.sm) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                    Text("다시 시뮬레이션")
                        .font(.Exit.body)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "00D4AA"), Color(hex: "00B894")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, ExitSpacing.md)
    }
}

// MARK: - Simulation Settings Sheet

struct SimulationSettingsSheet: View {
    @Bindable var viewModel: SimulationViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempVolatility: Double = 15.0
    @State private var tempFailureThreshold: Double = 1.1
    @State private var selectedField: SettingField = .volatility
    
    enum SettingField {
        case volatility
        case failureThreshold
    }
    
    var body: some View {
        ZStack {
            Color.Exit.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 헤더
                header
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ExitSpacing.xl) {
                        // 변동성 설정
                        volatilitySection
                        
                        // 실패 조건 설정
                        failureThresholdSection
                        
                        // 퀵 버튼
                        quickButtons
                        
                        // 초기화 버튼
                        resetButton
                    }
                    .padding(.vertical, ExitSpacing.lg)
                }
                
                // 적용 버튼
                applyButton
            }
        }
        .onAppear {
            tempVolatility = viewModel.effectiveVolatility
            tempFailureThreshold = viewModel.failureThresholdMultiplier
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            
            Spacer()
            
            Text("시뮬레이션 설정")
                .font(.Exit.title3)
                .foregroundStyle(Color.Exit.primaryText)
            
            Spacer()
            
            // 균형용
            Image(systemName: "xmark")
                .font(.Exit.body)
                .foregroundStyle(.clear)
        }
        .padding(.horizontal, ExitSpacing.lg)
        .padding(.vertical, ExitSpacing.lg)
    }
    
    // MARK: - Volatility Section
    
    private var volatilitySection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            // 제목 및 설명
            VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                HStack {
                    Image(systemName: "waveform.path.ecg")
                        .foregroundStyle(Color.Exit.accent)
                    Text("수익률 변동성")
                        .font(.Exit.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.Exit.primaryText)
                }
                
                Text("주식 시장은 매년 수익률이 달라요. 변동성이 높으면 오르락내리락이 심하고, 낮으면 안정적이에요.")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // 설정 카드
            settingCard(
                value: tempVolatility,
                suffix: "%",
                isSelected: selectedField == .volatility,
                onTap: { selectedField = .volatility },
                onDecrease: {
                    if tempVolatility > 1 {
                        tempVolatility -= 1
                    }
                },
                onIncrease: {
                    if tempVolatility < 50 {
                        tempVolatility += 1
                    }
                }
            )
            
            // 참고 정보
            referenceInfo(
                items: [
                    ("📈 S&P500 역사적 변동성", "약 15~20%"),
                    ("🏦 채권 중심 포트폴리오", "약 5~10%"),
                    ("🎢 성장주 중심 포트폴리오", "약 20~30%")
                ]
            )
        }
        .padding(.horizontal, ExitSpacing.lg)
    }
    
    // MARK: - Failure Threshold Section
    
    private var failureThresholdSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            // 제목 및 설명
            VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                HStack {
                    Image(systemName: "clock.badge.exclamationmark")
                        .foregroundStyle(Color.Exit.caution)
                    Text("실패 조건")
                        .font(.Exit.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.Exit.primaryText)
                }
                
                Text("목표 기간보다 얼마나 늦어지면 '실패'로 볼지 정해요. 예를 들어 150%면 10년 목표일 때 15년이 넘으면 실패예요.")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // 설정 카드
            settingCard(
                value: tempFailureThreshold * 100,
                suffix: "%",
                isSelected: selectedField == .failureThreshold,
                onTap: { selectedField = .failureThreshold },
                onDecrease: {
                    if tempFailureThreshold > 1.1 {
                        tempFailureThreshold -= 0.1
                    }
                },
                onIncrease: {
                    if tempFailureThreshold < 3.0 {
                        tempFailureThreshold += 0.1
                    }
                }
            )
            
            // 현재 적용 예시
            if viewModel.originalDDayMonths > 0 {
                let originalYears = viewModel.originalDDayMonths / 12
                let originalMonths = viewModel.originalDDayMonths % 12
                let failureMonths = Int(Double(viewModel.originalDDayMonths) * tempFailureThreshold)
                let failureYears = failureMonths / 12
                let failureRemainingMonths = failureMonths % 12
                
                VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                    HStack(spacing: ExitSpacing.xs) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.Exit.accent)
                        Text("현재 설정 적용 시")
                            .font(.Exit.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.Exit.accent)
                    }
                    
                    let originalText = originalMonths > 0 ? "\(originalYears)년 \(originalMonths)개월" : "\(originalYears)년"
                    let failureText = failureRemainingMonths > 0 ? "\(failureYears)년 \(failureRemainingMonths)개월" : "\(failureYears)년"
                    
                    Text("목표: \(originalText) → 실패 기준: \(failureText) 초과")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
                .padding(ExitSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.Exit.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
            }
        }
        .padding(.horizontal, ExitSpacing.lg)
    }
    
    // MARK: - Setting Card
    
    private func settingCard(
        value: Double,
        suffix: String,
        isSelected: Bool,
        onTap: @escaping () -> Void,
        onDecrease: @escaping () -> Void,
        onIncrease: @escaping () -> Void
    ) -> some View {
        HStack {
            // - 버튼
            Button(action: onDecrease) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // 값 표시
            Button(action: onTap) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(String(format: "%.0f", value))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? Color.Exit.accent : Color.Exit.primaryText)
                    
                    Text(suffix)
                        .font(.Exit.title3)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // + 버튼
            Button(action: onIncrease) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.Exit.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, ExitSpacing.lg)
        .padding(.horizontal, ExitSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: ExitRadius.lg)
                .fill(Color.Exit.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: ExitRadius.lg)
                        .stroke(isSelected ? Color.Exit.accent : Color.Exit.divider, lineWidth: isSelected ? 2 : 1)
                )
        )
    }
    
    // MARK: - Reference Info
    
    private func referenceInfo(items: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: ExitSpacing.xs) {
            ForEach(items, id: \.0) { item in
                HStack {
                    Text(item.0)
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.tertiaryText)
                    Spacer()
                    Text(item.1)
                        .font(.Exit.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
            }
        }
        .padding(ExitSpacing.md)
        .background(Color.Exit.secondaryCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
    }
    
    // MARK: - Quick Buttons
    
    private var quickButtons: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            Text("빠른 조절")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            
            HStack(spacing: ExitSpacing.sm) {
                quickButton("+1%") { adjustSelectedField(by: 1) }
                quickButton("+5%") { adjustSelectedField(by: 5) }
                quickButton("+10%") { adjustSelectedField(by: 10) }
                quickButton("+25%") { adjustSelectedField(by: 25) }
                quickButton("+50%") { adjustSelectedField(by: 50) }
            }
            
            HStack(spacing: ExitSpacing.sm) {
                quickButton("-1%") { adjustSelectedField(by: -1) }
                quickButton("-5%") { adjustSelectedField(by: -5) }
                quickButton("-10%") { adjustSelectedField(by: -10) }
                quickButton("-25%") { adjustSelectedField(by: -25) }
                quickButton("-50%") { adjustSelectedField(by: -50) }
            }
        }
        .padding(.horizontal, ExitSpacing.lg)
    }
    
    private func quickButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.Exit.caption)
                .fontWeight(.medium)
                .foregroundStyle(label.hasPrefix("-") ? Color.Exit.warning : Color.Exit.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, ExitSpacing.sm)
                .background(
                    (label.hasPrefix("-") ? Color.Exit.warning : Color.Exit.accent).opacity(0.15)
                )
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
        }
        .buttonStyle(.plain)
    }
    
    private func adjustSelectedField(by percent: Double) {
        switch selectedField {
        case .volatility:
            let newValue = tempVolatility + percent
            tempVolatility = max(1, min(50, newValue))
        case .failureThreshold:
            let newValue = tempFailureThreshold + (percent / 100)
            tempFailureThreshold = max(1.1, min(3.0, newValue))
        }
    }
    
    // MARK: - Reset Button
    
    private var resetButton: some View {
        Button {
            tempVolatility = viewModel.activeScenario?.returnRateVolatility ?? 15.0
            tempFailureThreshold = 1.1
        } label: {
            HStack(spacing: ExitSpacing.sm) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14))
                Text("기본값으로 초기화")
                    .font(.Exit.caption)
            }
            .foregroundStyle(Color.Exit.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, ExitSpacing.md)
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: ExitRadius.md)
                    .stroke(Color.Exit.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, ExitSpacing.lg)
    }
    
    // MARK: - Apply Button
    
    private var applyButton: some View {
        Button {
            viewModel.updateVolatility(tempVolatility)
            viewModel.updateFailureThreshold(tempFailureThreshold)
            dismiss()
        } label: {
            Text("설정 저장")
                .font(.Exit.body)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, ExitSpacing.md)
                .background(LinearGradient.exitAccent)
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.xl))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, ExitSpacing.lg)
        .padding(.bottom, ExitSpacing.xl)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        SimulationView(viewModel: SimulationViewModel())
    }
    .preferredColorScheme(.dark)
}
