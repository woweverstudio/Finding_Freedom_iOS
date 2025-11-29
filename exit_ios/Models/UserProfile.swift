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
    
    /// 보유 자산 종류 (복수 선택)
    var assetTypes: [String] = []
    
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
        assetTypes: [String]
    ) {
        self.desiredMonthlyIncome = desiredMonthlyIncome
        self.currentNetAssets = currentNetAssets
        self.monthlyInvestment = monthlyInvestment
        self.assetTypes = assetTypes
        self.hasCompletedOnboarding = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Asset Types
extension UserProfile {
    static let availableAssetTypes: [String] = [
        "현금",
        "예금·적금",
        "주식",
        "코인",
        "채권",
        "투자용 부동산",
        "금"
    ]
}

