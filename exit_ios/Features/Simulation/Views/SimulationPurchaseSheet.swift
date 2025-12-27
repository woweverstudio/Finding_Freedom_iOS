//
//  SimulationPurchaseSheet.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 시뮬레이션 프로모션 풀팝업 (체험 안함 + 미구매 사용자용)
struct SimulationPurchaseSheet: View {
    let onClose: () -> Void
    let onStartTrial: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.Exit.background.ignoresSafeArea()
                
                SimulationPromotionView(
                    onStartTrial: onStartTrial
                )
            }
            .navigationTitle("몬테카를로 시뮬레이션")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") {
                        onClose()
                    }
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.accent)
                }
            }
            .toolbarBackground(Color.Exit.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

#Preview {
    SimulationPurchaseSheet(
        onClose: {},
        onStartTrial: {}
    )
}

