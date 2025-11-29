//
//  DepositSheet.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 입금 시트
struct DepositSheet: View {
    @Bindable var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDatePicker = false
    
    var body: some View {
        ZStack {
            Color.Exit.background.ignoresSafeArea()
            
            VStack(spacing: ExitSpacing.lg) {
                sheetHeader(title: "입금하기")
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ExitSpacing.xl) {
                        // 입금액 표시
                        VStack(spacing: ExitSpacing.sm) {
                            Text("이번 달 투자·저축 입금액")
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
                
                CustomNumberKeyboard(
                    value: $viewModel.depositAmount
                )
                
                Button {
                    viewModel.submitDeposit()
                } label: {
                    Text("입금 완료")
                        .exitPrimaryButton(isEnabled: viewModel.depositAmount > 0)
                }
                .disabled(viewModel.depositAmount <= 0)
                .padding(.horizontal, ExitSpacing.md)
                .padding(.bottom, ExitSpacing.lg)
            }
        }
        .presentationDetents([.large])
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
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 (E)"
        return formatter.string(from: date)
    }
    
    private func sheetHeader(title: String) -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            
            Spacer()
            
            Text(title)
                .font(.Exit.title3)
                .foregroundStyle(Color.Exit.primaryText)
            
            Spacer()
            
            Image(systemName: "xmark")
                .font(.Exit.body)
                .foregroundStyle(.clear)
        }
        .padding(.horizontal, ExitSpacing.lg)
        .padding(.top, ExitSpacing.lg)
    }
}
