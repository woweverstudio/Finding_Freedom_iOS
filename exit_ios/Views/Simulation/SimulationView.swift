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
    
    var body: some View {
        ZStack {
            if viewModel.isSimulating {
                // 로딩 화면
                loadingView
            } else if let result = viewModel.monteCarloResult {
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
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: ExitSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color.Exit.accent)
            
            Text("시뮬레이션 실행 중...")
                .font(.Exit.title3)
                .foregroundStyle(Color.Exit.primaryText)
            
            Text("\(viewModel.simulationCount.formatted())번 시뮬레이션")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
        }
    }
    
    // MARK: - Results View
    
    private func resultsView(result: MonteCarloResult) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: ExitSpacing.lg) {
                // 시뮬레이션 정보
                if let scenario = viewModel.activeScenario {
                    SimulationInfoCard(
                        scenario: scenario,
                        currentAssetAmount: viewModel.currentAssetAmount,
                        effectiveVolatility: viewModel.effectiveVolatility,
                        totalSimulations: result.totalSimulations
                    )
                }
                
                // 성공률 카드
                SuccessRateCard(result: result)
                
                // 자산 변화 예측 차트
                if let paths = result.representativePaths,
                   let scenario = viewModel.activeScenario {
                    AssetPathChart(paths: paths, scenario: scenario)
                }
                
                // 연도별 분포 차트
                DistributionChart(
                    yearDistributionData: viewModel.yearDistributionData,
                    result: result
                )
                
                // 퍼센타일 카드
                PercentileCard(result: result)
                
                // 상세 통계
                if let scenario = viewModel.activeScenario {
                    StatisticsCard(
                        result: result,
                        scenario: scenario,
                        effectiveVolatility: viewModel.effectiveVolatility
                    )
                }
                
                // 시뮬레이션 설정
                SimulationSettingsCard(
                    onRefresh: { viewModel.refreshSimulation() }
                )
                
                Spacer()
                    .frame(height: 80)
            }
            .padding(.vertical, ExitSpacing.lg)
        }
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
