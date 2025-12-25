//
//  PolygonStockDataService.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  Polygon.io API를 사용하는 실제 종목 데이터 서비스
//

import Foundation

/// Polygon.io API를 사용하는 종목 데이터 서비스
final class PolygonStockDataService: StockDataServiceProtocol {
    
    // MARK: - Singleton
    
    static let shared = PolygonStockDataService()
    
    // MARK: - Properties
    
    private let apiKey: String
    private let baseURL = "https://api.polygon.io"
    private let session: URLSession
    private let cache = StockDataCache.shared
    
    private(set) var lastUpdated: Date?
    
    /// 인기 종목 티커 목록 (프리로드용)
    /// ETF + 빅테크 주식 혼합
    private let popularTickers = [
        // ETF
        "SCHD", "QQQM", "SPLG", "JEPQ", "JEPI",
        // 빅테크
        "AAPL", "MSFT", "GOOGL", "AMZN", "NVDA", "META", "TSLA"
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
        
        await withTaskGroup(of: StockInfo?.self) { group in
            for ticker in tickersToFetch {
                group.addTask {
                    // 캐시에 iconUrl이 있으면 사용
                    if let cached = self.cache.getStock(ticker: ticker.ticker),
                       cached.isValid,
                       cached.stockInfo.iconUrl != nil {
                        return cached.stockInfo.toStockInfo()
                    }
                    
                    // 상세 정보 가져오기
                    do {
                        return try await self.fetchTickerDetails(ticker: ticker.ticker)
                    } catch {
                        // 실패 시 기본 정보만 반환
                        return ticker.toStockInfo()
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
        // 캐시 확인
        if let cached = cache.getStock(ticker: ticker),
           cached.isValid,
           let priceHistory = cached.priceHistory {
            return priceHistory.toPriceHistorySummary()
        }
        
        // 5년치 일별 데이터 요청
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .year, value: -5, to: endDate)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let endpoint = "/v2/aggs/ticker/\(ticker)/range/1/day/\(dateFormatter.string(from: startDate))/\(dateFormatter.string(from: endDate))"
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
        // 캐시 확인
        if let cached = cache.getStock(ticker: ticker),
           cached.isValid,
           let dividendHistory = cached.dividendHistory {
            return dividendHistory.toDividendHistorySummary()
        }
        
        // 최근 5년 배당 데이터 요청
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .year, value: -5, to: endDate)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let endpoint = "/v3/reference/dividends"
        var components = URLComponents(string: baseURL + endpoint)!
        components.queryItems = [
            URLQueryItem(name: "ticker", value: ticker),
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
    
    /// 배당 히스토리 계산
    private func calculateDividendHistory(from dividends: [PolygonDividend], ticker: String) -> DividendHistorySummary {
        guard !dividends.isEmpty else {
            return DividendHistorySummary(
                annualDividend: 0,
                dividendYield: 0,
                dividendGrowthRate: 0,
                exDividendDates: []
            )
        }
        
        // 최근 1년 배당금 합계
        let calendar = Calendar.current
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: Date())!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
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
        
        // 배당 성장률 (5년)
        var dividendGrowthRate = 0.0
        if dividends.count >= 2 {
            let sortedByDate = dividends.sorted { $0.exDividendDate > $1.exDividendDate }
            if let recent = sortedByDate.first,
               let oldest = sortedByDate.last,
               oldest.cashAmount > 0 {
                let years = Double(sortedByDate.count) / 4.0 // 분기배당 가정
                if years > 0 {
                    dividendGrowthRate = pow(recent.cashAmount / oldest.cashAmount, 1.0 / years) - 1
                }
            }
        }
        
        // 배당락일 목록
        let exDividendDates = recentDividends.map { $0.exDividendDate }
        
        return DividendHistorySummary(
            annualDividend: annualDividend,
            dividendYield: dividendYield,
            dividendGrowthRate: max(0, dividendGrowthRate), // 음수 방지
            exDividendDates: exDividendDates
        )
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

