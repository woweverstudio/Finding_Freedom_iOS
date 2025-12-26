//
//  PortfolioMonteCarlo.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  포트폴리오 전용 몬테카를로 시뮬레이션
//

import Foundation

// MARK: - 포트폴리오 예측 결과

/// 포트폴리오 미래 예측 결과 (5년, 1억 기준)
struct PortfolioProjectionResult {
    /// 시작 금액 (1억 = 100,000,000)
    let initialAmount: Double
    
    /// 월별 최고 시나리오 (상위 20%) - 차트용
    let monthlyBestCase: [Double]
    
    /// 월별 중앙값 (50%) - 차트용
    let monthlyMedian: [Double]
    
    /// 월별 최악 시나리오 (하위 20%) - 차트용
    let monthlyWorstCase: [Double]
    
    /// 연도별 최고 시나리오 (상위 20%) - 테이블용
    let bestCase: [Double]
    
    /// 연도별 중앙값 (50%) - 테이블용
    let median: [Double]
    
    /// 연도별 최악 시나리오 (하위 20%) - 테이블용
    let worstCase: [Double]
    
    /// 시뮬레이션 횟수
    let totalSimulations: Int
    
    /// 총 연수
    var totalYears: Int {
        median.count - 1
    }
    
    /// 총 개월수
    var totalMonths: Int {
        monthlyMedian.count - 1
    }
    
    /// 최종 수익률 범위 (퍼센트)
    var finalReturnRange: (best: Double, median: Double, worst: Double) {
        let best = (bestCase.last ?? initialAmount) / initialAmount - 1.0
        let med = (median.last ?? initialAmount) / initialAmount - 1.0
        let worst = (worstCase.last ?? initialAmount) / initialAmount - 1.0
        return (best, med, worst)
    }
}

// MARK: - 포트폴리오 몬테카를로 시뮬레이터

/// 포트폴리오 전용 몬테카를로 시뮬레이터
enum PortfolioMonteCarlo {
    
    /// 기본 시작 금액 (1억)
    static let defaultInitialAmount: Double = 100_000_000
    
    // MARK: - 포트폴리오 미래 예측
    
    /// 포트폴리오 미래 예측 시뮬레이션 (월별 + 연도별, 1억 기준)
    /// - Parameters:
    ///   - cagr: 연평균 기대 수익률 (0.10 = 10%)
    ///   - volatility: 연간 변동성 (0.20 = 20%)
    ///   - years: 예측 기간 (기본 5년)
    ///   - initialAmount: 시작 금액 (기본 1억)
    ///   - simulationCount: 시뮬레이션 횟수 (기본 5000회)
    /// - Returns: 포트폴리오 예측 결과
    static func projectPortfolio(
        cagr: Double,
        volatility: Double,
        years: Int = 5,
        initialAmount: Double = defaultInitialAmount,
        simulationCount: Int = 5000
    ) -> PortfolioProjectionResult {
        
        let totalMonths = years * 12
        
        // 월별 파라미터 계산
        let monthlyMean = log(1 + cagr) / 12.0 - 0.5 * (volatility * volatility) / 12.0
        let monthlyVolatility = volatility / sqrt(12.0)
        
        // 월별 모든 시뮬레이션 결과 저장
        var monthlyResults: [[Double]] = Array(repeating: [], count: totalMonths + 1)
        monthlyResults[0] = Array(repeating: initialAmount, count: simulationCount)
        
        for _ in 0..<simulationCount {
            var currentValue = initialAmount
            
            for month in 1...totalMonths {
                let monthlyReturn = sampleNormalDistribution(
                    mean: monthlyMean,
                    standardDeviation: monthlyVolatility
                )
                currentValue *= exp(monthlyReturn)
                monthlyResults[month].append(currentValue)
            }
        }
        
        // 월별 percentile 계산 (차트용)
        var monthlyBestCase: [Double] = [initialAmount]
        var monthlyMedian: [Double] = [initialAmount]
        var monthlyWorstCase: [Double] = [initialAmount]
        
        for month in 1...totalMonths {
            let valuesAtMonth = monthlyResults[month].sorted()
            
            let p20Index = Int(Double(valuesAtMonth.count) * 0.2)
            let p50Index = valuesAtMonth.count / 2
            let p80Index = Int(Double(valuesAtMonth.count) * 0.8)
            
            monthlyWorstCase.append(valuesAtMonth[p20Index])
            monthlyMedian.append(valuesAtMonth[p50Index])
            monthlyBestCase.append(valuesAtMonth[min(p80Index, valuesAtMonth.count - 1)])
        }
        
        // 연도별 데이터 추출 (테이블용) - 12개월마다
        var bestCase: [Double] = [initialAmount]
        var median: [Double] = [initialAmount]
        var worstCase: [Double] = [initialAmount]
        
        for year in 1...years {
            let monthIndex = year * 12
            bestCase.append(monthlyBestCase[monthIndex])
            median.append(monthlyMedian[monthIndex])
            worstCase.append(monthlyWorstCase[monthIndex])
        }
        
        return PortfolioProjectionResult(
            initialAmount: initialAmount,
            monthlyBestCase: monthlyBestCase,
            monthlyMedian: monthlyMedian,
            monthlyWorstCase: monthlyWorstCase,
            bestCase: bestCase,
            median: median,
            worstCase: worstCase,
            totalSimulations: simulationCount
        )
    }
    
    // MARK: - Random Sampling
    
    /// 정규분포에서 샘플링 (Box-Muller 변환 사용)
    private static func sampleNormalDistribution(
        mean: Double,
        standardDeviation: Double
    ) -> Double {
        let u1 = Double.random(in: 0..<1)
        let u2 = Double.random(in: 0..<1)
        
        let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
        
        return mean + z0 * standardDeviation
    }
}

// MARK: - 포트폴리오 과거 성과 데이터

/// 종목별 과거 성과 데이터 (월별)
struct StockHistoricalPerformance: Identifiable {
    var id: String { ticker }
    let ticker: String
    let name: String
    let dates: [Date]           // 월별 날짜
    let values: [Double]        // 월별 가치 (시작 = 1.0)
    
    var totalReturn: Double {
        (values.last ?? 1.0) - 1.0
    }
}

/// 포트폴리오 과거 성과 데이터 (월별)
struct PortfolioHistoricalData {
    /// 월별 날짜
    let dates: [Date]
    
    /// 연도 레이블 (X축용)
    let yearLabels: [String]
    
    /// 월별 포트폴리오 가치 (시작 = 1.0)
    let values: [Double]
    
    /// 종목별 과거 성과 데이터
    let stockPerformances: [StockHistoricalPerformance]
    
    /// 총 수익률
    var totalReturn: Double {
        (values.last ?? 1.0) - 1.0
    }
    
    /// CAGR
    var cagr: Double {
        guard dates.count > 1 else { return 0 }
        let years = Double(dates.count - 1) / 12.0
        guard years > 0 else { return 0 }
        return pow(values.last ?? 1.0, 1.0 / years) - 1
    }
    
    init(dates: [Date] = [], yearLabels: [String] = [], values: [Double] = [], stockPerformances: [StockHistoricalPerformance] = []) {
        self.dates = dates
        self.yearLabels = yearLabels
        self.values = values
        self.stockPerformances = stockPerformances
    }
}

// MARK: - 과거 성과 계산

extension PortfolioMonteCarlo {
    
    /// 포트폴리오 과거 성과 계산 (월별 데이터, 종목별 성과 포함)
    static func calculateHistoricalPerformance(
        holdings: [(ticker: String, weight: Double)],
        stocksData: [StockAnalysisData]
    ) -> PortfolioHistoricalData {
        
        guard !holdings.isEmpty else {
            return PortfolioHistoricalData()
        }
        
        // 모든 종목에서 공통 날짜 범위 찾기
        let allDates = stocksData.flatMap { $0.dailyPrices.map { $0.date } }
        guard let minDate = allDates.min(), let maxDate = allDates.max() else {
            return PortfolioHistoricalData()
        }
        
        // 월별 날짜 생성 (매월 말일 기준)
        var monthlyDates: [Date] = []
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        
        var currentDate = minDate
        while currentDate <= maxDate {
            if let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: calendar.startOfDay(for: currentDate)) {
                let targetDate = min(endOfMonth, maxDate)
                if monthlyDates.isEmpty || !calendar.isDate(targetDate, inSameDayAs: monthlyDates.last!) {
                    monthlyDates.append(targetDate)
                }
            }
            
            if let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDate) {
                currentDate = calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth)) ?? nextMonth
            } else {
                break
            }
        }
        
        // 연도 레이블 생성
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        var yearLabels: [String] = []
        var lastYear = ""
        for date in monthlyDates {
            let year = formatter.string(from: date)
            if year != lastYear {
                yearLabels.append(year)
                lastYear = year
            }
        }
        
        // 종목별 월별 성과 계산 (배당 포함)
        var stockPerformances: [StockHistoricalPerformance] = []
        
        for holding in holdings {
            guard let stock = stocksData.first(where: { $0.info.ticker == holding.ticker }),
                  !stock.dailyPrices.isEmpty else {
                continue
            }
            
            var priceByDate: [Date: Double] = [:]
            for price in stock.dailyPrices {
                let dayStart = calendar.startOfDay(for: price.date)
                priceByDate[dayStart] = price.close
            }
            
            guard let stockMinDate = stock.dailyPrices.map({ $0.date }).min() else {
                continue
            }
            
            let annualDividendYield = stock.dividendHistory.dividendYield
            let monthlyDividendYield = annualDividendYield / 12.0
            
            var stockMonthlyDates: [Date] = []
            var stockMonthlyPrices: [Double] = []
            
            for monthDate in monthlyDates {
                var closestPrice: Double?
                var checkDate = monthDate
                
                for _ in 0..<10 {
                    let dayStart = calendar.startOfDay(for: checkDate)
                    if let price = priceByDate[dayStart] {
                        closestPrice = price
                        break
                    }
                    if let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) {
                        checkDate = prevDay
                    } else {
                        break
                    }
                }
                
                if let price = closestPrice, monthDate >= stockMinDate {
                    stockMonthlyDates.append(monthDate)
                    stockMonthlyPrices.append(price)
                }
            }
            
            guard let firstMonthlyPrice = stockMonthlyPrices.first, firstMonthlyPrice > 0 else {
                continue
            }
            
            var stockMonthlyValues: [Double] = []
            for (monthIndex, price) in stockMonthlyPrices.enumerated() {
                let priceReturn = price / firstMonthlyPrice
                let cumulativeDividendMultiplier = pow(1 + monthlyDividendYield, Double(monthIndex))
                let totalReturn = priceReturn * cumulativeDividendMultiplier
                stockMonthlyValues.append(totalReturn)
            }
            
            if !stockMonthlyDates.isEmpty {
                stockPerformances.append(StockHistoricalPerformance(
                    ticker: stock.info.ticker,
                    name: stock.info.displayName,
                    dates: stockMonthlyDates,
                    values: stockMonthlyValues
                ))
            }
        }
        
        // 포트폴리오 전체 월별 가중 성과 계산
        var portfolioValues: [Double] = []
        
        for (_, monthDate) in monthlyDates.enumerated() {
            var weightedValue = 0.0
            var totalWeight = 0.0
            
            for holding in holdings {
                if let stockPerf = stockPerformances.first(where: { $0.ticker == holding.ticker }),
                   let dateIndex = stockPerf.dates.firstIndex(where: { calendar.isDate($0, inSameDayAs: monthDate) }) {
                    weightedValue += stockPerf.values[dateIndex] * holding.weight
                    totalWeight += holding.weight
                }
            }
            
            if totalWeight > 0 {
                portfolioValues.append(weightedValue / totalWeight)
            } else if !portfolioValues.isEmpty {
                portfolioValues.append(portfolioValues.last ?? 1.0)
            }
        }
        
        // 포트폴리오 값 정규화 (시작 = 1.0)
        if let firstValue = portfolioValues.first, firstValue > 0 {
            portfolioValues = portfolioValues.map { $0 / firstValue }
        }
        
        return PortfolioHistoricalData(
            dates: monthlyDates,
            yearLabels: yearLabels,
            values: portfolioValues,
            stockPerformances: stockPerformances
        )
    }
}

