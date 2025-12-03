//
//  PlanHeaderView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 상단 네비게이션 바 - 현재 계획 설정값 표시
/// 모든 탭에서 항상 표시되어 사용자가 설정값을 잊지 않도록 함
struct PlanHeaderView: View {
    let scenario: Scenario?
    let currentAssetAmount: Double
    let hideAmounts: Bool
    let onScenarioTap: () -> Void
    
    /// 시나리오에 적용될 실제 자산 (자산 + 오프셋)
    private var effectiveAsset: Double {
        guard let scenario = scenario else { return currentAssetAmount }
        return scenario.effectiveAsset(with: currentAssetAmount)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 메인 헤더 컨텐츠
            headerContent
            
            // 하단 구분선
            Rectangle()
                .fill(Color.Exit.divider)
                .frame(height: 1)
        }
        .background(Color.Exit.background)
    }
    
    // MARK: - Header Content
    
    private var headerContent: some View {
        VStack(spacing: ExitSpacing.sm) {
            // 시나리오 이름 + 설정 버튼
            HStack {
                Button(action: onScenarioTap) {
                    HStack(spacing: ExitSpacing.xs) {
                        Text(scenario?.name ?? "내 계획")
                            .font(.Exit.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.Exit.accent)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.Exit.accent)
                    }
                    .padding(.horizontal, ExitSpacing.sm)
                    .padding(.vertical, ExitSpacing.xs)
                    .background(
                        Capsule()
                            .fill(Color.Exit.accent.opacity(0.15))
                    )
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            
            // 핵심 설정값 3개 (가로 배치)
            HStack(spacing: ExitSpacing.md) {
                // 현재 자산
                planValueItem(
                    icon: "banknote",
                    label: "자산",
                    value: hideAmounts ? "•••" : ExitNumberFormatter.formatToEokManWon(effectiveAsset),
                    valueColor: Color.Exit.primaryText
                )
                
                verticalDivider
                
                // 목표 월 수입
                planValueItem(
                    icon: "arrow.down.circle",
                    label: "목표 월수입",
                    value: ExitNumberFormatter.formatToManWon(scenario?.desiredMonthlyIncome ?? 0),
                    valueColor: Color.Exit.accent
                )
                
                verticalDivider
                
                // 목표 수익률
                planValueItem(
                    icon: "chart.line.uptrend.xyaxis",
                    label: "목표 수익률",
                    value: String(format: "%.1f%%", scenario?.preRetirementReturnRate ?? 0),
                    valueColor: Color.Exit.accent
                )
            }
        }
        .padding(.horizontal, ExitSpacing.md)
        .padding(.vertical, ExitSpacing.sm)
    }
    
    // MARK: - Plan Value Item
    
    private func planValueItem(
        icon: String,
        label: String,
        value: String,
        valueColor: Color
    ) -> some View {
        VStack(alignment: .center, spacing: 2) {
            // 레이블
            HStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundStyle(Color.Exit.tertiaryText)
                
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.Exit.tertiaryText)
            }
            
            // 값
            Text(value)
                .font(.Exit.caption)
                .fontWeight(.bold)
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Vertical Divider
    
    private var verticalDivider: some View {
        Rectangle()
            .fill(Color.Exit.divider)
            .frame(width: 1, height: 32)
    }
}

// MARK: - Compact Header (스크롤 시 축소 버전, 추후 사용)

struct PlanHeaderCompactView: View {
    let scenario: Scenario?
    let currentAssetAmount: Double
    let hideAmounts: Bool
    
    /// 시나리오에 적용될 실제 자산 (자산 + 오프셋)
    private var effectiveAsset: Double {
        guard let scenario = scenario else { return currentAssetAmount }
        return scenario.effectiveAsset(with: currentAssetAmount)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: ExitSpacing.md) {
                // 시나리오 이름
                Text(scenario?.name ?? "내 계획")
                    .font(.Exit.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.accent)
                
                Spacer()
                
                // 자산 | 월수입 | 수익률 (한 줄)
                HStack(spacing: ExitSpacing.sm) {
                    Text(hideAmounts ? "•••" : ExitNumberFormatter.formatToEokManWon(effectiveAsset))
                        .font(.Exit.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.Exit.primaryText)
                    
                    Text("•")
                        .foregroundStyle(Color.Exit.tertiaryText)
                    
                    Text(ExitNumberFormatter.formatToManWon(scenario?.desiredMonthlyIncome ?? 0))
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    Text("•")
                        .foregroundStyle(Color.Exit.tertiaryText)
                    
                    Text(String(format: "%.1f%%", scenario?.preRetirementReturnRate ?? 0))
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
            }
            .padding(.horizontal, ExitSpacing.md)
            .padding(.vertical, ExitSpacing.sm)
            
            // 하단 구분선
            Rectangle()
                .fill(Color.Exit.divider)
                .frame(height: 1)
        }
        .background(Color.Exit.background)
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
                onScenarioTap: {}
            )
            
            // 컴팩트 헤더
            PlanHeaderCompactView(
                scenario: nil,
                currentAssetAmount: 150_000_000,
                hideAmounts: false
            )
            
            Spacer()
        }
    }
    .preferredColorScheme(.dark)
}

