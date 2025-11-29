//
//  AssetUpdateSheet.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 자산 변동 업데이트 시트
struct AssetUpdateSheet: View {
    @Bindable var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    
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
                            Text(ExitNumberFormatter.formatToWon(viewModel.totalAssetsInput))
                                .font(.Exit.numberDisplay)
                                .foregroundStyle(viewModel.totalAssetsInput < 0 ? Color.Exit.warning : Color.Exit.primaryText)
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.1), value: viewModel.totalAssetsInput)
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
                                
                                Text("\(viewModel.selectedAssetTypes.count)개 선택")
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
                        value: $viewModel.totalAssetsInput,
                        showNegativeToggle: true
                    )
                    .transition(.scale)
                }
                
                Button {
                    viewModel.submitAssetUpdate()
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
                    viewModel.toggleAssetType(type)
                } label: {
                    HStack {
                        Text(type)
                            .font(.Exit.body)
                        Spacer()
                        if viewModel.selectedAssetTypes.contains(type) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                        }
                    }
                    .foregroundStyle(viewModel.selectedAssetTypes.contains(type) ? Color.Exit.primaryText : Color.Exit.secondaryText)
                    .padding(ExitSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: ExitRadius.sm)
                            .fill(viewModel.selectedAssetTypes.contains(type) ? Color.Exit.accent.opacity(0.2) : Color.Exit.secondaryCardBackground)
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
