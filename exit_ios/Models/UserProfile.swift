//
//  UserProfile.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    /// 은퇴 후 희망 월 수입 (원 단위)
    var desiredMonthlyIncome: Double = 3_000_000
    
    /// 현재 순자산 - 투자 가능 자산만 (원 단위)
    var currentNetAssets: Double = 0
    
    /// 월 평균 저축·투자 금액 (원 단위)
    var monthlyInvestment: Double = 500_000
    
    /// 은퇴 전 연 목표 수익률 (%)
    var preRetirementReturnRate: Double = 6.5
    
    /// 은퇴 후 연 목표 수익률 (%)
    var postRetirementReturnRate: Double = 5.0
    
    /// 예상 물가 상승률 (%)
    var inflationRate: Double = 2.5
    
    /// 온보딩 완료 여부
    var hasCompletedOnboarding: Bool = false
    
    /// 생성일
    var createdAt: Date = Date()
    
    /// 마지막 업데이트일
    var updatedAt: Date = Date()
    
    init() {}
    
    init(
        desiredMonthlyIncome: Double,
        currentNetAssets: Double,
        monthlyInvestment: Double,
        preRetirementReturnRate: Double = 6.5,
        postRetirementReturnRate: Double = 5.0,
        inflationRate: Double = 2.5
    ) {
        self.desiredMonthlyIncome = desiredMonthlyIncome
        self.currentNetAssets = currentNetAssets
        self.monthlyInvestment = monthlyInvestment
        self.preRetirementReturnRate = preRetirementReturnRate
        self.postRetirementReturnRate = postRetirementReturnRate
        self.inflationRate = inflationRate
        self.hasCompletedOnboarding = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// 설정 업데이트
    func updateSettings(
        desiredMonthlyIncome: Double? = nil,
        monthlyInvestment: Double? = nil,
        preRetirementReturnRate: Double? = nil,
        postRetirementReturnRate: Double? = nil,
        inflationRate: Double? = nil
    ) {
        if let value = desiredMonthlyIncome { self.desiredMonthlyIncome = value }
        if let value = monthlyInvestment { self.monthlyInvestment = value }
        if let value = preRetirementReturnRate { self.preRetirementReturnRate = value }
        if let value = postRetirementReturnRate { self.postRetirementReturnRate = value }
        if let value = inflationRate { self.inflationRate = value }
        self.updatedAt = Date()
    }
}
