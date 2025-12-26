//
//  PolygonStockDataService.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  Polygon.io API를 사용하는 실제 종목 데이터 서비스
//

import Foundation

/// Polygon.io API를 사용하는 종목 데이터 서비스
final class PolygonStockDataService: StockDataServiceProtocol, StockAnalysisDataServiceProtocol {
    
    // MARK: - Singleton
    
    static let shared = PolygonStockDataService()
    
    // MARK: - Properties
    
    private let apiKey: String
    private let baseURL = "https://api.polygon.io"
    private let session: URLSession
    private let cache = StockDataCache.shared
    
    private(set) var lastUpdated: Date?
    
    /// 티커 매핑 (데이터가 이상한 종목을 다른 종목 데이터로 대체)
    /// UI에서는 원래 티커로 표시되지만, 실제 데이터는 매핑된 티커 사용
    private let tickerDataMapping: [String: String] = [
        "SPYM": "VOO"  // SPYM 데이터 이상 → VOO 데이터 사용
    ]
    
    /// API 호출용 티커 반환 (매핑된 티커가 있으면 반환)
    private func apiTicker(for ticker: String) -> String {
        return tickerDataMapping[ticker.uppercased()] ?? ticker
    }
    
    /// 매핑된 티커인지 확인 (캐시 무시 판단용)
    private func isMappedTicker(_ ticker: String) -> Bool {
        return tickerDataMapping[ticker.uppercased()] != nil
    }
    
    /// 인기 종목 티커 목록 (프리로드용)
    /// ETF + 빅테크 주식 혼합
    private let popularTickers = [
        // ETF
        "SCHD", "QQQM", "SPYM", "JEPQ", "JEPI",
        // 빅테크
        "AAPL", "MSFT", "GOOGL", "AMZN", "NVDA", "META", "TSLA", "O"
    ]
    
    // MARK: - Initialization
    
    private init() {
        // AppConfig에서 API Key 가져오기
        self.apiKey = AppConfig.polygonAPIKey
        
        // URLSession 설정
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - StockDataServiceProtocol Implementation
    
    func fetchAllStocks() async throws -> [StockInfo] {
        // 캐시된 인기 종목들 반환
        var stocks: [StockInfo] = []
        
        for ticker in popularTickers {
            if let cached = cache.getStock(ticker: ticker), cached.isValid {
                stocks.append(cached.stockInfo.toStockInfo())
            } else {
                // 캐시가 없거나 만료된 경우 API에서 가져오기
                do {
                    if let stockInfo = try await fetchTickerDetails(ticker: ticker) {
                        stocks.append(stockInfo)
                    }
                } catch {
                    print("⚠️ Failed to fetch \(ticker): \(error.localizedDescription)")
                }
            }
        }
        
        lastUpdated = Date()
        return stocks
    }
    
    func searchStocks(query: String) async throws -> [StockInfo] {
        guard !query.isEmpty else {
            return try await fetchAllStocks()
        }
        
        // 캐시에서 먼저 검색
        let cachedResults = cache.searchCachedStocks(query: query)
        if !cachedResults.isEmpty {
            return cachedResults
        }
        
        // API 호출
        let endpoint = "/v3/reference/tickers"
        var components = URLComponents(string: baseURL + endpoint)!
        components.queryItems = [
            URLQueryItem(name: "search", value: query),
            URLQueryItem(name: "active", value: "true"),
            URLQueryItem(name: "market", value: "stocks"),
            URLQueryItem(name: "limit", value: "20"),
            URLQueryItem(name: "apiKey", value: apiKey)
        ]
        
        let response: PolygonTickersResponse = try await performRequest(url: components.url!)
        
        guard let results = response.results else {
            return []
        }
        
        // 각 티커의 상세 정보를 가져와서 iconUrl 포함
        var stocks: [StockInfo] = []
        
        // 병렬로 상세 정보 가져오기 (최대 10개만)
        let tickersToFetch = Array(results.prefix(10))
        
        // 캐시된 종목 미리 확인
        var cachedStocks: [String: StockInfo] = [:]
        var tickersNeedFetch: [PolygonTicker] = []
        
        for ticker in tickersToFetch {
            if let cached = cache.getStock(ticker: ticker.ticker),
               cached.isValid,
               cached.stockInfo.iconUrl != nil {
                cachedStocks[ticker.ticker] = cached.stockInfo.toStockInfo()
            } else {
                tickersNeedFetch.append(ticker)
            }
        }
        
        // 캐시된 종목 추가
        stocks.append(contentsOf: cachedStocks.values)
        
        // 캐시에 없는 종목만 병렬로 가져오기
        // 폴백용 StockInfo 미리 생성
        let fallbackStocks = Dictionary(uniqueKeysWithValues: tickersNeedFetch.map { ($0.ticker, $0.toStockInfo()) })
        
        await withTaskGroup(of: StockInfo?.self) { group in
            for ticker in tickersNeedFetch {
                let tickerSymbol = ticker.ticker
                let fallback = fallbackStocks[tickerSymbol]
                
                group.addTask {
                    do {
                        return try await self.fetchTickerDetails(ticker: tickerSymbol)
                    } catch {
                        // 실패 시 기본 정보만 반환
                        return fallback
                    }
                }
            }
            
            for await stockInfo in group {
                if let info = stockInfo {
                    stocks.append(info)
                }
            }
        }
        
        return stocks
    }
    
    func fetchPriceHistory(ticker: String) async throws -> PriceHistorySummary? {
        // 매핑된 티커가 아닌 경우에만 캐시 확인
        // (매핑된 티커는 이전에 잘못된 데이터가 캐시되어 있을 수 있음)
        if !isMappedTicker(ticker),
           let cached = cache.getStock(ticker: ticker),
           cached.isValid,
           let priceHistory = cached.priceHistory {
            return priceHistory.toPriceHistorySummary()
        }
        
        // API 호출용 티커 (매핑된 티커 사용)
        let queryTicker = apiTicker(for: ticker)
        
        // 5년치 일별 데이터 요청
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .year, value: -5, to: endDate)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let endpoint = "/v2/aggs/ticker/\(queryTicker)/range/1/day/\(dateFormatter.string(from: startDate))/\(dateFormatter.string(from: endDate))"
        var components = URLComponents(string: baseURL + endpoint)!
        components.queryItems = [
            URLQueryItem(name: "adjusted", value: "true"),
            URLQueryItem(name: "sort", value: "asc"),
            URLQueryItem(name: "apiKey", value: apiKey)
        ]
        
        let response: PolygonAggregatesResponse = try await performRequest(url: components.url!)
        
        guard let results = response.results, !results.isEmpty else {
            return nil
        }
        
        // 가격 히스토리 계산
        let priceHistory = calculatePriceHistory(from: results)
        
        // 캐시 업데이트
        updateCacheWithPriceHistory(ticker: ticker, priceHistory: priceHistory)
        
        return priceHistory
    }
    
    func fetchDividendHistory(ticker: String) async throws -> DividendHistorySummary? {
        // 매핑된 티커가 아닌 경우에만 캐시 확인
        if !isMappedTicker(ticker),
           let cached = cache.getStock(ticker: ticker),
           cached.isValid,
           let dividendHistory = cached.dividendHistory {
            return dividendHistory.toDividendHistorySummary()
        }
        
        // API 호출용 티커 (매핑된 티커 사용)
        let queryTicker = apiTicker(for: ticker)
        
        // 최근 5년 배당 데이터 요청
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .year, value: -5, to: endDate)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let endpoint = "/v3/reference/dividends"
        var components = URLComponents(string: baseURL + endpoint)!
        components.queryItems = [
            URLQueryItem(name: "ticker", value: queryTicker),
            URLQueryItem(name: "ex_dividend_date.gte", value: dateFormatter.string(from: startDate)),
            URLQueryItem(name: "order", value: "desc"),
            URLQueryItem(name: "limit", value: "100"),
            URLQueryItem(name: "apiKey", value: apiKey)
        ]
        
        let response: PolygonDividendsResponse = try await performRequest(url: components.url!)
        
        let results = response.results ?? []
        
        // 배당 히스토리 계산
        let dividendHistory = calculateDividendHistory(from: results, ticker: ticker)
        
        // 캐시 업데이트
        updateCacheWithDividendHistory(ticker: ticker, dividendHistory: dividendHistory)
        
        return dividendHistory
    }
    
    func fetchStocksWithData(tickers: [String]) async throws -> [StockWithData] {
        var result: [StockWithData] = []
        
        for ticker in tickers {
            do {
                // 종목 정보
                let stockInfo: StockInfo
                if let cached = cache.getStock(ticker: ticker), cached.isValid {
                    stockInfo = cached.stockInfo.toStockInfo()
                } else if let fetched = try await fetchTickerDetails(ticker: ticker) {
                    stockInfo = fetched
                } else {
                    continue
                }
                
                // 가격 히스토리
                guard let priceHistory = try await fetchPriceHistory(ticker: ticker) else {
                    continue
                }
                
                // 배당 히스토리
                let dividendHistory = try await fetchDividendHistory(ticker: ticker) ?? DividendHistorySummary(
                    annualDividend: 0,
                    dividendYield: 0,
                    dividendGrowthRate: 0,
                    exDividendDates: []
                )
                
                let stockWithData = StockWithData(
                    info: stockInfo,
                    priceHistory: priceHistory,
                    dividendHistory: dividendHistory
                )
                result.append(stockWithData)
                
            } catch {
                print("⚠️ Failed to fetch data for \(ticker): \(error.localizedDescription)")
            }
        }
        
        return result
    }
    
    /// 분석용 전체 데이터 가져오기 (일별 가격 포함)
    func fetchStocksWithAnalysisData(tickers: [String]) async throws -> [StockAnalysisData] {
        var result: [StockAnalysisData] = []
        
        for ticker in tickers {
            do {
                // 종목 정보
                let stockInfo: StockInfo
                if let cached = cache.getStock(ticker: ticker), cached.isValid {
                    stockInfo = cached.stockInfo.toStockInfo()
                } else if let fetched = try await fetchTickerDetails(ticker: ticker) {
                    stockInfo = fetched
                } else {
                    continue
                }
                
                // 일별 가격 데이터 + 가격 히스토리
                let (dailyPrices, priceHistory) = try await fetchDailyPricesAndHistory(ticker: ticker)
                
                guard !dailyPrices.isEmpty else {
                    continue
                }
                
                // 배당 히스토리
                let dividendHistory = try await fetchDividendHistory(ticker: ticker) ?? DividendHistorySummary(
                    annualDividend: 0,
                    dividendYield: 0,
                    dividendGrowthRate: 0,
                    exDividendDates: []
                )
                
                let stockAnalysisData = StockAnalysisData(
                    info: stockInfo,
                    dailyPrices: dailyPrices,
                    priceHistory: priceHistory,
                    dividendHistory: dividendHistory
                )
                result.append(stockAnalysisData)
                
            } catch {
                print("⚠️ Failed to fetch analysis data for \(ticker): \(error.localizedDescription)")
            }
        }
        
        return result
    }
    
    /// 일별 가격 데이터 + 히스토리 요약 함께 가져오기
    private func fetchDailyPricesAndHistory(ticker: String) async throws -> ([DailyPrice], PriceHistorySummary) {
        // API 호출용 티커 (매핑된 티커 사용)
        let queryTicker = apiTicker(for: ticker)
        
        // 5년치 일별 데이터 요청
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .year, value: -5, to: endDate)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let endpoint = "/v2/aggs/ticker/\(queryTicker)/range/1/day/\(dateFormatter.string(from: startDate))/\(dateFormatter.string(from: endDate))"
        var components = URLComponents(string: baseURL + endpoint)!
        components.queryItems = [
            URLQueryItem(name: "adjusted", value: "true"),
            URLQueryItem(name: "sort", value: "asc"),
            URLQueryItem(name: "apiKey", value: apiKey)
        ]
        
        let response: PolygonAggregatesResponse = try await performRequest(url: components.url!)
        
        guard let results = response.results, !results.isEmpty else {
            return ([], PriceHistorySummary(
                startDate: "",
                startPrice: 0,
                currentPrice: 0,
                annualReturns: [],
                dailyVolatility: 0,
                maxDrawdown: 0
            ))
        }
        
        // 일별 가격 데이터 변환
        let dailyPrices = results.map { agg in
            DailyPrice(date: agg.date, close: agg.close)
        }
        
        // 가격 히스토리 계산
        let priceHistory = calculatePriceHistory(from: results)
        
        // 캐시 업데이트
        updateCacheWithPriceHistory(ticker: ticker, priceHistory: priceHistory)
        
        return (dailyPrices, priceHistory)
    }
    
    // MARK: - Public Helper Methods
    
    /// 티커 상세 정보 가져오기 (외부에서 로고 URL 조회용)
    func fetchTickerDetailsPublic(ticker: String) async throws -> StockInfo? {
        return try await fetchTickerDetails(ticker: ticker)
    }
    
    // MARK: - Private Methods
    
    /// 티커 상세 정보 가져오기
    private func fetchTickerDetails(ticker: String) async throws -> StockInfo? {
        let endpoint = "/v3/reference/tickers/\(ticker)"
        var components = URLComponents(string: baseURL + endpoint)!
        components.queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey)
        ]
        
        let response: PolygonTickerDetailsResponse = try await performRequest(url: components.url!)
        
        guard let details = response.results else {
            return nil
        }
        
        // 디버그: branding 정보 확인
        print("📷 \(ticker) branding - icon: \(details.branding?.iconUrl ?? "nil"), logo: \(details.branding?.logoUrl ?? "nil")")
        
        let stockInfo = details.toStockInfo()
        
        // 캐시에 저장 (icon_url 우선 사용)
        let iconUrl = details.branding?.iconUrl
        let cachedInfo = CachedStockInfo(
            ticker: details.ticker,
            name: details.name,
            exchange: details.primaryExchange,
            sector: details.sicDescription,
            currency: details.currencyName,
            iconUrl: iconUrl,
            stockType: details.type,
            marketCap: details.marketCap,
            description: details.description
        )
        cache.saveStock(CachedStockData(
            stockInfo: cachedInfo,
            priceHistory: nil,
            dividendHistory: nil,
            cachedAt: Date()
        ))
        
        return stockInfo
    }
    
    /// API 요청 수행
    private func performRequest<T: Codable>(url: URL) async throws -> T {
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PolygonAPIError.networkError(NSError(domain: "Invalid response", code: -1))
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoder = JSONDecoder()
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw PolygonAPIError.decodingError(error)
                }
            case 401:
                throw PolygonAPIError.unauthorized
            case 404:
                throw PolygonAPIError.notFound
            case 429:
                throw PolygonAPIError.rateLimitExceeded
            default:
                throw PolygonAPIError.serverError(httpResponse.statusCode)
            }
        } catch let error as PolygonAPIError {
            throw error
        } catch {
            throw PolygonAPIError.networkError(error)
        }
    }
    
    /// 가격 히스토리 계산
    private func calculatePriceHistory(from aggregates: [PolygonAggregate]) -> PriceHistorySummary {
        guard let first = aggregates.first, let last = aggregates.last else {
            return PriceHistorySummary(
                startDate: "",
                startPrice: 0,
                currentPrice: 0,
                annualReturns: [],
                dailyVolatility: 0,
                maxDrawdown: 0
            )
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // 연간 수익률 계산
        var annualReturns: [Double] = []
        let calendar = Calendar.current
        var yearlyData: [Int: (first: Double, last: Double)] = [:]
        
        for agg in aggregates {
            let year = calendar.component(.year, from: agg.date)
            if yearlyData[year] == nil {
                yearlyData[year] = (agg.close, agg.close)
            } else {
                yearlyData[year]?.1 = agg.close
            }
        }
        
        let sortedYears = yearlyData.keys.sorted()
        for i in 1..<sortedYears.count {
            let prevYear = sortedYears[i - 1]
            let currYear = sortedYears[i]
            if let prev = yearlyData[prevYear], let curr = yearlyData[currYear] {
                let returnRate = (curr.1 - prev.1) / prev.1
                annualReturns.append(returnRate)
            }
        }
        
        // 일일 변동성 계산
        var dailyReturns: [Double] = []
        for i in 1..<aggregates.count {
            let prevClose = aggregates[i - 1].close
            let currClose = aggregates[i].close
            if prevClose > 0 {
                dailyReturns.append((currClose - prevClose) / prevClose)
            }
        }
        
        let dailyVolatility = standardDeviation(dailyReturns)
        
        // MDD 계산
        var peak = aggregates.first?.close ?? 0
        var maxDrawdown = 0.0
        
        for agg in aggregates {
            if agg.close > peak {
                peak = agg.close
            }
            let drawdown = (agg.close - peak) / peak
            if drawdown < maxDrawdown {
                maxDrawdown = drawdown
            }
        }
        
        return PriceHistorySummary(
            startDate: dateFormatter.string(from: first.date),
            startPrice: first.close,
            currentPrice: last.close,
            annualReturns: annualReturns,
            dailyVolatility: dailyVolatility,
            maxDrawdown: maxDrawdown
        )
    }
    
    /// 배당 히스토리 계산 (안정적인 성장률 계산)
    private func calculateDividendHistory(from dividends: [PolygonDividend], ticker: String) -> DividendHistorySummary {
        guard !dividends.isEmpty else {
            return DividendHistorySummary(
                annualDividend: 0,
                dividendYield: 0,
                dividendGrowthRate: 0,
                exDividendDates: []
            )
        }
        
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: Date())!
        
        // 최근 1년 배당금 합계
        let recentDividends = dividends.filter { dividend in
            if let date = dateFormatter.date(from: dividend.exDividendDate) {
                return date > oneYearAgo
            }
            return false
        }
        
        let annualDividend = recentDividends.reduce(0.0) { $0 + $1.cashAmount }
        
        // 배당 수익률 (현재 주가 필요 - 캐시에서 가져오기)
        var dividendYield = 0.0
        if let cached = cache.getStock(ticker: ticker),
           let priceHistory = cached.priceHistory,
           priceHistory.currentPrice > 0 {
            dividendYield = annualDividend / priceHistory.currentPrice
        }
        
        // 배당 성장률 계산
        let dividendGrowthRate = calculateDividendGrowthRate(
            dividends: dividends,
            ticker: ticker,
            calendar: calendar,
            dateFormatter: dateFormatter
        )
        
        // 배당락일 목록
        let exDividendDates = recentDividends.map { $0.exDividendDate }
        
        return DividendHistorySummary(
            annualDividend: annualDividend,
            dividendYield: dividendYield,
            dividendGrowthRate: dividendGrowthRate,
            exDividendDates: exDividendDates
        )
    }
    
    /// 배당 성장률 계산 (별도 함수로 분리)
    private func calculateDividendGrowthRate(
        dividends: [PolygonDividend],
        ticker: String,
        calendar: Calendar,
        dateFormatter: DateFormatter
    ) -> Double {
        // 1. 금리 연동 ETF (단기채, 머니마켓)는 성장률 0 처리
        // 이런 종목은 금리 변동에 따라 배당이 바뀌는 것이지 "성장"이 아님
        let interestRateLinkedETFs = [
            "SGOV", "SHV", "BIL", "SPTS", "VGSH", "GBIL", "TFLO", "USFR",  // 단기채
            "SHY", "IGSB", "SCHO", "FLOT", "FLRN", "SRLN",  // 단기/변동금리
            "MINT", "JPST", "GSY", "ICSH", "NEAR", "PULS"   // 초단기/머니마켓
        ]
        if interestRateLinkedETFs.contains(ticker.uppercased()) {
            return 0.0
        }
        
        // 2. 연도별 배당금 합계 및 횟수 계산
        var yearlyDividends: [Int: Double] = [:]
        var yearlyDividendCounts: [Int: Int] = [:]
        
        for dividend in dividends {
            if let date = dateFormatter.date(from: dividend.exDividendDate) {
                let year = calendar.component(.year, from: date)
                yearlyDividends[year, default: 0] += dividend.cashAmount
                yearlyDividendCounts[year, default: 0] += 1
            }
        }
        
        let currentYear = calendar.component(.year, from: Date())
        let sortedYears = yearlyDividends.keys.sorted()
        
        guard sortedYears.count >= 2 else { return 0.0 }
        
        // 3. 평균 배당 횟수 계산 (완전 연도 기준)
        let completeYearCounts = sortedYears.filter { $0 < currentYear }
            .compactMap { yearlyDividendCounts[$0] }
        let avgDividendCount = completeYearCounts.isEmpty ? 4.0 :
            Double(completeYearCounts.reduce(0, +)) / Double(completeYearCounts.count)
        
        // 4. 완전한 연도 판별 (평균의 70% 이상 배당이 있어야 완전한 연도)
        let minDividendsRequired = max(2, Int(avgDividendCount * 0.7))
        
        let completeYears = sortedYears.filter { year in
            // 현재 연도 제외 (아직 진행 중)
            guard year < currentYear else { return false }
            // 배당 횟수가 충분한 연도만 포함
            let count = yearlyDividendCounts[year] ?? 0
            return count >= minDividendsRequired
        }
        
        // 5. 최소 2개 완전 연도 필요
        guard completeYears.count >= 2,
              let firstYear = completeYears.first,
              let lastYear = completeYears.last,
              let firstYearDiv = yearlyDividends[firstYear],
              let lastYearDiv = yearlyDividends[lastYear],
              firstYearDiv > 0 else {
            return 0.0
        }
        
        let yearSpan = Double(lastYear - firstYear)
        guard yearSpan > 0 else { return 0.0 }
        
        // 6. CAGR 계산
        let rawGrowthRate = pow(lastYearDiv / firstYearDiv, 1.0 / yearSpan) - 1
        
        // 7. 합리적 범위로 제한 (-20% ~ +25%)
        // 대부분의 배당 성장주는 연 5~15% 성장
        // 25% 이상은 비정상적 (신규 배당 시작, 특별 배당 등)
        let clampedGrowthRate = min(max(rawGrowthRate, -0.20), 0.25)
        
        // 8. 음수는 0으로 표시 (UI에서 혼란 방지)
        return max(0, clampedGrowthRate)
    }
    
    /// 표준편차 계산
    private func standardDeviation(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
        return sqrt(variance)
    }
    
    /// 캐시에 가격 히스토리 업데이트
    private func updateCacheWithPriceHistory(ticker: String, priceHistory: PriceHistorySummary) {
        let cachedPriceHistory = CachedPriceHistory(
            startDate: priceHistory.startDate,
            startPrice: priceHistory.startPrice,
            currentPrice: priceHistory.currentPrice,
            annualReturns: priceHistory.annualReturns,
            dailyVolatility: priceHistory.dailyVolatility,
            maxDrawdown: priceHistory.maxDrawdown
        )
        
        if let cached = cache.getStock(ticker: ticker) {
            let updated = CachedStockData(
                stockInfo: cached.stockInfo,
                priceHistory: cachedPriceHistory,
                dividendHistory: cached.dividendHistory,
                cachedAt: Date()
            )
            cache.saveStock(updated)
        }
    }
    
    /// 캐시에 배당 히스토리 업데이트
    private func updateCacheWithDividendHistory(ticker: String, dividendHistory: DividendHistorySummary) {
        let cachedDividendHistory = CachedDividendHistory(
            annualDividend: dividendHistory.annualDividend,
            dividendYield: dividendHistory.dividendYield,
            dividendGrowthRate: dividendHistory.dividendGrowthRate,
            exDividendDates: dividendHistory.exDividendDates
        )
        
        if let cached = cache.getStock(ticker: ticker) {
            let updated = CachedStockData(
                stockInfo: cached.stockInfo,
                priceHistory: cached.priceHistory,
                dividendHistory: cachedDividendHistory,
                cachedAt: Date()
            )
            cache.saveStock(updated)
        }
    }
}

// MARK: - Stock Data Cache

/// 종목 데이터 로컬 캐시 관리자
final class StockDataCache {
    static let shared = StockDataCache()
    
    private let cacheKey = "polygon_stock_cache"
    private var memoryCache: [String: CachedStockData] = [:]
    
    private init() {
        loadFromDisk()
    }
    
    /// 종목 캐시 가져오기
    func getStock(ticker: String) -> CachedStockData? {
        if let cached = memoryCache[ticker] {
            // 캐시가 만료되었으면 삭제
            if !cached.isValid {
                memoryCache.removeValue(forKey: ticker)
                saveToDisk()
                return nil
            }
            return cached
        }
        return nil
    }
    
    /// 종목 캐시 저장
    func saveStock(_ data: CachedStockData) {
        memoryCache[data.stockInfo.ticker] = data
        saveToDisk()
    }
    
    /// 캐시에서 종목 검색
    func searchCachedStocks(query: String) -> [StockInfo] {
        let lowercasedQuery = query.lowercased()
        return memoryCache.values
            .filter { cached in
                cached.isValid && (
                    cached.stockInfo.ticker.lowercased().contains(lowercasedQuery) ||
                    cached.stockInfo.name.lowercased().contains(lowercasedQuery)
                )
            }
            .map { $0.stockInfo.toStockInfo() }
    }
    
    /// 모든 캐시된 종목
    func getAllCachedStocks() -> [StockInfo] {
        return memoryCache.values
            .filter { $0.isValid }
            .map { $0.stockInfo.toStockInfo() }
    }
    
    /// 만료된 캐시 정리
    func cleanExpiredCache() {
        let validCache = memoryCache.filter { $0.value.isValid }
        if validCache.count != memoryCache.count {
            memoryCache = validCache
            saveToDisk()
        }
    }
    
    /// 캐시 전체 삭제
    func clearAll() {
        memoryCache.removeAll()
        UserDefaults.standard.removeObject(forKey: cacheKey)
    }
    
    // MARK: - Persistence
    
    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(memoryCache)
            UserDefaults.standard.set(data, forKey: cacheKey)
        } catch {
            print("⚠️ Failed to save cache: \(error)")
        }
    }
    
    private func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return }
        
        do {
            memoryCache = try JSONDecoder().decode([String: CachedStockData].self, from: data)
            cleanExpiredCache() // 로드 시 만료된 캐시 정리
        } catch {
            print("⚠️ Failed to load cache: \(error)")
            memoryCache = [:]
        }
    }
}

// MARK: - Model Conversions

extension PolygonTicker {
    func toStockInfo() -> StockInfo {
        StockInfo(
            ticker: ticker,
            name: name,
            nameKorean: nil,
            exchange: StockExchange(rawValue: primaryExchange ?? "NASDAQ") ?? .NASDAQ,
            sector: type,
            currency: .USD,
            iconUrl: nil,
            stockType: StockType.from(type)
        )
    }
}

extension PolygonTickerDetails {
    func toStockInfo() -> StockInfo {
        // icon_url 우선 사용 (jpeg 형식)
        let iconUrl = branding?.iconUrl
        
        return StockInfo(
            ticker: ticker,
            name: name,
            nameKorean: nil,
            exchange: StockExchange(rawValue: primaryExchange ?? "NASDAQ") ?? .NASDAQ,
            sector: sicDescription,
            currency: .USD,
            iconUrl: iconUrl,
            stockType: StockType.from(type)
        )
    }
}

extension CachedStockInfo {
    func toStockInfo() -> StockInfo {
        StockInfo(
            ticker: ticker,
            name: name,
            nameKorean: nil,
            exchange: StockExchange(rawValue: exchange ?? "NASDAQ") ?? .NASDAQ,
            sector: sector,
            currency: .USD,
            iconUrl: iconUrl,
            stockType: StockType.from(stockType)
        )
    }
}

extension CachedPriceHistory {
    func toPriceHistorySummary() -> PriceHistorySummary {
        PriceHistorySummary(
            startDate: startDate,
            startPrice: startPrice,
            currentPrice: currentPrice,
            annualReturns: annualReturns,
            dailyVolatility: dailyVolatility,
            maxDrawdown: maxDrawdown
        )
    }
}

extension CachedDividendHistory {
    func toDividendHistorySummary() -> DividendHistorySummary {
        DividendHistorySummary(
            annualDividend: annualDividend,
            dividendYield: dividendYield,
            dividendGrowthRate: dividendGrowthRate,
            exDividendDates: exDividendDates
        )
    }
}

