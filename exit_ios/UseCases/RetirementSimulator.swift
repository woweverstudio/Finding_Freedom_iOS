//
//  RetirementSimulator.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  은퇴 후 자산 변화 시뮬레이션 - 순수 비즈니스 로직
//

import Foundation

/// 단일 시뮬레이션 경로 (경로 + 소진 연도)
struct RetirementPath {
    let yearlyAssets: [Double]  // 연도별 자산
    let depletionYear: Int?     // 소진 연도 (없으면 nil)
    
    var finalAsset: Double {
        yearlyAssets.last ?? 0
    }
}

/// 은퇴 후 시뮬레이션 결과
struct RetirementSimulationResult {
    /// 행운 경로 (상위 10%)
    let bestPath: RetirementPath
    
    /// 평균 경로 (중앙값)
    let medianPath: RetirementPath
    
    /// 불운 경로 (하위 10%)
    let worstPath: RetirementPath
    
    /// 기존 예측 경로 (변동성 없음)
    let deterministicPath: RetirementPath
    
    /// 시뮬레이션 횟수
    let totalSimulations: Int
    
    // 편의 프로퍼티
    var medianDepletionYear: Int? { medianPath.depletionYear }
    var worstDepletionYear: Int? { worstPath.depletionYear }
}

/// 은퇴 후 자산 변화 시뮬레이터
/// nonisolated로 선언하여 백그라운드 스레드에서도 호출 가능
enum RetirementSimulator {
    
    /// 진행률 콜백 타입
    typealias ProgressCallback = @Sendable (Int) -> Void
    
    /// 은퇴 후 시뮬레이션 실행
    /// - Parameters:
    ///   - initialAsset: 초기 자산 (목표 자산)
    ///   - monthlySpending: 월 지출액 (희망 월 수입)
    ///   - annualReturn: 은퇴 후 연 수익률 (%)
    ///   - volatility: 수익률 변동성 (%)
    ///   - years: 시뮬레이션 기간 (년)
    ///   - simulationCount: 시뮬레이션 횟수
    ///   - progressCallback: 진행률 콜백
    /// - Returns: 시뮬레이션 결과
    nonisolated static func simulate(
        initialAsset: Double,
        monthlySpending: Double,
        annualReturn: Double,
        volatility: Double,
        years: Int = 40,
        simulationCount: Int = 10_000,
        progressCallback: ProgressCallback? = nil
    ) -> RetirementSimulationResult {
        
        var allPaths: [RetirementPath] = []
        
        // 월 수익률 파라미터 (로그 정규분포)
        let monthlyMean = log(1 + annualReturn / 100) / 12.0
        let monthlyVolatility = (volatility / 100) / sqrt(12.0)
        
        // 업데이트 간격 (200번마다 한 번씩 콜백)
        let updateInterval = 200
        
        for i in 0..<simulationCount {
            let path = runSingleSimulation(
                initialAsset: initialAsset,
                monthlySpending: monthlySpending,
                monthlyMean: monthlyMean,
                monthlyVolatility: monthlyVolatility,
                years: years
            )
            
            allPaths.append(path)
            
            // 진행률 콜백
            if (i + 1) % updateInterval == 0 || i == simulationCount - 1 {
                progressCallback?(i + 1)
            }
        }
        
        // 기존 예측 (변동성 없음)
        let deterministicPath = calculateDeterministicPath(
            initialAsset: initialAsset,
            monthlySpending: monthlySpending,
            annualReturn: annualReturn,
            years: years
        )
        
        // 대표 경로 추출 (최종 자산 기준으로 정렬)
        // 최종 자산이 높은 순서로 정렬 (상위 = 행운, 하위 = 불운)
        let sortedPaths = allPaths.sorted { $0.finalAsset > $1.finalAsset }
        
        let bestPath = sortedPaths[simulationCount / 10]           // 상위 10%
        let medianPath = sortedPaths[simulationCount / 2]          // 중앙값
        let worstPath = sortedPaths[simulationCount * 9 / 10]      // 하위 10%
        
        return RetirementSimulationResult(
            bestPath: bestPath,
            medianPath: medianPath,
            worstPath: worstPath,
            deterministicPath: deterministicPath,
            totalSimulations: simulationCount
        )
    }
    
    // MARK: - Single Simulation
    
    /// 단일 시뮬레이션 실행
    nonisolated private static func runSingleSimulation(
        initialAsset: Double,
        monthlySpending: Double,
        monthlyMean: Double,
        monthlyVolatility: Double,
        years: Int
    ) -> RetirementPath {
        
        var yearlyAssets: [Double] = [initialAsset]
        var currentAsset = initialAsset
        var depletionYear: Int? = nil
        
        for year in 1...years {
            // 12개월 시뮬레이션
            for _ in 1...12 {
                // 월 수익률 샘플링 (Box-Muller 변환)
                let monthlyReturn = sampleNormalDistribution(
                    mean: monthlyMean,
                    standardDeviation: monthlyVolatility
                )
                
                // 수익 적용 (로그 정규분포)
                currentAsset *= exp(monthlyReturn)
                
                // 지출
                currentAsset -= monthlySpending
            }
            
            yearlyAssets.append(max(0, currentAsset))
            
            // 자산 소진 체크
            if currentAsset <= 0 && depletionYear == nil {
                depletionYear = year
            }
        }
        
        return RetirementPath(yearlyAssets: yearlyAssets, depletionYear: depletionYear)
    }
    
    // MARK: - Deterministic Calculation
    
    /// 확정적 계산 (변동성 없음)
    nonisolated private static func calculateDeterministicPath(
        initialAsset: Double,
        monthlySpending: Double,
        annualReturn: Double,
        years: Int
    ) -> RetirementPath {
        var yearlyAssets: [Double] = [initialAsset]
        var currentAsset = initialAsset
        let monthlyReturn = annualReturn / 100 / 12
        var depletionYear: Int? = nil
        
        for year in 1...years {
            for _ in 1...12 {
                currentAsset *= (1 + monthlyReturn)
                currentAsset -= monthlySpending
            }
            yearlyAssets.append(max(0, currentAsset))
            
            if currentAsset <= 0 && depletionYear == nil {
                depletionYear = year
            }
        }
        
        return RetirementPath(yearlyAssets: yearlyAssets, depletionYear: depletionYear)
    }
    
    // MARK: - Random Sampling
    
    /// 정규분포에서 샘플링 (Box-Muller 변환)
    nonisolated private static func sampleNormalDistribution(
        mean: Double,
        standardDeviation: Double
    ) -> Double {
        let u1 = Double.random(in: 0..<1)
        let u2 = Double.random(in: 0..<1)
        let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
        return mean + z0 * standardDeviation
    }
    
    // MARK: - Scenario-based Simulation
    
    /// 시나리오 기반 시뮬레이션 (편의 메서드)
    nonisolated static func simulate(
        scenario: Scenario,
        simulationCount: Int = 10_000,
        progressCallback: ProgressCallback? = nil
    ) -> RetirementSimulationResult {
        
        // 목표 자산 계산
        let targetAsset = RetirementCalculator.calculateTargetAssets(
            desiredMonthlyIncome: scenario.desiredMonthlyIncome,
            postRetirementReturnRate: scenario.postRetirementReturnRate,
            inflationRate: scenario.inflationRate
        )
        
        return simulate(
            initialAsset: targetAsset,
            monthlySpending: scenario.desiredMonthlyIncome,
            annualReturn: scenario.postRetirementReturnRate,
            volatility: scenario.returnRateVolatility,
            simulationCount: simulationCount,
            progressCallback: progressCallback
        )
    }
}
