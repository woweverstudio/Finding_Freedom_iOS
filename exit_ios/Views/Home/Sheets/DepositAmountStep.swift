//
//  DepositAmountStep.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 스텝3: 금액 입력 뷰
struct DepositAmountStep: View {
    let selectedYear: Int
    let selectedMonth: Int
    let selectedCategory: DepositCategory
    @Binding var amount: Double
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 선택된 월 표시
            HStack {
                Text("\(String(selectedYear))년 \(selectedMonth)월")
                    .font(.Exit.subheadline)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                Spacer()
            }
            .padding(.horizontal, ExitSpacing.lg)
            .padding(.top, ExitSpacing.md)
            
            // 선택된 카테고리 카드
            selectedCategoryCard
                .padding(.horizontal, ExitSpacing.md)
                .padding(.top, ExitSpacing.md)
            
            // 금액 표시
            VStack(spacing: ExitSpacing.xs) {
                Text(ExitNumberFormatter.formatToWon(amount))
                    .font(.Exit.numberDisplay)
                    .foregroundStyle(Color.Exit.primaryText)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.1), value: amount)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ExitSpacing.xl)
            
            Spacer()
            
            // 키패드
            CustomNumberKeyboard(value: $amount)
            
            // 완료 버튼
            Button(action: onComplete) {
                Text("완료")
                    .exitPrimaryButton(isEnabled: true)
            }
            .padding(.horizontal, ExitSpacing.md)
            .padding(.bottom, ExitSpacing.lg)
        }
    }
    
    // MARK: - Selected Category Card
    
    private var selectedCategoryCard: some View {
        HStack(spacing: ExitSpacing.md) {
            // 아이콘
            ZStack {
                Circle()
                    .fill(Color.Exit.accent.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: selectedCategory.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.Exit.accent)
            }
            
            // 카테고리 정보
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedCategory.rawValue)
                    .font(.Exit.body)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Text(selectedCategory.description)
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            
            Spacer()
            
            // 패시브인컴 뱃지
            if selectedCategory.isPassiveIncome {
                Text("패시브")
                    .font(.Exit.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.Exit.accent)
                    .padding(.horizontal, ExitSpacing.sm)
                    .padding(.vertical, 4)
                    .background(Color.Exit.accent.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(ExitSpacing.md)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
    }
}

