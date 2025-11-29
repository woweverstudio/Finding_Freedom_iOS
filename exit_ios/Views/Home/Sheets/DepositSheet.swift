//
//  DepositSheet.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 입금 유형
enum DepositType: String, CaseIterable, Identifiable {
    case salary = "월급/보너스"
    case dividend = "배당금"
    case interest = "이자 수입"
    case rent = "월세/임대료"
    case investmentProfit = "투자 수익"
    case other = "기타 입금"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .salary: return "briefcase.fill"
        case .dividend: return "chart.line.uptrend.xyaxis"
        case .interest: return "banknote.fill"
        case .rent: return "house.fill"
        case .investmentProfit: return "arrow.up.right.circle.fill"
        case .other: return "dollarsign.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .salary: return "근로소득, 상여금 등"
        case .dividend: return "주식/펀드 배당금"
        case .interest: return "예적금, 채권 이자"
        case .rent: return "부동산 임대 수입"
        case .investmentProfit: return "매매 차익, 기타 투자 수익"
        case .other: return "그 외 기타 수입"
        }
    }
    
    /// 패시브인컴 여부
    var isPassiveIncome: Bool {
        switch self {
        case .salary, .other:
            return false
        case .dividend, .interest, .rent, .investmentProfit:
            return true
        }
    }
    
    var accentColor: Color {
        Color.Exit.accent
    }
}

/// 입금 시트 스텝
enum DepositStep: Int, CaseIterable {
    case selectType = 0
    case enterAmount = 1
    
    var title: String {
        switch self {
        case .selectType: return "입금 유형 선택"
        case .enterAmount: return "금액 입력"
        }
    }
}

/// 입금 시트
struct DepositSheet: View {
    @Bindable var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep: DepositStep = .selectType
    @State private var selectedType: DepositType?
    @State private var showDatePicker = false
    
    var body: some View {
        ZStack {
            Color.Exit.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 헤더
                sheetHeader
                
                // 진행률 표시
                progressIndicator
                
                // 스텝별 컨텐츠
                Group {
                    switch currentStep {
                    case .selectType:
                        typeSelectionStep
                    case .enterAmount:
                        amountInputStep
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .presentationDetents([.large])
    }
    
    // MARK: - Header
    
    private var sheetHeader: some View {
        HStack {
            Button {
                if currentStep == .selectType {
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        currentStep = .selectType
                        showDatePicker = false
                    }
                }
            } label: {
                Image(systemName: currentStep == .selectType ? "xmark" : "chevron.left")
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            
            Spacer()
            
            Text(currentStep.title)
                .font(.Exit.title3)
                .foregroundStyle(Color.Exit.primaryText)
            
            Spacer()
            
            // 균형을 위한 투명 아이콘
            Image(systemName: "xmark")
                .font(.Exit.body)
                .foregroundStyle(.clear)
        }
        .padding(.horizontal, ExitSpacing.lg)
        .padding(.top, ExitSpacing.lg)
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: ExitSpacing.sm) {
            ForEach(DepositStep.allCases, id: \.rawValue) { step in
                Capsule()
                    .fill(step.rawValue <= currentStep.rawValue ? Color.Exit.accent : Color.Exit.divider)
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .padding(.horizontal, ExitSpacing.lg)
        .padding(.top, ExitSpacing.md)
    }
    
    // MARK: - Step 1: Type Selection
    
    private var typeSelectionStep: some View {
        VStack(spacing: ExitSpacing.lg) {
            // 안내 텍스트
            VStack(spacing: ExitSpacing.sm) {
                Text("어떤 종류의 입금인가요?")
                    .font(.Exit.title2)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Text("패시브인컴은 안전점수에 반영됩니다")
                    .font(.Exit.subheadline)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            .padding(.top, ExitSpacing.xl)
            
            // 카테고리 그리드
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: ExitSpacing.md) {
                    ForEach(DepositType.allCases) { type in
                        DepositTypeCard(
                            type: type,
                            isSelected: selectedType == type
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedType = type
                            }
                        }
                    }
                }
                .padding(.horizontal, ExitSpacing.lg)
            }
            
            Spacer()
            
            // 다음 버튼
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    currentStep = .enterAmount
                }
            } label: {
                Text("다음")
                    .exitPrimaryButton(isEnabled: selectedType != nil)
            }
            .disabled(selectedType == nil)
            .padding(.horizontal, ExitSpacing.md)
            .padding(.bottom, ExitSpacing.lg)
        }
    }
    
    // MARK: - Step 2: Amount Input
    
    private var amountInputStep: some View {
        VStack(spacing: ExitSpacing.lg) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: ExitSpacing.xl) {
                    // 입금액 표시
                    VStack(spacing: ExitSpacing.sm) {
                        Text("입금액")
                            .font(.Exit.body)
                            .foregroundStyle(Color.Exit.secondaryText)
                        
                        Text(ExitNumberFormatter.formatToWon(viewModel.depositAmount))
                            .font(.Exit.numberDisplay)
                            .foregroundStyle(Color.Exit.primaryText)
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.1), value: viewModel.depositAmount)
                    }
                    
                    // 입금 날짜 선택
                    depositDateSection
                }
                .padding(.top, ExitSpacing.lg)
            }
            
            if !showDatePicker {
                CustomNumberKeyboard(
                    value: $viewModel.depositAmount
                )
            }
            
            Button {
                submitDeposit()
            } label: {
                Text("입금 완료")
                    .exitPrimaryButton(isEnabled: viewModel.depositAmount > 0)
            }
            .disabled(viewModel.depositAmount <= 0)
            .padding(.horizontal, ExitSpacing.md)
            .padding(.bottom, ExitSpacing.lg)
        }
    }
    
    // MARK: - Deposit Date Section
    
    private var depositDateSection: some View {
        VStack(spacing: ExitSpacing.sm) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showDatePicker.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                        Text("입금 날짜")
                            .font(.Exit.subheadline)
                            .foregroundStyle(Color.Exit.secondaryText)
                        
                        Text(formattedDate(viewModel.depositDate))
                            .font(.Exit.body)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.Exit.primaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "calendar")
                        .font(.Exit.body)
                        .foregroundStyle(Color.Exit.accent)
                }
                .padding(ExitSpacing.md)
                .background(Color.Exit.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, ExitSpacing.md)
            
            if showDatePicker {
                DatePicker(
                    "입금 날짜",
                    selection: $viewModel.depositDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(Color.Exit.accent)
                .padding(ExitSpacing.md)
                .background(Color.Exit.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
                .padding(.horizontal, ExitSpacing.md)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .onChange(of: viewModel.depositDate) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showDatePicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - Submit
    
    private func submitDeposit() {
        guard let type = selectedType else { return }
        
        // 패시브인컴인 경우 passiveIncome으로 처리
        viewModel.submitDeposit(isPassiveIncome: type.isPassiveIncome, depositType: type.rawValue)
    }
    
    // MARK: - Helpers
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 (E)"
        return formatter.string(from: date)
    }
}

// MARK: - Deposit Type Card

private struct DepositTypeCard: View {
    let type: DepositType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: ExitSpacing.sm) {
                // 아이콘
                ZStack {
                    Circle()
                        .fill(isSelected ? type.accentColor.opacity(0.2) : Color.Exit.secondaryCardBackground)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: type.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isSelected ? type.accentColor : Color.Exit.secondaryText)
                }
                
                // 타이틀
                Text(type.rawValue)
                    .font(.Exit.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? Color.Exit.primaryText : Color.Exit.secondaryText)
                
                // 설명
                Text(type.description)
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 120)
            .padding(ExitSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: ExitRadius.lg)
                    .fill(Color.Exit.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ExitRadius.lg)
                    .stroke(isSelected ? type.accentColor : Color.Exit.divider, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    DepositSheet(viewModel: HomeViewModel())
        .preferredColorScheme(.dark)
}
