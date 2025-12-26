//
//  PortfolioAnalyzer.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  포트폴리오 분석 엔진 - PortfolioCalculator를 활용한 종합 분석
//

import Foundation

/// 포트폴리오 분석기 (정적 메서드 - 순수 비즈니스 로직)
enum PortfolioAnalyzer {
    
    // MARK: - Main Analysis (New - StockAnalysisData 사용)
    
    /// 포트폴리오 전체 분석 (개선된 버전 - 상관계수 반영)
    /// - Parameters:
    ///   - holdings: 보유 종목 및 비중
    ///   - stocksData: 종목별 분석 데이터 (일별 가격 포함)
    ///   - riskFreeRate: 무위험 수익률 (기본 3.5%)
    /// - Returns: 분석 결과
    static func analyzeWithDailyData(
        holdings: [(ticker: String, weight: Double)],
        stocksData: [StockAnalysisData],
        riskFreeRate: Double = 0.035
    ) -> PortfolioAnalysisResult {
        
        // 빈 포트폴리오 처리
        guard !holdings.isEmpty, !stocksData.isEmpty else {
            return emptyResult
        }
        
        // 1. 상관계수 행렬 계산
        let correlationMatrix = PortfolioCalculator.calculateCorrelationMatrix(stocksData: stocksData)
        
        // 2. 포트폴리오 실제 CAGR 계산
        let cagr = PortfolioCalculator.calculatePortfolioCAGR(holdings: holdings, stocksData: stocksData)
        let cagrWithDividends = PortfolioCalculator.calculatePortfolioCAGRWithDividends(holdings: holdings, stocksData: stocksData)
        
        // 3. 총 수익률 계산
        let returns = PortfolioCalculator.calculateTotalReturn(holdings: holdings, stocksData: stocksData)
        
        // 4. 포트폴리오 변동성 계산 (상관계수 반영)
        let volatility = PortfolioCalculator.calculatePortfolioVolatility(
            holdings: holdings,
            stocksData: stocksData,
            correlationMatrix: correlationMatrix
        )
        
        // 5. 포트폴리오 실제 MDD 계산
        let mdd = PortfolioCalculator.calculatePortfolioMDD(holdings: holdings, stocksData: stocksData)
        
        // 6. Sharpe Ratio 계산
        let sharpeRatio = PortfolioCalculator.calculateSharpeRatio(
            portfolioReturn: cagrWithDividends,
            volatility: volatility,
            riskFreeRate: riskFreeRate
        )
        
        // 7. 배당 지표 계산
        let dividendMetrics = PortfolioCalculator.calculateDividendMetrics(holdings: holdings, stocksData: stocksData)
        
        // 8. 점수 계산
        let score = PortfolioCalculator.calculateScore(
            cagr: cagr,
            volatility: volatility,
            sharpeRatio: sharpeRatio,
            mdd: mdd
        )
        
        return PortfolioAnalysisResult(
            cagr: cagr,
            cagrWithDividends: cagrWithDividends,
            totalReturn: returns.total,
            priceReturn: returns.price,
            dividendReturn: returns.dividend,
            volatility: volatility,
            sharpeRatio: sharpeRatio,
            mdd: mdd,
            dividendYield: dividendMetrics.yield,
            dividendGrowthRate: dividendMetrics.growthRate,
            score: score
        )
    }
    
    // MARK: - Legacy Analysis (StockWithData 호환성 유지)
    
    /// 포트폴리오 전체 분석 (기존 호환성 유지)
    /// - Parameters:
    ///   - holdings: 보유 종목 및 비중
    ///   - stocksData: 종목별 전체 데이터
    ///   - riskFreeRate: 무위험 수익률 (기본 3.5%)
    /// - Returns: 분석 결과
    static func analyze(
        holdings: [(ticker: String, weight: Double)],
        stocksData: [StockWithData],
        riskFreeRate: Double = 0.035
    ) -> PortfolioAnalysisResult {
        
        // 빈 포트폴리오 처리
        guard !holdings.isEmpty, !stocksData.isEmpty else {
            return emptyResult
        }
        
        // 1. 포트폴리오 가중 평균 수익률 계산
        let (cagr, cagrWithDividends) = calculateWeightedCAGR(
            holdings: holdings,
            stocksData: stocksData
        )
        
        // 2. 총 수익률 계산
        let (totalReturn, priceReturn, dividendReturn) = calculateTotalReturns(
            holdings: holdings,
            stocksData: stocksData
        )
        
        // 3. 위험 지표 계산
        let volatility = calculateWeightedVolatility(
            holdings: holdings,
            stocksData: stocksData
        )
        
        let mdd = calculateWeightedMDD(
            holdings: holdings,
            stocksData: stocksData
        )
        
        // 4. Sharpe Ratio 계산
        let sharpeRatio = PortfolioCalculator.calculateSharpeRatio(
            portfolioReturn: cagrWithDividends,
            volatility: volatility,
            riskFreeRate: riskFreeRate
        )
        
        // 5. 배당 지표 계산
        let (dividendYield, dividendGrowthRate) = calculateDividendMetrics(
            holdings: holdings,
            stocksData: stocksData
        )
        
        // 6. 점수 계산
        let score = PortfolioCalculator.calculateScore(
            cagr: cagr,
            volatility: volatility,
            sharpeRatio: sharpeRatio,
            mdd: mdd
        )
        
        return PortfolioAnalysisResult(
            cagr: cagr,
            cagrWithDividends: cagrWithDividends,
            totalReturn: totalReturn,
            priceReturn: priceReturn,
            dividendReturn: dividendReturn,
            volatility: volatility,
            sharpeRatio: sharpeRatio,
            mdd: mdd,
            dividendYield: dividendYield,
            dividendGrowthRate: dividendGrowthRate,
            score: score
        )
    }
    
    // MARK: - Legacy CAGR Calculation
    
    /// 가중 평균 CAGR 계산 (Legacy)
    private static func calculateWeightedCAGR(
        holdings: [(ticker: String, weight: Double)],
        stocksData: [StockWithData]
    ) -> (cagr: Double, cagrWithDividends: Double) {
        
        var weightedCagr: Double = 0
        var weightedCagrWithDiv: Double = 0
        var totalWeight: Double = 0
        
        for holding in holdings {
            guard let stock = stocksData.first(where: { $0.info.ticker == holding.ticker }) else {
                continue
            }
            
            weightedCagr += stock.priceHistory.cagr * holding.weight
            weightedCagrWithDiv += stock.cagrWithDividends * holding.weight
            totalWeight += holding.weight
        }
        
        guard totalWeight > 0 else { return (0, 0) }
        
        return (weightedCagr / totalWeight, weightedCagrWithDiv / totalWeight)
    }
    
    // MARK: - Legacy Total Return Calculation
    
    /// 총 수익률 계산 (Legacy)
    private static func calculateTotalReturns(
        holdings: [(ticker: String, weight: Double)],
        stocksData: [StockWithData]
    ) -> (total: Double, price: Double, dividend: Double) {
        
        var weightedPriceReturn: Double = 0
        var weightedDividendReturn: Double = 0
        var totalWeight: Double = 0
        
        for holding in holdings {
            guard let stock = stocksData.first(where: { $0.info.ticker == holding.ticker }) else {
                continue
            }
            
            let priceReturn = stock.priceHistory.totalPriceReturn
            let years = Double(stock.priceHistory.annualReturns.count)
            let dividendReturn = stock.dividendHistory.dividendYield * years
            
            weightedPriceReturn += priceReturn * holding.weight
            weightedDividendReturn += dividendReturn * holding.weight
            totalWeight += holding.weight
        }
        
        guard totalWeight > 0 else { return (0, 0, 0) }
        
        let normalizedPriceReturn = weightedPriceReturn / totalWeight
        let normalizedDividendReturn = weightedDividendReturn / totalWeight
        
        return (
            normalizedPriceReturn + normalizedDividendReturn,
            normalizedPriceReturn,
            normalizedDividendReturn
        )
    }
    
    // MARK: - Legacy Volatility Calculation
    
    /// 가중 평균 변동성 계산 (Legacy)
    private static func calculateWeightedVolatility(
        holdings: [(ticker: String, weight: Double)],
        stocksData: [StockWithData]
    ) -> Double {
        
        var weightedVolatility: Double = 0
        var totalWeight: Double = 0
        
        for holding in holdings {
            guard let stock = stocksData.first(where: { $0.info.ticker == holding.ticker }) else {
                continue
            }
            
            weightedVolatility += stock.priceHistory.annualVolatility * holding.weight
            totalWeight += holding.weight
        }
        
        guard totalWeight > 0 else { return 0 }
        
        // 분산투자 효과 적용 (간소화: 종목 수에 따라 변동성 감소)
        let diversificationFactor = 1.0 - min(0.3, Double(holdings.count - 1) * 0.05)
        
        return (weightedVolatility / totalWeight) * diversificationFactor
    }
    
    // MARK: - Legacy MDD Calculation
    
    /// 가중 평균 MDD 계산 (Legacy)
    private static func calculateWeightedMDD(
        holdings: [(ticker: String, weight: Double)],
        stocksData: [StockWithData]
    ) -> Double {
        
        var weightedMDD: Double = 0
        var totalWeight: Double = 0
        
        for holding in holdings {
            guard let stock = stocksData.first(where: { $0.info.ticker == holding.ticker }) else {
                continue
            }
            
            weightedMDD += stock.priceHistory.maxDrawdown * holding.weight
            totalWeight += holding.weight
        }
        
        guard totalWeight > 0 else { return 0 }
        
        return weightedMDD / totalWeight
    }
    
    // MARK: - Legacy Dividend Metrics
    
    /// 배당 지표 계산 (Legacy)
    private static func calculateDividendMetrics(
        holdings: [(ticker: String, weight: Double)],
        stocksData: [StockWithData]
    ) -> (yield: Double, growthRate: Double) {
        
        var weightedYield: Double = 0
        var weightedGrowthRate: Double = 0
        var totalWeight: Double = 0
        var dividendStocksWeight: Double = 0
        
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
    
    // MARK: - Sector/Region Allocation
    
    /// 섹터별 배분 계산 (StockWithData 버전)
    static func calculateSectorAllocation(
        holdings: [(ticker: String, weight: Double)],
        stocksData: [StockWithData]
    ) -> [SectorAllocation] {
        
        var sectorWeights: [String: Double] = [:]
        
        for holding in holdings {
            guard let stock = stocksData.first(where: { $0.info.ticker == holding.ticker }) else {
                continue
            }
            
            let sector = stock.info.sector ?? "기타"
            sectorWeights[sector, default: 0] += holding.weight
        }
        
        return sectorWeights.map { sector, weight in
            let emoji = sectorEmoji(for: sector)
            return SectorAllocation(sector: sector, weight: weight, emoji: emoji)
        }.sorted { $0.weight > $1.weight }
    }
    
    /// 섹터별 배분 계산 (StockAnalysisData 버전)
    static func calculateSectorAllocation(
        holdings: [(ticker: String, weight: Double)],
        stocksData: [StockAnalysisData]
    ) -> [SectorAllocation] {
        
        var sectorWeights: [String: Double] = [:]
        
        for holding in holdings {
            guard let stock = stocksData.first(where: { $0.info.ticker == holding.ticker }) else {
                continue
            }
            
            let sector = stock.info.sector ?? "기타"
            sectorWeights[sector, default: 0] += holding.weight
        }
        
        return sectorWeights.map { sector, weight in
            let emoji = sectorEmoji(for: sector)
            return SectorAllocation(sector: sector, weight: weight, emoji: emoji)
        }.sorted { $0.weight > $1.weight }
    }
    
    /// 지역별 배분 계산 (현재 미국 주식만 지원)
    static func calculateRegionAllocation(
        holdings: [(ticker: String, weight: Double)],
        stocksData: [StockWithData]
    ) -> [RegionAllocation] {
        
        let totalWeight = holdings.reduce(0.0) { $0 + $1.weight }
        guard totalWeight > 0 else { return [] }
        
        return [RegionAllocation(region: "미국", flag: "🇺🇸", weight: totalWeight)]
    }
    
    /// 지역별 배분 계산 (StockAnalysisData 버전)
    static func calculateRegionAllocation(
        holdings: [(ticker: String, weight: Double)],
        stocksData: [StockAnalysisData]
    ) -> [RegionAllocation] {
        
        let totalWeight = holdings.reduce(0.0) { $0 + $1.weight }
        guard totalWeight > 0 else { return [] }
        
        return [RegionAllocation(region: "미국", flag: "🇺🇸", weight: totalWeight)]
    }
    
    // MARK: - Helpers
    
    private static func sectorEmoji(for sector: String) -> String {
        switch sector.lowercased() {
        case "technology": return "💻"
        case "etf": return "📊"
        case "energy": return "🔋"
        case "healthcare": return "🏥"
        case "finance", "financial": return "🏦"
        case "consumer": return "🛒"
        default: return "📈"
        }
    }
    
    // MARK: - Empty Result
    
    private static var emptyResult: PortfolioAnalysisResult {
        PortfolioAnalysisResult(
            cagr: 0,
            cagrWithDividends: 0,
            totalReturn: 0,
            priceReturn: 0,
            dividendReturn: 0,
            volatility: 0,
            sharpeRatio: 0,
            mdd: 0,
            dividendYield: 0,
            dividendGrowthRate: 0,
            score: PortfolioScore(total: 0, profitability: 0, stability: 0, efficiency: 0)
        )
    }
}
