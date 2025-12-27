//
//  PromptButton.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 다른 탭으로 이동하는 프롬프트 버튼
/// 타이틀, 서브타이틀, 이동할 탭을 파라미터로 받아 표시
struct PromptButton: View {
    @Environment(\.appState) private var appState
    
    let title: String
    let subtitle: String
    let destinationTab: MainTab
    
    var body: some View {
        Button {
            appState.selectedTab = destinationTab
        } label: {
            ExitCard(style: .outlined, padding: ExitSpacing.md, radius: ExitRadius.lg) {
                HStack(spacing: ExitSpacing.md) {
                    VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                        Text(title)
                            .font(.Exit.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.Exit.primaryText)
                        
                        Text(subtitle)
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.Exit.accent)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, ExitSpacing.md)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        VStack(spacing: ExitSpacing.md) {
            PromptButton(
                title: "📈 내 수익률을 모르겠다면?",
                subtitle: "포트폴리오 분석으로 예상 수익률 확인하기",
                destinationTab: .portfolio
            )
            
            PromptButton(
                title: "🎲 만약 주식이 떨어지면?",
                subtitle: "30,000가지 미래로 더 자세히 분석해드려요",
                destinationTab: .simulation
            )
        }
    }
    .preferredColorScheme(.dark)
    .environment(\.appState, AppStateManager())
}

