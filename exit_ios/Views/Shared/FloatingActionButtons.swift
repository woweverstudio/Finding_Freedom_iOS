//
//  FloatingActionButtons.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 하단 플로팅 액션 버튼 (자산 업데이트 + 입금하기)
struct FloatingActionButtons: View {
    @Environment(\.appState) private var appState
    
    var body: some View {
        HStack(spacing: ExitSpacing.md) {
            // 자산 변동 업데이트 (좌측)
            Button {
                // 현재 Asset 값으로 초기화
                appState.totalAssetsInput = appState.currentAssetAmount
                if let asset = appState.currentAsset {
                    appState.selectedAssetTypes = Set(asset.assetTypes)
                }
                appState.showAssetUpdateSheet = true
            } label: {
                HStack(spacing: ExitSpacing.xs) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14, weight: .semibold))
                    Text("자산 업데이트")
                        .font(.Exit.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color.Exit.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.Exit.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: ExitRadius.md)
                        .stroke(Color.Exit.divider, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            
            // 입금하기 (우측)
            Button {
                appState.depositAmount = 0
                appState.depositDate = Date()
                appState.showDepositSheet = true
            } label: {
                HStack(spacing: ExitSpacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("입금하기")
                        .font(.Exit.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(LinearGradient.exitAccent)
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
                .exitButtonShadow()
            }
            .buttonStyle(.plain)
        }
        .padding(ExitSpacing.md)
        .background(
            LinearGradient(
                colors: [Color.Exit.background.opacity(0), Color.Exit.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
            .allowsHitTesting(false)
        )
    }
}

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        VStack {
            Spacer()
            FloatingActionButtons()
        }
    }
    .preferredColorScheme(.dark)
    .environment(\.appState, AppStateManager())
}
