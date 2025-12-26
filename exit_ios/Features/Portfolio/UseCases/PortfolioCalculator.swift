//
//  PortfolioCalculator.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  포트폴리오 지표 계산 엔진 - 상관계수, 변동성, MDD, CAGR 등 순수 계산 로직
//

import Foundation

/// 포트폴리오 계산기 (순수 계산 로직)
enum PortfolioCalculator {
    
    // MARK: - Correlation Matrix
    
    /// 종목 간 상관계수 행렬 계산
    /// - Parameter stocksData: 종목별 분석 데이터
    /// - Returns: 상관계수 행렬 (n x n)
    static func calculateCorrelationMatrix(stocksData: [StockAnalysisData]) -> [[Double]] {
        let n = stocksData.count
        guard n > 0 else { return [] }
        
        // 공통 기간의 일별 수익률 추출
        let alignedReturns = alignDailyReturns(stocksData: stocksData)
        
        // 상관계수 행렬 초기화
        var matrix = Array(repeating: Array(repeating: 0.0, count: n), count: n)
        
        for i in 0..<n {
            for j in 0..<n {
                if i == j {
                    matrix[i][j] = 1.0  // 자기 자신과의 상관계수는 1
                } else if i < j {
                    let correlation = calculateCorrelation(
                        returns1: alignedReturns[i],
                        returns2: alignedReturns[j]
                    )
                    matrix[i][j] = correlation
                    matrix[j][i] = correlation  // 대칭
                }
            }
        }
        
        return matrix
    }
    
    /// 두 수익률 시리즈의 상관계수 계산
    private static func calculateCorrelation(returns1: [Double], returns2: [Double]) -> Double {
        guard returns1.count == returns2.count, !returns1.isEmpty else { return 0 }
        
        let n = Double(returns1.count)
        let mean1 = returns1.reduce(0, +) / n
        let mean2 = returns2.reduce(0, +) / n
        
        var covariance = 0.0
        var variance1 = 0.0
        var variance2 = 0.0
        
        for i in 0..<returns1.count {
            let diff1 = returns1[i] - mean1
            let diff2 = returns2[i] - mean2
            covariance += diff1 * diff2
            variance1 += diff1 * diff1
            variance2 += diff2 * diff2
        }
        
        let denominator = sqrt(variance1 * variance2)
        guard denominator > 0 else { return 0 }
        
        return covariance / denominator
    }
    
    /// 종목들의 일별 수익률을 공통 기간으로 정렬
    private static func alignDailyReturns(stocksData: [StockAnalysisData]) -> [[Double]] {
        guard !stocksData.isEmpty else { return [] }
        
        // 모든 종목의 날짜 집합
        var commonDates: Set<Date> = Set(stocksData[0].dailyPrices.map { $0.date })
        for stock in stocksData.dropFirst() {
            let dates = Set(stock.dailyPrices.map { $0.date })
            commonDates = commonDates.intersection(dates)
        }
        
        let sortedDates = commonDates.sorted()
        
        // 각 종목의 정렬된 수익률 계산
        return stocksData.map { stock in
            let priceMap = Dictionary(uniqueKeysWithValues: stock.dailyPrices.map { ($0.date, $0.close) })
            var returns: [Double] = []
            
            for i in 1..<sortedDates.count {
                let prevDate = sortedDates[i - 1]
                let currDate = sortedDates[i]
                
                if let prevPrice = priceMap[prevDate], let currPrice = priceMap[currDate], prevPrice > 0 {
                    returns.append((currPrice - prevPrice) / prevPrice)
                }
            }
            
            return returns
        }
    }
    
    // MARK: - Portfolio Volatility
    
    /// 포트폴리오 변동성 계산 (상관계수 반영)
    /// σp = √(Σ wi²σi² + ΣΣ wiwjσiσjρij)
    static func calculatePortfolioVolatility(
        holdings: [(ticker: String, weight: Double)],
        stocksData: [StockAnalysisData],
        correlationMatrix: [[Double]]
    ) -> Double {
        let n = stocksData.count
        guard n > 0, correlationMatrix.count == n else { return 0 }
        
        // stocksData 순서에 맞춰 비중과 변동성 배열 구성
        // (상관계수 행렬이 stocksData 순서로 생성되므로 동일 순서 사용)
        var weights: [Double] = Array(repeating: 0.0, count: n)
        var volatilities: [Double] = Array(repeating: 0.0, count: n)
        
        for (index, stock) in stocksData.enumerated() {
            if let holding = holdings.first(where: { $0.ticker == stock.info.ticker }) {
                weights[index] = holding.weight
                volatilities[index] = stock.annualVolatility
            }
        }
        
        // 포트폴리오 분산 계산
        var portfolioVariance = 0.0
        
        for i in 0..<n {
            for j in 0..<n {
                let wi = weights[i]
                let wj = weights[j]
                let sigmaI = volatilities[i]
                let sigmaJ = volatilities[j]
                let rhoIJ = correlationMatrix[i][j]
                
                portfolioVariance += wi * wj * sigmaI * sigmaJ * rhoIJ
            }
        }
        
        return sqrt(max(0, portfolioVariance))
    }
    
    // MARK: - Portfolio MDD
    
    /// 포트폴리오 실제 MDD 계산 (일별 포트폴리오 가치 기반)
    static func calculatePortfolioMDD(
        holdings: [(ticker: String, weight: Double)],
        stocksData: [StockAnalysisData]
    ) -> Double {
        // 포트폴리오 일별 가치 계산
        let portfolioValues = calculatePortfolioDailyValues(holdings: holdings, stocksData: stocksData)
        
        guard !portfolioValues.isEmpty else { return 0 }
        
        // MDD 계산
        var peak = portfolioValues[0]
        var maxDrawdown = 0.0
        
        for value in portfolioValues {
            if value > peak {
                peak = value
            }
            let drawdown = (value - peak) / peak
            if drawdown < maxDrawdown {
                maxDrawdown = drawdown
            }
        }
        
        return maxDrawdown
    }
    
    /// 포트폴리오 일별 가치 시리즈 계산
    static func calculatePortfolioDailyValues(
        holdings: [(ticker: String, weight: Double)],
        stocksData: [StockAnalysisData]
    ) -> [Double] {
        guard !holdings.isEmpty, !stocksData.isEmpty else { return [] }
        
        // 모든 종목의 공통 날짜 찾기
        var commonDates: Set<Date> = Set(stocksData[0].dailyPrices.map { $0.date })
        for stock in stocksData.dropFirst() {
            let dates = Set(stock.dailyPrices.map { $0.date })
            commonDates = commonDates.intersection(dates)
        }
        
        let sortedDates = commonDates.sorted()
        guard !sortedDates.isEmpty else { return [] }
        
        // 각 종목의 가격 맵
        var priceMaps: [String: [Date: Double]] = [:]
        for stock in stocksData {
            priceMaps[stock.info.ticker] = Dictionary(uniqueKeysWithValues: stock.dailyPrices.map { ($0.date, $0.close) })
        }
        
        // 각 종목의 첫날 가격 기준 정규화된 비중
        var initialNormalizedWeights: [String: Double] = [:]
        let firstDate = sortedDates[0]
        
        for holding in holdings {
            guard let priceMap = priceMaps[holding.ticker],
                  let firstPrice = priceMap[firstDate], firstPrice > 0 else { continue }
            // 비중 * (1 / 첫날가격) = 각 종목당 보유 "단위" 수
            initialNormalizedWeights[holding.ticker] = holding.weight / firstPrice
        }
        
        // 일별 포트폴리오 가치 계산
        var portfolioValues: [Double] = []
        
        for date in sortedDates {
            var dailyValue = 0.0
            
            for (ticker, units) in initialNormalizedWeights {
                if let priceMap = priceMaps[ticker], let price = priceMap[date] {
                    dailyValue += units * price
                }
            }
            
            portfolioValues.append(dailyValue)
        }
        
        return portfolioValues
    }
    
    // MARK: - Portfolio CAGR
    
    /// 포트폴리오 실제 CAGR 계산 (일별 포트폴리오 가치 기반)
    static func calculatePortfolioCAGR(
        holdings: [(ticker: String, weight: Double)],
        stocksData: [StockAnalysisData]
    ) -> Double {
        let portfolioValues = calculatePortfolioDailyValues(holdings: holdings, stocksData: stocksData)
        
        guard let firstValue = portfolioValues.first,
              let lastValue = portfolioValues.last,
              firstValue > 0 else { return 0 }
        
        // 거래일 수로 연수 계산 (약 252 거래일/년)
        let tradingDays = Double(portfolioValues.count)
        let years = tradingDays / 252.0
        
        guard years > 0 else { return 0 }
        
        // CAGR = (최종가치/초기가치)^(1/년수) - 1
        return pow(lastValue / firstValue, 1.0 / years) - 1
    }
    
    /// 포트폴리오 배당 포함 CAGR 계산
    static func calculatePortfolioCAGRWithDividends(
        holdings: [(ticker: String, weight: Double)],
        stocksData: [StockAnalysisData]
    ) -> Double {
        let priceCAGR = calculatePortfolioCAGR(holdings: holdings, stocksData: stocksData)
        
        // 가중 평균 배당률 계산
        var weightedDividendYield = 0.0
        var totalWeight = 0.0
        
        for holding in holdings {
            if let stock = stocksData.first(where: { $0.info.ticker == holding.ticker }) {
                weightedDividendYield += stock.dividendHistory.dividendYield * holding.weight
                totalWeight += holding.weight
            }
        }
        
        let avgDividendYield = totalWeight > 0 ? weightedDividendYield / totalWeight : 0
        
        // 배당 재투자 가정 간소화: CAGR에 평균 배당률 추가
        return priceCAGR + avgDividendYield
    }
    
    // MARK: - Total Return
    
    /// 포트폴리오 총 수익률 계산
    static func calculateTotalReturn(
        holdings: [(ticker: String, weight: Double)],
        stocksData: [StockAnalysisData]
    ) -> (total: Double, price: Double, dividend: Double) {
        let portfolioValues = calculatePortfolioDailyValues(holdings: holdings, stocksData: stocksData)
        
        guard let firstValue = portfolioValues.first,
              let lastValue = portfolioValues.last,
              firstValue > 0 else { return (0, 0, 0) }
        
        let priceReturn = (lastValue - firstValue) / firstValue
        
        // 배당 수익률 계산 (가중 평균 × 년수)
        let tradingDays = Double(portfolioValues.count)
        let years = tradingDays / 252.0
        
        var weightedDividendYield = 0.0
        var totalWeight = 0.0
        
        for holding in holdings {
            if let stock = stocksData.first(where: { $0.info.ticker == holding.ticker }) {
                weightedDividendYield += stock.dividendHistory.dividendYield * holding.weight
                totalWeight += holding.weight
            }
        }
        
        let avgDividendYield = totalWeight > 0 ? weightedDividendYield / totalWeight : 0
        let dividendReturn = avgDividendYield * years
        
        return (priceReturn + dividendReturn, priceReturn, dividendReturn)
    }
    
    // MARK: - Sharpe Ratio
    
    /// Sharpe Ratio 계산
    static func calculateSharpeRatio(
        portfolioReturn: Double,
        volatility: Double,
        riskFreeRate: Double = 0.035
    ) -> Double {
        guard volatility > 0 else { return 0 }
        return (portfolioReturn - riskFreeRate) / volatility
    }
    
    // MARK: - Dividend Metrics
    
    /// 포트폴리오 배당 지표 계산
    static func calculateDividendMetrics(
        holdings: [(ticker: String, weight: Double)],
        stocksData: [StockAnalysisData]
    ) -> (yield: Double, growthRate: Double) {
        var weightedYield = 0.0
        var weightedGrowthRate = 0.0
        var totalWeight = 0.0
        var dividendStocksWeight = 0.0
        
        for holding in holdings {
            guard let stock = stocksData.first(where: { $0.info.ticker == holding.ticker }) else {
                continue
            }
            
            weightedYield += stock.dividendHistory.dividendYield * holding.weight
            
            if stock.dividendHistory.dividendYield > 0 {
                weightedGrowthRate += stock.dividendHistory.dividendGrowthRate * holding.weight
                dividendStocksWeight += holding.weight
            }
            
            totalWeight += holding.weight
        }
        
        guard totalWeight > 0 else { return (0, 0) }
        
        let avgYield = weightedYield / totalWeight
        let avgGrowthRate = dividendStocksWeight > 0 ? weightedGrowthRate / dividendStocksWeight : 0
        
        return (avgYield, avgGrowthRate)
    }
    
    // MARK: - Score Calculation
    
    /// 종합 점수 계산
    /// 기준: S&P 500 수준 포트폴리오가 약 75-80점(B등급)이 되도록 조정
    static func calculateScore(
        cagr: Double,
        volatility: Double,
        sharpeRatio: Double,
        mdd: Double
    ) -> PortfolioScore {
        // 수익성 점수 (40점 만점)
        // 기준 완화: S&P 500 장기 CAGR ~10%가 32점 정도 되도록
        let profitability: Int = {
            switch cagr {
            case 0.12...: return 40      // 12%+ (매우 우수)
            case 0.08..<0.12: return 32  // 8-12% (우수 - S&P 500 수준)
            case 0.05..<0.08: return 24  // 5-8% (양호)
            case 0.03..<0.05: return 16  // 3-5% (보통)
            case 0..<0.03: return 8      // 0-3% (저조)
            default: return 0            // 마이너스
            }
        }()
        
        // 안정성 점수 (30점 만점) = 변동성(15) + MDD(15)
        // 기준 완화: 주식 포트폴리오 현실 반영
        let volatilityScore: Int = {
            switch volatility {
            case 0..<0.18: return 15     // 18% 미만 (안정적)
            case 0.18..<0.25: return 12  // 18-25% (S&P 500 수준)
            case 0.25..<0.32: return 9   // 25-32% (다소 높음)
            case 0.32..<0.40: return 5   // 32-40% (높음)
            default: return 2            // 40%+ (매우 높음)
            }
        }()
        
        let mddScore: Int = {
            switch abs(mdd) {
            case 0..<0.20: return 15     // 20% 미만 (안정적)
            case 0.20..<0.30: return 12  // 20-30% (S&P 500 수준)
            case 0.30..<0.40: return 8   // 30-40% (다소 높음)
            case 0.40..<0.55: return 4   // 40-55% (높음)
            default: return 1            // 55%+ (매우 높음)
            }
        }()
        
        let stability = volatilityScore + mddScore
        
        // 효율성 점수 (30점 만점)
        // 기준 완화: Sharpe 0.8-1.0이 20점 정도 되도록
        let efficiency: Int = {
            switch sharpeRatio {
            case 1.2...: return 30       // 1.2+ (매우 우수)
            case 0.9..<1.2: return 25    // 0.9-1.2 (우수)
            case 0.7..<0.9: return 20    // 0.7-0.9 (양호 - S&P 500 수준)
            case 0.5..<0.7: return 15    // 0.5-0.7 (보통)
            case 0.3..<0.5: return 10    // 0.3-0.5 (저조)
            case 0..<0.3: return 5       // 0-0.3 (매우 저조)
            default: return 0            // 마이너스
            }
        }()
        
        let total = profitability + stability + efficiency
        
        return PortfolioScore(
            total: total,
            profitability: profitability,
            stability: stability,
            efficiency: efficiency
        )
    }
}

