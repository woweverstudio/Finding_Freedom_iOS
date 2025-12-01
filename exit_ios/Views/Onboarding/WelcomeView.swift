//
//  WelcomeView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 앱 시작 환영 화면
struct WelcomeView: View {
    let onStart: () -> Void
    
    var body: some View {
        ZStack {
            // 배경
            Color.Exit.background
                .ignoresSafeArea()
            
            // 배경 장식 효과
            backgroundEffects
            
            VStack(spacing: 0) {
                Spacer()
                
                // 로고 및 타이틀
                titleSection
                
                Spacer()
                    .frame(height: ExitSpacing.xxl)
                
                // 메시지들
                messagesSection
                
                Spacer()
                
                // 시작 버튼
                startButton
            }
            .padding(.horizontal, ExitSpacing.lg)
        }
    }
    
    // MARK: - Background Effects
    
    private var backgroundEffects: some View {
        ZStack {
            // 상단 그라데이션 원
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.Exit.accent.opacity(0.15),
                            Color.Exit.accent.opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: 100, y: -150)
                .blur(radius: 60)
            
            // 하단 그라데이션 원
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.Exit.accent.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: -120, y: 300)
                .blur(radius: 40)
        }
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        VStack(spacing: ExitSpacing.lg) {
            // Exit 로고 텍스트
            Text("Exit")
                .font(.system(size: 72, weight: .black, design: .default))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.Exit.accent, Color(hex: "00B894")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.Exit.accent.opacity(0.5), radius: 20, x: 0, y: 10)
            
            Text("에 오신 것을 환영합니다!")
                .font(.Exit.title2)
                .foregroundStyle(Color.Exit.primaryText)
        }
    }
    
    // MARK: - Messages Section
    
    private var messagesSection: some View {
        VStack(spacing: ExitSpacing.xl) {
            // 메시지 1
            Text("회사생활 지긋지긋 하시죠?")
                .font(.Exit.title3)
                .foregroundStyle(Color.Exit.primaryText)
            
            // 메시지 2
            VStack(spacing: ExitSpacing.xs) {
                Text("꿈만같던 은퇴,")
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                HStack(spacing: ExitSpacing.xs) {
                    Text("Exit")
                        .font(.Exit.body)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.Exit.accent)
                    
                    Text("과 함께라면 가능합니다.")
                        .font(.Exit.body)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
            }
            
            // 메시지 3 - 강조
            Text("천리길도 한걸음부터")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.tertiaryText)
                .italic()
        }
        .multilineTextAlignment(.center)
    }
    
    // MARK: - Start Button
    
    private var startButton: some View {
        Button(action: onStart) {
            Text("회사 탈출 계획 시작하기")
                .font(.Exit.body)                
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(LinearGradient.exitAccent)
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
                .exitButtonShadow()
        }
        .padding(.bottom, ExitSpacing.xxl)
    }
}

// MARK: - Preview

#Preview {
    WelcomeView {
        print("Start tapped")
    }
    .preferredColorScheme(.dark)
}



