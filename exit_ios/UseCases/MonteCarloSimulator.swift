//
//  MonteCarloSimulator.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  몬테카를로 시뮬레이션 - 순수 비즈니스 로직 (안드로이드 재사용 가능)
//

import Foundation

/// 자산 변화 경로 (단일 시뮬레이션)
struct AssetPath {
    /// 월별 자산 값
    let monthlyAssets: [Double]
    
    /// 목표 달성 개월 수 (실패 시 nil)
    let monthsToTarget: Int?
    
    /// 성공 여부
    var isSuccess: Bool {
        monthsToTarget != nil
    }
}

/// 대표 경로들 (시각화용)
struct RepresentativePaths {
    /// 최선의 경우 (10 percentile)
    let best: AssetPath
    
    /// 중앙값 (50 percentile)
    let median: AssetPath
    
    /// 최악의 경우 (90 percentile)
    let worst: AssetPath
}

/// 몬테카를로 시뮬레이션 결과
struct MonteCarloResult {
    /// 성공률 (0.0 ~ 1.0)
    let successRate: Double
    
    /// 성공한 시뮬레이션들의 도달 개월 수 분포
    let successMonthsDistribution: [Int]
    
    /// 실패한 시뮬레이션 수
    let failureCount: Int
    
    /// 전체 시뮬레이션 횟수
    let totalSimulations: Int
    
    /// 대표 자산 경로 (시각화용)
    /// - 10 percentile (최선)
    /// - 50 percentile (중앙값)
    /// - 90 percentile (최악)
    let representativePaths: RepresentativePaths?
    
    /// 성공 시 평균 도달 개월 수
    var averageMonthsToSuccess: Double {
        guard !successMonthsDistribution.isEmpty else { return 0 }
        let sum = successMonthsDistribution.reduce(0, +)
        return Double(sum) / Double(successMonthsDistribution.count)
    }
    
    /// 중앙값 (50% 확률)
    var medianMonths: Int {
        guard !successMonthsDistribution.isEmpty else { return 0 }
        let sorted = successMonthsDistribution.sorted()
        return sorted[sorted.count / 2]
    }
    
    /// 10% 최악의 경우 (90 percentile)
    var worstCase10Percent: Int {
        guard !successMonthsDistribution.isEmpty else { return 0 }
        let sorted = successMonthsDistribution.sorted()
        let index = Int(Double(sorted.count) * 0.9)
        return sorted[min(index, sorted.count - 1)]
    }
    
    /// 10% 최선의 경우 (10 percentile)
    var bestCase10Percent: Int {
        guard !successMonthsDistribution.isEmpty else { return 0 }
        let sorted = successMonthsDistribution.sorted()
        let index = Int(Double(sorted.count) * 0.1)
        return sorted[index]
    }
    
    /// 연도별 분포 (히스토그램용)
    /// - Returns: [연도: 해당 연도에 도달한 시뮬레이션 수]
    func yearDistribution() -> [Int: Int] {
        var distribution: [Int: Int] = [:]
        
        for months in successMonthsDistribution {
            let years = months / 12
            distribution[years, default: 0] += 1
        }
        
        return distribution
    }
}

/// 몬테카를로 시뮬레이터 (정적 메서드만 사용 - 안드로이드 재사용 가능)
enum MonteCarloSimulator {
    
    // MARK: - Main Simulation
    
    /// 몬테카를로 시뮬레이션 실행
    /// - Parameters:
    ///   - initialAsset: 초기 자산 (원)
    ///   - monthlyInvestment: 월 투자 금액 (원)
    ///   - targetAsset: 목표 자산 (원)
    ///   - meanReturn: 평균 연 수익률 (%, 예: 6.5)
    ///   - volatility: 수익률 표준편차 (%, 예: 15)
    ///   - simulationCount: 시뮬레이션 횟수 (기본 10,000)
    ///   - maxMonths: 최대 개월 수 (기본 1200개월 = 100년)
    ///   - trackPaths: 자산 경로 추적 여부 (차트용)
    /// - Returns: 시뮬레이션 결과
    static func simulate(
        initialAsset: Double,
        monthlyInvestment: Double,
        targetAsset: Double,
        meanReturn: Double,
        volatility: Double,
        simulationCount: Int = 10_000,
        maxMonths: Int = 1200,
        trackPaths: Bool = true
    ) -> MonteCarloResult {
        
        var successMonths: [Int] = []
        var allPaths: [AssetPath] = []
        var failureCount = 0
        
        // 시뮬레이션 실행
        for _ in 0..<simulationCount {
            let (months, path) = runSingleSimulation(
                initialAsset: initialAsset,
                monthlyInvestment: monthlyInvestment,
                targetAsset: targetAsset,
                meanReturn: meanReturn,
                volatility: volatility,
                maxMonths: maxMonths,
                trackPath: trackPaths
            )
            
            if let months = months {
                successMonths.append(months)
            } else {
                failureCount += 1
            }
            
            if trackPaths, let path = path {
                allPaths.append(path)
            }
        }
        
        let successRate = Double(successMonths.count) / Double(simulationCount)
        
        // 대표 경로 추출
        let representativePaths = trackPaths ? extractRepresentativePaths(
            paths: allPaths,
            successMonths: successMonths
        ) : nil
        
        return MonteCarloResult(
            successRate: successRate,
            successMonthsDistribution: successMonths,
            failureCount: failureCount,
            totalSimulations: simulationCount,
            representativePaths: representativePaths
        )
    }
    
    // MARK: - Single Simulation
    
    /// 단일 시뮬레이션 실행
    /// - Returns: (목표 달성 개월 수, 자산 경로)
    private static func runSingleSimulation(
        initialAsset: Double,
        monthlyInvestment: Double,
        targetAsset: Double,
        meanReturn: Double,
        volatility: Double,
        maxMonths: Int,
        trackPath: Bool
    ) -> (months: Int?, path: AssetPath?) {
        
        var currentAsset = initialAsset
        var months = 0
        var assetHistory: [Double] = trackPath ? [initialAsset] : []
        
        // 월 평균 수익률과 표준편차 계산
        let annualMean = meanReturn / 100.0
        let annualVolatility = volatility / 100.0
        
        // 로그 정규분포를 위한 파라미터 변환
        let monthlyMean = log(1 + annualMean) / 12.0
        let monthlyVolatility = annualVolatility / sqrt(12.0)
        
        while currentAsset < targetAsset && months < maxMonths {
            // 1. 월초 투자금 추가
            currentAsset += monthlyInvestment
            
            // 2. 정규분포에서 수익률 샘플링 (Box-Muller 변환)
            let monthlyReturn = sampleNormalDistribution(
                mean: monthlyMean,
                standardDeviation: monthlyVolatility
            )
            
            // 3. 수익 적용 (로그 정규분포)
            currentAsset *= exp(monthlyReturn)
            
            // 4. 자산이 0 이하로 떨어지면 실패
            if currentAsset <= 0 {
                let path = trackPath ? AssetPath(
                    monthlyAssets: assetHistory,
                    monthsToTarget: nil
                ) : nil
                return (nil, path)
            }
            
            months += 1
            
            // 경로 추적
            if trackPath {
                assetHistory.append(currentAsset)
            }
        }
        
        // 목표 달성 여부 확인
        let success = currentAsset >= targetAsset
        let finalMonths = success ? months : nil
        
        let path = trackPath ? AssetPath(
            monthlyAssets: assetHistory,
            monthsToTarget: finalMonths
        ) : nil
        
        return (finalMonths, path)
    }
    
    // MARK: - Random Sampling
    
    /// 정규분포에서 샘플링 (Box-Muller 변환 사용)
    /// - Parameters:
    ///   - mean: 평균
    ///   - standardDeviation: 표준편차
    /// - Returns: 샘플링된 값
    private static func sampleNormalDistribution(
        mean: Double,
        standardDeviation: Double
    ) -> Double {
        // Box-Muller 변환
        let u1 = Double.random(in: 0..<1)
        let u2 = Double.random(in: 0..<1)
        
        // 표준정규분포 샘플
        let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
        
        // 평균과 표준편차 적용
        return mean + z0 * standardDeviation
    }
    
    // MARK: - Representative Paths
    
    /// 대표 경로 추출
    private static func extractRepresentativePaths(
        paths: [AssetPath],
        successMonths: [Int]
    ) -> RepresentativePaths? {
        guard !successMonths.isEmpty else { return nil }
        
        let sorted = successMonths.sorted()
        let bestIndex = Int(Double(sorted.count) * 0.1)
        let medianIndex = sorted.count / 2
        let worstIndex = Int(Double(sorted.count) * 0.9)
        
        let bestMonths = sorted[bestIndex]
        let medianMonths = sorted[medianIndex]
        let worstMonths = sorted[min(worstIndex, sorted.count - 1)]
        
        // 해당 개월수와 가장 가까운 경로 찾기
        let bestPath = paths.first { $0.monthsToTarget == bestMonths } ?? paths[bestIndex]
        let medianPath = paths.first { $0.monthsToTarget == medianMonths } ?? paths[medianIndex]
        let worstPath = paths.first { $0.monthsToTarget == worstMonths } ?? paths[min(worstIndex, paths.count - 1)]
        
        return RepresentativePaths(
            best: bestPath,
            median: medianPath,
            worst: worstPath
        )
    }
    
    // MARK: - Scenario-based Simulation
    
    /// 시나리오 기반 시뮬레이션 (편의 메서드)
    /// - Parameters:
    ///   - scenario: 시나리오
    ///   - currentAsset: 현재 자산
    ///   - simulationCount: 시뮬레이션 횟수
    ///   - trackPaths: 자산 경로 추적 여부
    /// - Returns: 시뮬레이션 결과
    static func simulate(
        scenario: Scenario,
        currentAsset: Double,
        simulationCount: Int = 10_000,
        trackPaths: Bool = true
    ) -> MonteCarloResult {
        // 목표 자산 계산
        let targetAsset = RetirementCalculator.calculateTargetAssets(
            desiredMonthlyIncome: scenario.desiredMonthlyIncome,
            postRetirementReturnRate: scenario.postRetirementReturnRate,
            inflationRate: scenario.inflationRate
        )
        
        // 시나리오 오프셋 적용
        let effectiveAsset = scenario.effectiveAsset(with: currentAsset)
        
        return simulate(
            initialAsset: effectiveAsset,
            monthlyInvestment: scenario.monthlyInvestment,
            targetAsset: targetAsset,
            meanReturn: scenario.preRetirementReturnRate,
            volatility: scenario.returnRateVolatility,
            simulationCount: simulationCount,
            trackPaths: trackPaths
        )
    }
}

// MARK: - Result Extensions

extension MonteCarloResult {
    /// 성공 횟수
    var successCount: Int {
        successMonthsDistribution.count
    }
    
    /// 성공 여부 (50% 이상)
    var isLikelyToSucceed: Bool {
        successRate >= 0.5
    }
    
    /// 신뢰도 등급
    var confidenceLevel: ConfidenceLevel {
        switch successRate {
        case 0.95...: return .veryHigh
        case 0.85..<0.95: return .high
        case 0.70..<0.85: return .moderate
        case 0.50..<0.70: return .low
        default: return .veryLow
        }
    }
    
    enum ConfidenceLevel: String {
        case veryHigh = "매우 높음"
        case high = "높음"
        case moderate = "보통"
        case low = "낮음"
        case veryLow = "매우 낮음"
        
        var color: String {
            switch self {
            case .veryHigh: return "00D4AA"  // 액센트 색
            case .high: return "00D4AA"
            case .moderate: return "FFD60A"  // 노랑
            case .low: return "FF9500"       // 주황
            case .veryLow: return "FF3B30"   // 빨강
            }
        }
    }
}

