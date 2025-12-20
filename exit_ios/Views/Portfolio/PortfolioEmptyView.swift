//
//  PortfolioEmptyView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  포트폴리오 빈 상태 뷰
//

import SwiftUI

/// 포트폴리오가 없을 때 표시되는 빈 상태 뷰
struct PortfolioEmptyView: View {
    let onStartTapped: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: ExitSpacing.xl) {
            Spacer()
            
            // 일러스트레이션
            illustrationSection
            
            // 타이틀
            VStack(spacing: ExitSpacing.sm) {
                Text("내 포트폴리오 분석하기")
                    .font(.Exit.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Text("보유 종목을 추가하고\n포트폴리오 성과를 분석해보세요")
                    .font(.Exit.subheadline)
                    .foregroundStyle(Color.Exit.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            // 기능 설명
            featureList
            
            Spacer()
            
            // 시작 버튼
            Button(action: onStartTapped) {
                HStack(spacing: ExitSpacing.sm) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    
                    Text("종목 추가하기")
                        .font(.Exit.body)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(LinearGradient.exitAccent)
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, ExitSpacing.lg)
            .padding(.bottom, ExitSpacing.lg)
        }
    }
    
    // MARK: - Subviews
    
    private var illustrationSection: some View {
        ZStack {
            // 배경 원
            Circle()
                .fill(Color.Exit.accent.opacity(0.1))
                .frame(width: 160, height: 160)
            
            // 아이콘들
            ForEach(0..<3) { index in
                iconBubble(index: index)
            }
            
            // 메인 아이콘
            ZStack {
                Circle()
                    .fill(Color.Exit.cardBackground)
                    .frame(width: 80, height: 80)
                
                Text("📊")
                    .font(.system(size: 40))
            }
        }
        .frame(height: 180)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    private func iconBubble(index: Int) -> some View {
        let icons = ["💹", "📈", "💰"]
        let angles: [Double] = [-45, 45, 180]
        let distances: [CGFloat] = [70, 75, 65]
        
        let angle = Angle(degrees: angles[index])
        let distance = distances[index]
        
        return ZStack {
            Circle()
                .fill(Color.Exit.secondaryCardBackground)
                .frame(width: 44, height: 44)
            
            Text(icons[index])
                .font(.system(size: 20))
        }
        .offset(
            x: cos(angle.radians) * distance,
            y: sin(angle.radians) * distance
        )
        .offset(y: isAnimating ? -5 : 5)
        .animation(
            .easeInOut(duration: 1.5 + Double(index) * 0.2)
            .repeatForever(autoreverses: true)
            .delay(Double(index) * 0.3),
            value: isAnimating
        )
    }
    
    private var featureList: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            FeatureRow(
                icon: "chart.pie.fill",
                title: "수익률 분석",
                description: "CAGR, 배당 포함 총수익률"
            )
            
            FeatureRow(
                icon: "shield.lefthalf.filled",
                title: "위험 분석",
                description: "변동성, MDD, Sharpe Ratio"
            )
            
            FeatureRow(
                icon: "lightbulb.fill",
                title: "AI 인사이트",
                description: "맞춤형 개선 제안"
            )
        }
        .padding(.horizontal, ExitSpacing.xl)
    }
}

/// 기능 설명 행
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: ExitSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.Exit.accent)
                .frame(width: 36, height: 36)
                .background(Color.Exit.accent.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.Exit.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Text(description)
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        PortfolioEmptyView(onStartTapped: {})
    }
}

