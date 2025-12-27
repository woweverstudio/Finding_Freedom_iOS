//
//  StockModels.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  포트폴리오 분석을 위한 종목 모델
//

import Foundation
import SwiftData

// MARK: - Exchange Types

/// 거래소 종류 (미국 시장만 지원)
enum StockExchange: String, Codable, CaseIterable {
    case NYSE = "NYSE"
    case NASDAQ = "NASDAQ"
    case AMEX = "AMEX"
    case BATS = "BATS"
    case ARCA = "ARCA"
    case OTC = "OTC"
    
    var displayName: String {
        switch self {
        case .NYSE: return "뉴욕증권거래소"
        case .NASDAQ: return "나스닥"
        case .AMEX: return "아메리칸증권거래소"
        case .BATS: return "BATS 거래소"
        case .ARCA: return "NYSE Arca"
        case .OTC: return "장외거래"
        }
    }
    
    var shortName: String {
        rawValue
    }
    
    var flagEmoji: String {
        "🇺🇸"
    }
}

/// 통화 종류 (USD만 지원)
enum StockCurrency: String, Codable {
    case USD = "USD"
    
    var symbol: String {
        "$"
    }
}

/// 종목 유형
enum StockType: String, Codable {
    case commonStock = "CS"      // 보통주
    case etf = "ETF"             // ETF
    case etn = "ETN"             // ETN
    case fund = "FUND"           // 펀드
    case adr = "ADRC"            // ADR
    case other = "OTHER"         // 기타
    
    /// 표시용 라벨
    var displayLabel: String {
        switch self {
        case .commonStock: return "주식"
        case .etf: return "ETF"
        case .etn: return "ETN"
        case .fund: return "펀드"
        case .adr: return "ADR"
        case .other: return ""
        }
    }
    
    /// 짧은 라벨 (배지용)
    var badge: String? {
        switch self {
        case .commonStock: return nil
        case .etf: return "ETF"
        case .etn: return "ETN"
        case .fund: return "펀드"
        case .adr: return "ADR"
        case .other: return nil
        }
    }
    
    /// ETF 계열인지 확인
    var isETFType: Bool {
        self == .etf || self == .etn
    }
    
    /// API type 문자열로부터 생성
    static func from(_ type: String?) -> StockType {
        guard let type = type?.uppercased() else { return .other }
        switch type {
        case "CS": return .commonStock
        case "ETF": return .etf
        case "ETN": return .etn
        case "FUND": return .fund
        case "ADRC": return .adr
        default: return .other
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
    let iconUrl: String?
    let stockType: StockType
    
    init(ticker: String, name: String, nameKorean: String? = nil, exchange: StockExchange, sector: String? = nil, currency: StockCurrency, iconUrl: String? = nil, stockType: StockType = .other) {
        self.ticker = ticker
        self.name = name
        self.nameKorean = nameKorean
        self.exchange = exchange
        self.sector = sector
        self.currency = currency
        self.iconUrl = iconUrl
        self.stockType = stockType
    }
    
    /// 표시용 이름 (ETF는 티커, 주식은 회사명)
    var displayName: String {
        if stockType.isETFType {
            return ticker
        }
        return nameKorean ?? name
    }
    
    /// 서브 표시용 (타입 + 설명)
    /// ETF: "ETF · Schwab U.S. Dividend Equity ETF"
    /// 주식: "AAPL"
    var subDisplayName: String {
        if let badge = stockType.badge {
            if stockType.isETFType {
                return "\(badge) · \(name)"
            }
            return "\(badge) · \(ticker)"
        }
        return ticker
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

// MARK: - Daily Price Data

/// 일별 가격 데이터 (분석용)
struct DailyPrice: Codable {
    let date: Date
    let close: Double
    
    /// 일별 수익률 계산용
    func dailyReturn(from previousClose: Double) -> Double {
        guard previousClose > 0 else { return 0 }
        return (close - previousClose) / previousClose
    }
}

// MARK: - Stock with Full Data (Legacy Support)

/// 종목 + 가격/배당 데이터 통합 (기존 호환성 유지)
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

// MARK: - Stock Analysis Data

/// 종목 분석용 전체 데이터 (일별 가격 포함)
struct StockAnalysisData: Identifiable {
    var id: String { info.ticker }
    
    let info: StockInfo
    let dailyPrices: [DailyPrice]       // 일별 가격 (상관계수, MDD용)
    let priceHistory: PriceHistorySummary
    let dividendHistory: DividendHistorySummary
    
    // 데이터 품질 정보 (티커 변경 추적)
    let dataQuality: DataQuality
    let tickerHistory: TickerHistory?
    
    /// 기본 이니셜라이저 (기존 호환성)
    init(
        info: StockInfo,
        dailyPrices: [DailyPrice],
        priceHistory: PriceHistorySummary,
        dividendHistory: DividendHistorySummary,
        dataQuality: DataQuality = .reliable,
        tickerHistory: TickerHistory? = nil
    ) {
        self.info = info
        self.dailyPrices = dailyPrices
        self.priceHistory = priceHistory
        self.dividendHistory = dividendHistory
        self.dataQuality = dataQuality
        self.tickerHistory = tickerHistory
    }
    
    /// 일별 수익률 배열 계산
    var dailyReturns: [Double] {
        guard dailyPrices.count > 1 else { return [] }
        var returns: [Double] = []
        for i in 1..<dailyPrices.count {
            let prevClose = dailyPrices[i - 1].close
            let currClose = dailyPrices[i].close
            if prevClose > 0 {
                returns.append((currClose - prevClose) / prevClose)
            }
        }
        return returns
    }
    
    /// 연간 변동성 (일별 수익률 기반)
    var annualVolatility: Double {
        let returns = dailyReturns
        guard !returns.isEmpty else { return 0 }
        let mean = returns.reduce(0, +) / Double(returns.count)
        let variance = returns.reduce(0) { $0 + pow($1 - mean, 2) } / Double(returns.count)
        return sqrt(variance) * sqrt(252)
    }
    
    /// 배당 포함 총 수익률
    var totalReturnWithDividends: Double {
        let years = Double(priceHistory.annualReturns.count)
        guard years > 0 else { return priceHistory.totalPriceReturn }
        let cumulativeDividendReturn = dividendHistory.dividendYield * years
        return priceHistory.totalPriceReturn + cumulativeDividendReturn
    }
    
    /// 배당 포함 CAGR
    var cagrWithDividends: Double {
        let years = Double(priceHistory.annualReturns.count)
        guard years > 0 else { return 0 }
        return pow(1 + totalReturnWithDividends, 1.0 / years) - 1
    }
    
    /// 데이터 품질 경고가 필요한지
    var needsDataQualityWarning: Bool {
        dataQuality.needsWarning
    }
    
    /// 데이터 품질 표시 메시지
    var dataQualityMessage: String? {
        dataQuality.displayMessage
    }
    
    /// 티커 변경 이력 표시 문자열
    var tickerChangeDisplay: String? {
        tickerHistory?.displayString
    }
    
    /// StockWithData로 변환 (호환성)
    var asStockWithData: StockWithData {
        StockWithData(
            info: info,
            priceHistory: priceHistory,
            dividendHistory: dividendHistory
        )
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

