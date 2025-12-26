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
    
    private let analysisService: StockAnalysisDataServiceProtocol
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
    
    /// 분석 단계 (UI 표시용)
    private(set) var analysisPhase: PortfolioAnalysisPhase = .fetchingData
    
    /// 분석 진행률 (UI 표시용)
    private(set) var analysisProgress: Double = 0
    
    /// 실제 분석 완료 여부 (내부 플래그)
    private var isAnalysisCompleted = false
    
    /// 진행률 Task
    private var progressTask: Task<Void, Never>?
    
    /// 종목 데이터 캐시
    private(set) var stocksDataCache: [StockWithData] = []
    
    /// 분석용 데이터 캐시 (일별 가격 포함)
    private(set) var analysisDataCache: [StockAnalysisData] = []
    
    /// 벤치마크 데이터 캐시 (VOO, SGOV)
    private(set) var benchmarkDataCache: [String: StockAnalysisData] = [:]
    
    /// 동적 벤치마크 지표
    private(set) var dynamicBenchmarks: [DynamicBenchmark] = []
    
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
    
    // MARK: - 차트 데이터
    
    /// 과거 5년 성과 데이터
    private(set) var historicalData: PortfolioHistoricalData?
    
    /// 미래 10년 예측 데이터
    private(set) var projectionData: PortfolioProjectionResult?
    
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
    
    init(analysisService: StockAnalysisDataServiceProtocol = StockDataServiceFactory.createAnalysisService()) {
        self.analysisService = analysisService
    }
    
    // MARK: - Configuration
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSavedHoldings()
    }
    
    // MARK: - Data Loading
    
    /// 초기 데이터 로드 (viewState는 변경하지 않음)
    @MainActor
    func loadInitialData() async {
        isLoading = true
        
        do {
            allStocks = try await analysisService.fetchAllStocks()
            searchResults = allStocks
            // viewState는 여기서 변경하지 않음 - loadSavedHoldings()에서 처리
        } catch {
            errorMessage = error.localizedDescription
            // 에러가 발생해도 viewState는 유지 (allStocks 로드 실패 시에만 에러 표시)
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
            searchResults = try await analysisService.searchStocks(query: searchQuery)
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
        
        // 새 종목은 비중 0으로 시작
        let holding = PortfolioHoldingDisplay(
            ticker: stock.ticker,
            name: stock.displayName,
            subName: stock.subDisplayName,
            exchange: stock.exchange,
            sectorEmoji: stock.sectorEmoji,
            iconUrl: stock.iconUrl,
            stockType: stock.stockType,
            weight: 0.0
        )
        
        holdings.append(holding)
        
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
            // 빈 상태여도 편집 화면 유지 (빈 상태 안내는 PortfolioEditView에서 처리)
            analysisResult = nil
        }
        
        saveHoldings()
    }
    
    /// 비중 업데이트 (정수 퍼센트로 반올림)
    @MainActor
    func updateWeight(for ticker: String, weight: Double) {
        guard let index = holdings.firstIndex(where: { $0.ticker == ticker }) else {
            return
        }
        
        // 1% 단위로 반올림 (소수점 오차 방지)
        let roundedWeight = (weight * 100).rounded() / 100
        holdings[index].weight = max(0, min(1, roundedWeight))
        saveHoldings()
    }
    
    /// 비중 균등화 (정수 퍼센트로 반올림)
    @MainActor
    func equalizeWeights() {
        guard !holdings.isEmpty else { return }
        
        let count = holdings.count
        let baseWeight = Int(100 / count)  // 정수 퍼센트
        let remainder = 100 - (baseWeight * count)  // 나머지
        
        for i in holdings.indices {
            // 앞에서부터 나머지를 1%씩 분배
            let extra = i < remainder ? 1 : 0
            holdings[i].weight = Double(baseWeight + extra) / 100.0
        }
        
        saveHoldings()
    }
    
    /// 모든 비중 0%로 초기화
    @MainActor
    func resetAllWeights() {
        for i in holdings.indices {
            holdings[i].weight = 0
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
        isAnalysisCompleted = false
        analysisPhase = .fetchingData
        analysisProgress = 0
        
        // 가짜 진행률 타이머 시작 (자연스러운 UX)
        startProgressTimer()
        
        do {
            let tickers = holdings.map { $0.ticker }
            let holdingsData = holdings.map { (ticker: $0.ticker, weight: $0.weight) }
            
            // 분석용 데이터 가져오기 (일별 가격 포함)
            // 벤치마크(VOO, SGOV)도 함께 가져오기
            let benchmarkTickers = ["VOO", "SGOV"]
            let allTickers = tickers + benchmarkTickers.filter { !tickers.contains($0) }
            
            let allData = try await analysisService.fetchStocksWithAnalysisData(tickers: allTickers)
            
            // 포트폴리오 데이터와 벤치마크 데이터 분리
            analysisDataCache = allData.filter { tickers.contains($0.info.ticker) }
            stocksDataCache = analysisDataCache.map { $0.asStockWithData }
            
            // 벤치마크 데이터 캐시
            for benchmarkTicker in benchmarkTickers {
                if let data = allData.first(where: { $0.info.ticker == benchmarkTicker }) {
                    benchmarkDataCache[benchmarkTicker] = data
                }
            }
            
            // 동적 벤치마크 계산
            calculateDynamicBenchmarks()
            
            // 분석 실행 (상관계수 반영)
            analysisResult = PortfolioAnalyzer.analyzeWithDailyData(
                holdings: holdingsData,
                stocksData: analysisDataCache
            )
            
            // 배분 계산
            sectorAllocation = PortfolioAnalyzer.calculateSectorAllocation(
                holdings: holdingsData,
                stocksData: analysisDataCache
            )
            
            regionAllocation = PortfolioAnalyzer.calculateRegionAllocation(
                holdings: holdingsData,
                stocksData: analysisDataCache
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
                
                // 차트 데이터 계산
                calculateChartData(result: result)
            }
            
            // 실제 분석 완료 - 진행률 애니메이션이 끝날 때까지 대기
            isAnalysisCompleted = true
            await waitForProgressCompletion()
            
            viewState = .analyzed
            HapticService.shared.success()
            
        } catch {
            stopProgressTimer()
            errorMessage = error.localizedDescription
            viewState = .error(error.localizedDescription)
            HapticService.shared.error()
        }
        
        isLoading = false
    }
    
    /// 가짜 진행률 Task 시작
    @MainActor
    private func startProgressTimer() {
        progressTask?.cancel()
        
        progressTask = Task { @MainActor in
            // 총 예상 시간: 2.5초 (데이터 로딩이 길면 더 오래 걸림)
            // 0.05초마다 업데이트
            let updateInterval: UInt64 = 50_000_000  // 0.05초
            var elapsedTime = 0.0
            
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: updateInterval)
                elapsedTime += 0.05
                
                if self.isAnalysisCompleted {
                    // 분석 완료됨 - 빠르게 100%로 마무리
                    self.analysisProgress = min(1.0, self.analysisProgress + 0.08)
                    self.updatePhaseFromProgress()
                    
                    if self.analysisProgress >= 1.0 {
                        break
                    }
                } else {
                    // 분석 진행 중 - 천천히 증가 (최대 85%까지)
                    // 이징 함수로 자연스럽게 느려지는 효과
                    let targetProgress = min(0.85, elapsedTime / 3.0)  // 3초에 85%
                    let easedProgress = self.easeOutCubic(targetProgress / 0.85) * 0.85
                    self.analysisProgress = easedProgress
                    self.updatePhaseFromProgress()
                }
            }
        }
    }
    
    /// 진행률에 따라 단계 업데이트
    @MainActor
    private func updatePhaseFromProgress() {
        switch analysisProgress {
        case 0..<0.45:
            analysisPhase = .fetchingData
        case 0.45..<1.0:
            analysisPhase = .analyzing
        default:
            analysisPhase = .completed
        }
    }
    
    /// 이징 함수 (점점 느려지는 효과)
    private func easeOutCubic(_ x: Double) -> Double {
        return 1 - pow(1 - x, 3)
    }
    
    /// Task 정지
    @MainActor
    private func stopProgressTimer() {
        progressTask?.cancel()
        progressTask = nil
    }
    
    /// 진행률 애니메이션 완료 대기
    @MainActor
    private func waitForProgressCompletion() async {
        // 진행률이 100%가 될 때까지 대기
        while analysisProgress < 1.0 {
            try? await Task.sleep(nanoseconds: 50_000_000)  // 0.05초
        }
        // 완료 상태를 잠깐 보여주기
        try? await Task.sleep(nanoseconds: 200_000_000)  // 0.2초
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
    
    /// 빈 상태로 돌아가기 (holdings는 유지)
    @MainActor
    func backToEmpty() {
        viewState = .empty
    }
    
    /// 분석 결과 화면으로 돌아가기
    @MainActor
    func backToAnalyzed() {
        viewState = .analyzed
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
        analysisDataCache = []
        sharpeBreakdown = []
        volatilityBreakdown = []
        mddBreakdown = []
        cagrBreakdown = []
        dividendBreakdown = []
        historicalData = nil
        projectionData = nil
        viewState = .empty
        
        clearSavedHoldings()
    }
    
    // MARK: - Persistence
    
    /// 초기화 완료 여부
    private var isConfigured = false
    
    private func saveHoldings() {
        // UserDefaults에 간단히 저장 (프로토타입용)
        let data = holdings.map { ["ticker": $0.ticker, "weight": $0.weight] as [String: Any] }
        UserDefaults.standard.set(data, forKey: "portfolio_holdings")
    }
    
    private func loadSavedHoldings() {
        // 이미 초기화되었으면 중복 실행 방지
        guard !isConfigured else { return }
        isConfigured = true
        
        let savedData = UserDefaults.standard.array(forKey: "portfolio_holdings") as? [[String: Any]]
        
        // 저장된 데이터가 없어도 allStocks는 로드해야 함
        Task { @MainActor in
            await loadInitialData()
            
            // 저장된 holdings 복원
            if let data = savedData {
                await restoreHoldings(from: data)
            }
            
            // holdings 복원 후 최종 viewState 결정
            if !holdings.isEmpty {
                viewState = .editing
            }
        }
    }
    
    /// 저장된 holdings 복원 (캐시 → API 순서로 찾기)
    @MainActor
    private func restoreHoldings(from data: [[String: Any]]) async {
        // 캐시된 모든 종목 가져오기
        let cachedStocks = StockDataCache.shared.getAllCachedStocks()
        
        var restoredHoldings: [PortfolioHoldingDisplay] = []
        
        for dict in data {
            guard let ticker = dict["ticker"] as? String,
                  let weight = dict["weight"] as? Double else {
                continue
            }
            
            // 1. allStocks에서 찾기
            // 2. 캐시에서 찾기
            var stock = allStocks.first(where: { $0.ticker == ticker }) ??
                        cachedStocks.first(where: { $0.ticker == ticker })
            
            // 3. 캐시에도 없으면 API로 가져오기
            if stock == nil {
                if let polygonService = analysisService as? PolygonStockDataService {
                    stock = try? await polygonService.fetchTickerDetailsPublic(ticker: ticker)
                }
            }
            
            guard let stockInfo = stock else {
                continue
            }
            
            restoredHoldings.append(PortfolioHoldingDisplay(
                ticker: ticker,
                name: stockInfo.displayName,
                subName: stockInfo.subDisplayName,
                exchange: stockInfo.exchange,
                sectorEmoji: stockInfo.sectorEmoji,
                iconUrl: stockInfo.iconUrl,
                stockType: stockInfo.stockType,
                weight: weight
            ))
        }
        
        holdings = restoredHoldings
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
    
    // MARK: - Chart Data Calculation
    
    /// 차트 데이터 계산 (과거 성과 + 미래 예측)
    private func calculateChartData(result: PortfolioAnalysisResult) {
        let holdingsData = holdings.map { (ticker: $0.ticker, weight: $0.weight) }
        
        // 과거 5년 성과 계산
        historicalData = MonteCarloSimulator.calculateHistoricalPerformance(
            holdings: holdingsData,
            stocksData: stocksDataCache
        )
        
        // 미래 10년 예측 시뮬레이션
        // CAGR과 Volatility를 사용하여 몬테카를로 시뮬레이션
        projectionData = MonteCarloSimulator.projectPortfolio(
            cagr: result.cagrWithDividends,
            volatility: result.volatility,
            years: 10,
            simulationCount: 5000
        )
    }
    
    // MARK: - Helpers
    
    /// 특정 종목의 상세 데이터 가져오기
    func getStockData(for ticker: String) -> StockWithData? {
        stocksDataCache.first { $0.info.ticker == ticker }
    }
    
    // MARK: - Dynamic Benchmark
    
    /// 동적 벤치마크 계산 (VOO, SGOV)
    private func calculateDynamicBenchmarks() {
        let riskFreeRate = 0.035
        dynamicBenchmarks = []
        
        // VOO (S&P 500)
        if let vooData = benchmarkDataCache["VOO"] {
            let holdings = [(ticker: "VOO", weight: 1.0)]
            let cagr = PortfolioCalculator.calculatePortfolioCAGRWithDividends(
                holdings: holdings,
                stocksData: [vooData]
            )
            let volatility = vooData.annualVolatility
            let mdd = vooData.priceHistory.maxDrawdown
            let sharpe = volatility > 0 ? (cagr - riskFreeRate) / volatility : 0
            
            dynamicBenchmarks.append(DynamicBenchmark(
                ticker: "VOO",
                name: "S&P 500",
                emoji: "🇺🇸",
                cagr: cagr,
                volatility: volatility,
                mdd: mdd,
                sharpeRatio: sharpe,
                dividendYield: vooData.dividendHistory.dividendYield
            ))
        }
        
        // SGOV (미국 단기채권)
        if let sgovData = benchmarkDataCache["SGOV"] {
            let holdings = [(ticker: "SGOV", weight: 1.0)]
            let cagr = PortfolioCalculator.calculatePortfolioCAGRWithDividends(
                holdings: holdings,
                stocksData: [sgovData]
            )
            let volatility = sgovData.annualVolatility
            let mdd = sgovData.priceHistory.maxDrawdown
            let sharpe = volatility > 0 ? (cagr - riskFreeRate) / volatility : 0
            
            dynamicBenchmarks.append(DynamicBenchmark(
                ticker: "SGOV",
                name: "미국 단기채권",
                emoji: "🏦",
                cagr: cagr,
                volatility: volatility,
                mdd: mdd,
                sharpeRatio: sharpe,
                dividendYield: sgovData.dividendHistory.dividendYield
            ))
        }
    }
    
    /// 지표 타입별 벤치마크 BenchmarkMetric 배열 반환
    func benchmarks(for type: BenchmarkMetric.MetricType) -> [BenchmarkMetric] {
        // 동적 벤치마크 데이터가 있으면 사용, 없으면 기본값 사용
        guard !dynamicBenchmarks.isEmpty else {
            return BenchmarkMetric.benchmarks(for: type)
        }
        
        return dynamicBenchmarks.map { benchmark in
            let value: Double
            let formattedValue: String
            
            switch type {
            case .cagr:
                value = benchmark.cagr
                formattedValue = String(format: "%.1f%%", benchmark.cagr * 100)
            case .sharpeRatio:
                value = benchmark.sharpeRatio
                formattedValue = String(format: "%.2f", benchmark.sharpeRatio)
            case .volatility:
                value = benchmark.volatility
                formattedValue = String(format: "%.1f%%", benchmark.volatility * 100)
            case .mdd:
                value = benchmark.mdd
                formattedValue = String(format: "%.1f%%", benchmark.mdd * 100)
            }
            
            return BenchmarkMetric(
                name: benchmark.name,
                ticker: benchmark.ticker,
                emoji: benchmark.emoji,
                value: value,
                formattedValue: formattedValue
            )
        }
    }
}

// MARK: - Display Models

/// 포트폴리오 보유 종목 (UI 표시용)
struct PortfolioHoldingDisplay: Identifiable {
    let id = UUID()
    let ticker: String
    let name: String           // 메인 표시명 (ETF는 티커, 주식은 회사명)
    let subName: String        // 서브 표시명 (ETF는 풀네임, 주식은 티커)
    let exchange: StockExchange
    let sectorEmoji: String
    let iconUrl: String?
    let stockType: StockType
    var weight: Double
    
    var weightPercent: String {
        String(format: "%.1f%%", weight * 100)
    }
}

/// 동적 벤치마크 데이터 (VOO, SGOV 실제 데이터 기반)
struct DynamicBenchmark: Identifiable {
    let id = UUID()
    let ticker: String
    let name: String
    let emoji: String
    let cagr: Double
    let volatility: Double
    let mdd: Double
    let sharpeRatio: Double
    let dividendYield: Double
}

