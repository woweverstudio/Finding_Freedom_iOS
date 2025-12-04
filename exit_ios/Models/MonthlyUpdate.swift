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
    
    /// 해당 월 투자·저축 입금액 (원 단위) - 레거시, 마이그레이션용
    var depositAmount: Double = 0
    
    /// 해당 월 패시브인컴 총액 (배당+이자+월세 등, 원 단위) - 레거시, 마이그레이션용
    var passiveIncome: Double = 0
    
    // MARK: - 카테고리별 금액 (5개 항목)
    
    /// 월급/보너스 (원 단위)
    var salaryAmount: Double = 0
    
    /// 배당금 (원 단위)
    var dividendAmount: Double = 0
    
    /// 이자 수입 (원 단위)
    var interestAmount: Double = 0
    
    /// 월세/임대료 (원 단위)
    var rentAmount: Double = 0
    
    /// 기타 입금 (원 단위)
    var otherAmount: Double = 0
    
    /// 해당 월 총 자산 (원 단위)
    var totalAssets: Double = 0
    
    /// 입금 날짜 (실제 입금한 날짜)
    var depositDate: Date = Date()
    
    /// 기록일 (데이터 생성/수정 시간)
    var recordedAt: Date = Date()
    
    // MARK: - Computed Properties
    
    /// 총 입금액 (5개 카테고리 합계)
    var totalDeposit: Double {
        salaryAmount + dividendAmount + interestAmount + rentAmount + otherAmount
    }
    
    /// 총 패시브인컴 (배당 + 이자 + 월세)
    var totalPassiveIncome: Double {
        dividendAmount + interestAmount + rentAmount
    }
    
    /// 근로소득 (월급 + 기타)
    var totalActiveIncome: Double {
        salaryAmount + otherAmount
    }
    
    init() {}
    
    init(
        yearMonth: String,
        depositAmount: Double,
        passiveIncome: Double = 0,
        totalAssets: Double,
        depositDate: Date = Date()
    ) {
        self.id = UUID()
        self.yearMonth = yearMonth
        self.depositAmount = depositAmount
        self.passiveIncome = passiveIncome
        self.totalAssets = totalAssets
        self.depositDate = depositDate
        self.recordedAt = Date()
    }
    
    /// 카테고리별 금액으로 초기화
    init(
        yearMonth: String,
        salaryAmount: Double = 0,
        dividendAmount: Double = 0,
        interestAmount: Double = 0,
        rentAmount: Double = 0,
        otherAmount: Double = 0,
        totalAssets: Double
    ) {
        self.id = UUID()
        self.yearMonth = yearMonth
        self.salaryAmount = salaryAmount
        self.dividendAmount = dividendAmount
        self.interestAmount = interestAmount
        self.rentAmount = rentAmount
        self.otherAmount = otherAmount
        // 레거시 필드도 동기화
        self.depositAmount = salaryAmount + otherAmount
        self.passiveIncome = dividendAmount + interestAmount + rentAmount
        self.totalAssets = totalAssets
        self.depositDate = Date()
        self.recordedAt = Date()
    }
    
    /// 현재 연월 문자열 생성
    static func currentYearMonth() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMM"
        return formatter.string(from: Date())
    }
    
    /// 날짜로부터 연월 문자열 생성
    static func yearMonth(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMM"
        return formatter.string(from: date)
    }
}
