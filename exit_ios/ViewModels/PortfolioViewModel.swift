//
//  PortfolioViewModel.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  포트폴리오 뷰모델
//

import Foundation
import SwiftUI
import SwiftData
import Observation

/// 포트폴리오 뷰 상태
enum PortfolioViewState: Equatable {
    case empty              // 포트폴리오 없음
    case editing            // 포트폴리오 편집 중
    case analyzing          // 분석 중
    case analyzed           // 분석 완료
    case error(String)      // 오류 발생
}

/// 포트폴리오 뷰모델
@Observable
final class PortfolioViewModel {
    
    // MARK: - Dependencies
    
    private let dataService: StockDataServiceProtocol
    private var modelContext: ModelContext?
    
    // MARK: - State
    
    /// 현재 뷰 상태
    private(set) var viewState: PortfolioViewState = .empty
    
    /// 로딩 중 여부
    private(set) var isLoading = false
    
    /// 검색 쿼리
    var searchQuery = ""
    
    /// 검색 결과
    private(set) var searchResults: [StockInfo] = []
    
    /// 전체 종목 목록 (캐시)
    private(set) var allStocks: [StockInfo] = []
    
    /// 현재 포트폴리오 (편집 중)
    private(set) var holdings: [PortfolioHoldingDisplay] = []
    
    /// 분석 결과
    private(set) var analysisResult: PortfolioAnalysisResult?
    
    /// 섹터 배분
    private(set) var sectorAllocation: [SectorAllocation] = []
    
    /// 지역 배분
    private(set) var regionAllocation: [RegionAllocation] = []
    
    /// 인사이트
    private(set) var insights: [PortfolioInsightsGenerator.Insight] = []
    
    /// 에러 메시지
    private(set) var errorMessage: String?
    
    /// 종목 데이터 캐시
    private(set) var stocksDataCache: [StockWithData] = []
    
    // MARK: - 종목별 상세 분석 데이터
    
    /// Sharpe Ratio 종목별 분해
    private(set) var sharpeBreakdown: [StockMetricBreakdown] = []
    
    /// 변동성 종목별 분해
    private(set) var volatilityBreakdown: [StockMetricBreakdown] = []
    
    /// MDD 종목별 분해
    private(set) var mddBreakdown: [StockMetricBreakdown] = []
    
    /// CAGR 종목별 분해
    private(set) var cagrBreakdown: [StockMetricBreakdown] = []
    
    /// 배당 종목별 분해
    private(set) var dividendBreakdown: [DividendStockBreakdown] = []
    
    // MARK: - Computed Properties
    
    /// 총 비중 합계
    var totalWeight: Double {
        holdings.reduce(0) { $0 + $1.weight }
    }
    
    /// 비중 합계가 100%인지
    var isWeightValid: Bool {
        abs(totalWeight - 1.0) < 0.001
    }
    
    /// 분석 가능 여부
    var canAnalyze: Bool {
        !holdings.isEmpty && isWeightValid
    }
    
    /// 검색 결과 필터링 (이미 추가된 종목 제외)
    var filteredSearchResults: [StockInfo] {
        let addedTickers = Set(holdings.map { $0.ticker })
        return searchResults.filter { !addedTickers.contains($0.ticker) }
    }
    
    // MARK: - Initialization
    
    init(dataService: StockDataServiceProtocol = StockDataServiceFactory.createService()) {
        self.dataService = dataService
    }
    
    // MARK: - Configuration
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSavedHoldings()
    }
    
    // MARK: - Data Loading
    
    /// 초기 데이터 로드
    @MainActor
    func loadInitialData() async {
        isLoading = true
        
        do {
            allStocks = try await dataService.fetchAllStocks()
            searchResults = allStocks
            
            if holdings.isEmpty {
                viewState = .empty
            } else {
                viewState = .editing
            }
        } catch {
            errorMessage = error.localizedDescription
            viewState = .error(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    /// 종목 검색
    @MainActor
    func search() async {
        guard !searchQuery.isEmpty else {
            searchResults = allStocks
            return
        }
        
        do {
            searchResults = try await dataService.searchStocks(query: searchQuery)
        } catch {
            // 검색 실패 시 로컬 필터링
            let query = searchQuery.lowercased()
            searchResults = allStocks.filter {
                $0.ticker.lowercased().contains(query) ||
                $0.name.lowercased().contains(query) ||
                ($0.nameKorean?.lowercased().contains(query) ?? false)
            }
        }
    }
    
    // MARK: - Portfolio Management
    
    /// 종목 추가
    @MainActor
    func addStock(_ stock: StockInfo) {
        // 이미 추가된 종목인지 확인
        guard !holdings.contains(where: { $0.ticker == stock.ticker }) else {
            return
        }
        
        // 초기 비중 계산 (균등 분배)
        let newWeight = holdings.isEmpty ? 1.0 : 0.0
        
        let holding = PortfolioHoldingDisplay(
            ticker: stock.ticker,
            name: stock.displayName,
            exchange: stock.exchange,
            sectorEmoji: stock.sectorEmoji,
            weight: newWeight
        )
        
        holdings.append(holding)
        
        // 비중 자동 조정
        if holdings.count > 1 {
            equalizeWeights()
        }
        
        viewState = .editing
        saveHoldings()
        
        // 검색 초기화
        searchQuery = ""
    }
    
    /// 종목 제거
    @MainActor
    func removeStock(at index: Int) {
        guard index < holdings.count else { return }
        
        holdings.remove(at: index)
        
        if holdings.isEmpty {
            viewState = .empty
            analysisResult = nil
        } else {
            equalizeWeights()
        }
        
        saveHoldings()
    }
    
    /// 비중 업데이트
    @MainActor
    func updateWeight(for ticker: String, weight: Double) {
        guard let index = holdings.firstIndex(where: { $0.ticker == ticker }) else {
            return
        }
        
        holdings[index].weight = max(0, min(1, weight))
        saveHoldings()
    }
    
    /// 비중 균등화
    @MainActor
    func equalizeWeights() {
        guard !holdings.isEmpty else { return }
        
        let equalWeight = 1.0 / Double(holdings.count)
        for i in holdings.indices {
            holdings[i].weight = equalWeight
        }
        
        saveHoldings()
    }
    
    /// 비중 정규화 (합계 100%로)
    @MainActor
    func normalizeWeights() {
        guard totalWeight > 0 else { return }
        
        let factor = 1.0 / totalWeight
        for i in holdings.indices {
            holdings[i].weight *= factor
        }
        
        saveHoldings()
    }
    
    // MARK: - Analysis
    
    /// 포트폴리오 분석 실행
    @MainActor
    func analyze() async {
        guard canAnalyze else {
            if !isWeightValid {
                errorMessage = "비중 합계가 100%가 되어야 합니다"
            }
            return
        }
        
        viewState = .analyzing
        isLoading = true
        errorMessage = nil
        
        do {
            // 종목 데이터 가져오기
            let tickers = holdings.map { $0.ticker }
            stocksDataCache = try await dataService.fetchStocksWithData(tickers: tickers)
            
            // 분석 실행 (백그라운드)
            let holdingsData = holdings.map { (ticker: $0.ticker, weight: $0.weight) }
            
            analysisResult = PortfolioAnalyzer.analyze(
                holdings: holdingsData,
                stocksData: stocksDataCache
            )
            
            // 배분 계산
            sectorAllocation = PortfolioAnalyzer.calculateSectorAllocation(
                holdings: holdingsData,
                stocksData: stocksDataCache
            )
            
            regionAllocation = PortfolioAnalyzer.calculateRegionAllocation(
                holdings: holdingsData,
                stocksData: stocksDataCache
            )
            
            // 종목별 상세 분석 데이터 계산
            calculateStockBreakdowns()
            
            // 상세 인사이트 생성 (breakdown 데이터 포함)
            if let result = analysisResult {
                insights = PortfolioInsightsGenerator.generateDetailedInsights(
                    result: result,
                    sectorAllocation: sectorAllocation,
                    regionAllocation: regionAllocation,
                    cagrBreakdown: cagrBreakdown,
                    sharpeBreakdown: sharpeBreakdown,
                    volatilityBreakdown: volatilityBreakdown,
                    mddBreakdown: mddBreakdown,
                    dividendBreakdown: dividendBreakdown
                )
            }
            
            viewState = .analyzed
            HapticService.shared.success()
            
        } catch {
            errorMessage = error.localizedDescription
            viewState = .error(error.localizedDescription)
            HapticService.shared.error()
        }
        
        isLoading = false
    }
    
    /// 편집 모드로 돌아가기
    @MainActor
    func backToEdit() {
        viewState = .editing
    }
    
    /// 편집 모드 시작 (빈 상태에서)
    @MainActor
    func startEditing() {
        viewState = .editing
    }
    
    /// 포트폴리오 초기화
    @MainActor
    func resetPortfolio() {
        holdings = []
        analysisResult = nil
        sectorAllocation = []
        regionAllocation = []
        insights = []
        stocksDataCache = []
        sharpeBreakdown = []
        volatilityBreakdown = []
        mddBreakdown = []
        cagrBreakdown = []
        dividendBreakdown = []
        viewState = .empty
        
        clearSavedHoldings()
    }
    
    // MARK: - Persistence
    
    private func saveHoldings() {
        // UserDefaults에 간단히 저장 (프로토타입용)
        let data = holdings.map { ["ticker": $0.ticker, "weight": $0.weight] as [String: Any] }
        UserDefaults.standard.set(data, forKey: "portfolio_holdings")
    }
    
    private func loadSavedHoldings() {
        guard let data = UserDefaults.standard.array(forKey: "portfolio_holdings") as? [[String: Any]] else {
            return
        }
        
        // 저장된 데이터로 holdings 복원
        Task { @MainActor in
            await loadInitialData()
            
            holdings = data.compactMap { dict -> PortfolioHoldingDisplay? in
                guard let ticker = dict["ticker"] as? String,
                      let weight = dict["weight"] as? Double,
                      let stock = allStocks.first(where: { $0.ticker == ticker }) else {
                    return nil
                }
                
                return PortfolioHoldingDisplay(
                    ticker: ticker,
                    name: stock.displayName,
                    exchange: stock.exchange,
                    sectorEmoji: stock.sectorEmoji,
                    weight: weight
                )
            }
            
            if !holdings.isEmpty {
                viewState = .editing
            }
        }
    }
    
    private func clearSavedHoldings() {
        UserDefaults.standard.removeObject(forKey: "portfolio_holdings")
    }
    
    // MARK: - Stock Breakdowns Calculation
    
    /// 종목별 상세 분석 데이터 계산
    private func calculateStockBreakdowns() {
        guard !holdings.isEmpty, !stocksDataCache.isEmpty else { return }
        
        // 포트폴리오 평균 값들
        let portfolioVolatility = analysisResult?.volatility ?? 0
        let portfolioMDD = analysisResult?.mdd ?? 0
        let portfolioCAGR = analysisResult?.cagrWithDividends ?? 0
        let portfolioYield = analysisResult?.dividendYield ?? 0
        
        // CAGR Breakdown
        var cagrData: [(ticker: String, name: String, emoji: String, value: Double, weight: Double)] = []
        for holding in holdings {
            guard let stock = stocksDataCache.first(where: { $0.info.ticker == holding.ticker }) else { continue }
            cagrData.append((
                ticker: holding.ticker,
                name: holding.name,
                emoji: holding.sectorEmoji,
                value: stock.cagrWithDividends,
                weight: holding.weight
            ))
        }
        let sortedCAGR = cagrData.sorted { $0.value > $1.value }
        cagrBreakdown = sortedCAGR.enumerated().map { index, data in
            StockMetricBreakdown(
                ticker: data.ticker,
                name: data.name,
                emoji: data.emoji,
                value: data.value,
                formattedValue: String(format: "%.1f%%", data.value * 100),
                weight: data.weight,
                contribution: data.value * data.weight,
                isPositive: data.value >= portfolioCAGR,
                rank: index + 1
            )
        }
        
        // Volatility Breakdown (낮을수록 좋음)
        var volatilityData: [(ticker: String, name: String, emoji: String, value: Double, weight: Double)] = []
        for holding in holdings {
            guard let stock = stocksDataCache.first(where: { $0.info.ticker == holding.ticker }) else { continue }
            volatilityData.append((
                ticker: holding.ticker,
                name: holding.name,
                emoji: holding.sectorEmoji,
                value: stock.priceHistory.annualVolatility,
                weight: holding.weight
            ))
        }
        let sortedVolatility = volatilityData.sorted { $0.value < $1.value }  // 낮은 순
        volatilityBreakdown = sortedVolatility.enumerated().map { index, data in
            StockMetricBreakdown(
                ticker: data.ticker,
                name: data.name,
                emoji: data.emoji,
                value: data.value,
                formattedValue: String(format: "%.1f%%", data.value * 100),
                weight: data.weight,
                contribution: data.value * data.weight,
                isPositive: data.value <= portfolioVolatility,  // 낮으면 긍정적
                rank: index + 1
            )
        }
        
        // MDD Breakdown (절대값 낮을수록 좋음)
        var mddData: [(ticker: String, name: String, emoji: String, value: Double, weight: Double)] = []
        for holding in holdings {
            guard let stock = stocksDataCache.first(where: { $0.info.ticker == holding.ticker }) else { continue }
            mddData.append((
                ticker: holding.ticker,
                name: holding.name,
                emoji: holding.sectorEmoji,
                value: stock.priceHistory.maxDrawdown,
                weight: holding.weight
            ))
        }
        let sortedMDD = mddData.sorted { abs($0.value) < abs($1.value) }  // 절대값 낮은 순
        mddBreakdown = sortedMDD.enumerated().map { index, data in
            StockMetricBreakdown(
                ticker: data.ticker,
                name: data.name,
                emoji: data.emoji,
                value: data.value,
                formattedValue: String(format: "%.1f%%", data.value * 100),
                weight: data.weight,
                contribution: data.value * data.weight,
                isPositive: abs(data.value) <= abs(portfolioMDD),
                rank: index + 1
            )
        }
        
        // Sharpe Ratio Breakdown (높을수록 좋음)
        // 개별 종목 Sharpe = (CAGR - 무위험수익률) / 변동성
        let riskFreeRate = 0.035
        var sharpeData: [(ticker: String, name: String, emoji: String, value: Double, weight: Double)] = []
        for holding in holdings {
            guard let stock = stocksDataCache.first(where: { $0.info.ticker == holding.ticker }) else { continue }
            let volatility = stock.priceHistory.annualVolatility
            let sharpe = volatility > 0 ? (stock.cagrWithDividends - riskFreeRate) / volatility : 0
            sharpeData.append((
                ticker: holding.ticker,
                name: holding.name,
                emoji: holding.sectorEmoji,
                value: sharpe,
                weight: holding.weight
            ))
        }
        let sortedSharpe = sharpeData.sorted { $0.value > $1.value }  // 높은 순
        let portfolioSharpe = analysisResult?.sharpeRatio ?? 0
        sharpeBreakdown = sortedSharpe.enumerated().map { index, data in
            StockMetricBreakdown(
                ticker: data.ticker,
                name: data.name,
                emoji: data.emoji,
                value: data.value,
                formattedValue: String(format: "%.2f", data.value),
                weight: data.weight,
                contribution: data.value * data.weight,
                isPositive: data.value >= portfolioSharpe,
                rank: index + 1
            )
        }
        
        // Dividend Breakdown
        var dividendData: [DividendStockBreakdown] = []
        for holding in holdings {
            guard let stock = stocksDataCache.first(where: { $0.info.ticker == holding.ticker }) else { continue }
            let contribution = stock.dividendHistory.dividendYield * holding.weight
            dividendData.append(DividendStockBreakdown(
                ticker: holding.ticker,
                name: holding.name,
                emoji: holding.sectorEmoji,
                weight: holding.weight,
                yield: stock.dividendHistory.dividendYield,
                growthRate: stock.dividendHistory.dividendGrowthRate,
                contribution: contribution
            ))
        }
        dividendBreakdown = dividendData.sorted { $0.yield > $1.yield }
    }
    
    // MARK: - Helpers
    
    /// 특정 종목의 상세 데이터 가져오기
    func getStockData(for ticker: String) -> StockWithData? {
        stocksDataCache.first { $0.info.ticker == ticker }
    }
}

// MARK: - Display Models

/// 포트폴리오 보유 종목 (UI 표시용)
struct PortfolioHoldingDisplay: Identifiable {
    let id = UUID()
    let ticker: String
    let name: String
    let exchange: StockExchange
    let sectorEmoji: String
    var weight: Double
    
    var weightPercent: String {
        String(format: "%.1f%%", weight * 100)
    }
}

