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
    let originalDDayMonths: Int  // 기존 D-Day (확정적 계산)
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            // 헤더
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(Color.Exit.accent)
                Text("FIRE 달성 시점 비교")
                    .font(.Exit.title3)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            Divider()
                .background(Color.Exit.divider)
            
            // 기존 D-Day vs 시뮬레이션 결과
            VStack(spacing: ExitSpacing.md) {
                // 기존 예측 (확정적 계산)
                percentileRow(
                    label: "📌 기존 예측 (변동성 미반영)",
                    months: originalDDayMonths,
                    color: Color.Exit.secondaryText,
                    isHighlighted: false
                )
                
                Divider()
                    .background(Color.Exit.divider)
                
                // 설명
                Text("시장 변동성을 반영한 시뮬레이션 결과")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.tertiaryText)
                
                percentileRow(
                    label: "🎯 최선의 경우 (상위 10%)",
                    months: result.bestCase10Percent,
                    color: Color.Exit.positive,
                    isHighlighted: false
                )
                
                percentileRow(
                    label: "📊 시뮬레이션 중앙값",
                    months: result.medianMonths,
                    color: Color.Exit.accent,
                    isHighlighted: true
                )
                
                percentileRow(
                    label: "⚠️ 최악의 경우 (하위 10%)",
                    months: result.worstCase10Percent,
                    color: Color.Exit.caution,
                    isHighlighted: false
                )
            }
            
            // 해석
            differenceExplanation
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // 기존 예측과 시뮬레이션 결과 비교 설명
    private var differenceExplanation: some View {
        let diff = result.medianMonths - originalDDayMonths
        let diffYears = abs(diff) / 12
        let diffMonths = abs(diff) % 12
        
        let diffText: String
        if diffYears > 0 && diffMonths > 0 {
            diffText = "\(diffYears)년 \(diffMonths)개월"
        } else if diffYears > 0 {
            diffText = "\(diffYears)년"
        } else {
            diffText = "\(diffMonths)개월"
        }
        
        let message: String
        if diff > 12 {
            message = "시장 변동성을 고려하면 기존 예측보다 약 \(diffText) 더 걸릴 수 있어요"
        } else if diff < -12 {
            message = "운이 좋으면 기존 예측보다 약 \(diffText) 빨리 달성할 수도 있어요"
        } else {
            message = "기존 예측과 시뮬레이션 결과가 비슷해요. 계획이 현실적입니다"
        }
        
        return VStack(alignment: .leading, spacing: ExitSpacing.xs) {
            Divider()
                .background(Color.Exit.divider)
            
            Text(message)
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func percentileRow(label: String, months: Int, color: Color, isHighlighted: Bool) -> some View {
        HStack {
            Text(label)
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            
            Spacer()
            
            Text(formatMonths(months))
                .font(isHighlighted ? .Exit.title3 : .Exit.body)
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

