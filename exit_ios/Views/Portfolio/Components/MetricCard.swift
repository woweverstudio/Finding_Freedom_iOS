//
//  MetricCard.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  지표 카드 컴포넌트
//

import SwiftUI

/// 지표 카드
struct MetricCard: View {
    let metric: PortfolioMetric
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ExitSpacing.md) {
                // 이모지
                Text(metric.emoji)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(metric.color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
                
                // 타이틀 & 서브타이틀
                VStack(alignment: .leading, spacing: 2) {
                    Text(metric.title)
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    Text(metric.subtitle)
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.tertiaryText)
                }
                
                Spacer()
                
                // 값
                Text(metric.formattedValue)
                    .font(.Exit.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(metric.color)
                
                // 물음표 아이콘
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.Exit.tertiaryText)
            }
            .exitCard(.small)
        }
        .buttonStyle(.plain)
    }
}

/// 지표 그룹 카드
struct MetricGroupCard: View {
    let title: String
    let emoji: String
    let metrics: [MetricRow]
    
    struct MetricRow: Identifiable {
        let id = UUID()
        let label: String
        let value: String
        let color: Color
        let isHighlighted: Bool
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            // 헤더
            HStack(spacing: ExitSpacing.sm) {
                Text(emoji)
                    .font(.system(size: 20))
                
                Text(title)
                    .font(.Exit.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            // 구분선
            Divider()
                .background(Color.Exit.divider)
            
            // 지표 목록
            VStack(spacing: ExitSpacing.sm) {
                ForEach(metrics) { metric in
                    HStack {
                        Text(metric.label)
                            .font(.Exit.subheadline)
                            .foregroundStyle(Color.Exit.secondaryText)
                        
                        Spacer()
                        
                        Text(metric.value)
                            .font(metric.isHighlighted ? .Exit.body : .Exit.subheadline)
                            .fontWeight(metric.isHighlighted ? .bold : .medium)
                            .foregroundStyle(metric.color)
                    }
                }
            }
        }
        .exitCard()
    }
}

/// 배당 정보 카드
struct DividendInfoCard: View {
    let dividendYield: Double
    let dividendGrowthRate: Double
    let hasDividend: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            // 헤더
            HStack(spacing: ExitSpacing.sm) {
                Text("💰")
                    .font(.system(size: 20))
                
                Text("배당 정보")
                    .font(.Exit.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            Divider()
                .background(Color.Exit.divider)
            
            if hasDividend {
                // 배당률
                HStack {
                    Text("현재 배당률")
                        .font(.Exit.subheadline)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    Spacer()
                    
                    Text(String(format: "%.2f%%", dividendYield * 100))
                        .font(.Exit.body)
                        .fontWeight(.bold)
                        .foregroundStyle(dividendYield >= 0.03 ? Color.Exit.accent : Color.Exit.primaryText)
                }
                
                // 배당 성장률
                if dividendGrowthRate > 0 {
                    HStack {
                        Text("배당 성장률 (5Y)")
                            .font(.Exit.subheadline)
                            .foregroundStyle(Color.Exit.secondaryText)
                        
                        Spacer()
                        
                        Text(String(format: "+%.1f%%", dividendGrowthRate * 100))
                            .font(.Exit.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.Exit.positive)
                    }
                }
                
                // 고배당 팁
                if dividendYield >= 0.03 {
                    HStack(spacing: ExitSpacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.Exit.accent)
                        
                        Text("고배당 포트폴리오! 안정적인 현금흐름을 기대할 수 있어요.")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.accent)
                    }
                    .padding(.top, ExitSpacing.xs)
                }
            } else {
                HStack(spacing: ExitSpacing.xs) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.Exit.tertiaryText)
                    
                    Text("배당을 지급하지 않는 종목들로 구성되어 있어요")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
            }
        }
        .exitCard()
    }
}

// InsightCard는 DetailedInsightCard.swift에 정의되어 있습니다.

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            MetricCard(
                metric: .cagr(0.125),
                onTap: {}
            )
            
            MetricCard(
                metric: .sharpeRatio(1.25),
                onTap: {}
            )
            
            MetricGroupCard(
                title: "수익성",
                emoji: "💰",
                metrics: [
                    .init(label: "CAGR", value: "12.5%", color: .Exit.accent, isHighlighted: true),
                    .init(label: "배당 포함 CAGR", value: "14.2%", color: .Exit.accent, isHighlighted: false),
                    .init(label: "총 수익률", value: "85.3%", color: .Exit.primaryText, isHighlighted: false)
                ]
            )
            
            DividendInfoCard(
                dividendYield: 0.0342,
                dividendGrowthRate: 0.112,
                hasDividend: true
            )
            
            InsightCard(
                insight: .init(
                    type: .strength,
                    category: .profitability,
                    title: "우수한 수익률",
                    message: "지난 5년간 연평균 12.5%의 수익률을 기록했어요. S&P500 장기 평균을 상회하는 훌륭한 성과예요!",
                    emoji: "💪",
                    details: nil
                )
            )
        }
        .padding()
    }
    .background(Color.Exit.background)
}

