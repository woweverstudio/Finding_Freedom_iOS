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
            if let result = viewModel.displayResult {
                // 결과 화면 (진행 중이거나 완료)
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
