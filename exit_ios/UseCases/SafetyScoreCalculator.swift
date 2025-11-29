//
//  SafetyScoreCalculator.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import Foundation

/// 안전 점수 결과
struct SafetyScoreResult {
    /// 총점 (0~100)
    let totalScore: Double
    
    /// 목표 충족 점수 (0~25)
    let goalFulfillmentScore: Double
    
    /// 수익률 안전성 점수 (0~25)
    let returnSafetyScore: Double
    
    /// 자산 다각화 점수 (0~25)
    let diversificationScore: Double
    
    /// 자산 성장성 점수 (0~25)
    let growthScore: Double
    
    /// 이전 대비 점수 변화
    var scoreChange: Double = 0
}

/// 안전 점수 계산 유스케이스
/// 4개 항목 각 25점, 총 100점 만점
enum SafetyScoreCalculator {
    
    // MARK: - 개별 점수 계산
    
    /// 1. 목표 충족 점수 계산
    /// (이번 달 패시브인컴 × 12) ÷ 희망 연 수입 × 25
    /// - Parameters:
    ///   - monthlyPassiveIncome: 이번 달 패시브인컴 (원 단위)
    ///   - desiredMonthlyIncome: 희망 월 수입 (원 단위)
    /// - Returns: 점수 (0~25)
    static func calculateGoalFulfillment(
        monthlyPassiveIncome: Double,
        desiredMonthlyIncome: Double
    ) -> Double {
        guard desiredMonthlyIncome > 0 else { return 0 }
        
        let annualPassiveIncome = monthlyPassiveIncome * 12
        let desiredAnnualIncome = desiredMonthlyIncome * 12
        let ratio = annualPassiveIncome / desiredAnnualIncome
        
        return min(ratio * 25, 25)
    }
    
    /// 2. 수익률 안전성 점수 계산
    /// 연환산 패시브인컴 ÷ 현재 총자산 → 3~8% 구간에서 25점
    /// - Parameters:
    ///   - monthlyPassiveIncome: 이번 달 패시브인컴 (원 단위)
    ///   - totalAssets: 현재 총 자산 (원 단위)
    /// - Returns: 점수 (0~25)
    static func calculateReturnSafety(
        monthlyPassiveIncome: Double,
        totalAssets: Double
    ) -> Double {
        guard totalAssets > 0 else { return 0 }
        
        let annualPassiveIncome = monthlyPassiveIncome * 12
        let returnRate = (annualPassiveIncome / totalAssets) * 100  // 퍼센트
        
        // 3~8% 구간에서 최고점
        if returnRate >= 3 && returnRate <= 8 {
            return 25
        } else if returnRate < 3 {
            // 0~3% 구간: 선형 증가
            return (returnRate / 3) * 25
        } else {
            // 8% 초과: 점진적 감소 (너무 높은 수익률은 리스크)
            let excess = returnRate - 8
            return max(25 - excess * 2, 10)  // 최소 10점
        }
    }
    
    /// 3. 자산 다각화 점수 계산
    /// 보유 자산군 개수 기반 (7종 중 선택)
    /// - Parameter assetTypeCount: 보유 자산 종류 수
    /// - Returns: 점수 (0~25)
    static func calculateDiversification(assetTypeCount: Int) -> Double {
        // 7개 자산군 중 보유 개수에 따라 점수 산정
        // 1개: 약 3.5점, 2개: 7점, ..., 7개: 25점
        let score = Double(min(assetTypeCount, 7)) / 7.0 * 25
        return score
    }
    
    /// 4. 자산 성장성 점수 계산
    /// (이번 달 총자산 – 이전 달 총자산) ÷ 이전 총자산 – 물가상승률
    /// - Parameters:
    ///   - currentAssets: 이번 달 총 자산 (원 단위)
    ///   - previousAssets: 이전 달 총 자산 (원 단위)
    ///   - inflationRate: 연간 물가 상승률 (%, 기본값 2.5)
    /// - Returns: 점수 (0~25)
    static func calculateGrowth(
        currentAssets: Double,
        previousAssets: Double,
        inflationRate: Double = 2.5
    ) -> Double {
        guard previousAssets > 0 else { return 12.5 }  // 데이터 없으면 중간점
        
        let monthlyGrowthRate = (currentAssets - previousAssets) / previousAssets * 100
        let monthlyInflation = inflationRate / 12  // 월간 물가상승률
        let realGrowthRate = monthlyGrowthRate - monthlyInflation
        
        // 실질 성장률 0% = 12.5점, +2% = 25점, -2% = 0점
        let score = 12.5 + (realGrowthRate / 2) * 12.5
        return max(0, min(score, 25))
    }
    
    // MARK: - 통합 계산
    
    /// 전체 안전 점수 계산
    /// - Parameters:
    ///   - monthlyPassiveIncome: 이번 달 패시브인컴
    ///   - desiredMonthlyIncome: 희망 월 수입
    ///   - currentAssets: 현재 총 자산
    ///   - previousAssets: 이전 달 총 자산
    ///   - assetTypeCount: 보유 자산 종류 수
    ///   - inflationRate: 물가 상승률 (기본 2.5%)
    ///   - previousTotalScore: 이전 총점 (변화량 계산용)
    /// - Returns: 안전 점수 결과
    static func calculate(
        monthlyPassiveIncome: Double,
        desiredMonthlyIncome: Double,
        currentAssets: Double,
        previousAssets: Double,
        assetTypeCount: Int,
        inflationRate: Double = 2.5,
        previousTotalScore: Double? = nil
    ) -> SafetyScoreResult {
        let goalScore = calculateGoalFulfillment(
            monthlyPassiveIncome: monthlyPassiveIncome,
            desiredMonthlyIncome: desiredMonthlyIncome
        )
        
        let returnScore = calculateReturnSafety(
            monthlyPassiveIncome: monthlyPassiveIncome,
            totalAssets: currentAssets
        )
        
        let diversificationScore = calculateDiversification(assetTypeCount: assetTypeCount)
        
        let growthScore = calculateGrowth(
            currentAssets: currentAssets,
            previousAssets: previousAssets,
            inflationRate: inflationRate
        )
        
        let total = goalScore + returnScore + diversificationScore + growthScore
        let change = previousTotalScore.map { total - $0 } ?? 0
        
        return SafetyScoreResult(
            totalScore: total,
            goalFulfillmentScore: goalScore,
            returnSafetyScore: returnScore,
            diversificationScore: diversificationScore,
            growthScore: growthScore,
            scoreChange: change
        )
    }
    
    /// MonthlyUpdate 배열로부터 안전 점수 계산
    static func calculate(
        from updates: [MonthlyUpdate],
        desiredMonthlyIncome: Double,
        inflationRate: Double = 2.5
    ) -> SafetyScoreResult {
        // 최신 2개 업데이트 가져오기
        let sorted = updates.sorted { $0.yearMonth > $1.yearMonth }
        let current = sorted.first
        let previous = sorted.dropFirst().first
        
        return calculate(
            monthlyPassiveIncome: current?.passiveIncome ?? 0,
            desiredMonthlyIncome: desiredMonthlyIncome,
            currentAssets: current?.totalAssets ?? 0,
            previousAssets: previous?.totalAssets ?? current?.totalAssets ?? 0,
            assetTypeCount: current?.assetTypes.count ?? 0,
            inflationRate: inflationRate
        )
    }
}

