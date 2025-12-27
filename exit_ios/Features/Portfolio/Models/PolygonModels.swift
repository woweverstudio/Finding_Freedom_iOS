//
//  PolygonModels.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  Polygon.io API 응답 모델
//

import Foundation

// MARK: - Tickers Response (종목 검색)

/// Polygon.io /v3/reference/tickers 응답
struct PolygonTickersResponse: Codable {
    let results: [PolygonTicker]?
    let status: String
    let requestId: String?
    let count: Int?
    let nextUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case results, status, count
        case requestId = "request_id"
        case nextUrl = "next_url"
    }
}

/// 티커 정보
struct PolygonTicker: Codable {
    let ticker: String
    let name: String
    let market: String?
    let locale: String?
    let primaryExchange: String?
    let type: String?
    let active: Bool?
    let currencyName: String?
    let cik: String?
    let compositeFigi: String?
    let shareClassFigi: String?
    let lastUpdatedUtc: String?
    
    enum CodingKeys: String, CodingKey {
        case ticker, name, market, locale, type, active, cik
        case primaryExchange = "primary_exchange"
        case currencyName = "currency_name"
        case compositeFigi = "composite_figi"
        case shareClassFigi = "share_class_figi"
        case lastUpdatedUtc = "last_updated_utc"
    }
}

// MARK: - Ticker Events Response (티커 변경 이벤트)

/// Polygon.io /vX/reference/tickers/{id}/events 응답
/// 티커 변경(symbol renaming, rebranding) 이력 조회용
struct PolygonTickerEventsResponse: Codable {
    let results: PolygonTickerEventsResult?
    let status: String
    let requestId: String?
    
    enum CodingKeys: String, CodingKey {
        case results, status
        case requestId = "request_id"
    }
}

/// 티커 이벤트 결과
struct PolygonTickerEventsResult: Codable {
    let name: String?
    let compositeFigi: String?
    let cik: String?
    let events: [PolygonTickerEvent]?
    
    enum CodingKeys: String, CodingKey {
        case name, cik, events
        case compositeFigi = "composite_figi"
    }
}

/// 개별 티커 이벤트
struct PolygonTickerEvent: Codable {
    let type: String?              // "ticker_change"
    let date: String?              // 이벤트 발생일 (YYYY-MM-DD)
    let tickerChange: TickerChangeInfo?
    
    enum CodingKeys: String, CodingKey {
        case type, date
        case tickerChange = "ticker_change"
    }
}

/// 티커 변경 상세 정보
struct TickerChangeInfo: Codable {
    let ticker: String?            // 변경 후 티커 (현재 티커)
}

// MARK: - Ticker Details Response (종목 상세)

/// Polygon.io /v3/reference/tickers/{ticker} 응답
struct PolygonTickerDetailsResponse: Codable {
    let results: PolygonTickerDetails?
    let status: String
    let requestId: String?
    
    enum CodingKeys: String, CodingKey {
        case results, status
        case requestId = "request_id"
    }
}

/// 티커 상세 정보
struct PolygonTickerDetails: Codable {
    let ticker: String
    let name: String
    let market: String?
    let locale: String?
    let primaryExchange: String?
    let type: String?
    let active: Bool?
    let currencyName: String?
    let cik: String?
    let compositeFigi: String?
    let shareClassFigi: String?
    let marketCap: Double?
    let phoneNumber: String?
    let address: PolygonAddress?
    let description: String?
    let sicCode: String?
    let sicDescription: String?
    let tickerRoot: String?
    let homepageUrl: String?
    let totalEmployees: Int?
    let listDate: String?
    let branding: PolygonBranding?
    let shareClassSharesOutstanding: Double?
    let weightedSharesOutstanding: Double?
    let roundLot: Int?
    
    enum CodingKeys: String, CodingKey {
        case ticker, name, market, locale, type, active, cik, address, description
        case primaryExchange = "primary_exchange"
        case currencyName = "currency_name"
        case compositeFigi = "composite_figi"
        case shareClassFigi = "share_class_figi"
        case marketCap = "market_cap"
        case phoneNumber = "phone_number"
        case sicCode = "sic_code"
        case sicDescription = "sic_description"
        case tickerRoot = "ticker_root"
        case homepageUrl = "homepage_url"
        case totalEmployees = "total_employees"
        case listDate = "list_date"
        case branding
        case shareClassSharesOutstanding = "share_class_shares_outstanding"
        case weightedSharesOutstanding = "weighted_shares_outstanding"
        case roundLot = "round_lot"
    }
}

/// 주소 정보
struct PolygonAddress: Codable {
    let address1: String?
    let city: String?
    let state: String?
    let postalCode: String?
    
    enum CodingKeys: String, CodingKey {
        case address1, city, state
        case postalCode = "postal_code"
    }
}

/// 브랜딩 정보 (로고 등)
struct PolygonBranding: Codable {
    let logoUrl: String?
    let iconUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case logoUrl = "logo_url"
        case iconUrl = "icon_url"
    }
}

// MARK: - Aggregates Response (가격 히스토리)

/// Polygon.io /v2/aggs/ticker/{ticker}/range/{multiplier}/{timespan}/{from}/{to} 응답
struct PolygonAggregatesResponse: Codable {
    let ticker: String?
    let queryCount: Int?
    let resultsCount: Int?
    let adjusted: Bool?
    let results: [PolygonAggregate]?
    let status: String
    let requestId: String?
    let count: Int?
    
    enum CodingKeys: String, CodingKey {
        case ticker, adjusted, results, status, count
        case queryCount = "queryCount"
        case resultsCount = "resultsCount"
        case requestId = "request_id"
    }
}

/// OHLCV 데이터
struct PolygonAggregate: Codable {
    let open: Double       // o
    let high: Double       // h
    let low: Double        // l
    let close: Double      // c
    let volume: Double     // v
    let volumeWeighted: Double?  // vw
    let timestamp: Int64   // t (milliseconds)
    let transactions: Int? // n
    
    enum CodingKeys: String, CodingKey {
        case open = "o"
        case high = "h"
        case low = "l"
        case close = "c"
        case volume = "v"
        case volumeWeighted = "vw"
        case timestamp = "t"
        case transactions = "n"
    }
    
    /// timestamp를 Date로 변환
    var date: Date {
        Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
    }
}

// MARK: - Dividends Response (배당 데이터)

/// Polygon.io /v3/reference/dividends 응답
struct PolygonDividendsResponse: Codable {
    let results: [PolygonDividend]?
    let status: String
    let requestId: String?
    let nextUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case results, status
        case requestId = "request_id"
        case nextUrl = "next_url"
    }
}

/// 배당 정보
struct PolygonDividend: Codable {
    let ticker: String
    let cashAmount: Double
    let currency: String?
    let declarationDate: String?
    let exDividendDate: String
    let frequency: Int?
    let payDate: String?
    let recordDate: String?
    let dividendType: String?
    
    enum CodingKeys: String, CodingKey {
        case ticker, currency, frequency
        case cashAmount = "cash_amount"
        case declarationDate = "declaration_date"
        case exDividendDate = "ex_dividend_date"
        case payDate = "pay_date"
        case recordDate = "record_date"
        case dividendType = "dividend_type"
    }
}

// MARK: - Data Quality (데이터 품질 검증)

/// 데이터 품질 상태
/// 티커 변경 등으로 인한 데이터 신뢰성 문제를 추적
enum DataQuality: Codable, Equatable {
    case reliable                        // 신뢰할 수 있음 (5년 데이터 완전)
    case merged(previousTicker: String)  // FIGI로 이전 티커 데이터 병합됨
    case limited(reason: String)         // 제한적 (이유 포함)
    case unreliable(reason: String)      // 신뢰 불가
    
    /// 사용자에게 표시할 메시지
    var displayMessage: String? {
        switch self {
        case .reliable:
            return nil
        case .merged(let previousTicker):
            return "\(previousTicker)에서 티커가 변경됨"
        case .limited(let reason):
            return reason
        case .unreliable(let reason):
            return "⚠️ \(reason)"
        }
    }
    
    /// 데이터가 분석에 사용 가능한지
    var isUsable: Bool {
        switch self {
        case .reliable, .merged, .limited:
            return true
        case .unreliable:
            return false
        }
    }
    
    /// 경고 표시가 필요한지
    var needsWarning: Bool {
        switch self {
        case .reliable, .merged:
            return false
        case .limited, .unreliable:
            return true
        }
    }
}

/// 티커 이력 정보 (Ticker Events API 기반)
struct TickerHistory: Codable, Equatable {
    let currentTicker: String
    let previousTickers: [String]       // 과거 티커들
    let tickerChangeDate: String?       // 티커 변경일 (알 수 있는 경우)
    
    /// 티커 변경이 있었는지
    var hasTickerChange: Bool {
        !previousTickers.isEmpty
    }
    
    /// 표시용 문자열 (예: "FB → META")
    var displayString: String? {
        guard let previousTicker = previousTickers.first else { return nil }
        if let changeDate = tickerChangeDate {
            return "\(previousTicker) → \(currentTicker) (\(changeDate))"
        }
        return "\(previousTicker) → \(currentTicker)"
    }
}

/// 데이터 유효성 검사 결과
struct DataValidationResult {
    let quality: DataQuality
    let validStartDate: Date?           // 유효 데이터 시작일
    let validEndDate: Date?             // 유효 데이터 종료일
    let issues: [DataValidationIssue]   // 발견된 문제점
    let tickerHistory: TickerHistory?   // 티커 변경 이력 (있는 경우)
    
    /// 유효 데이터 기간 (년 단위)
    var validDataYears: Double? {
        guard let start = validStartDate, let end = validEndDate else { return nil }
        return end.timeIntervalSince(start) / (365.25 * 24 * 60 * 60)
    }
}

/// 데이터 검증 중 발견된 문제
enum DataValidationIssue: Codable, Equatable {
    case zeroStartPrice                  // 시작 가격이 0
    case extremeVolatility(Double)       // 비정상적으로 높은 변동성 (100%+)
    case extremeCAGR(Double)             // 비정상적인 CAGR (100%+ 또는 -80% 미만)
    case extremeMDD(Double)              // 비정상적인 MDD (-90% 미만)
    case insufficientData(years: Double) // 데이터 기간 부족 (3년 미만)
    case tickerChange(from: String)      // 티커 변경 감지
    
    var description: String {
        switch self {
        case .zeroStartPrice:
            return "시작 가격이 0입니다"
        case .extremeVolatility(let vol):
            return "변동성이 비정상적으로 높습니다 (\(String(format: "%.0f", vol * 100))%)"
        case .extremeCAGR(let cagr):
            return "연평균 수익률이 비정상적입니다 (\(String(format: "%.0f", cagr * 100))%)"
        case .extremeMDD(let mdd):
            return "MDD가 비정상적으로 큽니다 (\(String(format: "%.0f", mdd * 100))%)"
        case .insufficientData(let years):
            return "데이터 기간이 부족합니다 (\(String(format: "%.1f", years))년)"
        case .tickerChange(let from):
            return "\(from)에서 티커가 변경되었습니다"
        }
    }
}

// MARK: - Cached Stock Data (로컬 캐싱용)

/// 캐시된 종목 데이터
struct CachedStockData: Codable {
    let stockInfo: CachedStockInfo
    let priceHistory: CachedPriceHistory?
    let dividendHistory: CachedDividendHistory?
    let cachedAt: Date
    
    // 데이터 품질 정보
    let dataQuality: DataQuality?
    let tickerHistory: TickerHistory?
    
    /// 캐시 유효 기간 (1주일)
    static let cacheValidityDuration: TimeInterval = 7 * 24 * 60 * 60
    
    /// 캐시가 유효한지 확인
    var isValid: Bool {
        Date().timeIntervalSince(cachedAt) < Self.cacheValidityDuration
    }
    
    /// 기존 캐시와의 호환성을 위한 이니셜라이저
    init(stockInfo: CachedStockInfo, priceHistory: CachedPriceHistory?, dividendHistory: CachedDividendHistory?, cachedAt: Date, dataQuality: DataQuality? = nil, tickerHistory: TickerHistory? = nil) {
        self.stockInfo = stockInfo
        self.priceHistory = priceHistory
        self.dividendHistory = dividendHistory
        self.cachedAt = cachedAt
        self.dataQuality = dataQuality
        self.tickerHistory = tickerHistory
    }
}

/// 캐시된 종목 기본 정보
struct CachedStockInfo: Codable {
    let ticker: String
    let name: String
    let exchange: String?
    let sector: String?
    let currency: String?
    let iconUrl: String?
    let stockType: String?
    let marketCap: Double?
    let description: String?
}

/// 캐시된 가격 히스토리
struct CachedPriceHistory: Codable {
    let startDate: String
    let startPrice: Double
    let currentPrice: Double
    let annualReturns: [Double]
    let dailyVolatility: Double
    let maxDrawdown: Double
}

/// 캐시된 배당 히스토리
struct CachedDividendHistory: Codable {
    let annualDividend: Double
    let dividendYield: Double
    let dividendGrowthRate: Double
    let exDividendDates: [String]
}

// MARK: - Error Types

/// Polygon API 에러
enum PolygonAPIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case rateLimitExceeded
    case unauthorized
    case notFound
    case serverError(Int)
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다"
        case .networkError(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        case .decodingError(let error):
            return "데이터 파싱 오류: \(error.localizedDescription)"
        case .rateLimitExceeded:
            return "API 요청 한도를 초과했습니다. 잠시 후 다시 시도해주세요."
        case .unauthorized:
            return "API 인증에 실패했습니다"
        case .notFound:
            return "요청한 데이터를 찾을 수 없습니다"
        case .serverError(let code):
            return "서버 오류 (\(code))"
        case .noData:
            return "데이터가 없습니다"
        }
    }
}

