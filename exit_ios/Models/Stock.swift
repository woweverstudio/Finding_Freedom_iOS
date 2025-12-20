//
//  Stock.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  포트폴리오 분석을 위한 종목 모델
//

import Foundation
import SwiftData

// MARK: - Exchange Types

/// 거래소 종류
enum StockExchange: String, Codable, CaseIterable {
    case NYSE = "NYSE"
    case NASDAQ = "NASDAQ"
    case KOSPI = "KOSPI"
    case KOSDAQ = "KOSDAQ"
    
    var displayName: String {
        switch self {
        case .NYSE: return "뉴욕증권거래소"
        case .NASDAQ: return "나스닥"
        case .KOSPI: return "코스피"
        case .KOSDAQ: return "코스닥"
        }
    }
    
    var isUS: Bool {
        self == .NYSE || self == .NASDAQ
    }
    
    var isKR: Bool {
        self == .KOSPI || self == .KOSDAQ
    }
    
    var flagEmoji: String {
        isUS ? "🇺🇸" : "🇰🇷"
    }
}

/// 통화 종류
enum StockCurrency: String, Codable {
    case USD = "USD"
    case KRW = "KRW"
    
    var symbol: String {
        switch self {
        case .USD: return "$"
        case .KRW: return "₩"
        }
    }
}

// MARK: - Stock Info

/// 종목 기본 정보
struct StockInfo: Identifiable, Codable, Hashable {
    var id: String { ticker }
    
    let ticker: String
    let name: String
    let nameKorean: String?
    let exchange: StockExchange
    let sector: String?
    let currency: StockCurrency
    
    /// 표시용 이름 (한국어 우선)
    var displayName: String {
        nameKorean ?? name
    }
    
    /// 짧은 표시용 이름 (최대 10자)
    var shortDisplayName: String {
        let fullName = displayName
        if fullName.count > 10 {
            return String(fullName.prefix(9)) + "…"
        }
        return fullName
    }
    
    /// 섹터 이모지
    var sectorEmoji: String {
        switch sector?.lowercased() {
        case "technology": return "💻"
        case "etf": return "📊"
        case "energy": return "🔋"
        case "healthcare": return "🏥"
        case "finance", "financial": return "🏦"
        case "consumer": return "🛒"
        default: return "📈"
        }
    }
}

// MARK: - Price Data

/// 가격 히스토리 요약 (Mock용 간소화 버전)
struct PriceHistorySummary: Codable {
    let startDate: String
    let startPrice: Double
    let currentPrice: Double
    let annualReturns: [Double]
    let dailyVolatility: Double
    let maxDrawdown: Double
    
    /// 총 수익률 (가격만)
    var totalPriceReturn: Double {
        (currentPrice - startPrice) / startPrice
    }
    
    /// 연평균 수익률 (CAGR)
    var cagr: Double {
        let years = Double(annualReturns.count)
        guard years > 0, startPrice > 0 else { return 0 }
        return pow(currentPrice / startPrice, 1.0 / years) - 1
    }
    
    /// 연간 변동성
    var annualVolatility: Double {
        dailyVolatility * sqrt(252)
    }
}

// MARK: - Dividend Data

/// 배당 히스토리 요약
struct DividendHistorySummary: Codable {
    let annualDividend: Double
    let dividendYield: Double
    let dividendGrowthRate: Double
    let exDividendDates: [String]
    
    /// 다음 배당락일 (예상)
    var nextExDividendDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let now = Date()
        return exDividendDates
            .compactMap { formatter.date(from: $0) }
            .filter { $0 > now }
            .min()
    }
    
    /// 배당 주기 (분기/반기/연간)
    var dividendFrequency: String {
        switch exDividendDates.count {
        case 0: return "배당 없음"
        case 1: return "연간"
        case 2: return "반기"
        case 4: return "분기"
        default: return "분기"
        }
    }
}

// MARK: - Stock with Full Data

/// 종목 + 가격/배당 데이터 통합
struct StockWithData: Identifiable {
    var id: String { info.ticker }
    
    let info: StockInfo
    let priceHistory: PriceHistorySummary
    let dividendHistory: DividendHistorySummary
    
    /// 배당 포함 총 수익률 (간소화 계산)
    var totalReturnWithDividends: Double {
        let years = Double(priceHistory.annualReturns.count)
        guard years > 0 else { return priceHistory.totalPriceReturn }
        
        // 배당 재투자 가정 간소화: 연간 배당률 × 년수 추가
        let cumulativeDividendReturn = dividendHistory.dividendYield * years
        return priceHistory.totalPriceReturn + cumulativeDividendReturn
    }
    
    /// 배당 포함 CAGR
    var cagrWithDividends: Double {
        let years = Double(priceHistory.annualReturns.count)
        guard years > 0 else { return 0 }
        return pow(1 + totalReturnWithDividends, 1.0 / years) - 1
    }
}

// MARK: - Portfolio Holding

/// 포트폴리오 내 보유 종목
@Model
final class PortfolioHolding {
    var id: UUID = UUID()
    var ticker: String = ""
    var weight: Double = 0  // 비중 (0.0 ~ 1.0)
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init() {}
    
    init(ticker: String, weight: Double) {
        self.id = UUID()
        self.ticker = ticker
        self.weight = weight
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// 비중 업데이트
    func updateWeight(_ newWeight: Double) {
        self.weight = max(0, min(1, newWeight))
        self.updatedAt = Date()
    }
}

// MARK: - JSON Decoding Helpers

/// Mock JSON 디코딩용 구조체
struct MockStockData: Codable {
    let stocks: [StockInfoDTO]
    let priceHistory: [String: PriceHistorySummary]
    let dividendHistory: [String: DividendHistorySummary]
    let lastUpdated: String
}

struct StockInfoDTO: Codable {
    let ticker: String
    let name: String
    let nameKorean: String?
    let exchange: String
    let sector: String?
    let currency: String
    
    func toStockInfo() -> StockInfo {
        StockInfo(
            ticker: ticker,
            name: name,
            nameKorean: nameKorean,
            exchange: StockExchange(rawValue: exchange) ?? .NASDAQ,
            sector: sector,
            currency: StockCurrency(rawValue: currency) ?? .USD
        )
    }
}

