//
//  SimulationPurchaseSheet.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 시뮬레이션 구매 풀팝업
struct SimulationPurchaseSheet: View {
    @Environment(\.storeService) private var storeService
    let viewModel: SimulationViewModel
    let onClose: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.Exit.background.ignoresSafeArea()
                
                SimulationPromotionView(
                    userProfile: viewModel.userProfile,
                    currentAssetAmount: viewModel.currentAssetAmount,
                    onStart: {
                        // 구매 후 storeService.hasMontecarloSimulation이 true가 되면
                        // MainTabView의 onChange에서 자동으로 처리됨
                    },
                    isPurchased: storeService.hasMontecarloSimulation
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
        viewModel: SimulationViewModel(),
        onClose: {}
    )
}

