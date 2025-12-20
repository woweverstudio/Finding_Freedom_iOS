//
//  DetailedInsightCard.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  상세 투자 인사이트 카드
//

import SwiftUI

/// 상세 인사이트 카드 - 확장 가능한 디테일 포함
struct DetailedInsightCard: View {
    let insight: PortfolioInsightsGenerator.Insight
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 메인 카드 영역
            mainContent
            
            // 상세 정보 (확장 시)
            if isExpanded, let details = insight.details, !details.isEmpty {
                detailsSection(details: details)
            }
        }
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: ExitRadius.lg)
                .strokeBorder(borderColor, lineWidth: 1)
        )
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            // 헤더: 카테고리 + 타입 뱃지
            HStack(spacing: ExitSpacing.sm) {
                // 카테고리 뱃지
                Text(insight.category.rawValue)
                    .font(.Exit.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(categoryColor)
                    .padding(.horizontal, ExitSpacing.sm)
                    .padding(.vertical, 4)
                    .background(categoryColor.opacity(0.15))
                    .clipShape(Capsule())
                
                Spacer()
                
                // 타입 아이콘
                typeIcon
            }
            
            // 타이틀
            HStack(spacing: ExitSpacing.sm) {
                Text(insight.emoji)
                    .font(.system(size: 24))
                
                Text(insight.title)
                    .font(.Exit.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            // 메시지
            Text(insight.message)
                .font(.Exit.subheadline)
                .foregroundStyle(Color.Exit.secondaryText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            
            // 확장 버튼 (상세 정보가 있는 경우)
            if let details = insight.details, !details.isEmpty {
                expandButton(detailsCount: details.count)
            }
        }
        .padding(ExitSpacing.md)
    }
    
    // MARK: - Details Section
    
    private func detailsSection(details: [String]) -> some View {
        VStack(alignment: .leading, spacing: ExitSpacing.xs) {
            Divider()
                .background(Color.Exit.divider)
            
            VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                ForEach(Array(details.enumerated()), id: \.offset) { index, detail in
                    detailRow(detail)
                }
            }
            .padding(ExitSpacing.md)
        }
    }
    
    private func detailRow(_ detail: String) -> some View {
        Group {
            if detail.isEmpty {
                Spacer()
                    .frame(height: ExitSpacing.sm)
            } else {
                Text(detail)
                    .font(.Exit.subheadline)
                    .foregroundStyle(detailColor(for: detail))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    // MARK: - Expand Button
    
    private func expandButton(detailsCount: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: ExitSpacing.xs) {
                Text(isExpanded ? "접기" : "상세 보기 (\(detailsCount)개 항목)")
                    .font(.Exit.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.Exit.accent)
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.Exit.accent)
            }
        }
        .buttonStyle(.plain)
        .padding(.top, ExitSpacing.xs)
    }
    
    // MARK: - Type Icon
    
    private var typeIcon: some View {
        Group {
            switch insight.type {
            case .strength:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.Exit.positive)
            case .warning:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.Exit.warning)
            case .suggestion:
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(Color.Exit.caution)
            }
        }
        .font(.system(size: 18))
    }
    
    // MARK: - Colors
    
    private var backgroundColor: Color {
        switch insight.type {
        case .strength:
            return Color.Exit.positive.opacity(0.08)
        case .warning:
            return Color.Exit.warning.opacity(0.08)
        case .suggestion:
            return Color.Exit.caution.opacity(0.08)
        }
    }
    
    private var borderColor: Color {
        switch insight.type {
        case .strength:
            return Color.Exit.positive.opacity(0.2)
        case .warning:
            return Color.Exit.warning.opacity(0.2)
        case .suggestion:
            return Color.Exit.caution.opacity(0.2)
        }
    }
    
    private var categoryColor: Color {
        switch insight.category {
        case .profitability:
            return .Exit.accent
        case .risk:
            return .Exit.warning
        case .dividend:
            return .Exit.positive
        case .diversification:
            return .orange
        case .efficiency:
            return .purple
        case .overall:
            return .Exit.primaryText
        }
    }
    
    /// 상세 텍스트 색상 결정 (prefix 기반)
    private func detailColor(for text: String) -> Color {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        
        // [좋음], [양호] 등의 태그로 판단
        if trimmed.hasPrefix("[좋음]") || trimmed.hasPrefix("[우수]") || trimmed.hasPrefix("[강점]") {
            return Color.Exit.positive
        } else if trimmed.hasPrefix("[주의]") || trimmed.hasPrefix("[경고]") || trimmed.hasPrefix("[위험]") {
            return Color.Exit.warning
        } else if trimmed.hasPrefix("[제안]") || trimmed.hasPrefix("[팁]") {
            return Color.Exit.caution
        } else if trimmed.hasPrefix("•") || trimmed.hasPrefix("-") {
            // 목록 항목
            return Color.Exit.secondaryText
        } else if text.hasPrefix("    ") || text.hasPrefix("\t") {
            // 들여쓰기된 상세 항목
            return Color.Exit.secondaryText
        } else {
            return Color.Exit.secondaryText
        }
    }
}

// MARK: - 기존 InsightCard (호환성 유지)

struct InsightCard: View {
    let insight: PortfolioInsightsGenerator.Insight
    
    var body: some View {
        DetailedInsightCard(insight: insight)
    }
}

// MARK: - Preview

#Preview {
    let sampleInsights: [PortfolioInsightsGenerator.Insight] = [
        .init(
            type: .strength,
            category: .profitability,
            title: "수익률 분석: AAPL이 주도",
            message: "AAPL이 가장 높은 CAGR 23.5%를 기록하며 포트폴리오 수익에 11.8%p 기여하고 있어요. 포트폴리오 전체 CAGR은 15.3%입니다.",
            emoji: "📈",
            details: [
                "[종목별 CAGR 순위]",
                "1. AAPL: CAGR 23.5% [좋음] (기여 +11.8%p)",
                "2. MSFT: CAGR 18.2% [좋음] (기여 +9.1%p)",
                "3. VTI: CAGR 12.1% (기여 +6.1%p)",
                "",
                "[주의] 수익률이 낮은 종목:",
                "    • INTC: CAGR 2.1% - 비중 조정 고려"
            ]
        ),
        .init(
            type: .warning,
            category: .risk,
            title: "변동성 분석: 포트폴리오 22.5%",
            message: "포트폴리오 변동성이 22.5%로 적정 수준이에요. 일부 종목이 변동성을 높이고 있어요.",
            emoji: "📊",
            details: [
                "[종목별 변동성]",
                "• AAPL: 28.5% 보통",
                "• TSLA: 45.2% [위험] 높음",
                "• VTI: 15.3% [좋음] 낮음",
                "",
                "[제안] 변동성 관리 방안:",
                "    1. 고변동성 종목 비중 축소",
                "    2. 저변동성 ETF(예: SCHD, VTI) 추가"
            ]
        ),
        .init(
            type: .suggestion,
            category: .diversification,
            title: "분산투자 분석: 5개 종목, 3개 섹터",
            message: "포트폴리오가 5개 종목, 3개 섹터에 분산되어 있어 리스크가 잘 관리되고 있어요.",
            emoji: "📊",
            details: [
                "[섹터별 배분]",
                "• 기술: 60% [주의] 높음",
                "• 금융: 25% 적정",
                "• 헬스케어: 15% 적정",
                "",
                "[지역별 배분]",
                "• 미국: 80%",
                "• 한국: 20%"
            ]
        )
    ]
    
    return ScrollView {
        VStack(spacing: 16) {
            ForEach(sampleInsights) { insight in
                DetailedInsightCard(insight: insight)
            }
        }
        .padding()
    }
    .background(Color.Exit.background)
}

