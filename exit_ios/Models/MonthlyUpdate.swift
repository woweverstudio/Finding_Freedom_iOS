//
//  MonthlyUpdate.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import Foundation
import SwiftData

@Model
final class MonthlyUpdate {
    /// 고유 ID
    var id: UUID = UUID()
    
    /// 기록 연월 (yyyyMM 형식)
    var yearMonth: String = ""
    
    /// 해당 월 투자·저축 입금액 (원 단위)
    var depositAmount: Double = 0
    
    /// 해당 월 패시브인컴 총액 (배당+이자+월세 등, 원 단위)
    var passiveIncome: Double = 0
    
    /// 해당 월 총 자산 (원 단위)
    var totalAssets: Double = 0
    
    /// 보유 자산 종류 (해당 시점)
    var assetTypes: [String] = []
    
    /// 기록일
    var recordedAt: Date = Date()
    
    init() {}
    
    init(
        yearMonth: String,
        depositAmount: Double,
        passiveIncome: Double,
        totalAssets: Double,
        assetTypes: [String] = []
    ) {
        self.id = UUID()
        self.yearMonth = yearMonth
        self.depositAmount = depositAmount
        self.passiveIncome = passiveIncome
        self.totalAssets = totalAssets
        self.assetTypes = assetTypes
        self.recordedAt = Date()
    }
    
    /// 현재 연월 문자열 생성
    static func currentYearMonth() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMM"
        return formatter.string(from: Date())
    }
}

