//
//  SuccessRateCard.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 성공률 카드
struct SuccessRateCard: View {
    let result: MonteCarloResult
    let originalDDayMonths: Int  // 기존 D-Day
    var failureThresholdMultiplier: Double = 1.1  // 실패 조건 배수 (기본값 1.1)
    
    // 시뮬레이션 조건 표시용
    var userProfile: UserProfile? = nil
    var currentAssetAmount: Double = 0
    var effectiveVolatility: Double = 0
    
    /// 실패 기준 기간 (기존 D-Day * multiplier)
    private var failureThresholdMonths: Int {
        Int(Double(originalDDayMonths) * failureThresholdMultiplier)
    }
    
    private var failureThresholdText: String {
        let years = failureThresholdMonths / 12
        let months = failureThresholdMonths % 12
        if months == 0 {
            return "\(years)년"
        } else {
            return "\(years)년 \(months)개월"
        }
    }
    
    private var originalDDayText: String {
        let years = originalDDayMonths / 12
        let months = originalDDayMonths % 12
        if months == 0 {
            return "\(years)년"
        } else {
            return "\(years)년 \(months)개월"
        }
    }
    
    private var extraTimeText: String {
        let extraMonths = failureThresholdMonths - originalDDayMonths
        let years = extraMonths / 12
        let months = extraMonths % 12
        if years > 0 && months > 0 {
            return "\(years)년 \(months)개월"
        } else if years > 0 {
            return "\(years)년"
        } else {
            return "\(months)개월"
        }
    }
    
    private var failurePercentText: String {
        let percent = Int((failureThresholdMultiplier - 1) * 100)
        return "\(percent)%"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            // 1. 타이틀
            HStack {
                Image(systemName: "percent")
                    .foregroundStyle(Color.Exit.accent)
                Text("성공 확률")
                    .font(.Exit.title3)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            // 2. 차트 및 데이터 (성공률 + 코칭 메시지)
            VStack(spacing: ExitSpacing.md) {
                // 큰 성공률 표시
                VStack(spacing: ExitSpacing.sm) {
                    Text("계획대로 회사 탈출에 성공할 확률")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(Int(result.successRate * 100))")
                            .font(.system(size: 72, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(hex: result.confidenceLevel.color))
                        
                        Text("%")
                            .font(.Exit.title)
                            .foregroundStyle(Color.Exit.secondaryText)
                    }
                    
                    Text(result.confidenceLevel.rawValue)
                        .font(.Exit.body)
                        .foregroundStyle(Color(hex: result.confidenceLevel.color))
                        .padding(.horizontal, ExitSpacing.md)
                        .padding(.vertical, ExitSpacing.xs)
                        .background(
                            Capsule()
                                .fill(Color(hex: result.confidenceLevel.color).opacity(0.15))
                        )
                }
                
                // 코칭 메시지
                Text(successRateMessage)
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // 3. 도움말
            helpSection
            
            // 4. 시뮬레이션 조건
            if let profile = userProfile {
                simulationConditionSection(profile: profile)
            }
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.xl))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // MARK: - Help Section
    
    private var helpSection: some View {
        HStack(alignment: .top, spacing: ExitSpacing.sm) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.Exit.accent)
            
            VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                Text("이 확률이 의미하는 것")
                    .font(.Exit.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                    Text("주식 시장은 매년 오르락내리락해요. 그래서 \(result.totalSimulations.formatted())가지 다른 미래를 시뮬레이션해봤어요.")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.tertiaryText)
                    
                    Text("현재 계획대로면 \(originalDDayText) 후에 FIRE를 달성해요. 여기서는 계획보다 \(failurePercentText) 넘게 늦어지면(\(failureThresholdText)) '실패'로 봤어요.")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.tertiaryText)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(ExitSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Exit.secondaryCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
    }
    
    // MARK: - Simulation Condition
    
    private func simulationConditionSection(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            Text("📊 시뮬레이션 조건")
                .font(.Exit.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.Exit.secondaryText)
            
            HStack(spacing: ExitSpacing.md) {
                dataItem(label: "현재 자산", value: ExitNumberFormatter.formatChartAxis(currentAssetAmount))
                dataItem(label: "월 투자", value: ExitNumberFormatter.formatToManWon(profile.monthlyInvestment))
                dataItem(label: "수익률", value: String(format: "%.1f%%", profile.preRetirementReturnRate))
                dataItem(label: "변동성", value: String(format: "%.0f%%", effectiveVolatility))
            }
        }
    }
    
    private func dataItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.tertiaryText)
            Text(value)
                .font(.Exit.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.Exit.primaryText)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var successRateMessage: String {
        switch result.confidenceLevel {
        case .veryHigh:
            return "현재 계획대로라면 목표 달성이 거의 확실합니다! 훌륭해요 🎉"
        case .high:
            return "목표 달성 가능성이 높습니다. 현재 계획을 유지하세요"
        case .moderate:
            return "계획대로 진행하면 달성 가능합니다. 입금을 조금 더 늘리면 더 안전해요"
        case .low:
            return "목표 달성이 불확실합니다. 월 저축액을 늘리거나 목표를 조정하세요"
        case .veryLow:
            return "현재 계획으로는 목표 달성이 어렵습니다. 계획을 재검토하세요"
        }
    }
}
