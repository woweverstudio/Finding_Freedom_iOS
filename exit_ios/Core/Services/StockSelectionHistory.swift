//
//  StockSelectionHistory.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  종목 선택 히스토리 관리
//

import Foundation

/// 종목 선택 히스토리 관리자
final class StockSelectionHistory {
    
    // MARK: - Singleton
    
    static let shared = StockSelectionHistory()
    
    // MARK: - Properties
    
    private let historyKey = "stock_selection_history"
    private let maxHistoryCount = 12  // 최대 저장 개수
    
    private var history: [String] = []
    
    // MARK: - Initialization
    
    private init() {
        loadHistory()
    }
    
    // MARK: - Public Methods
    
    /// 히스토리 가져오기
    func getHistory() -> [String] {
        return history
    }
    
    /// 히스토리에 추가 (중복 제거, 최신이 앞으로)
    func addToHistory(_ ticker: String) {
        // 이미 있으면 제거 후 맨 앞에 추가
        history.removeAll { $0 == ticker }
        history.insert(ticker, at: 0)
        
        // 최대 개수 제한
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }
        
        saveHistory()
    }
    
    /// 여러 티커 한번에 추가
    func addToHistory(_ tickers: [String]) {
        for ticker in tickers {
            addToHistory(ticker)
        }
    }
    
    /// 히스토리에서 제거
    func removeFromHistory(_ ticker: String) {
        history.removeAll { $0 == ticker }
        saveHistory()
    }
    
    /// 히스토리 전체 삭제
    func clearHistory() {
        history.removeAll()
        saveHistory()
    }
    
    /// 히스토리가 비어있는지 확인
    var isEmpty: Bool {
        history.isEmpty
    }
    
    // MARK: - Private Methods
    
    private func saveHistory() {
        UserDefaults.standard.set(history, forKey: historyKey)
    }
    
    private func loadHistory() {
        history = UserDefaults.standard.stringArray(forKey: historyKey) ?? []
    }
}

