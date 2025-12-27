//
//  DDayHeaderCard.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// D-Day 헤더 카드
/// 은퇴까지 남은 기간 또는 은퇴 가능 상태를 표시
struct DDayHeaderCard: View {
    let result: RetirementCalculationResult?
    let animationTrigger: UUID
    @Binding var showFormulaSheet: Bool
    
    var body: some View {
        ExitCard(style: .elevated, radius: ExitRadius.xl) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: ExitSpacing.md) {
                    mainTitle
                }
                .frame(maxWidth: .infinity)
                
                // 계산방법 물음표 버튼 (우측 상단)
                Button {
                    showFormulaSheet = true
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.Exit.tertiaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // MARK: - Main Title
    
    private var mainTitle: some View {
        Group {
            if let result = result {
                if result.isRetirementReady {
                    retirementReadyView(result: result)
                } else {
                    VStack(spacing: ExitSpacing.sm) {
                        Text("회사 탈출까지")
                            .font(.Exit.body)
                            .foregroundStyle(Color.Exit.secondaryText)
                        
                        DDayRollingView(
                            months: result.monthsToRetirement,
                            animationID: animationTrigger
                        )
                        
                        Text("남았습니다.")
                            .font(.Exit.body)
                            .foregroundStyle(Color.Exit.secondaryText)
                    }
                }
            } else {
                Text("계산 중...")
                    .font(.Exit.title2)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
        }
    }
    
    // MARK: - Retirement Ready View
    
    private func retirementReadyView(result: RetirementCalculationResult) -> some View {
        VStack(spacing: ExitSpacing.md) {
            Text("🎉")
                .font(.system(size: 40))
            
            Text("은퇴 가능합니다!")
                .font(.Exit.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.Exit.accent)
            
            if let requiredRate = result.requiredReturnRate {
                VStack(spacing: ExitSpacing.xs) {
                    Text("필요 수익률")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    Text(String(format: "연 %.2f%%", requiredRate))
                        .font(.Exit.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(requiredRate < 4 ? Color.Exit.positive : Color.Exit.accent)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        DDayHeaderCard(
            result: nil,
            animationTrigger: UUID(),
            showFormulaSheet: .constant(false)
        )
    }
    .preferredColorScheme(.dark)
}

