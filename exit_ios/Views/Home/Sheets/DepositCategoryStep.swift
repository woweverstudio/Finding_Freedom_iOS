//
//  DepositCategoryStep.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 스텝2: 카테고리 선택 뷰
struct DepositCategoryStep: View {
    let selectedYear: Int
    let selectedMonth: Int
    let totalAmount: Double
    let amountForCategory: (DepositCategory) -> Double
    let onSelectCategory: (DepositCategory) -> Void
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: ExitSpacing.lg) {
            // 선택된 월 표시
            HStack {
                Text("\(String(selectedYear))년 \(selectedMonth)월")
                    .font(.Exit.subheadline)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                Spacer()
                
                if totalAmount > 0 {
                    Text("총 \(ExitNumberFormatter.formatToManWon(totalAmount))")
                        .font(.Exit.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.Exit.accent)
                }
            }
            .padding(.horizontal, ExitSpacing.lg)
            .padding(.top, ExitSpacing.md)
            
            // 안내 텍스트
            Text("어떤 수입을 기록할까요?")
                .font(.Exit.title2)
                .foregroundStyle(Color.Exit.primaryText)
            
            // 카테고리 선택 리스트
            ScrollView(showsIndicators: false) {
                VStack(spacing: ExitSpacing.sm) {
                    ForEach(DepositCategory.allCases) { category in
                        CategorySelectRow(
                            category: category,
                            amount: amountForCategory(category),
                            onTap: {
                                onSelectCategory(category)
                            }
                        )
                    }
                }
                .padding(.horizontal, ExitSpacing.md)
            }
            
            Spacer()
            
            // 저장 버튼 (금액이 있을 때만)
            Button(action: onSave) {
                Text("저장하기")
                    .exitPrimaryButton(isEnabled: totalAmount > 0)
            }
            .disabled(totalAmount <= 0)
            .padding(.horizontal, ExitSpacing.md)
            .padding(.bottom, ExitSpacing.lg)
        }
    }
}

// MARK: - Category Select Row

struct CategorySelectRow: View {
    let category: DepositCategory
    let amount: Double
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ExitSpacing.md) {
                // 아이콘
                ZStack {
                    Circle()
                        .fill(amount > 0 ? Color.Exit.accent.opacity(0.2) : Color.Exit.secondaryCardBackground)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(amount > 0 ? Color.Exit.accent : Color.Exit.secondaryText)
                }
                
                // 카테고리 정보
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue)
                        .font(.Exit.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.Exit.primaryText)
                    
                    Text(category.description)
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
                
                Spacer()
                
                // 금액 표시 (이미 입력된 경우)
                if amount > 0 {
                    Text(ExitNumberFormatter.formatToManWon(amount))
                        .font(.Exit.body)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.Exit.accent)
                }
                
                // 화살표
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.Exit.tertiaryText)
            }
            .padding(ExitSpacing.md)
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        }
        .buttonStyle(.plain)
    }
}

