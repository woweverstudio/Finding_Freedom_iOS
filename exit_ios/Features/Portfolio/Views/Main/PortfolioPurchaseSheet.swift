//
//  PortfolioPurchaseSheet.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 포트폴리오 구매 풀팝업
struct PortfolioPurchaseSheet: View {
    @Environment(\.storeService) private var storeService
    let onClose: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.Exit.background.ignoresSafeArea()
                
                PortfolioPromotionView(
                    onStart: {
                        // 구매 후 storeService.hasPortfolioAnalysis가 true가 되면
                        // MainTabView의 onChange에서 자동으로 처리됨
                    },
                    isPurchased: storeService.hasPortfolioAnalysis
                )
            }
            .navigationTitle("포트폴리오 분석")
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
    PortfolioPurchaseSheet(
        onClose: {}
    )
}

