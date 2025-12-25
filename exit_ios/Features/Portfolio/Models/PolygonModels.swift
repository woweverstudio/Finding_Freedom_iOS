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

// MARK: - Cached Stock Data (로컬 캐싱용)

/// 캐시된 종목 데이터
struct CachedStockData: Codable {
    let stockInfo: CachedStockInfo
    let priceHistory: CachedPriceHistory?
    let dividendHistory: CachedDividendHistory?
    let cachedAt: Date
    
    /// 캐시 유효 기간 (1주일)
    static let cacheValidityDuration: TimeInterval = 7 * 24 * 60 * 60
    
    /// 캐시가 유효한지 확인
    var isValid: Bool {
        Date().timeIntervalSince(cachedAt) < Self.cacheValidityDuration
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

