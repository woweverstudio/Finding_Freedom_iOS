//
//  ProgressSectionView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 진행률 섹션
/// 진행률 링 차트와 금액 숨김 토글을 포함
struct ProgressSectionView: View {
    let result: RetirementCalculationResult?
    let progressValue: Double
    let animationTrigger: UUID
    @Binding var hideAmounts: Bool
    @Binding var showFormulaSheet: Bool
    
    var body: some View {
        VStack(spacing: ExitSpacing.lg) {
            // 진행률 링 차트 + 토글 버튼
            if let result = result {
                ZStack(alignment: .bottom) {
                    ProgressRingView(
                        progress: progressValue,
                        currentAmount: ExitNumberFormatter.formatToEokManWon(result.currentAssets),
                        targetAmount: ExitNumberFormatter.formatToEokManWon(result.targetAssets),
                        percentText: ExitNumberFormatter.formatPercentInt(result.progressPercent),
                        hideAmounts: hideAmounts,
                        animationID: animationTrigger
                    )
                    .frame(width: 200, height: 200)
                    
                    HStack {
                        Spacer()
                        amountVisibilityToggle
                    }
                }
            }
        }
        .padding(.horizontal, ExitSpacing.md)
        .sheet(isPresented: $showFormulaSheet) {
            CalculationFormulaSheet()
        }
    }
    
    // MARK: - Amount Visibility Toggle
    
    private var amountVisibilityToggle: some View {
        ExitChip(
            text: hideAmounts ? "금액 보기" : "금액 숨김",
            isSelected: hideAmounts
        ) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                hideAmounts.toggle()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        ProgressSectionView(
            result: nil,
            progressValue: 0.5,
            animationTrigger: UUID(),
            hideAmounts: .constant(false),
            showFormulaSheet: .constant(false)
        )
    }
    .preferredColorScheme(.dark)
}

