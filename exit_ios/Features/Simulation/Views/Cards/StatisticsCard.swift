//
//  StatisticsCard.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 상세 통계 카드
struct StatisticsCard: View {
    let result: MonteCarloResult
    let userProfile: UserProfile
    let effectiveVolatility: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            // 헤더
            ExitCardHeader(icon: "info.circle.fill", title: "시뮬레이션 상세")
            
            VStack(spacing: ExitSpacing.sm) {
                statRow(label: "시뮬레이션 횟수", value: "\(result.totalSimulations.formatted())회")
                statRow(label: "성공", value: "\(result.successCount.formatted())회", valueColor: Color.Exit.positive)
                statRow(label: "실패", value: "\(result.failureCount.formatted())회", valueColor: Color.Exit.warning)
                
                Divider()
                    .background(Color.Exit.divider)
                    .padding(.vertical, ExitSpacing.xs)
                
                statRow(label: "평균 수익률", value: String(format: "%.1f%%", userProfile.preRetirementReturnRate))
                statRow(label: "수익률 변동성", value: String(format: "%.1f%%", effectiveVolatility))
                statRow(label: "월 저축액", value: ExitNumberFormatter.formatToManWon(userProfile.monthlyInvestment))
            }
        }
        .exitCard()
        .padding(.horizontal, ExitSpacing.md)
    }
    
    private func statRow(label: String, value: String, valueColor: Color = Color.Exit.primaryText) -> some View {
        HStack {
            Text(label)
                .font(.Exit.body)
                .foregroundStyle(Color.Exit.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.Exit.body)
                .fontWeight(.medium)
                .foregroundStyle(valueColor)
        }
    }
    
}

