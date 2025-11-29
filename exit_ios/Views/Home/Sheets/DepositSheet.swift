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
    
    @State private var showPassiveIncomeInput = false
    
    var body: some View {
        ZStack {
            Color.Exit.background.ignoresSafeArea()
            
            VStack(spacing: ExitSpacing.lg) {
                sheetHeader(title: "입금하기")
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ExitSpacing.xl) {
                        VStack(spacing: ExitSpacing.sm) {
                            Text("이번 달 투자·저축 입금액")
                                .font(.Exit.body)
                                .foregroundStyle(Color.Exit.secondaryText)
                            
                            Text(ExitNumberFormatter.formatToEokManWon(viewModel.depositAmount))
                                .font(.Exit.numberDisplay)
                                .foregroundStyle(Color.Exit.primaryText)
                        }
                        
                        Button {
                            withAnimation {
                                showPassiveIncomeInput.toggle()
                            }
                        } label: {
                            HStack {
                                Text("이번 달 받은 패시브인컴 총액 (선택)")
                                    .font(.Exit.subheadline)
                                    .foregroundStyle(Color.Exit.secondaryText)
                                
                                Spacer()
                                
                                Image(systemName: showPassiveIncomeInput ? "chevron.up" : "chevron.down")
                                    .foregroundStyle(Color.Exit.tertiaryText)
                            }
                            .padding(ExitSpacing.md)
                            .background(Color.Exit.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
                        }
                        .padding(.horizontal, ExitSpacing.md)
                        
                        if showPassiveIncomeInput {
                            VStack(spacing: ExitSpacing.sm) {
                                Text("배당 + 이자 + 월세 등")
                                    .font(.Exit.caption)
                                    .foregroundStyle(Color.Exit.tertiaryText)
                                
                                Text(ExitNumberFormatter.formatToManWon(viewModel.passiveIncomeAmount))
                                    .font(.Exit.title2)
                                    .foregroundStyle(Color.Exit.accent)
                            }
                        }
                    }
                    .padding(.top, ExitSpacing.lg)
                }
                
                CustomNumberKeyboard(
                    value: showPassiveIncomeInput ? $viewModel.passiveIncomeAmount : $viewModel.depositAmount
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

