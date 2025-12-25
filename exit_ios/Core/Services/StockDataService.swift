//
//  StockDataService.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  종목 데이터 서비스 - Mock 데이터 또는 실제 Supabase 데이터 제공
//

import Foundation

// MARK: - Stock Data Service Protocol

/// 종목 데이터 서비스 프로토콜
/// 실제 구현체를 쉽게 교체할 수 있도록 프로토콜로 정의
protocol StockDataServiceProtocol {
    /// 모든 종목 목록 가져오기
    func fetchAllStocks() async throws -> [StockInfo]
    
    /// 종목 검색
    func searchStocks(query: String) async throws -> [StockInfo]
    
    /// 특정 종목의 가격 히스토리 가져오기
    func fetchPriceHistory(ticker: String) async throws -> PriceHistorySummary?
    
    /// 특정 종목의 배당 히스토리 가져오기
    func fetchDividendHistory(ticker: String) async throws -> DividendHistorySummary?
    
    /// 여러 종목의 전체 데이터 가져오기
    func fetchStocksWithData(tickers: [String]) async throws -> [StockWithData]
    
    /// 마지막 업데이트 시간
    var lastUpdated: Date? { get }
}

// MARK: - Mock Stock Data Service

/// Mock 데이터를 사용하는 서비스 (프로토타입/테스트용)
final class MockStockDataService: StockDataServiceProtocol {
    
    // MARK: - Singleton
    
    static let shared = MockStockDataService()
    
    // MARK: - Properties
    
    private var mockData: MockStockData?
    private(set) var lastUpdated: Date?
    
    // MARK: - Initialization
    
    private init() {
        loadMockData()
    }
    
    // MARK: - Data Loading
    
    private func loadMockData() {
        guard let url = Bundle.main.url(forResource: "mock_stocks", withExtension: "json") else {
            print("❌ mock_stocks.json 파일을 찾을 수 없습니다")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            mockData = try JSONDecoder().decode(MockStockData.self, from: data)
            
            let formatter = ISO8601DateFormatter()
            if let dateString = mockData?.lastUpdated {
                lastUpdated = formatter.date(from: dateString)
            }
            
            print("✅ Mock 데이터 로드 완료: \(mockData?.stocks.count ?? 0)개 종목")
        } catch {
            print("❌ Mock 데이터 파싱 오류: \(error)")
        }
    }
    
    // MARK: - Protocol Implementation
    
    func fetchAllStocks() async throws -> [StockInfo] {
        // 네트워크 지연 시뮬레이션
        try await Task.sleep(nanoseconds: 300_000_000)  // 0.3초
        
        guard let data = mockData else {
            throw StockDataError.dataNotLoaded
        }
        
        return data.stocks.map { $0.toStockInfo() }
    }
    
    func searchStocks(query: String) async throws -> [StockInfo] {
        let allStocks = try await fetchAllStocks()
        
        guard !query.isEmpty else {
            return allStocks
        }
        
        let lowercasedQuery = query.lowercased()
        
        return allStocks.filter { stock in
            stock.ticker.lowercased().contains(lowercasedQuery) ||
            stock.name.lowercased().contains(lowercasedQuery) ||
            (stock.nameKorean?.lowercased().contains(lowercasedQuery) ?? false)
        }
    }
    
    func fetchPriceHistory(ticker: String) async throws -> PriceHistorySummary? {
        try await Task.sleep(nanoseconds: 100_000_000)  // 0.1초
        return mockData?.priceHistory[ticker]
    }
    
    func fetchDividendHistory(ticker: String) async throws -> DividendHistorySummary? {
        try await Task.sleep(nanoseconds: 100_000_000)  // 0.1초
        return mockData?.dividendHistory[ticker]
    }
    
    func fetchStocksWithData(tickers: [String]) async throws -> [StockWithData] {
        try await Task.sleep(nanoseconds: 500_000_000)  // 0.5초
        
        guard let data = mockData else {
            throw StockDataError.dataNotLoaded
        }
        
        var result: [StockWithData] = []
        
        for ticker in tickers {
            guard let stockDTO = data.stocks.first(where: { $0.ticker == ticker }),
                  let priceHistory = data.priceHistory[ticker],
                  let dividendHistory = data.dividendHistory[ticker] else {
                continue
            }
            
            let stockWithData = StockWithData(
                info: stockDTO.toStockInfo(),
                priceHistory: priceHistory,
                dividendHistory: dividendHistory
            )
            result.append(stockWithData)
        }
        
        return result
    }
}

// MARK: - Supabase Stock Data Service (Future Implementation)

/// Supabase를 사용하는 실제 서비스 (추후 구현)
final class SupabaseStockDataService: StockDataServiceProtocol {
    
    // MARK: - Singleton
    
    static let shared = SupabaseStockDataService()
    
    // MARK: - Properties
    
    private(set) var lastUpdated: Date?
    
    // TODO: Supabase 클라이언트 추가
    // private let supabase: SupabaseClient
    
    // MARK: - Initialization
    
    private init() {
        // TODO: Supabase 초기화
    }
    
    // MARK: - Protocol Implementation
    
    func fetchAllStocks() async throws -> [StockInfo] {
        // TODO: Supabase에서 데이터 가져오기
        throw StockDataError.notImplemented
    }
    
    func searchStocks(query: String) async throws -> [StockInfo] {
        // TODO: Supabase에서 검색
        throw StockDataError.notImplemented
    }
    
    func fetchPriceHistory(ticker: String) async throws -> PriceHistorySummary? {
        // TODO: Supabase에서 가격 히스토리 가져오기
        throw StockDataError.notImplemented
    }
    
    func fetchDividendHistory(ticker: String) async throws -> DividendHistorySummary? {
        // TODO: Supabase에서 배당 히스토리 가져오기
        throw StockDataError.notImplemented
    }
    
    func fetchStocksWithData(tickers: [String]) async throws -> [StockWithData] {
        // TODO: Supabase에서 전체 데이터 가져오기
        throw StockDataError.notImplemented
    }
}

// MARK: - Stock Data Service Factory

/// 서비스 팩토리 - 환경에 따라 적절한 서비스 반환
enum StockDataServiceFactory {
    
    /// 사용할 서비스 종류
    enum ServiceType {
        case mock       // Mock 데이터 (테스트용)
        case polygon    // Polygon.io API (실제 데이터)
    }
    
    /// 현재 사용할 서비스 타입
    static var currentServiceType: ServiceType = .polygon
    
    /// 현재 환경에 맞는 서비스 반환
    static func createService() -> StockDataServiceProtocol {
        switch currentServiceType {
        case .mock:
            return MockStockDataService.shared
        case .polygon:
            return PolygonStockDataService.shared
        }
    }
    
    /// Mock 서비스로 전환 (테스트용)
    static func useMockService() {
        currentServiceType = .mock
    }
    
    /// Polygon 서비스로 전환
    static func usePolygonService() {
        currentServiceType = .polygon
    }
}

// MARK: - Errors

enum StockDataError: LocalizedError {
    case dataNotLoaded
    case stockNotFound(ticker: String)
    case networkError(underlying: Error)
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .dataNotLoaded:
            return "데이터를 불러올 수 없습니다"
        case .stockNotFound(let ticker):
            return "\(ticker) 종목을 찾을 수 없습니다"
        case .networkError(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        case .notImplemented:
            return "아직 구현되지 않은 기능입니다"
        }
    }
}

// MARK: - Local Cache Manager (Future)

/// 로컬 캐시 관리자 (추후 구현)
/// SwiftData를 사용하여 종목 데이터를 로컬에 캐싱
final class StockLocalCacheManager {
    
    static let shared = StockLocalCacheManager()
    
    private init() {}
    
    /// 캐시 유효 기간 (7일)
    private let cacheValidityDuration: TimeInterval = 7 * 24 * 60 * 60
    
    /// 캐시가 유효한지 확인
    func isCacheValid() -> Bool {
        guard let lastSync = UserDefaults.standard.object(forKey: "lastStockDataSync") as? Date else {
            return false
        }
        return Date().timeIntervalSince(lastSync) < cacheValidityDuration
    }
    
    /// 마지막 동기화 시간 업데이트
    func updateLastSyncTime() {
        UserDefaults.standard.set(Date(), forKey: "lastStockDataSync")
    }
    
    // TODO: SwiftData를 사용한 캐시 저장/조회 구현
}

