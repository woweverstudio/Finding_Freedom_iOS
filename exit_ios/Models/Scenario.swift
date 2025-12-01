//
//  Scenario.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import Foundation
import SwiftData

@Model
final class Scenario {
    /// 시나리오 고유 ID
    var id: UUID = UUID()
    
    /// 시나리오 이름
    var name: String = "내 계획"
    
    /// 시스템 기본 시나리오 여부 (삭제/이름변경 불가)
    /// - Note: "내 계획" 시나리오처럼 앱이 기본 생성한 시나리오
    var isSystemScenario: Bool = false
    
    /// 은퇴 후 희망 월 수입 (원 단위)
    var desiredMonthlyIncome: Double = 3_000_000
    
    /// 자산 오프셋 (원 단위)
    /// 실제 자산에 더하거나 빼서 "만약 ~라면?" 시뮬레이션에 사용
    /// 예: 로또당첨 시나리오는 +10억, 기본 시나리오는 0
    var assetOffset: Double = 0
    
    /// 매월 목표 투자금액 (원 단위)
    var monthlyInvestment: Double = 500_000
    
    /// 은퇴 전 연 목표 수익률 (%)
    var preRetirementReturnRate: Double = 6.5
    
    /// 은퇴 후 연 목표 수익률 (%)
    var postRetirementReturnRate: Double = 5.0
    
    /// 예상 물가 상승률 (%)
    var inflationRate: Double = 2.5
    
    /// 수익률 변동성 (표준편차, %)
    /// - Note: 몬테카를로 시뮬레이션에 사용
    /// - 주식 중심 포트폴리오: 15~20%
    /// - 혼합 포트폴리오: 10~15%
    /// - 안정적 포트폴리오: 5~10%
    var returnRateVolatility: Double = 15.0
    
    /// 현재 적용 중인 시나리오 여부
    var isActive: Bool = false
    
    /// 생성일
    var createdAt: Date = Date()
    
    /// 마지막 업데이트일
    var updatedAt: Date = Date()
    
    init() {}
    
    init(
        name: String,
        desiredMonthlyIncome: Double,
        assetOffset: Double = 0,
        monthlyInvestment: Double,
        preRetirementReturnRate: Double = 6.5,
        postRetirementReturnRate: Double = 5.0,
        inflationRate: Double = 2.5,
        returnRateVolatility: Double = 15.0,
        isActive: Bool = false,
        isSystemScenario: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.isSystemScenario = isSystemScenario
        self.desiredMonthlyIncome = desiredMonthlyIncome
        self.assetOffset = assetOffset
        self.monthlyInvestment = monthlyInvestment
        self.preRetirementReturnRate = preRetirementReturnRate
        self.postRetirementReturnRate = postRetirementReturnRate
        self.inflationRate = inflationRate
        self.returnRateVolatility = returnRateVolatility
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// 시나리오 복제
    func duplicate(withName newName: String) -> Scenario {
        Scenario(
            name: newName,
            desiredMonthlyIncome: desiredMonthlyIncome,
            assetOffset: assetOffset,
            monthlyInvestment: monthlyInvestment,
            preRetirementReturnRate: preRetirementReturnRate,
            postRetirementReturnRate: postRetirementReturnRate,
            inflationRate: inflationRate,
            returnRateVolatility: returnRateVolatility,
            isActive: false
        )
    }
    
    /// 시나리오에 적용될 실제 자산 계산
    /// - Parameter currentAsset: 현재 실제 자산 (Asset.amount)
    /// - Returns: 시나리오에 적용될 자산 (실제 자산 + 오프셋)
    func effectiveAsset(with currentAsset: Double) -> Double {
        currentAsset + assetOffset
    }
    
    /// 삭제 가능 여부
    /// - Note: 시스템 시나리오는 삭제/이름변경 불가
    var isDeletable: Bool {
        !isSystemScenario
    }
}

// MARK: - Preset Scenarios
extension Scenario {
    static func createDefaultScenarios(
        desiredMonthlyIncome: Double,
        currentNetAssets: Double,
        monthlyInvestment: Double
    ) -> [Scenario] {
        [
            Scenario(
                name: "내 계획",
                desiredMonthlyIncome: desiredMonthlyIncome,
                assetOffset: 0,
                monthlyInvestment: monthlyInvestment,
                isActive: true,
                isSystemScenario: true  // 삭제/이름변경 불가
            ),
            Scenario(
                name: "물가폭등",
                desiredMonthlyIncome: desiredMonthlyIncome,
                assetOffset: 0,
                monthlyInvestment: monthlyInvestment,
                preRetirementReturnRate: 8.5,   // 명목 수익률도 상승
                postRetirementReturnRate: 7.0,  // 명목 수익률도 상승
                inflationRate: 5.0              // 물가 상승률 증가 (실질 수익률 2%)
            ),
            Scenario(
                name: "주식폭락",
                desiredMonthlyIncome: desiredMonthlyIncome,
                assetOffset: -currentNetAssets * 0.5,  // 현재 자산의 -50%
                monthlyInvestment: monthlyInvestment,
                preRetirementReturnRate: 3.0,  // 수익률 감소
                postRetirementReturnRate: 3.0,
                inflationRate: 2.5
            ),
            Scenario(
                name: "로또당첨",
                desiredMonthlyIncome: desiredMonthlyIncome,
                assetOffset: 1_000_000_000,  // +10억 오프셋
                monthlyInvestment: monthlyInvestment,
                preRetirementReturnRate: 6.5,
                postRetirementReturnRate: 5.0,
                inflationRate: 2.5
            )
        ]
    }
}
