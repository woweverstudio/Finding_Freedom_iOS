//
//  SimulationView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 시뮬레이션 탭 메인 뷰
struct SimulationView: View {
    @Environment(\.appState) private var appState
    @Bindable var viewModel: SimulationViewModel
    @State private var currentScreen: SimulationScreen = .empty
    @State private var scrollOffset: CGFloat = 0
    
    /// 화면 상태
    enum SimulationScreen {
        case empty      // 미구입 또는 초기 화면
        case setup      // 설정 화면
        case results    // 결과 화면
    }
    
    /// 스크롤 20pt 이상이면 컴팩트 모드
    private var isHeaderCompact: Bool {
        scrollOffset > 20
    }
    
    var body: some View {
        ZStack {
            // 화면 상태에 따른 뷰 전환
            switch currentScreen {
            case .empty:
                emptyScreenView
                
            case .setup:
                SimulationSetupView(
                    viewModel: viewModel,
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            // 결과가 있으면 결과로, 없으면 empty로
                            currentScreen = viewModel.displayResult != nil ? .results : .empty
                        }
                    },
                    onStart: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentScreen = .results
                        }
                    }
                )
                .transition(.move(edge: .trailing))
                
            case .results:
                resultsScreenView
            }
        }
        .onChange(of: appState.storeKit.hasMontecarloSimulation) { _, hasPurchased in
            // 구입 완료 시 설정 화면으로 이동
            if hasPurchased && currentScreen == .empty {
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentScreen = .setup
                }
            }
        }
    }
    
    // MARK: - Empty Screen
    
    private var emptyScreenView: some View {
        SimulationEmptyView(
            userProfile: viewModel.userProfile,
            currentAssetAmount: viewModel.currentAssetAmount,
            onStart: {
                // 이미 구입한 경우 설정 화면으로
                if appState.storeKit.hasMontecarloSimulation {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentScreen = .setup
                    }
                }
                // 미구입인 경우 EmptyView에서 구입 처리
            },
            isPurchased: appState.storeKit.hasMontecarloSimulation
        )
    }
    
    // MARK: - Results Screen
    
    private var resultsScreenView: some View {
        VStack(spacing: 0) {
            // 메인 컨텐츠
            ZStack {
                if viewModel.isSimulating {
                    loadingView
                } else if let result = viewModel.displayResult {
                    resultsView(result: result)
                } else {
                    // 결과가 없으면 로딩 화면
                    loadingView
                }
            }
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
            Text("30,000가지 미래를 시뮬레이션하고 있습니다")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            
            Spacer()
        }
    }
    
    // MARK: - Results View
    
    private func resultsView(result: MonteCarloResult) -> some View {
        let isAlreadyRetired = viewModel.originalDDayMonths == 0
        
        return ScrollView(showsIndicators: false) {
            VStack(spacing: ExitSpacing.lg) {
                if isAlreadyRetired {
                    // 이미 은퇴 가능한 경우: 은퇴 후 시뮬레이션만 표시
                    retirementReadyHeader
                    
                    // 은퇴 후 단기(1~10년) 자산 변화
                    if let retirementResult = viewModel.retirementResult,
                       let profile = viewModel.userProfile {
                        RetirementShortTermChart(result: retirementResult, userProfile: profile)
                    }
                    
                    // 은퇴 후 장기(40년) 자산 변화 예측
                    if let retirementResult = viewModel.retirementResult,
                       let profile = viewModel.userProfile {
                        RetirementProjectionChart(result: retirementResult, userProfile: profile)
                    }
                    
                    // 시뮬레이션 정보 카드
                    if let profile = viewModel.userProfile {
                        SimulationInfoCard(
                            userProfile: profile,
                            currentAssetAmount: viewModel.currentAssetAmount,
                            effectiveVolatility: viewModel.effectiveVolatility,
                            result: result
                        )
                    }
                } else {
                    // 아직 은퇴 전: 전체 시뮬레이션 표시
                    
                    // 1. 성공률 카드
                    SuccessRateCard(
                        result: result,
                        originalDDayMonths: viewModel.originalDDayMonths,
                        failureThresholdMultiplier: viewModel.failureThresholdMultiplier,
                        userProfile: viewModel.userProfile,
                        currentAssetAmount: viewModel.currentAssetAmount,
                        effectiveVolatility: viewModel.effectiveVolatility
                    )
                    
                    // 2. 자산 변화 예측 차트 + FIRE 달성 시점 비교
                    if let paths = result.representativePaths,
                       let profile = viewModel.userProfile {
                        AssetPathChart(
                            paths: paths,
                            userProfile: profile,
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
                        userProfile: viewModel.userProfile,
                        currentAssetAmount: viewModel.currentAssetAmount,
                        effectiveVolatility: viewModel.effectiveVolatility
                    )
                    
                    // 4. 은퇴 후 단기(1~10년) 자산 변화
                    if let retirementResult = viewModel.retirementResult,
                       let profile = viewModel.userProfile {
                        RetirementShortTermChart(result: retirementResult, userProfile: profile)
                    }
                    
                    // 5. 은퇴 후 장기(40년) 자산 변화 예측
                    if let retirementResult = viewModel.retirementResult,
                       let profile = viewModel.userProfile {
                        RetirementProjectionChart(result: retirementResult, userProfile: profile)
                    }
                    
                    // 6. 시뮬레이션 정보 카드
                    if let profile = viewModel.userProfile {
                        SimulationInfoCard(
                            userProfile: profile,
                            currentAssetAmount: viewModel.currentAssetAmount,
                            effectiveVolatility: viewModel.effectiveVolatility,
                            result: result
                        )
                    }
                }
                
                // 액션 버튼들
                actionButtons                
            }
            .padding(.vertical, ExitSpacing.lg)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { _, newValue in
            scrollOffset = newValue
        }
    }
    
    // MARK: - Retirement Ready Header
    
    private var retirementReadyHeader: some View {
        VStack(spacing: ExitSpacing.md) {
            Text("🎉")
                .font(.system(size: 50))
            
            Text("이미 은퇴 가능합니다!")
                .font(.Exit.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.Exit.accent)
            
            if let profile = viewModel.userProfile {
                let requiredRate = RetirementCalculator.calculateRequiredReturnRate(
                    currentAssets: viewModel.currentAssetAmount,
                    desiredMonthlyIncome: profile.desiredMonthlyIncome,
                    inflationRate: profile.inflationRate
                )
                
                VStack(spacing: ExitSpacing.xs) {
                    Text("매월 \(ExitNumberFormatter.formatToManWon(profile.desiredMonthlyIncome)) 현금흐름을 위해")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    HStack(spacing: ExitSpacing.xs) {
                        Text("연")
                            .font(.Exit.body)
                            .foregroundStyle(Color.Exit.secondaryText)
                        Text(String(format: "%.2f%%", requiredRate))
                            .font(.Exit.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(requiredRate < 4 ? Color.Exit.positive : Color.Exit.accent)
                        Text("수익률만 달성하면 됩니다")
                            .font(.Exit.body)
                            .foregroundStyle(Color.Exit.secondaryText)
                    }
                }
            }
            
            Text("아래는 은퇴 후 자산 변화 시뮬레이션입니다")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.tertiaryText)
                .padding(.top, ExitSpacing.sm)
        }
        .padding(ExitSpacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: ExitRadius.xl)
                .fill(LinearGradient.exitCard)
        )
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        // 다시 시뮬레이션 버튼만 표시
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentScreen = .setup
            }
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
        .padding(.horizontal, ExitSpacing.md)
    }
}
