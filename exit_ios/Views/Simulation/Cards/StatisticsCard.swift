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
    let scenario: Scenario
    let effectiveVolatility: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            // 헤더
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Color.Exit.accent)
                Text("시뮬레이션 상세")
                    .font(.Exit.title3)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            Divider()
                .background(Color.Exit.divider)
            
            VStack(spacing: ExitSpacing.sm) {
                animatedCountRow(label: "시뮬레이션 횟수", value: result.totalSimulations, suffix: "회")
                animatedCountRow(label: "성공", value: result.successCount, suffix: "회", valueColor: Color.Exit.positive)
                animatedCountRow(label: "실패", value: result.failureCount, suffix: "회", valueColor: Color.Exit.warning)
                
                Divider()
                    .background(Color.Exit.divider)
                    .padding(.vertical, ExitSpacing.xs)
                
                statRow(label: "평균 수익률", value: String(format: "%.1f%%", scenario.preRetirementReturnRate))
                statRow(label: "수익률 변동성", value: String(format: "%.1f%%", effectiveVolatility))
                statRow(label: "월 저축액", value: ExitNumberFormatter.formatToManWon(scenario.monthlyInvestment))
            }
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
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
    
    private func animatedCountRow(label: String, value: Int, suffix: String, valueColor: Color = Color.Exit.primaryText) -> some View {
        HStack {
            Text(label)
                .font(.Exit.body)
                .foregroundStyle(Color.Exit.secondaryText)

            Spacer()

            HStack(spacing: 0) {
                AnimatedCountText(value: value)
                Text(suffix)
            }
            .font(.Exit.body)
            .fontWeight(.medium)
            .foregroundStyle(valueColor)
        }
    }
}

