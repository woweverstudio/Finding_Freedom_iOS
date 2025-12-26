//
//  StockDataService.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  종목 데이터 서비스 프로토콜 및 팩토리
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

/// 확장 프로토콜: 분석용 데이터 제공 (일별 가격 포함)
protocol StockAnalysisDataServiceProtocol: StockDataServiceProtocol {
    /// 분석용 전체 데이터 가져오기 (일별 가격 포함)
    func fetchStocksWithAnalysisData(tickers: [String]) async throws -> [StockAnalysisData]
}

// MARK: - Stock Data Service Factory

/// 서비스 팩토리
enum StockDataServiceFactory {
    
    /// 분석용 서비스 반환
    static func createAnalysisService() -> StockAnalysisDataServiceProtocol {
        return PolygonStockDataService.shared
    }
}

// MARK: - Errors

enum StockDataError: LocalizedError {
    case dataNotLoaded
    case stockNotFound(ticker: String)
    case networkError(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .dataNotLoaded:
            return "데이터를 불러올 수 없습니다"
        case .stockNotFound(let ticker):
            return "\(ticker) 종목을 찾을 수 없습니다"
        case .networkError(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        }
    }
}
