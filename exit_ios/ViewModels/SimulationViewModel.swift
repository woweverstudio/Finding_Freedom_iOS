//
//  SimulationViewModel.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import Foundation
import SwiftData
import Observation

@Observable
final class SimulationViewModel {
    // MARK: - Dependencies
    
    private var modelContext: ModelContext?
    
    // MARK: - State
    
    /// 현재 자산
    var currentAsset: Asset?
    
    /// 활성 시나리오
    var activeScenario: Scenario?
    
    /// 몬테카를로 시뮬레이션 결과
    var monteCarloResult: MonteCarloResult?
    
    /// 시뮬레이션 진행 중 여부
    var isSimulating: Bool = false
    
    /// 시뮬레이션 횟수 (사용자가 조정 가능)
    var simulationCount: Int = 10_000
    
    /// 변동성 조정 (사용자가 조정 가능, Pro 기능)
    var customVolatility: Double?
    
    // MARK: - Computed Properties
    
    /// 현재 자산 금액
    var currentAssetAmount: Double {
        currentAsset?.amount ?? 0
    }
    
    /// 사용할 변동성 (커스텀 또는 시나리오 기본값)
    var effectiveVolatility: Double {
        customVolatility ?? activeScenario?.returnRateVolatility ?? 15.0
    }
    
    /// 차트용 연도 분포 데이터
    var yearDistributionData: [(year: Int, count: Int)] {
        guard let result = monteCarloResult else { return [] }
        
        let distribution = result.yearDistribution()
        return distribution.sorted(by: { $0.key < $1.key })
            .map { (year: $0.key, count: $0.value) }
    }
    
    /// 퍼센타일 데이터 (차트용)
    var percentileData: [PercentilePoint] {
        guard let result = monteCarloResult else { return [] }
        
        return [
            PercentilePoint(label: "최선 10%", months: result.bestCase10Percent, percentile: 10),
            PercentilePoint(label: "평균", months: Int(result.averageMonthsToSuccess), percentile: 50),
            PercentilePoint(label: "중앙값", months: result.medianMonths, percentile: 50),
            PercentilePoint(label: "최악 10%", months: result.worstCase10Percent, percentile: 90)
        ]
    }
    
    // MARK: - Initialization
    
    func configure(with context: ModelContext) {
        self.modelContext = context
        loadData()
    }
    
    // MARK: - Data Loading
    
    func loadData() {
        guard let context = modelContext else { return }
        
        // Asset 로드
        let assetDescriptor = FetchDescriptor<Asset>()
        currentAsset = try? context.fetch(assetDescriptor).first
        
        // 활성 Scenario 로드
        let scenarioDescriptor = FetchDescriptor<Scenario>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        let scenarios = (try? context.fetch(scenarioDescriptor)) ?? []
        activeScenario = scenarios.first(where: { $0.isActive }) ?? scenarios.first
    }
    
    // MARK: - Simulation
    
    /// 몬테카를로 시뮬레이션 실행
    @MainActor
    func runMonteCarloSimulation() async {
        guard let scenario = activeScenario else { return }
        
        isSimulating = true
        
        // 시뮬레이션에 필요한 값들을 미리 캡처
        let currentAsset = self.currentAssetAmount
        let simCount = self.simulationCount
        
        // 백그라운드 스레드에서 시뮬레이션 실행
        let result = await Task.detached(priority: .userInitiated) {
            MonteCarloSimulator.simulate(
                scenario: scenario,
                currentAsset: currentAsset,
                simulationCount: simCount
            )
        }.value
        
        // 결과를 메인 스레드에서 업데이트
        self.monteCarloResult = result
        self.isSimulating = false
    }
    
    /// 시뮬레이션 다시 실행
    func refreshSimulation() {
        Task { @MainActor in
            await runMonteCarloSimulation()
        }
    }
    
    /// 시뮬레이션 횟수 변경
    func updateSimulationCount(_ count: Int) {
        simulationCount = count
        refreshSimulation()
    }
    
    /// 변동성 변경
    func updateVolatility(_ volatility: Double) {
        customVolatility = volatility
        refreshSimulation()
    }
    
    /// 변동성 초기화 (시나리오 기본값으로)
    func resetVolatility() {
        customVolatility = nil
        refreshSimulation()
    }
}

// MARK: - Supporting Types

struct PercentilePoint: Identifiable {
    let id = UUID()
    let label: String
    let months: Int
    let percentile: Int
    
    var years: Double {
        Double(months) / 12.0
    }
    
    var displayText: String {
        let years = months / 12
        let remainingMonths = months % 12
        if remainingMonths == 0 {
            return "\(years)년"
        } else {
            return "\(years)년 \(remainingMonths)개월"
        }
    }
}

