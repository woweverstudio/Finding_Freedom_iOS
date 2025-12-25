//
//  PortfolioAnalyzer.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  포트폴리오 분석 엔진 - 로컬에서 모든 지표 계산
//

import Foundation

/// 포트폴리오 분석기 (정적 메서드 - 순수 비즈니스 로직)
enum PortfolioAnalyzer {
    
    // MARK: - Main Analysis
    
    /// 포트폴리오 전체 분석
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
        let sharpeRatio = calculateSharpeRatio(
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
        let score = calculateScore(
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
    
    // MARK: - CAGR Calculation
    
    /// 가중 평균 CAGR 계산
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
    
    // MARK: - Total Return Calculation
    
    /// 총 수익률 계산
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
    
    // MARK: - Volatility Calculation
    
    /// 가중 평균 변동성 계산
    /// 참고: 정확한 포트폴리오 변동성은 상관계수를 고려해야 하지만,
    /// 간소화를 위해 가중 평균 사용 (실제 구현 시 개선 필요)
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
    
    // MARK: - MDD Calculation
    
    /// 가중 평균 MDD 계산
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
    
    // MARK: - Sharpe Ratio Calculation
    
    /// Sharpe Ratio 계산
    static func calculateSharpeRatio(
        portfolioReturn: Double,
        volatility: Double,
        riskFreeRate: Double
    ) -> Double {
        guard volatility > 0 else { return 0 }
        return (portfolioReturn - riskFreeRate) / volatility
    }
    
    // MARK: - Dividend Metrics
    
    /// 배당 지표 계산
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
    
    // MARK: - Score Calculation
    
    /// 종합 점수 계산
    static func calculateScore(
        cagr: Double,
        volatility: Double,
        sharpeRatio: Double,
        mdd: Double
    ) -> PortfolioScore {
        
        // 수익성 점수 (40점 만점)
        let profitability: Int = {
            switch cagr {
            case 0.15...: return 40
            case 0.10..<0.15: return 32
            case 0.07..<0.10: return 24
            case 0.05..<0.07: return 16
            case 0..<0.05: return 8
            default: return 0
            }
        }()
        
        // 안정성 점수 (30점 만점) = 변동성(15) + MDD(15)
        let volatilityScore: Int = {
            switch volatility {
            case 0..<0.12: return 15
            case 0.12..<0.18: return 12
            case 0.18..<0.25: return 9
            case 0.25..<0.35: return 5
            default: return 2
            }
        }()
        
        let mddScore: Int = {
            switch abs(mdd) {
            case 0..<0.15: return 15
            case 0.15..<0.25: return 12
            case 0.25..<0.35: return 8
            case 0.35..<0.50: return 4
            default: return 1
            }
        }()
        
        let stability = volatilityScore + mddScore
        
        // 효율성 점수 (30점 만점)
        let efficiency: Int = {
            switch sharpeRatio {
            case 1.5...: return 30
            case 1.2..<1.5: return 25
            case 1.0..<1.2: return 20
            case 0.7..<1.0: return 15
            case 0.5..<0.7: return 10
            case 0..<0.5: return 5
            default: return 0
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
    
    // MARK: - Sector/Region Allocation
    
    /// 섹터별 배분 계산
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
            let emoji: String = {
                switch sector.lowercased() {
                case "technology": return "💻"
                case "etf": return "📊"
                case "energy": return "🔋"
                case "healthcare": return "🏥"
                case "finance", "financial": return "🏦"
                case "consumer": return "🛒"
                default: return "📈"
                }
            }()
            return SectorAllocation(sector: sector, weight: weight, emoji: emoji)
        }.sorted { $0.weight > $1.weight }
    }
    
    /// 지역별 배분 계산 (현재 미국 주식만 지원)
    static func calculateRegionAllocation(
        holdings: [(ticker: String, weight: Double)],
        stocksData: [StockWithData]
    ) -> [RegionAllocation] {
        
        // 현재 미국 주식만 지원하므로 모든 비중을 미국으로 계산
        let totalWeight = holdings.reduce(0.0) { $0 + $1.weight }
        
        guard totalWeight > 0 else { return [] }
        
        return [RegionAllocation(region: "미국", flag: "🇺🇸", weight: totalWeight)]
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

// MARK: - Insights Generator

/// 포트폴리오 인사이트 생성기
enum PortfolioInsightsGenerator {
    
    struct Insight: Identifiable {
        let id = UUID()
        let type: InsightType
        let category: InsightCategory
        let title: String
        let message: String
        let emoji: String
        let details: [String]?  // 추가 세부 정보
    }
    
    enum InsightType {
        case strength    // 강점
        case warning     // 주의
        case suggestion  // 개선 제안
    }
    
    enum InsightCategory: String {
        case profitability = "수익성"
        case risk = "위험"
        case dividend = "배당"
        case diversification = "분산투자"
        case efficiency = "효율성"
        case overall = "종합"
    }
    
    /// 상세 분석 결과 기반 인사이트 생성
    static func generateDetailedInsights(
        result: PortfolioAnalysisResult,
        sectorAllocation: [SectorAllocation],
        regionAllocation: [RegionAllocation],
        cagrBreakdown: [StockMetricBreakdown],
        sharpeBreakdown: [StockMetricBreakdown],
        volatilityBreakdown: [StockMetricBreakdown],
        mddBreakdown: [StockMetricBreakdown],
        dividendBreakdown: [DividendStockBreakdown]
    ) -> [Insight] {
        
        var insights: [Insight] = []
        
        // ═══════════════════════════════════════════════════════════
        // 1. 종합 평가
        // ═══════════════════════════════════════════════════════════
        insights.append(generateOverallInsight(result: result))
        
        // ═══════════════════════════════════════════════════════════
        // 2. 수익성 분석
        // ═══════════════════════════════════════════════════════════
        insights.append(contentsOf: generateProfitabilityInsights(
            result: result,
            cagrBreakdown: cagrBreakdown
        ))
        
        // ═══════════════════════════════════════════════════════════
        // 3. 위험 분석
        // ═══════════════════════════════════════════════════════════
        insights.append(contentsOf: generateRiskInsights(
            result: result,
            volatilityBreakdown: volatilityBreakdown,
            mddBreakdown: mddBreakdown
        ))
        
        // ═══════════════════════════════════════════════════════════
        // 4. 효율성 분석 (Sharpe Ratio)
        // ═══════════════════════════════════════════════════════════
        insights.append(contentsOf: generateEfficiencyInsights(
            result: result,
            sharpeBreakdown: sharpeBreakdown
        ))
        
        // ═══════════════════════════════════════════════════════════
        // 5. 배당 분석
        // ═══════════════════════════════════════════════════════════
        insights.append(contentsOf: generateDividendInsights(
            result: result,
            dividendBreakdown: dividendBreakdown
        ))
        
        // ═══════════════════════════════════════════════════════════
        // 6. 분산투자 분석
        // ═══════════════════════════════════════════════════════════
        insights.append(contentsOf: generateDiversificationInsights(
            sectorAllocation: sectorAllocation,
            regionAllocation: regionAllocation,
            stockCount: cagrBreakdown.count
        ))
        
        return insights
    }
    
    // MARK: - Overall Insight
    
    private static func generateOverallInsight(result: PortfolioAnalysisResult) -> Insight {
        let score = result.score.total
        let grade = result.score.grade
        
        var message = ""
        var emoji = ""
        var type: InsightType = .strength
        var details: [String] = []
        
        switch grade {
        case "S":
            emoji = "🏆"
            message = "최상위 포트폴리오입니다! 수익성(\(result.score.profitability)/40점), 안정성(\(result.score.stability)/30점), 효율성(\(result.score.efficiency)/30점) 모든 영역에서 뛰어난 성과를 보이고 있어요."
            type = .strength
            details = [
                "[좋음] 수익성: \(result.score.profitability >= 32 ? "매우 우수" : "우수") - 시장 평균을 상회하는 성과",
                "[좋음] 안정성: \(result.score.stability >= 24 ? "매우 우수" : "우수") - 변동성과 낙폭이 잘 관리됨",
                "[좋음] 효율성: \(result.score.efficiency >= 24 ? "매우 우수" : "우수") - 위험 대비 수익이 탁월함"
            ]
        case "A":
            emoji = "👍"
            message = "우수한 포트폴리오입니다! 총점 \(score)점으로 대부분의 영역에서 좋은 성과를 보이고 있어요."
            type = .strength
            if result.score.profitability < 24 {
                details.append("[주의] 수익성 개선 여지: 성장주 비중 확대 고려")
            } else {
                details.append("[좋음] 수익성: 양호한 수준")
            }
            if result.score.stability < 18 {
                details.append("[주의] 안정성 개선 여지: 변동성 낮은 자산 추가 고려")
            } else {
                details.append("[좋음] 안정성: 양호한 수준")
            }
            if result.score.efficiency < 18 {
                details.append("[주의] 효율성 개선 여지: 비효율적인 종목 비중 조정 고려")
            } else {
                details.append("[좋음] 효율성: 양호한 수준")
            }
        case "B":
            emoji = "📊"
            message = "양호한 포트폴리오입니다. 총점 \(score)점으로 기본적인 구성은 갖추었으나, 일부 영역에서 개선이 필요해요."
            type = .suggestion
            details = generateImprovementDetails(result: result)
        case "C":
            emoji = "📋"
            message = "개선이 필요한 포트폴리오입니다. 총점 \(score)점으로 수익성, 안정성, 효율성 중 상당 부분에서 보완이 필요해요."
            type = .warning
            details = generateImprovementDetails(result: result)
        default:
            emoji = "📋"
            message = "포트폴리오 재검토가 필요합니다. 총점 \(score)점으로 전반적인 구조 개선이 시급해요."
            type = .warning
            details = generateImprovementDetails(result: result)
        }
        
        return Insight(
            type: type,
            category: .overall,
            title: "종합 평가: \(grade)등급 (\(score)점)",
            message: message,
            emoji: emoji,
            details: details.isEmpty ? nil : details
        )
    }
    
    private static func generateImprovementDetails(result: PortfolioAnalysisResult) -> [String] {
        var details: [String] = []
        
        if result.score.profitability < 24 {
            details.append("[주의] 수익성(\(result.score.profitability)/40점): 더 높은 성장률의 종목 추가 필요")
        }
        if result.score.stability < 18 {
            details.append("[주의] 안정성(\(result.score.stability)/30점): 변동성 낮은 ETF나 배당주 추가 권장")
        }
        if result.score.efficiency < 18 {
            details.append("[주의] 효율성(\(result.score.efficiency)/30점): 위험 대비 수익이 낮은 종목 비중 축소 고려")
        }
        
        return details
    }
    
    // MARK: - Profitability Insights
    
    private static func generateProfitabilityInsights(
        result: PortfolioAnalysisResult,
        cagrBreakdown: [StockMetricBreakdown]
    ) -> [Insight] {
        var insights: [Insight] = []
        
        // 최고 수익 종목 분석
        if let bestStock = cagrBreakdown.first {
            let isBestPositive = bestStock.value >= 0.10
            
            var details: [String] = ["[종목별 CAGR 순위]"]
            
            // 상위 3개 종목 분석
            for (index, stock) in cagrBreakdown.prefix(3).enumerated() {
                let contribution = stock.contribution * 100
                let cagrValue = stock.value * 100
                let tag = stock.value >= 0.10 ? "[좋음]" : (stock.value >= 0.05 ? "" : "[주의]")
                details.append("\(index + 1). \(stock.name): CAGR \(String(format: "%.1f", cagrValue))% \(tag) (기여 \(String(format: "+%.1f", contribution))%p)")
            }
            
            // 하위 종목 분석 (수익률이 낮은 종목)
            let underperformers = cagrBreakdown.filter { $0.value < 0.05 }
            if !underperformers.isEmpty {
                details.append("")
                details.append("[주의] 수익률이 낮은 종목:")
                for stock in underperformers {
                    details.append("• \(stock.name): CAGR \(String(format: "%.1f", stock.value * 100))% - 비중 조정 고려")
                }
            }
            
            insights.append(Insight(
                type: isBestPositive ? .strength : .suggestion,
                category: .profitability,
                title: "수익률 분석: \(bestStock.name) 주도",
                message: "\(bestStock.name)이(가) 가장 높은 CAGR \(String(format: "%.1f", bestStock.value * 100))%를 기록하며 포트폴리오 수익에 \(String(format: "%.1f", bestStock.contribution * 100))%p 기여하고 있어요. 포트폴리오 전체 CAGR은 \(String(format: "%.1f", result.cagrWithDividends * 100))%입니다.",
                emoji: "📈",
                details: details
            ))
        }
        
        // 마이너스 수익률 종목 경고
        let negativeStocks = cagrBreakdown.filter { $0.value < 0 }
        if !negativeStocks.isEmpty {
            var details = negativeStocks.map { stock in
                "• \(stock.name): CAGR \(String(format: "%.1f", stock.value * 100))% (비중 \(String(format: "%.0f", stock.weight * 100))%)"
            }
            details.append("")
            details.append("[제안] 개선 방안:")
            details.append("1. 해당 종목의 미래 전망 재검토")
            details.append("2. 비중 축소 또는 손절 고려")
            details.append("3. 더 나은 성과의 대체 종목 탐색")
            
            insights.append(Insight(
                type: .warning,
                category: .profitability,
                title: "수익률 경고: \(negativeStocks.count)개 종목 손실 중",
                message: "\(negativeStocks.map { $0.name }.joined(separator: ", "))이(가) 마이너스 수익률을 기록 중이에요. 포트폴리오 전체 수익률을 끌어내리는 원인입니다.",
                emoji: "📉",
                details: details
            ))
        }
        
        return insights
    }
    
    // MARK: - Risk Insights
    
    private static func generateRiskInsights(
        result: PortfolioAnalysisResult,
        volatilityBreakdown: [StockMetricBreakdown],
        mddBreakdown: [StockMetricBreakdown]
    ) -> [Insight] {
        var insights: [Insight] = []
        
        // 변동성 분석
        let highVolStocks = volatilityBreakdown.filter { $0.value > 0.30 }
        let lowVolStocks = volatilityBreakdown.filter { $0.value < 0.15 }
        
        var volDetails: [String] = ["[종목별 변동성]"]
        
        for stock in volatilityBreakdown {
            let tag = stock.value > 0.30 ? "[위험]" : (stock.value > 0.20 ? "" : "[좋음]")
            let level = stock.value > 0.30 ? "높음" : (stock.value > 0.20 ? "보통" : "낮음")
            volDetails.append("• \(stock.name): \(String(format: "%.1f", stock.value * 100))% \(tag) \(level)")
        }
        
        if !highVolStocks.isEmpty {
            volDetails.append("")
            volDetails.append("[주의] 높은 변동성 종목 (\(highVolStocks.count)개):")
            for stock in highVolStocks {
                volDetails.append("• \(stock.name) - 포트폴리오 변동성의 주요 원인")
            }
            volDetails.append("")
            volDetails.append("[제안] 변동성 관리 방안:")
            volDetails.append("1. 고변동성 종목 비중 축소")
            volDetails.append("2. 저변동성 ETF(예: SCHD, VTI) 추가")
            volDetails.append("3. 채권 ETF 일부 편입 고려")
        }
        
        if !lowVolStocks.isEmpty {
            volDetails.append("")
            volDetails.append("[좋음] 안정적인 종목 (\(lowVolStocks.count)개):")
            for stock in lowVolStocks {
                volDetails.append("• \(stock.name) - 포트폴리오 안정화에 기여")
            }
        }
        
        let volType: InsightType = result.volatility > 0.25 ? .warning : (result.volatility < 0.18 ? .strength : .suggestion)
        insights.append(Insight(
            type: volType,
            category: .risk,
            title: "변동성 분석: 포트폴리오 \(String(format: "%.1f", result.volatility * 100))%",
            message: result.volatility > 0.25 
                ? "포트폴리오 변동성이 \(String(format: "%.1f", result.volatility * 100))%로 다소 높아요. \(highVolStocks.first?.name ?? "일부 종목")이(가) 변동성을 높이는 주요 원인이에요."
                : "포트폴리오 변동성이 \(String(format: "%.1f", result.volatility * 100))%로 \(result.volatility < 0.18 ? "안정적" : "적정 수준")이에요.",
            emoji: "📊",
            details: volDetails
        ))
        
        // MDD 분석
        let severeDrawdownStocks = mddBreakdown.filter { abs($0.value) > 0.40 }
        
        var mddDetails: [String] = ["[종목별 최대 낙폭(MDD)]"]
        
        for stock in mddBreakdown {
            let tag = abs(stock.value) > 0.40 ? "[위험]" : (abs(stock.value) > 0.25 ? "[주의]" : "[좋음]")
            let severity = abs(stock.value) > 0.40 ? "심각" : (abs(stock.value) > 0.25 ? "주의" : "양호")
            mddDetails.append("• \(stock.name): \(String(format: "%.1f", stock.value * 100))% \(tag) \(severity)")
        }
        
        if !severeDrawdownStocks.isEmpty {
            mddDetails.append("")
            mddDetails.append("[경고] 심각한 낙폭 경험 종목:")
            for stock in severeDrawdownStocks {
                mddDetails.append("• \(stock.name): 과거 \(String(format: "%.0f", abs(stock.value) * 100))% 하락 경험")
            }
            mddDetails.append("")
            mddDetails.append("[제안] 낙폭 위험 관리:")
            mddDetails.append("1. 시장 하락 시 해당 종목 손실 대비")
            mddDetails.append("2. 분할 매수 전략 활용")
            mddDetails.append("3. 방어주/배당주 비중 확대 고려")
        }
        
        let worstMDD = mddBreakdown.max(by: { abs($0.value) < abs($1.value) })
        let mddType: InsightType = abs(result.mdd) > 0.30 ? .warning : .suggestion
        
        insights.append(Insight(
            type: mddType,
            category: .risk,
            title: "낙폭 위험 분석: 최대 \(String(format: "%.0f", abs(result.mdd) * 100))% 하락 가능",
            message: "포트폴리오가 과거 최대 \(String(format: "%.0f", abs(result.mdd) * 100))% 하락한 적이 있어요. \(worstMDD?.name ?? "일부 종목")이(가) \(String(format: "%.0f", abs(worstMDD?.value ?? 0) * 100))%로 가장 큰 낙폭을 기록했어요.",
            emoji: "📉",
            details: mddDetails
        ))
        
        return insights
    }
    
    // MARK: - Efficiency Insights
    
    private static func generateEfficiencyInsights(
        result: PortfolioAnalysisResult,
        sharpeBreakdown: [StockMetricBreakdown]
    ) -> [Insight] {
        var insights: [Insight] = []
        
        let efficientStocks = sharpeBreakdown.filter { $0.value >= 1.0 }
        let inefficientStocks = sharpeBreakdown.filter { $0.value < 0.5 }
        
        var details: [String] = ["[종목별 Sharpe Ratio]"]
        
        for stock in sharpeBreakdown {
            let tag = stock.value >= 1.0 ? "[좋음]" : (stock.value >= 0.5 ? "" : "[주의]")
            let grade = stock.value >= 1.5 ? "우수" : (stock.value >= 1.0 ? "양호" : (stock.value >= 0.5 ? "보통" : "미흡"))
            details.append("• \(stock.name): \(String(format: "%.2f", stock.value)) \(tag) \(grade)")
        }
        
        if !efficientStocks.isEmpty {
            details.append("")
            details.append("[좋음] 효율적인 종목 (Sharpe ≥ 1.0):")
            for stock in efficientStocks {
                details.append("• \(stock.name) - 위험 대비 좋은 수익")
            }
        }
        
        if !inefficientStocks.isEmpty {
            details.append("")
            details.append("[주의] 비효율적인 종목 (Sharpe < 0.5):")
            for stock in inefficientStocks {
                details.append("• \(stock.name) - 감수하는 위험 대비 수익이 낮음")
            }
            details.append("")
            details.append("[제안] 효율성 개선 방안:")
            details.append("1. 비효율 종목 비중 축소 고려")
            details.append("2. Sharpe Ratio 높은 ETF로 대체 검토")
            details.append("3. 전체 포트폴리오 리밸런싱")
        }
        
        let bestSharpe = sharpeBreakdown.first
        let worstSharpe = sharpeBreakdown.last
        
        let sharpeType: InsightType = result.sharpeRatio >= 1.0 ? .strength : (result.sharpeRatio >= 0.5 ? .suggestion : .warning)
        
        insights.append(Insight(
            type: sharpeType,
            category: .efficiency,
            title: "투자 효율성: Sharpe Ratio \(String(format: "%.2f", result.sharpeRatio))",
            message: result.sharpeRatio >= 1.0
                ? "포트폴리오의 위험조정수익률이 \(String(format: "%.2f", result.sharpeRatio))로 우수해요! \(bestSharpe?.name ?? "")이(가) \(String(format: "%.2f", bestSharpe?.value ?? 0))로 가장 효율적이에요."
                : "포트폴리오의 위험조정수익률이 \(String(format: "%.2f", result.sharpeRatio))로 \(result.sharpeRatio >= 0.5 ? "보통" : "개선 필요") 수준이에요. \(worstSharpe?.name ?? "일부 종목")(\(String(format: "%.2f", worstSharpe?.value ?? 0)))이(가) 전체 효율성을 낮추고 있어요.",
            emoji: "⚖️",
            details: details
        ))
        
        return insights
    }
    
    // MARK: - Dividend Insights
    
    private static func generateDividendInsights(
        result: PortfolioAnalysisResult,
        dividendBreakdown: [DividendStockBreakdown]
    ) -> [Insight] {
        var insights: [Insight] = []
        
        let highDividendStocks = dividendBreakdown.filter { $0.yield >= 0.03 }
        let noDividendStocks = dividendBreakdown.filter { $0.yield == 0 }
        let growingDividendStocks = dividendBreakdown.filter { $0.growthRate > 0.05 }
        
        var details: [String] = ["[종목별 배당 분석]"]
        
        for stock in dividendBreakdown {
            if stock.yield > 0 {
                let tag = stock.yield >= 0.03 ? "[좋음]" : ""
                let yieldLevel = stock.yield >= 0.03 ? "고배당" : (stock.yield >= 0.01 ? "보통" : "저배당")
                var line = "• \(stock.name): \(String(format: "%.2f", stock.yield * 100))% \(tag) \(yieldLevel)"
                if stock.growthRate > 0 {
                    line += ", 성장률 +\(String(format: "%.1f", stock.growthRate * 100))%"
                }
                details.append(line)
            } else {
                details.append("• \(stock.name): 무배당 (성장 재투자형)")
            }
        }
        
        if !highDividendStocks.isEmpty {
            details.append("")
            details.append("[좋음] 고배당 종목 (\(highDividendStocks.count)개):")
            for stock in highDividendStocks {
                let contribution = stock.contribution * 100
                details.append("• \(stock.name): 배당률 \(String(format: "%.2f", stock.yield * 100))%, 포트폴리오 기여 \(String(format: "%.2f", contribution))%p")
            }
        }
        
        if !growingDividendStocks.isEmpty {
            details.append("")
            details.append("[강점] 배당 성장 종목:")
            for stock in growingDividendStocks {
                details.append("• \(stock.name): 5년 배당성장률 +\(String(format: "%.1f", stock.growthRate * 100))%")
            }
        }
        
        if !noDividendStocks.isEmpty {
            details.append("")
            details.append("무배당 종목 (\(noDividendStocks.count)개):")
            for stock in noDividendStocks {
                details.append("• \(stock.name) - 성장에 집중하는 종목")
            }
        }
        
        // 배당 투자 전략 제안
        details.append("")
        if result.dividendYield >= 0.03 {
            details.append("[좋음] 배당 전략 평가: 우수")
            details.append("• 안정적인 현금흐름 확보됨")
            details.append("• 시장 하락 시 배당으로 일부 방어 가능")
        } else if result.dividendYield >= 0.01 {
            details.append("[제안] 배당 확대 고려:")
            details.append("• 현금흐름 강화를 원하면 배당주 비중 확대")
            details.append("• 추천: SCHD, VIG 등 배당성장 ETF")
        } else {
            details.append("[제안] 배당 전략:")
            details.append("• 현재 성장주 중심 포트폴리오")
            details.append("• 안정성 원하면 배당주/ETF 추가 고려")
        }
        
        let dividendType: InsightType = result.dividendYield >= 0.02 ? .strength : .suggestion
        
        insights.append(Insight(
            type: dividendType,
            category: .dividend,
            title: "배당 분석: 연 \(String(format: "%.2f", result.dividendYield * 100))% 수익",
            message: result.dividendYield >= 0.02
                ? "포트폴리오 배당률 \(String(format: "%.2f", result.dividendYield * 100))%로 \(highDividendStocks.first?.name ?? "배당주")가 주로 기여하고 있어요. 연간 꾸준한 현금흐름을 기대할 수 있어요."
                : "포트폴리오 배당률이 \(String(format: "%.2f", result.dividendYield * 100))%로 낮은 편이에요. \(noDividendStocks.isEmpty ? "" : "\(noDividendStocks.count)개 종목이 무배당입니다.")",
            emoji: "💰",
            details: details
        ))
        
        return insights
    }
    
    // MARK: - Diversification Insights
    
    private static func generateDiversificationInsights(
        sectorAllocation: [SectorAllocation],
        regionAllocation: [RegionAllocation],
        stockCount: Int
    ) -> [Insight] {
        var insights: [Insight] = []
        
        var details: [String] = []
        
        // 섹터 분산 분석
        details.append("[섹터별 배분]")
        for sector in sectorAllocation {
            let tag = sector.weight >= 0.5 ? "[위험]" : (sector.weight >= 0.3 ? "[주의]" : "")
            let level = sector.weight >= 0.5 ? "집중" : (sector.weight >= 0.3 ? "높음" : "적정")
            details.append("• \(sector.emoji) \(sector.sector): \(String(format: "%.0f", sector.weight * 100))% \(tag) \(level)")
        }
        
        // 지역 분산 분석
        details.append("")
        details.append("[지역별 배분]")
        for region in regionAllocation {
            details.append("• \(region.flag) \(region.region): \(String(format: "%.0f", region.weight * 100))%")
        }
        
        // 종목 수 분석
        details.append("")
        details.append("[분산투자 수준]")
        if stockCount < 3 {
            details.append("[주의] 종목 수가 적어 집중 위험 있음 (현재 \(stockCount)개)")
            details.append("[제안] 최소 5개 이상 종목으로 분산 권장")
        } else if stockCount <= 5 {
            details.append("적정 수준의 분산 (\(stockCount)개)")
            details.append("[팁] 10개 이상으로 확대하면 더 안정적")
        } else {
            details.append("[좋음] 충분한 종목 분산 (\(stockCount)개)")
        }
        
        // 섹터 집중도 경고
        let topSector = sectorAllocation.first
        if let top = topSector, top.weight >= 0.6 {
            details.append("")
            details.append("[경고] 섹터 집중 위험:")
            details.append("• \(top.sector) 섹터 비중이 \(String(format: "%.0f", top.weight * 100))%로 높음")
            details.append("[제안] 다른 섹터 종목 추가로 리스크 분산 권장")
            details.append("예: 헬스케어, 필수소비재, 금융 섹터")
        }
        
        // 지역 집중도
        if regionAllocation.count == 1 {
            let region = regionAllocation[0]
            details.append("")
            details.append("[경고] 지역 집중 위험:")
            details.append("• \(region.region) 시장에만 100% 투자 중")
            details.append("[제안] 글로벌 분산으로 국가별 리스크 완화 권장")
        }
        
        let hasConcentrationRisk = (topSector?.weight ?? 0) >= 0.6 || stockCount < 3 || regionAllocation.count == 1
        
        insights.append(Insight(
            type: hasConcentrationRisk ? .warning : .strength,
            category: .diversification,
            title: "분산투자 분석: \(stockCount)개 종목, \(sectorAllocation.count)개 섹터",
            message: hasConcentrationRisk
                ? "포트폴리오가 특정 \(topSector?.sector ?? "섹터") 또는 지역에 집중되어 있어요. 분산투자로 리스크를 낮추는 것을 권장해요."
                : "포트폴리오가 \(stockCount)개 종목, \(sectorAllocation.count)개 섹터에 분산되어 있어 리스크가 잘 관리되고 있어요.",
            emoji: "📊",
            details: details
        ))
        
        return insights
    }
    
    /// 분석 결과 기반 인사이트 생성 (기존 호환성 유지)
    static func generateInsights(
        result: PortfolioAnalysisResult,
        sectorAllocation: [SectorAllocation],
        regionAllocation: [RegionAllocation]
    ) -> [Insight] {
        // 빈 breakdown으로 호출 (호환성)
        return generateDetailedInsights(
            result: result,
            sectorAllocation: sectorAllocation,
            regionAllocation: regionAllocation,
            cagrBreakdown: [],
            sharpeBreakdown: [],
            volatilityBreakdown: [],
            mddBreakdown: [],
            dividendBreakdown: []
        )
    }
}

