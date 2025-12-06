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
    
    /// 10년 후 자산 (단기 분석용)
    var assetAt10Years: Double {
        yearlyAssets.count > 10 ? yearlyAssets[10] : (yearlyAssets.last ?? 0)
    }
}

/// 은퇴 후 시뮬레이션 결과
struct RetirementSimulationResult {
    // MARK: - 장기 (40년 기준) 경로
    
    /// 매우 행운 경로 - 40년 기준 (상위 10%)
    let veryBestPath: RetirementPath
    
    /// 행운 경로 - 40년 기준 (상위 30%)
    let luckyPath: RetirementPath
    
    /// 평균 경로 - 40년 기준 (중앙값 50%)
    let medianPath: RetirementPath
    
    /// 불행 경로 - 40년 기준 (하위 30%)
    let unluckyPath: RetirementPath
    
    /// 매우 불행 경로 - 40년 기준 (하위 10%)
    let veryWorstPath: RetirementPath
    
    // MARK: - 단기 (10년 기준) 경로
    
    /// 매우 행운 경로 - 10년 기준 (상위 10%)
    let shortTermVeryBestPath: RetirementPath
    
    /// 행운 경로 - 10년 기준 (상위 30%)
    let shortTermLuckyPath: RetirementPath
    
    /// 평균 경로 - 10년 기준 (중앙값 50%)
    let shortTermMedianPath: RetirementPath
    
    /// 불행 경로 - 10년 기준 (하위 30%)
    let shortTermUnluckyPath: RetirementPath
    
    /// 매우 불행 경로 - 10년 기준 (하위 10%)
    let shortTermVeryWorstPath: RetirementPath
    
    // MARK: - 공통
    
    /// 기존 예측 경로 (변동성 없음)
    let deterministicPath: RetirementPath
    
    /// 시뮬레이션 횟수
    let totalSimulations: Int
    
    // 기존 호환성을 위한 별칭
    var bestPath: RetirementPath { veryBestPath }
    var worstPath: RetirementPath { veryWorstPath }
    
    // 편의 프로퍼티
    var medianDepletionYear: Int? { medianPath.depletionYear }
    var worstDepletionYear: Int? { veryWorstPath.depletionYear }
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
        simulationCount: Int = 30_000,
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
        
        // === 장기 (40년) 기준 정렬 ===
        // 최종 자산 기준으로 오름차순 정렬
        // 2차 정렬: finalAsset이 같으면 (특히 둘 다 소진된 경우), 더 빨리 소진된 게 더 나쁨
        let sortedByFinal = allPaths.sorted { path0, path1 in
            if path0.finalAsset != path1.finalAsset {
                return path0.finalAsset < path1.finalAsset
            }
            // finalAsset이 같으면 소진 연도로 2차 정렬 (빨리 소진 = 더 나쁨 = 앞에 위치)
            let dep0 = path0.depletionYear ?? Int.max
            let dep1 = path1.depletionYear ?? Int.max
            return dep0 < dep1
        }
        
        let veryWorstPath = sortedByFinal[simulationCount * 10 / 100]
        let unluckyPath = sortedByFinal[simulationCount * 30 / 100]
        let medianPath = sortedByFinal[simulationCount * 50 / 100]
        let luckyPath = sortedByFinal[simulationCount * 70 / 100]
        let veryBestPath = sortedByFinal[simulationCount * 90 / 100]
        
        // === 단기 (10년) 기준 정렬 ===
        // 10년 후 자산 기준으로 오름차순 정렬
        // 2차 정렬: 자산이 같으면 소진 연도로 정렬
        let sortedBy10Years = allPaths.sorted { path0, path1 in
            if path0.assetAt10Years != path1.assetAt10Years {
                return path0.assetAt10Years < path1.assetAt10Years
            }
            let dep0 = path0.depletionYear ?? Int.max
            let dep1 = path1.depletionYear ?? Int.max
            return dep0 < dep1
        }
        
        let shortTermVeryWorstPath = sortedBy10Years[simulationCount * 10 / 100]
        let shortTermUnluckyPath = sortedBy10Years[simulationCount * 30 / 100]
        let shortTermMedianPath = sortedBy10Years[simulationCount * 50 / 100]
        let shortTermLuckyPath = sortedBy10Years[simulationCount * 70 / 100]
        let shortTermVeryBestPath = sortedBy10Years[simulationCount * 90 / 100]
        
        return RetirementSimulationResult(
            veryBestPath: veryBestPath,
            luckyPath: luckyPath,
            medianPath: medianPath,
            unluckyPath: unluckyPath,
            veryWorstPath: veryWorstPath,
            shortTermVeryBestPath: shortTermVeryBestPath,
            shortTermLuckyPath: shortTermLuckyPath,
            shortTermMedianPath: shortTermMedianPath,
            shortTermUnluckyPath: shortTermUnluckyPath,
            shortTermVeryWorstPath: shortTermVeryWorstPath,
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
    
    // MARK: - UserProfile-based Simulation
    
    /// UserProfile 기반 시뮬레이션 (편의 메서드)
    nonisolated static func simulate(
        profile: UserProfile,
        volatility: Double = 15.0,
        simulationCount: Int = 30_000,
        progressCallback: ProgressCallback? = nil
    ) -> RetirementSimulationResult {
        
        // 목표 자산 계산
        let targetAsset = RetirementCalculator.calculateTargetAssets(
            desiredMonthlyIncome: profile.desiredMonthlyIncome,
            postRetirementReturnRate: profile.postRetirementReturnRate,
            inflationRate: profile.inflationRate
        )
        
        return simulate(
            initialAsset: targetAsset,
            monthlySpending: profile.desiredMonthlyIncome,
            annualReturn: profile.postRetirementReturnRate,
            volatility: volatility,
            simulationCount: simulationCount,
            progressCallback: progressCallback
        )
    }
}
