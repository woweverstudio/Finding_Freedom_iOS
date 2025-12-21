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
/// nonisolated로 선언하여 백그라운드 스레드에서도 호출 가능
enum MonteCarloSimulator {
    
    // MARK: - Main Simulation
    
    /// 진행률 콜백 타입
    typealias ProgressCallback = @Sendable (Int, [Int], [AssetPath]) -> Void
    
    /// 몬테카를로 시뮬레이션 실행
    /// - Parameters:
    ///   - initialAsset: 초기 자산 (원)
    ///   - monthlyInvestment: 월 투자 금액 (원)
    ///   - targetAsset: 목표 자산 (원)
    ///   - meanReturn: 평균 연 수익률 (%, 예: 6.5)
    ///   - volatility: 수익률 표준편차 (%, 예: 15)
    ///   - simulationCount: 시뮬레이션 횟수 (기본 30,000)
    ///   - maxMonths: 최대 개월 수 (기본 1200개월 = 100년)
    ///   - trackPaths: 자산 경로 추적 여부 (차트용)
    ///   - progressCallback: 진행률 콜백 (completed, successMonths, paths)
    /// - Returns: 시뮬레이션 결과
    nonisolated static func simulate(
        initialAsset: Double,
        monthlyInvestment: Double,
        targetAsset: Double,
        meanReturn: Double,
        volatility: Double,
        simulationCount: Int = 30_000,
        maxMonths: Int = 1200,
        trackPaths: Bool = true,
        progressCallback: ProgressCallback? = nil
    ) -> MonteCarloResult {
        
        var successMonths: [Int] = []
        var allPaths: [AssetPath] = []
        var failureCount = 0
        
        // 업데이트 간격 (200번마다 한 번씩 콜백 - 부드러운 애니메이션)
        let updateInterval = 200
        
        // 시뮬레이션 실행
        for i in 0..<simulationCount {
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
            
            // 진행률 콜백 (100번마다)
            if (i + 1) % updateInterval == 0 || i == simulationCount - 1 {
                progressCallback?(i + 1, successMonths, allPaths)
            }
        }
        
        let successRate = Double(successMonths.count) / Double(simulationCount)
        
        // 대표 경로 추출
        let representativePaths = trackPaths ? extractRepresentativePathsPublic(
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
    nonisolated private static func runSingleSimulation(
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
            
            // 자산이 0 이하로 떨어져도 월 저축으로 회복 가능하므로 최소 0으로 유지
            if currentAsset < 0 {
                currentAsset = 0
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
    nonisolated private static func sampleNormalDistribution(
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
    
    /// 대표 경로 추출 (공개 메서드)
    nonisolated static func extractRepresentativePathsPublic(
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
    
    // MARK: - UserProfile-based Simulation
    
    /// UserProfile 기반 시뮬레이션 (편의 메서드)
    /// - Parameters:
    ///   - profile: 사용자 프로필
    ///   - currentAsset: 현재 자산
    ///   - volatility: 변동성 (기본값 15%)
    ///   - simulationCount: 시뮬레이션 횟수
    ///   - trackPaths: 자산 경로 추적 여부
    ///   - progressCallback: 진행률 콜백
    /// - Returns: 시뮬레이션 결과
    nonisolated static func simulate(
        profile: UserProfile,
        currentAsset: Double,
        volatility: Double = 15.0,
        simulationCount: Int = 30_000,
        trackPaths: Bool = true,
        progressCallback: ProgressCallback? = nil
    ) -> MonteCarloResult {
        // 목표 자산 계산
        let targetAsset = RetirementCalculator.calculateTargetAssets(
            desiredMonthlyIncome: profile.desiredMonthlyIncome,
            postRetirementReturnRate: profile.postRetirementReturnRate
        )
        
        return simulate(
            initialAsset: currentAsset,
            monthlyInvestment: profile.monthlyInvestment,
            targetAsset: targetAsset,
            meanReturn: profile.preRetirementReturnRate,
            volatility: volatility,
            simulationCount: simulationCount,
            trackPaths: trackPaths,
            progressCallback: progressCallback
        )
    }
}

// MARK: - Portfolio Projection

/// 포트폴리오 미래 예측 결과 (10년)
struct PortfolioProjectionResult {
    /// 시작 자산 (현재 가치를 1.0으로 정규화)
    let initialValue: Double
    
    /// 월별 최고 시나리오 (상위 10%)
    let bestCase: [Double]
    
    /// 월별 중앙값 (50%)
    let median: [Double]
    
    /// 월별 최악 시나리오 (하위 10%)
    let worstCase: [Double]
    
    /// 시뮬레이션 횟수
    let totalSimulations: Int
    
    /// 총 개월 수
    var totalMonths: Int {
        median.count - 1
    }
    
    /// 최종 수익률 범위
    var finalReturnRange: (best: Double, median: Double, worst: Double) {
        let best = (bestCase.last ?? 1.0) - 1.0
        let med = (median.last ?? 1.0) - 1.0
        let worst = (worstCase.last ?? 1.0) - 1.0
        return (best, med, worst)
    }
}

/// 포트폴리오 과거 성과 데이터
struct PortfolioHistoricalData {
    /// 연도 레이블
    let years: [String]
    
    /// 연도별 포트폴리오 가치 (시작 = 1.0)
    let values: [Double]
    
    /// 총 수익률
    var totalReturn: Double {
        (values.last ?? 1.0) - 1.0
    }
    
    /// CAGR
    var cagr: Double {
        let years = Double(values.count - 1)
        guard years > 0 else { return 0 }
        return pow(values.last ?? 1.0, 1.0 / years) - 1
    }
}

extension MonteCarloSimulator {
    
    // MARK: - Portfolio Future Projection
    
    /// 포트폴리오 미래 10년 예측 시뮬레이션 (월별 샘플링으로 변동성 표현)
    /// - Parameters:
    ///   - cagr: 연평균 기대 수익률 (0.10 = 10%)
    ///   - volatility: 연간 변동성 (0.20 = 20%)
    ///   - years: 예측 기간 (기본 10년)
    ///   - simulationCount: 시뮬레이션 횟수 (기본 5000회)
    /// - Returns: 포트폴리오 예측 결과
    nonisolated static func projectPortfolio(
        cagr: Double,
        volatility: Double,
        years: Int = 10,
        simulationCount: Int = 5000
    ) -> PortfolioProjectionResult {
        
        let totalMonths = years * 12
        
        // 월별 파라미터 계산
        let monthlyMean = log(1 + cagr) / 12.0 - 0.5 * (volatility * volatility) / 12.0
        let monthlyVolatility = volatility / sqrt(12.0)
        
        // 모든 시뮬레이션 경로 저장 (월별)
        var allPaths: [[Double]] = []
        
        for _ in 0..<simulationCount {
            var path: [Double] = [1.0]  // 시작 = 1.0 (정규화)
            var currentValue = 1.0
            
            for _ in 0..<totalMonths {
                // 월별 로그 정규분포 (GBM)
                let monthlyReturn = sampleNormalDistribution(
                    mean: monthlyMean,
                    standardDeviation: monthlyVolatility
                )
                currentValue *= exp(monthlyReturn)
                path.append(currentValue)
            }
            
            allPaths.append(path)
        }
        
        // 월별로 percentile 계산 (60% 범위: 상위 20% ~ 하위 20%)
        var bestCase: [Double] = [1.0]
        var median: [Double] = [1.0]
        var worstCase: [Double] = [1.0]
        
        for month in 1...totalMonths {
            let valuesAtMonth = allPaths.map { $0[month] }.sorted()
            
            let p20Index = Int(Double(valuesAtMonth.count) * 0.2)
            let p50Index = valuesAtMonth.count / 2
            let p80Index = Int(Double(valuesAtMonth.count) * 0.8)
            
            // best = 상위 20% (80 percentile), worst = 하위 20% (20 percentile)
            worstCase.append(valuesAtMonth[p20Index])
            median.append(valuesAtMonth[p50Index])
            bestCase.append(valuesAtMonth[min(p80Index, valuesAtMonth.count - 1)])
        }
        
        return PortfolioProjectionResult(
            initialValue: 1.0,
            bestCase: bestCase,
            median: median,
            worstCase: worstCase,
            totalSimulations: simulationCount
        )
    }
    
    /// 포트폴리오 과거 성과 계산
    /// - Parameters:
    ///   - holdings: 보유 종목 비중
    ///   - stocksData: 종목별 데이터
    /// - Returns: 과거 성과 데이터
    static func calculateHistoricalPerformance(
        holdings: [(ticker: String, weight: Double)],
        stocksData: [StockWithData]
    ) -> PortfolioHistoricalData {
        
        guard !holdings.isEmpty else {
            return PortfolioHistoricalData(years: [], values: [])
        }
        
        // 가장 긴 연도 수 찾기 (보통 5년)
        let maxYears = stocksData.map { $0.priceHistory.annualReturns.count }.max() ?? 5
        
        // 연도별 포트폴리오 가중 수익률 계산
        var portfolioValues: [Double] = [1.0]  // 시작 = 1.0
        var currentValue = 1.0
        
        for yearIndex in 0..<maxYears {
            var weightedReturn = 0.0
            var totalWeight = 0.0
            
            for holding in holdings {
                guard let stock = stocksData.first(where: { $0.info.ticker == holding.ticker }),
                      yearIndex < stock.priceHistory.annualReturns.count else {
                    continue
                }
                
                let yearlyReturn = stock.priceHistory.annualReturns[yearIndex]
                // 배당 수익률도 연간 수익에 추가
                let dividendContribution = stock.dividendHistory.dividendYield
                
                weightedReturn += (yearlyReturn + dividendContribution) * holding.weight
                totalWeight += holding.weight
            }
            
            if totalWeight > 0 {
                let normalizedReturn = weightedReturn / totalWeight
                currentValue *= (1 + normalizedReturn)
            }
            
            portfolioValues.append(currentValue)
        }
        
        // 연도 레이블 생성 (현재 기준 과거)
        let currentYear = Calendar.current.component(.year, from: Date())
        var years: [String] = []
        for i in 0...maxYears {
            years.append("\(currentYear - maxYears + i)")
        }
        
        return PortfolioHistoricalData(
            years: years,
            values: portfolioValues
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

