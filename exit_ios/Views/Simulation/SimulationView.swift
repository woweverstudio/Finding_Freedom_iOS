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
            Text("10,000가지 미래를 시뮬레이션하고 있습니다")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            
            Spacer()
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
