//
//  AssetUpdateSheet.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 자산 변동 업데이트 시트
struct AssetUpdateSheet: View {
    @Environment(\.appState) private var appState
    @Environment(\.dismiss) private var dismiss
    
    // @Observable 객체에서 바인딩을 사용하려면 @Bindable 필요
    private var bindableAppState: Bindable<AppStateManager> {
        Bindable(appState)
    }
    
    var body: some View {
        ZStack {
            Color.Exit.background.ignoresSafeArea()
            
            VStack(spacing: ExitSpacing.lg) {
                sheetHeader(title: "자산 변동 업데이트")
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ExitSpacing.xl) {
                        VStack(spacing: ExitSpacing.sm) {
                            Text("현재 총 투자 가능 자산")
                                .font(.Exit.body)
                                .foregroundStyle(Color.Exit.secondaryText)
                            
                            // 원 단위 (천 단위 콤마)
                            Text(ExitNumberFormatter.formatToWon(appState.totalAssetsInput))
                                .font(.Exit.numberDisplay)
                                .foregroundStyle(appState.totalAssetsInput < 0 ? Color.Exit.warning : Color.Exit.primaryText)
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.1), value: appState.totalAssetsInput)
                        }
                    }
                    .padding(.top, ExitSpacing.lg)
                }
                
                CustomNumberKeyboard(
                    value: bindableAppState.totalAssetsInput,
                    showNegativeToggle: true
                )
                
                Button {
                    appState.submitAssetUpdate()
                } label: {
                    Text("업데이트 완료")
                        .exitPrimaryButton()
                }
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
