//
//  DetailedCalculationCard.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 상세 계산 설명 카드
/// 현재/목표 자산, 투자 정보, 필요 수익률 등을 표시
struct DetailedCalculationCard: View {
    let profile: UserProfile?
    let result: RetirementCalculationResult?
    let hideAmounts: Bool
    
    var body: some View {
        ExitCard(style: .filled, radius: ExitRadius.lg) {
            VStack(alignment: .leading, spacing: ExitSpacing.md) {
                if let profile = profile, let result = result {
                    // 현재 자산 / 목표 자산
                    AssetProgressRow(
                        currentAssets: ExitNumberFormatter.formatToEokManWon(result.currentAssets),
                        targetAssets: ExitNumberFormatter.formatToEokManWon(result.targetAssets),
                        percent: ExitNumberFormatter.formatPercentInt(result.progressPercent),
                        isHidden: hideAmounts
                    )
                    
                    ExitDivider()
                    
                    // 설명 텍스트
                    if result.isRetirementReady, let requiredRate = result.requiredReturnRate {
                        retirementReadyContent(
                            result: result,
                            profile: profile,
                            requiredRate: requiredRate
                        )
                    } else if result.monthsToRetirement > 0 {
                        accumulationContent(result: result, profile: profile)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // MARK: - Retirement Ready Content
    
    private func retirementReadyContent(
        result: RetirementCalculationResult,
        profile: UserProfile,
        requiredRate: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            HStack(spacing: 0) {
                Text("현재 자산 ")
                    .foregroundStyle(Color.Exit.secondaryText)
                Text(ExitNumberFormatter.formatToEokManWon(result.currentAssets))
                    .foregroundStyle(Color.Exit.accent)
                    .fontWeight(.semibold)
                    .blur(radius: hideAmounts ? 5 : 0)
                Text("으로")
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            .font(.Exit.subheadline)
            
            HStack(spacing: 0) {
                Text("매월 ")
                    .foregroundStyle(Color.Exit.secondaryText)
                Text(ExitNumberFormatter.formatToManWon(profile.desiredMonthlyIncome))
                    .foregroundStyle(Color.Exit.accent)
                    .fontWeight(.semibold)
                Text(" 현금흐름을 만들려면")
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            .font(.Exit.subheadline)
            
            HStack(spacing: 0) {
                Text("연 ")
                    .foregroundStyle(Color.Exit.secondaryText)
                Text(String(format: "%.2f%%", requiredRate))
                    .foregroundStyle(requiredRate < 4 ? Color.Exit.positive : Color.Exit.accent)
                    .fontWeight(.bold)
                Text(" 수익률만 달성하면 됩니다")
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            .font(.Exit.subheadline)
            
            // 수익률 수준 코멘트
            requiredRateComment(for: requiredRate)
        }
    }
    
    // MARK: - Accumulation Content
    
    private func accumulationContent(
        result: RetirementCalculationResult,
        profile: UserProfile
    ) -> some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            HStack(spacing: 0) {
                Text("매월 ")
                    .foregroundStyle(Color.Exit.secondaryText)
                Text(ExitNumberFormatter.formatToManWon(profile.desiredMonthlyIncome))
                    .foregroundStyle(Color.Exit.accent)
                    .fontWeight(.semibold)
                Text("의 현금흐름을 만들기 위해")
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            .font(.Exit.subheadline)
            
            HStack(spacing: 0) {
                Text("매월 ")
                    .foregroundStyle(Color.Exit.secondaryText)
                Text(ExitNumberFormatter.formatToManWon(profile.monthlyInvestment))
                    .foregroundStyle(Color.Exit.accent)
                    .fontWeight(.semibold)
                Text("씩 연복리 ")
                    .foregroundStyle(Color.Exit.secondaryText)
                Text(String(format: "%.1f%%", profile.preRetirementReturnRate))
                    .foregroundStyle(Color.Exit.accent)
                    .fontWeight(.semibold)
                Text("로 투자하면")
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            .font(.Exit.subheadline)
            
            HStack(spacing: 0) {
                Text(result.dDayString)
                    .foregroundStyle(Color.Exit.accent)
                    .fontWeight(.bold)
                Text(" 남았습니다.")
                    .font(.Exit.subheadline)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
        }
    }
    
    // MARK: - Required Rate Comment
    
    @ViewBuilder
    private func requiredRateComment(for rate: Double) -> some View {
        if rate < 3 {
            rateCommentRow("매우 안정적인 수익률입니다 (예금/채권 수준)", color: Color.Exit.positive)
        } else if rate < 5 {
            rateCommentRow("안정적인 수익률입니다 (배당주/채권 수준)", color: Color.Exit.positive)
        } else if rate < 7 {
            rateCommentRow("합리적인 수익률입니다 (인덱스펀드 수준)", color: Color.Exit.accent)
        } else {
            rateCommentRow("다소 높은 수익률이 필요합니다", color: Color.Exit.caution)
        }
    }
    
    private func rateCommentRow(_ text: String, color: Color) -> some View {
        HStack(spacing: ExitSpacing.xs) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(color)
            
            Text(text)
                .font(.Exit.caption)
                .foregroundStyle(color)
        }
        .padding(.top, ExitSpacing.xs)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        DetailedCalculationCard(
            profile: nil,
            result: nil,
            hideAmounts: false
        )
    }
    .preferredColorScheme(.dark)
}

