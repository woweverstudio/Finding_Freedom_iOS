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
            ExitCTAButton(
                title: "자산 업데이트",
                icon: "arrow.triangle.2.circlepath",
                style: .secondary,
                size: .medium,
                action: {
                    appState.totalAssetsInput = appState.currentAssetAmount
                    appState.showAssetUpdateSheet = true
                }
            )
            
            // 입금하기 (우측)
            ExitCTAButton(
                title: "입금하기",
                icon: "plus.circle.fill",
                size: .medium,
                action: {
                    appState.depositAmount = 0
                    appState.depositDate = Date()
                    appState.showDepositSheet = true
                }
            )
            .exitButtonShadow()
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
