//
//  RetirementCalculator.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import Foundation

/// 은퇴 계산 결과
struct RetirementCalculationResult {
    /// 은퇴 시 필요 자산 (원 단위)
    let targetAssets: Double
    
    /// 은퇴까지 남은 개월 수
    let monthsToRetirement: Int
    
    /// 현재 진행률 (0~100)
    let progressPercent: Double
    
    /// 계산에 사용된 현재 자산
    let currentAssets: Double
    
    /// 은퇴까지 남은 연도
    var yearsToRetirement: Int {
        monthsToRetirement / 12
    }
    
    /// 은퇴까지 남은 개월 (연도 제외)
    var remainingMonths: Int {
        monthsToRetirement % 12
    }
    
    /// D-DAY 표시용 문자열
    var dDayString: String {
        ExitNumberFormatter.formatMonthsToYearsMonths(monthsToRetirement)
    }
}

/// 은퇴 계산 유스케이스
/// 목표 자산 계산 및 D-DAY 산출
/// nonisolated로 선언하여 어떤 actor에서든 호출 가능
enum RetirementCalculator {
    
    // MARK: - 목표 자산 계산
    
    /// 은퇴 시 필요 자산 계산 (실질 4% 룰 적용)
    /// 필요 자산 = (희망 월 수입 × 12) ÷ (은퇴 후 수익률 – 물가 상승률)
    /// - Parameters:
    ///   - desiredMonthlyIncome: 은퇴 후 희망 월 수입 (원 단위)
    ///   - postRetirementReturnRate: 은퇴 후 연 목표 수익률 (%, 예: 5.0)
    ///   - inflationRate: 예상 물가 상승률 (%, 예: 2.5)
    /// - Returns: 필요 자산 (원 단위)
    nonisolated static func calculateTargetAssets(
        desiredMonthlyIncome: Double,
        postRetirementReturnRate: Double,
        inflationRate: Double
    ) -> Double {
        let annualIncome = desiredMonthlyIncome * 12
        let realReturnRate = (postRetirementReturnRate - inflationRate) / 100
        
        // 실질 수익률이 0 이하인 경우 방지
        // (물가 상승률 >= 수익률이면 자산이 실질적으로 줄어듦)
        guard realReturnRate > 0 else {
            return annualIncome * 50  // 50년치 자산 필요로 대체 (매우 보수적)
        }
        
        return annualIncome / realReturnRate
    }
    
    // MARK: - D-DAY 계산
    
    /// 목표 자산 도달까지 필요한 개월 수 계산 (월복리 시뮬레이션)
    /// - Parameters:
    ///   - currentAssets: 현재 순자산 (원 단위)
    ///   - targetAssets: 목표 자산 (원 단위)
    ///   - monthlyInvestment: 월 투자 금액 (원 단위)
    ///   - annualReturnRate: 은퇴 전 연 목표 수익률 (%, 예: 6.5)
    /// - Returns: 필요 개월 수
    nonisolated static func calculateMonthsToRetirement(
        currentAssets: Double,
        targetAssets: Double,
        monthlyInvestment: Double,
        annualReturnRate: Double
    ) -> Int {
        // 이미 목표 달성한 경우
        if currentAssets >= targetAssets {
            return 0
        }
        
        // 월 수익률 계산
        let monthlyReturnRate = pow(1 + annualReturnRate / 100, 1.0 / 12) - 1
        
        var currentValue = currentAssets
        var months = 0
        let maxMonths = 12 * 100  // 최대 100년
        
        while currentValue < targetAssets && months < maxMonths {
            // 월초 투자금 추가
            currentValue += monthlyInvestment
            // 월말 수익 적용
            currentValue *= (1 + monthlyReturnRate)
            months += 1
        }
        
        return months
    }
    
    // MARK: - 통합 계산
    
    /// UserProfile과 현재 자산 기반 은퇴 계산 실행
    /// - Parameters:
    ///   - profile: 사용자 프로필
    ///   - currentAsset: 현재 자산
    /// - Returns: 계산 결과
    nonisolated static func calculate(from profile: UserProfile, currentAsset: Double) -> RetirementCalculationResult {
        let targetAssets = calculateTargetAssets(
            desiredMonthlyIncome: profile.desiredMonthlyIncome,
            postRetirementReturnRate: profile.postRetirementReturnRate,
            inflationRate: profile.inflationRate
        )
        
        let months = calculateMonthsToRetirement(
            currentAssets: currentAsset,
            targetAssets: targetAssets,
            monthlyInvestment: profile.monthlyInvestment,
            annualReturnRate: profile.preRetirementReturnRate
        )
        
        let progress = min((currentAsset / targetAssets) * 100, 100)
        
        return RetirementCalculationResult(
            targetAssets: targetAssets,
            monthsToRetirement: months,
            progressPercent: progress,
            currentAssets: currentAsset
        )
    }
    
    /// 간단한 값들로 계산 실행
    nonisolated static func calculate(
        desiredMonthlyIncome: Double,
        currentNetAssets: Double,
        monthlyInvestment: Double,
        preRetirementReturnRate: Double = 6.5,
        postRetirementReturnRate: Double = 5.0,
        inflationRate: Double = 2.5
    ) -> RetirementCalculationResult {
        let targetAssets = calculateTargetAssets(
            desiredMonthlyIncome: desiredMonthlyIncome,
            postRetirementReturnRate: postRetirementReturnRate,
            inflationRate: inflationRate
        )
        
        let months = calculateMonthsToRetirement(
            currentAssets: currentNetAssets,
            targetAssets: targetAssets,
            monthlyInvestment: monthlyInvestment,
            annualReturnRate: preRetirementReturnRate
        )
        
        let progress = min((currentNetAssets / targetAssets) * 100, 100)
        
        return RetirementCalculationResult(
            targetAssets: targetAssets,
            monthsToRetirement: months,
            progressPercent: progress,
            currentAssets: currentNetAssets
        )
    }
}
