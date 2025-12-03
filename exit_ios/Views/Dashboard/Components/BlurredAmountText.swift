//
//  BlurredAmountText.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 금액을 블러 처리하는 텍스트 컴포넌트
struct BlurredAmountText: View {
    let text: String
    let isHidden: Bool
    
    var body: some View {
        Text(text)
            .blur(radius: isHidden ? 2 : 0)
            .opacity(isHidden ? 0.8 : 1)
            .animation(.easeInOut(duration: 0.2), value: isHidden)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        
        VStack(spacing: 20) {
            BlurredAmountText(text: "7,500만원", isHidden: false)
                .font(.Exit.title2)
                .foregroundStyle(Color.Exit.primaryText)
            
            BlurredAmountText(text: "7,500만원", isHidden: true)
                .font(.Exit.title2)
                .foregroundStyle(Color.Exit.primaryText)
        }
    }
    .preferredColorScheme(.dark)
}

