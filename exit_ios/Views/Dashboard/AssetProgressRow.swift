//
//  AssetProgressRow.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 자산 진행률 표시 행 (자동 축소로 1줄 유지, 블러 처리)
struct AssetProgressRow: View {
    let currentAssets: String
    let targetAssets: String
    let percent: String
    let isHidden: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Text(currentAssets)
                .foregroundStyle(Color.Exit.accent)
                .blur(radius: isHidden ? 10 : 0)
            
            Text("/")
                .foregroundStyle(Color.Exit.tertiaryText)
            
            Text(targetAssets)
                .foregroundStyle(Color.Exit.primaryText)
                .blur(radius: isHidden ? 10 : 0)
            
            Text("(\(percent))")
                .foregroundStyle(Color.Exit.secondaryText)
                .blur(radius: isHidden ? 8 : 0)
        }
        .font(.Exit.title3)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .animation(.easeInOut(duration: 0.2), value: isHidden)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        
        VStack(spacing: 20) {
            AssetProgressRow(
                currentAssets: "7,500만원",
                targetAssets: "4억 2,750만원",
                percent: "28%",
                isHidden: false
            )
            
            AssetProgressRow(
                currentAssets: "7,500만원",
                targetAssets: "4억 2,750만원",
                percent: "28%",
                isHidden: true
            )
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}

