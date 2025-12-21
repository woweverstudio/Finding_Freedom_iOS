//
//  MetricExplanationSheet.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  지표 설명 시트
//

import SwiftUI

/// 지표 설명 시트
struct MetricExplanationSheet: View {
    let metric: PortfolioMetric
    let years: Int
    @Environment(\.dismiss) private var dismiss
    
    private var explanation: MetricExplanation {
        switch metric {
        case .cagr(let value):
            return MetricExplanation.cagr(value: value, years: years)
        case .sharpeRatio(let value):
            return MetricExplanation.sharpeRatio(value: value)
        case .mdd(let value):
            return MetricExplanation.mdd(value: value)
        case .volatility(let value):
            return MetricExplanation.volatility(value: value)
        case .dividendYield(let value):
            return MetricExplanation.dividendYield(value: value)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ExitSpacing.lg) {
                    // 헤더
                    headerSection
                    
                    // 해석 가이드
                    interpretationGuideSection
                    
                    // 현재 값
                    currentValueSection
                    
                    // 개선 팁 (있는 경우)
                    if let tips = explanation.tips, !tips.isEmpty {
                        tipsSection(tips: tips)
                    }
                }
                .padding(ExitSpacing.lg)
            }
            .background(Color.Exit.background)
            .navigationTitle(explanation.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                    .foregroundStyle(Color.Exit.accent)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            HStack(spacing: ExitSpacing.sm) {
                Text(explanation.emoji)
                    .font(.system(size: 32))
                
                Text("\(metric.title)이 뭔가요?")
                    .font(.Exit.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            Text(explanation.simpleExplanation)
                .font(.Exit.body)
                .foregroundStyle(Color.Exit.secondaryText)
        }
    }
    
    private var interpretationGuideSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            Text("📊 해석 가이드")
                .font(.Exit.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.Exit.primaryText)
            
            VStack(spacing: ExitSpacing.sm) {
                ForEach(explanation.interpretationGuide.indices, id: \.self) { index in
                    let guide = explanation.interpretationGuide[index]
                    HStack(spacing: ExitSpacing.sm) {
                        Circle()
                            .fill(guide.color)
                            .frame(width: 8, height: 8)
                        
                        Text(guide.range)
                            .font(.Exit.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.Exit.primaryText)
                            .frame(width: 80, alignment: .leading)
                        
                        Text(guide.description)
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.secondaryText)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    private var currentValueSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            Divider()
                .background(Color.Exit.divider)
            
            HStack {
                Text("내 포트폴리오:")
                    .font(.Exit.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Spacer()
                
                Text(metric.formattedValue)
                    .font(.Exit.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(metric.color)
            }
            
            Text(interpretationText)
                .font(.Exit.subheadline)
                .foregroundStyle(Color.Exit.secondaryText)
        }
    }
    
    private func tipsSection(tips: [String]) -> some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            HStack(spacing: ExitSpacing.xs) {
                Text("💡")
                    .font(.system(size: 16))
                
                Text("개선 팁")
                    .font(.Exit.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                ForEach(tips.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: ExitSpacing.xs) {
                        Text("•")
                            .foregroundStyle(Color.Exit.accent)
                        
                        Text(tips[index])
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.secondaryText)
                    }
                }
            }
        }
        .padding(ExitSpacing.md)
        .background(Color.Exit.caution.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
    }
    
    // MARK: - Helpers
    
    private var interpretationText: String {
        switch metric {
        case .cagr(let v):
            if v >= 0.15 { return "🎉 훌륭해요! 시장 평균을 크게 상회하는 성과예요." }
            else if v >= 0.10 { return "👍 좋아요! S&P500 장기 평균과 비슷한 성과예요." }
            else if v >= 0.05 { return "😊 양호해요. 은행 예금보다는 좋은 성과예요." }
            else if v >= 0 { return "🤔 예금 금리 수준이에요. 전략을 점검해보세요." }
            else { return "😢 손실이 발생했어요. 포트폴리오 재검토를 권장해요." }
            
        case .sharpeRatio(let v):
            if v >= 1.5 { return "🏆 뛰어나요! 위험 대비 매우 효율적인 수익을 내고 있어요." }
            else if v >= 1.0 { return "👍 좋아요! 감수한 위험 대비 좋은 수익을 내고 있어요." }
            else if v >= 0.5 { return "😊 보통이에요. 괜찮은 편이지만 개선 여지가 있어요." }
            else if v >= 0 { return "🤔 위험 대비 수익이 낮아요. 전략 점검을 권장해요." }
            else { return "😢 무위험 자산(예금)보다 못한 성과예요. 재검토가 필요해요." }
            
        case .mdd(let v):
            if abs(v) <= 0.15 { return "👍 낙폭이 작아서 심리적 부담이 적은 포트폴리오예요." }
            else if abs(v) <= 0.25 { return "😊 평균적인 수준의 낙폭이에요." }
            else if abs(v) <= 0.35 { return "⚠️ 다소 큰 낙폭이에요. 장기 투자 관점이 필요해요." }
            else { return "🎢 상당한 낙폭이에요. 변동성 관리가 필요해요." }
            
        case .volatility(let v):
            if v <= 0.15 { return "👍 안정적인 포트폴리오예요." }
            else if v <= 0.25 { return "😊 평균적인 변동성이에요." }
            else if v <= 0.35 { return "⚠️ 다소 높은 변동성이에요. 단기 등락에 주의하세요." }
            else { return "🎢 높은 변동성이에요. 장기 관점에서 접근하세요." }
            
        case .dividendYield(let v):
            if v >= 0.04 { return "💰 고배당 포트폴리오! 안정적인 현금흐름이 기대돼요." }
            else if v >= 0.02 { return "👍 적절한 배당 수준이에요." }
            else if v >= 0.01 { return "😊 배당은 적지만 성장에 집중하는 포트폴리오일 수 있어요." }
            else { return "📈 배당보다 성장에 집중하는 포트폴리오예요." }
        }
    }
}

// MARK: - Preview

#Preview {
    MetricExplanationSheet(
        metric: .sharpeRatio(0.85),
        years: 5
    )
}

