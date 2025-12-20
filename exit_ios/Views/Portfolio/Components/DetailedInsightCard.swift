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
    
    /// 상세 정보가 있는지 여부
    private var hasDetails: Bool {
        guard let details = insight.details else { return false }
        return !details.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.isEmpty
    }
    
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
            
            // 확장 버튼 (상세 정보가 있는 경우에만)
            if hasDetails {
                expandButton
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
            } else if let parsed = parseTaggedText(detail) {
                // 태그가 있는 경우: 제목과 내용 분리
                VStack(alignment: .leading, spacing: 2) {
                    Text(parsed.tag)
                        .font(.Exit.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(parsed.tagColor)
                    
                    if !parsed.content.isEmpty {
                        Text(parsed.content)
                            .font(.Exit.subheadline)
                            .foregroundStyle(Color.Exit.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else {
                // 일반 텍스트
                Text(detail)
                    .font(.Exit.subheadline)
                    .foregroundStyle(Color.Exit.secondaryText)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    /// 태그가 있는 텍스트 파싱 (예: "[주의] 안정성(17/30점): 내용")
    private func parseTaggedText(_ text: String) -> (tag: String, content: String, tagColor: Color)? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        
        // 태그 패턴 확인
        let tagPatterns: [(prefix: String, color: Color)] = [
            ("[좋음]", Color.Exit.positive),
            ("[우수]", Color.Exit.positive),
            ("[강점]", Color.Exit.positive),
            ("[주의]", Color.Exit.warning),
            ("[경고]", Color.Exit.warning),
            ("[위험]", Color.Exit.warning),
            ("[제안]", Color.Exit.caution),
            ("[팁]", Color.Exit.caution)
        ]
        
        for (prefix, color) in tagPatterns {
            if trimmed.hasPrefix(prefix) {
                // 태그 뒤의 내용 추출
                let afterTag = String(trimmed.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                
                // 콜론(:)이 있으면 제목과 내용 분리
                if let colonIndex = afterTag.firstIndex(of: ":") {
                    let title = prefix + " " + String(afterTag[..<colonIndex])
                    let content = String(afterTag[afterTag.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                    return (title, content, color)
                } else {
                    // 콜론이 없으면 전체가 제목
                    return (trimmed, "", color)
                }
            }
        }
        
        // 대괄호로 시작하는 제목 스타일 (예: [종목별 CAGR 순위])
        if trimmed.hasPrefix("[") && trimmed.contains("]") {
            if let endIndex = trimmed.firstIndex(of: "]") {
                let tag = String(trimmed[...endIndex])
                let afterTag = String(trimmed[trimmed.index(after: endIndex)...]).trimmingCharacters(in: .whitespaces)
                return (tag, afterTag, Color.Exit.primaryText)
            }
        }
        
        return nil
    }
    
    // MARK: - Expand Button
    
    private var expandButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: ExitSpacing.xs) {
                Text(isExpanded ? "접기" : "상세 보기")
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
            category: .overall,
            title: "종합 평가: A등급 (85점)",
            message: "우수한 포트폴리오입니다! 총점 85점으로 대부분의 영역에서 좋은 성과를 보이고 있어요.",
            emoji: "👍",
            details: [
                "[좋음] 수익성: 양호한 수준",
                "[주의] 안정성(17/30점): 변동성 낮은 ETF나 배당주 추가 권장",
                "[좋음] 효율성: 양호한 수준"
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
                "• TSLA: 45.2% 높음",
                "• VTI: 15.3% 낮음",
                "",
                "[주의] 높은 변동성 종목 (1개):",
                "• TSLA - 포트폴리오 변동성의 주요 원인",
                "",
                "[제안] 변동성 관리 방안:",
                "1. 고변동성 종목 비중 축소",
                "2. 저변동성 ETF(예: SCHD, VTI) 추가"
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
                "• 기술: 60% 높음",
                "• 금융: 25% 적정",
                "• 헬스케어: 15% 적정",
                "",
                "[경고] 섹터 집중 위험:",
                "• 기술 섹터 비중이 60%로 높음",
                "[제안] 다른 섹터 종목 추가로 리스크 분산 권장: 헬스케어, 필수소비재, 금융 섹터"
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

