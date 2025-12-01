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
    
    /// 시뮬레이션 진행률 (0.0 ~ 1.0)
    var simulationProgress: Double = 0.0
    
    /// 시뮬레이션 횟수 (사용자가 조정 가능)
    var simulationCount: Int = 10_000
    
    /// 변동성 조정 (사용자가 조정 가능, Pro 기능)
    var customVolatility: Double?
    
    // MARK: - Computed Properties
    
    /// 현재 자산 금액
    var currentAssetAmount: Double {
        currentAsset?.amount ?? 0
    }
    
    /// 현재 표시할 결과
    var displayResult: MonteCarloResult? {
        return monteCarloResult
    }
    
    /// 사용할 변동성 (커스텀 또는 시나리오 기본값)
    var effectiveVolatility: Double {
        customVolatility ?? activeScenario?.returnRateVolatility ?? 15.0
    }
    
    /// 기존 D-Day (확정적 계산, 변동성 미반영)
    var originalDDayMonths: Int {
        guard let scenario = activeScenario else { return 0 }
        let result = RetirementCalculator.calculate(from: scenario, currentAsset: currentAssetAmount)
        return result.monthsToRetirement
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
    
    /// 몬테카를로 시뮬레이션 실행 (Fire-and-Forget 방식)
    /// UI가 즉시 업데이트되도록 await 없이 백그라운드 작업 시작
    @MainActor
    func runMonteCarloSimulation() {
        guard let scenario = activeScenario else { return }
        
        // 상태 변경
        isSimulating = true
        simulationProgress = 0.0
        
        // 메인 스레드에서 모든 값을 미리 캡처 (SwiftData @Model 접근)
        let currentAsset = self.currentAssetAmount
        let simCount = self.simulationCount
        let desiredMonthlyIncome = scenario.desiredMonthlyIncome
        let postRetirementReturnRate = scenario.postRetirementReturnRate
        let inflationRate = scenario.inflationRate
        let monthlyInvestment = scenario.monthlyInvestment
        let preRetirementReturnRate = scenario.preRetirementReturnRate
        let returnRateVolatility = scenario.returnRateVolatility
        let effectiveAsset = scenario.effectiveAsset(with: currentAsset)
        
        let targetAsset = RetirementCalculator.calculateTargetAssets(
            desiredMonthlyIncome: desiredMonthlyIncome,
            postRetirementReturnRate: postRetirementReturnRate,
            inflationRate: inflationRate
        )
        
        // 기존 D-Day 계산 (확정적 계산)
        let originalDDay = RetirementCalculator.calculateMonthsToRetirement(
            currentAssets: effectiveAsset,
            targetAssets: targetAsset,
            monthlyInvestment: monthlyInvestment,
            annualReturnRate: preRetirementReturnRate
        )
        
        // 실패 조건: 목표 D-Day * 1.5 (예: 8년 → 12년)
        let maxMonthsForSimulation = Int(Double(originalDDay) * 1.5)
        
        // 백그라운드 작업 시작
        Task.detached(priority: .userInitiated) { [weak self] in
            let result = MonteCarloSimulator.simulate(
                initialAsset: effectiveAsset,
                monthlyInvestment: monthlyInvestment,
                targetAsset: targetAsset,
                meanReturn: preRetirementReturnRate,
                volatility: returnRateVolatility,
                simulationCount: simCount,
                maxMonths: maxMonthsForSimulation,
                trackPaths: true,
                progressCallback: { @Sendable completed, _, _ in
                    // 진행률만 업데이트
                    let progress = Double(completed) / Double(simCount)
                    DispatchQueue.main.async {
                        self?.simulationProgress = progress
                    }
                }
            )
            
            // 완료 후 메인 스레드에서 결과 업데이트
            DispatchQueue.main.async {
                self?.monteCarloResult = result
                self?.isSimulating = false
            }
        }
    }
    
    /// 시뮬레이션 다시 실행
    @MainActor
    func refreshSimulation() {
        runMonteCarloSimulation()
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

