//
//  AmountEditSheet.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 금액 편집 타입
enum AmountEditType: Identifiable {
    case currentAsset
    case monthlyInvestment
    case desiredMonthlyIncome
    
    var id: String {
        switch self {
        case .currentAsset: return "currentAsset"
        case .monthlyInvestment: return "monthlyInvestment"
        case .desiredMonthlyIncome: return "desiredMonthlyIncome"
        }
    }
    
    var title: String {
        switch self {
        case .currentAsset:
            return "현재 자산"
        case .monthlyInvestment:
            return "매월 투자금액"
        case .desiredMonthlyIncome:
            return "은퇴 후 희망 월수입"
        }
    }
    
    var subtitle: String {
        switch self {
        case .currentAsset:
            return "현재 보유하고 있는 순자산을 입력해주세요"
        case .monthlyInvestment:
            return "매월 투자할 금액을 입력해주세요"
        case .desiredMonthlyIncome:
            return "은퇴 후 매월 필요한 금액을 입력해주세요"
        }
    }
    
    var showNegativeToggle: Bool {
        switch self {
        case .currentAsset:
            return true
        default:
            return false
        }
    }
}

/// 금액 편집 풀스크린 시트
struct AmountEditSheet: View {
    let type: AmountEditType
    let initialValue: Double
    let onConfirm: (Double) -> Void
    let onDismiss: () -> Void
    
    @State private var editingValue: Double
    
    init(
        type: AmountEditType,
        initialValue: Double,
        onConfirm: @escaping (Double) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.type = type
        self.initialValue = initialValue
        self.onConfirm = onConfirm
        self.onDismiss = onDismiss
        self._editingValue = State(initialValue: initialValue)
    }
    
    var body: some View {
        ZStack {
            // 배경
            Color.Exit.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 메인 컨텐츠
                VStack(spacing: ExitSpacing.xl) {
                    Spacer()
                    
                    // 제목
                    VStack(spacing: ExitSpacing.sm) {
                        Text(type.title)
                            .font(.Exit.title)
                            .foregroundStyle(Color.Exit.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text(type.subtitle)
                            .font(.Exit.body)
                            .foregroundStyle(Color.Exit.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, ExitSpacing.lg)
                    
                    // 금액 표시
                    amountDisplay
                    
                    Spacer()
                    
                    // 키보드
                    CustomNumberKeyboard(
                        value: $editingValue,
                        showNegativeToggle: type.showNegativeToggle
                    )
                }
                
                // 하단 버튼
                bottomButtons
            }
        }
    }
    
    // MARK: - Amount Display
    
    private var amountDisplay: some View {
        VStack(spacing: ExitSpacing.sm) {
            Text(ExitNumberFormatter.formatInputDisplay(abs(editingValue)))
                .font(.Exit.numberDisplay)
                .foregroundStyle(editingValue < 0 ? Color.Exit.warning : Color.Exit.primaryText)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.15), value: editingValue)
            
            Text(ExitNumberFormatter.formatToEokManWon(editingValue))
                .font(.Exit.title3)
                .foregroundStyle(Color.Exit.accent)
        }
    }
    
    // MARK: - Bottom Buttons
    
    private var bottomButtons: some View {
        HStack(spacing: ExitSpacing.md) {
            // 취소 버튼
            Button {
                onDismiss()
            } label: {
                Text("취소")
                    .exitSecondaryButton()
            }
            
            // 확인 버튼
            Button {
                onConfirm(editingValue)
            } label: {
                Text("확인")
                    .exitPrimaryButton(isEnabled: true)
            }
        }
        .padding(.horizontal, ExitSpacing.md)
        .padding(.bottom, ExitSpacing.xl)
    }
}

// MARK: - Preview

#Preview {
    AmountEditSheet(
        type: .currentAsset,
        initialValue: 120_000_000,
        onConfirm: { _ in },
        onDismiss: { }
    )
    .preferredColorScheme(.dark)
}

