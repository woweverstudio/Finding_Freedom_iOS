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
                    months: result.bestCase10Percent,
                    color: Color.Exit.positive
                )
                
                percentileRow(
                    icon: "📊",
                    label: "평균",
                    months: Int(result.averageMonthsToSuccess),
                    color: Color.Exit.accent
                )
                
                percentileRow(
                    icon: "📈",
                    label: "중앙값 (50%)",
                    months: result.medianMonths,
                    color: Color.Exit.accent
                )
                
                percentileRow(
                    icon: "⚠️",
                    label: "최악의 경우 (10%)",
                    months: result.worstCase10Percent,
                    color: Color.Exit.caution
                )
            }
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    private func percentileRow(icon: String, label: String, months: Int, color: Color) -> some View {
        HStack {
//            Text(icon)
//                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            
            Spacer()
            
            AnimatedMonthsText(months: months)
                .font(.Exit.body)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .padding(.vertical, ExitSpacing.xs)
    }
}

/// 개월수를 년/개월 형식으로 애니메이션 표시
private struct AnimatedMonthsText: View {
    let months: Int
    
    @State private var displayMonths: Double = 0
    
    var body: some View {
        Text(formatMonths(Int(displayMonths)))
            .contentTransition(.numericText(value: displayMonths))
            .animation(.easeOut(duration: 0.8), value: displayMonths)
            .onAppear {
                displayMonths = Double(months)
            }
            .onChange(of: months) { oldValue, newValue in
                displayMonths = Double(newValue)
            }
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

