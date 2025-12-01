//
//  PercentileCard.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 퍼센타일 카드
struct PercentileCard: View {
    let result: MonteCarloResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            // 헤더
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(Color.Exit.accent)
                Text("시나리오별 예상 기간")
                    .font(.Exit.title3)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            Divider()
                .background(Color.Exit.divider)
            
            // 퍼센타일 데이터
            VStack(spacing: ExitSpacing.md) {
                percentileRow(
                    icon: "🎯",
                    label: "최선의 경우 (10%)",
                    value: formatMonths(result.bestCase10Percent),
                    color: Color.Exit.positive
                )
                
                percentileRow(
                    icon: "📊",
                    label: "평균",
                    value: formatMonths(Int(result.averageMonthsToSuccess)),
                    color: Color.Exit.accent
                )
                
                percentileRow(
                    icon: "📈",
                    label: "중앙값 (50%)",
                    value: formatMonths(result.medianMonths),
                    color: Color.Exit.accent
                )
                
                percentileRow(
                    icon: "⚠️",
                    label: "최악의 경우 (10%)",
                    value: formatMonths(result.worstCase10Percent),
                    color: Color.Exit.caution
                )
            }
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    private func percentileRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack {
            Text(icon)
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            
            Spacer()
            
            Text(value)
                .font(.Exit.body)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .padding(.vertical, ExitSpacing.xs)
    }
    
    private func formatMonths(_ months: Int) -> String {
        let years = months / 12
        let remainingMonths = months % 12
        
        if remainingMonths == 0 {
            return "\(years)년"
        } else {
            return "\(years)년 \(remainingMonths)개월"
        }
    }
}

