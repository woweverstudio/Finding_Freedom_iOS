//
//  AssetSnapshot.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import Foundation
import SwiftData

/// 월별 자산 스냅샷 (히스토리용)
/// 안전 점수 중 "자산 성장성" 계산 및 그래프용 데이터로 활용됩니다.
@Model
final class AssetSnapshot {
    /// 고유 ID
    var id: UUID = UUID()
    
    /// 기록 연월 (yyyyMM 형식)
    var yearMonth: String = ""
    
    /// 해당 시점 자산 (원 단위)
    var amount: Double = 0
    
    /// 스냅샷 생성일
    var snapshotDate: Date = Date()
    
    init() {}
    
    init(yearMonth: String, amount: Double) {
        self.id = UUID()
        self.yearMonth = yearMonth
        self.amount = amount
        self.snapshotDate = Date()
    }
    
    /// 현재 연월 문자열 생성
    static func currentYearMonth() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMM"
        return formatter.string(from: Date())
    }
    
    /// 이전 달 연월 문자열 생성
    static func previousYearMonth() -> String? {
        let calendar = Calendar.current
        guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date()) else {
            return nil
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMM"
        return formatter.string(from: lastMonth)
    }
    
    /// 날짜로부터 연월 문자열 생성
    static func yearMonth(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMM"
        return formatter.string(from: date)
    }
}
