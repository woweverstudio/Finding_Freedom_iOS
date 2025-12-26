//
//  PortfolioMonteCarlo.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  포트폴리오 전용 몬테카를로 시뮬레이션
//

import Foundation

// MARK: - 포트폴리오 몬테카를로 시뮬레이터

/// 포트폴리오 전용 몬테카를로 시뮬레이터
enum PortfolioMonteCarlo {
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

