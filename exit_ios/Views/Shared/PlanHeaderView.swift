//
//  PlanHeaderView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

// MARK: - Scroll Offset Preference Key

/// 스크롤 오프셋을 부모 뷰로 전달하기 위한 PreferenceKey
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// 스크롤 오프셋 감지를 위한 뷰 모디파이어
struct ScrollOffsetModifier: ViewModifier {
    let coordinateSpace: String
    @Binding var offset: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: -geometry.frame(in: .named(coordinateSpace)).minY
                        )
                }
            )
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                offset = value
            }
    }
}

extension View {
    func trackScrollOffset(in coordinateSpace: String, offset: Binding<CGFloat>) -> some View {
        modifier(ScrollOffsetModifier(coordinateSpace: coordinateSpace, offset: offset))
    }
}

// MARK: - Plan Header View (통합)

/// 상단 네비게이션 바 - 현재 계획 설정값 표시
/// 스크롤에 따라 일반/컴팩트 모드 전환
struct PlanHeaderView: View {
    let scenario: Scenario?
    let currentAssetAmount: Double
    let hideAmounts: Bool
    let isCompact: Bool
    let onScenarioTap: () -> Void
    
    /// 시나리오에 적용될 실제 자산 (자산 + 오프셋)
    private var effectiveAsset: Double {
        guard let scenario = scenario else { return currentAssetAmount }
        return scenario.effectiveAsset(with: currentAssetAmount)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isCompact {
                compactHeader
            } else {
                expandedHeader
            }
        }
        .background(Color.Exit.background)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isCompact)
    }
    
    // MARK: - Expanded Header (기본)
    
    private var expandedHeader: some View {
        VStack(spacing: 0) {
            headerCard
                .padding(.horizontal, ExitSpacing.sm)
                .padding(.vertical, ExitSpacing.sm)
        }
    }
    
    // MARK: - Compact Header (스크롤 시)
    
    private var compactHeader: some View {
        Button(action: onScenarioTap) {
            HStack(spacing: ExitSpacing.sm) {
                // 시나리오 이름
                Text(scenario?.name ?? "내 계획")
                    .font(.Exit.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.accent)
                
                Spacer()
                
                // 핵심 정보만 (자산 • 월수입 • 투자 • 수익률)
                HStack(spacing: 4) {
                    Text(hideAmounts ? "•••" : ExitNumberFormatter.formatToEokManWon(effectiveAsset))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.Exit.primaryText)
                    
                    Text("•")
                        .foregroundStyle(Color.Exit.tertiaryText)
                    
                    Text(ExitNumberFormatter.formatToManWon(scenario?.desiredMonthlyIncome ?? 0))
                        .foregroundStyle(Color.Exit.accent)
                    
                    Text("•")
                        .foregroundStyle(Color.Exit.tertiaryText)
                    
                    Text(ExitNumberFormatter.formatToManWon(scenario?.monthlyInvestment ?? 0))
                        .foregroundStyle(Color.Exit.positive)
                    
                    Text("•")
                        .foregroundStyle(Color.Exit.tertiaryText)
                    
                    Text(String(format: "%.1f%%", scenario?.preRetirementReturnRate ?? 0))
                        .foregroundStyle(Color.Exit.accent)
                }
                .font(.Exit.caption2)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.Exit.tertiaryText)
            }
            .padding(.horizontal, ExitSpacing.md)
            .padding(.vertical, ExitSpacing.sm)
            .background(Color.Exit.cardBackground)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Header Card (테이블 스타일)
    
    private var headerCard: some View {
        VStack(spacing: 0) {
            // 시나리오 이름 헤더
            Button(action: onScenarioTap) {
                HStack {
                    Text(scenario?.name ?? "내 계획")
                        .font(.Exit.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.Exit.accent)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.Exit.accent.opacity(0.7))
                    
                    Spacer()
                }
                .padding(.horizontal, ExitSpacing.md)
                .padding(.vertical, ExitSpacing.sm)
                .background(Color.Exit.accent.opacity(0.08))
            }
            .buttonStyle(.plain)
            
            // 테이블 본문
            VStack(spacing: 0) {
                // 1행: 현재 자산 | 목표 월수입
                HStack(spacing: 0) {
                    tableCell(
                        label: "현재 자산",
                        value: hideAmounts ? "•••" : ExitNumberFormatter.formatToEokManWon(effectiveAsset),
                        valueColor: Color.Exit.primaryText
                    )
                    
                    Rectangle()
                        .fill(Color.Exit.divider)
                        .frame(width: 1)
                    
                    tableCell(
                        label: "목표 월수입",
                        value: ExitNumberFormatter.formatToManWon(scenario?.desiredMonthlyIncome ?? 0),
                        valueColor: Color.Exit.accent
                    )
                }
                .frame(height: 44)
                
                Rectangle()
                    .fill(Color.Exit.divider)
                    .frame(height: 1)
                
                // 2행: 매월 투자 | 목표 수익률
                HStack(spacing: 0) {
                    tableCell(
                        label: "매월 투자",
                        value: ExitNumberFormatter.formatToManWon(scenario?.monthlyInvestment ?? 0),
                        valueColor: Color.Exit.positive
                    )
                    
                    Rectangle()
                        .fill(Color.Exit.divider)
                        .frame(width: 1)
                    
                    tableCell(
                        label: "목표 수익률",
                        value: String(format: "%.1f%%", scenario?.preRetirementReturnRate ?? 0),
                        valueColor: Color.Exit.accent
                    )
                }
                .frame(height: 44)
            }
        }
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: ExitRadius.md)
                .stroke(Color.Exit.divider, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Table Cell
    
    private func tableCell(
        label: String,
        value: String,
        valueColor: Color
    ) -> some View {
        HStack {
            Text(label)
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.tertiaryText)
            
            Spacer()
            
            Text(value)
                .font(.Exit.caption)
                .fontWeight(.semibold)
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, ExitSpacing.sm)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        
        VStack(spacing: ExitSpacing.xl) {
            // 일반 헤더
            PlanHeaderView(
                scenario: nil,
                currentAssetAmount: 150_000_000,
                hideAmounts: false,
                isCompact: false,
                onScenarioTap: {}
            )
            
            // 컴팩트 헤더
            PlanHeaderView(
                scenario: nil,
                currentAssetAmount: 150_000_000,
                hideAmounts: false,
                isCompact: true,
                onScenarioTap: {}
            )
            
            Spacer()
        }
    }
    .preferredColorScheme(.dark)
}

