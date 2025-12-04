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
    
    /// 몬테카를로 시뮬레이션 결과 (목표 달성까지)
    var monteCarloResult: MonteCarloResult?
    
    /// 은퇴 후 시뮬레이션 결과
    var retirementResult: RetirementSimulationResult?
    
    /// 시뮬레이션 진행 중 여부
    var isSimulating: Bool = false
    
    /// 시뮬레이션 진행률 (0.0 ~ 1.0)
    var simulationProgress: Double = 0.0
    
    /// 현재 시뮬레이션 단계 설명
    var simulationPhase: SimulationPhase = .idle
    
    /// 시뮬레이션 횟수 (사용자가 조정 가능)
    var simulationCount: Int = 30_000
    
    /// 변동성 조정 (사용자가 조정 가능)
    var customVolatility: Double?
    
    /// 실패 조건 배수 (기본값 1.1 = 목표 기간의 110%)
    var failureThresholdMultiplier: Double = 1.1
    
    // MARK: - Simulation Phase
    
    enum SimulationPhase {
        case idle
        case preRetirement  // 목표 달성까지 시뮬레이션
        case postRetirement // 은퇴 후 시뮬레이션
        
        var description: String {
            switch self {
            case .idle: return ""
            case .preRetirement: return "목표 달성까지 시뮬레이션 중..."
            case .postRetirement: return "은퇴 후 시뮬레이션 중..."
            }
        }
    }
    
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
    
    /// 실패 기준 개월 수
    var failureThresholdMonths: Int {
        Int(Double(originalDDayMonths) * failureThresholdMultiplier)
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
            PercentilePoint(label: "행운 10%", months: result.bestCase10Percent, percentile: 10),
            PercentilePoint(label: "평균", months: Int(result.averageMonthsToSuccess), percentile: 50),
            PercentilePoint(label: "중앙값", months: result.medianMonths, percentile: 50),
            PercentilePoint(label: "불행 10%", months: result.worstCase10Percent, percentile: 90)
        ]
    }
    
    /// 목표 자산
    var targetAsset: Double {
        guard let scenario = activeScenario else { return 0 }
        return RetirementCalculator.calculateTargetAssets(
            desiredMonthlyIncome: scenario.desiredMonthlyIncome,
            postRetirementReturnRate: scenario.postRetirementReturnRate,
            inflationRate: scenario.inflationRate
        )
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
    
    /// 모든 시뮬레이션 실행 (목표 달성 + 은퇴 후)
    @MainActor
    func runAllSimulations() {
        guard let scenario = activeScenario else { return }
        
        // 상태 변경
        isSimulating = true
        simulationProgress = 0.0
        simulationPhase = .preRetirement
        
        // 메인 스레드에서 모든 값을 미리 캡처 (SwiftData @Model 접근)
        let currentAsset = self.currentAssetAmount
        let simCount = self.simulationCount
        let desiredMonthlyIncome = scenario.desiredMonthlyIncome
        let postRetirementReturnRate = scenario.postRetirementReturnRate
        let inflationRate = scenario.inflationRate
        let monthlyInvestment = scenario.monthlyInvestment
        let preRetirementReturnRate = scenario.preRetirementReturnRate
        let preRetirementVolatility = self.effectiveVolatility
        let postRetirementVolatility = Self.calculateVolatility(for: postRetirementReturnRate)
        let effectiveAsset = scenario.effectiveAsset(with: currentAsset)
        let failureMultiplier = self.failureThresholdMultiplier
        
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
        
        // 실패 조건: 목표 D-Day * failureMultiplier
        let maxMonthsForSimulation = Int(Double(originalDDay) * failureMultiplier)
        
        // 백그라운드 작업 시작
        Task.detached(priority: .userInitiated) { [weak self] in
            // Phase 1: 목표 달성까지 시뮬레이션 (은퇴 전 수익률/변동성 사용)
            let monteCarloResult = MonteCarloSimulator.simulate(
                initialAsset: effectiveAsset,
                monthlyInvestment: monthlyInvestment,
                targetAsset: targetAsset,
                meanReturn: preRetirementReturnRate,
                volatility: preRetirementVolatility,
                simulationCount: simCount,
                maxMonths: maxMonthsForSimulation,
                trackPaths: true,
                progressCallback: { @Sendable completed, _, _ in
                    let progress = Double(completed) / Double(simCount) * 0.5 // 전체의 50%
                    DispatchQueue.main.async {
                        self?.simulationProgress = progress
                    }
                }
            )
            
            // 메인 스레드에서 Phase 1 결과 저장 및 Phase 2 시작
            await MainActor.run {
                self?.monteCarloResult = monteCarloResult
                self?.simulationPhase = .postRetirement
            }
            
            // Phase 2: 은퇴 후 시뮬레이션 (은퇴 후 수익률/변동성 사용)
            let retirementResult = RetirementSimulator.simulate(
                initialAsset: targetAsset,
                monthlySpending: desiredMonthlyIncome,
                annualReturn: postRetirementReturnRate,
                volatility: postRetirementVolatility,
                simulationCount: simCount,
                progressCallback: { @Sendable completed in
                    let progress = 0.5 + Double(completed) / Double(simCount) * 0.5 // 50~100%
                    DispatchQueue.main.async {
                        self?.simulationProgress = progress
                    }
                }
            )
            
            // 완료 후 메인 스레드에서 결과 업데이트
            await MainActor.run {
                self?.retirementResult = retirementResult
                self?.simulationPhase = .idle
                self?.isSimulating = false
            }
        }
    }
    
    /// 시뮬레이션 다시 실행
    @MainActor
    func refreshSimulation() {
        runAllSimulations()
    }
    
    /// 시뮬레이션 횟수 변경
    func updateSimulationCount(_ count: Int) {
        simulationCount = count
        refreshSimulation()
    }
    
    /// 변동성 변경
    func updateVolatility(_ volatility: Double) {
        customVolatility = volatility
    }
    
    /// 변동성 초기화 (시나리오 기본값으로)
    func resetVolatility() {
        customVolatility = nil
    }
    
    /// 실패 조건 배수 변경
    func updateFailureThreshold(_ multiplier: Double) {
        failureThresholdMultiplier = multiplier
    }
    
    /// 실패 조건 초기화
    func resetFailureThreshold() {
        failureThresholdMultiplier = 1.1
    }
    
    /// 모든 설정 초기화
    func resetAllSettings() {
        resetVolatility()
        resetFailureThreshold()
    }
    
    // MARK: - Volatility Calculation
    
    /// 목표 수익률 기반 변동성 자동 계산
    /// - Parameter returnRate: 연 목표 수익률 (%)
    /// - Returns: 변동성 (표준편차, %)
    static func calculateVolatility(for returnRate: Double) -> Double {
        switch returnRate {
        case ..<2.5:  return 1.0    // 초안전 자산
        case 2.5..<4: return 4.5    // 국채 중심
        case 4..<6:   return 7.0    // 채권 혼합
        case 6..<7:   return 11.0   // 60:40 현실화
        case 7..<8:   return 13.0
        case 8..<9:   return 15.0
        case 9..<10:  return 17.0   // S&P500 평균
        case 10..<12: return 21.0
        case 12..<15: return 27.0
        case 15..<20: return 30.0
        default:      return 35.0   // 고위험·레버리지
        }
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
