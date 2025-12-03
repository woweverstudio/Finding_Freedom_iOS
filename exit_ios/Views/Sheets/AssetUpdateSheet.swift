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
    
    @State private var showAssetTypes = false
    
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
                        
                        Button {
                            withAnimation(.bouncy) {
                                showAssetTypes.toggle()
                            }
                        } label: {
                            HStack {
                                Text("보유 자산 종류 변경")
                                    .font(.Exit.subheadline)
                                    .foregroundStyle(Color.Exit.secondaryText)
                                
                                Spacer()
                                
                                Text("\(appState.selectedAssetTypes.count)개 선택")
                                    .font(.Exit.caption)
                                    .foregroundStyle(Color.Exit.accent)
                                
                                Image(systemName: showAssetTypes ? "chevron.up" : "chevron.down")
                                    .foregroundStyle(Color.Exit.tertiaryText)
                            }
                            .padding(ExitSpacing.md)
                            .background(Color.Exit.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
                        }
                        .padding(.horizontal, ExitSpacing.md)
                        
                        if showAssetTypes {
                            assetTypeGrid
                                .transition(.scale)
                        }
                    }
                    .padding(.top, ExitSpacing.lg)
                }
                
                if !showAssetTypes {
                    CustomNumberKeyboard(
                        value: bindableAppState.totalAssetsInput,
                        showNegativeToggle: true
                    )
                    .transition(.scale)
                }
                
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
    
    private var assetTypeGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: ExitSpacing.md) {
            ForEach(UserProfile.availableAssetTypes, id: \.self) { type in
                Button {
                    appState.toggleAssetType(type)
                } label: {
                    HStack {
                        Text(type)
                            .font(.Exit.body)
                        Spacer()
                        if appState.selectedAssetTypes.contains(type) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                        }
                    }
                    .foregroundStyle(appState.selectedAssetTypes.contains(type) ? Color.Exit.primaryText : Color.Exit.secondaryText)
                    .padding(ExitSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: ExitRadius.sm)
                            .fill(appState.selectedAssetTypes.contains(type) ? Color.Exit.accent.opacity(0.2) : Color.Exit.secondaryCardBackground)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, ExitSpacing.md)
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
