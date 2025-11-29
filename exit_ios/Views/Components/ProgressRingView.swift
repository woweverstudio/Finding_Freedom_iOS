//
//  ProgressRingView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 진행률 링 차트 컴포넌트
struct ProgressRingView: View {
    let progress: Double  // 0~1
    let currentAmount: String
    let targetAmount: String
    let percentText: String
    var hideAmounts: Bool = false
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            // 배경 링
            Circle()
                .stroke(
                    Color.Exit.divider,
                    lineWidth: 12
                )
            
            // 진행 링
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "00D4AA"),
                            Color(hex: "00B894"),
                            Color(hex: "00D4AA")
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.Exit.accent.opacity(0.5), radius: 8, x: 0, y: 0)
            
            // 중앙 텍스트
            VStack(spacing: ExitSpacing.xs) {
                if hideAmounts {
                    // 금액 숨김 모드
                    HiddenAmountDots()
                    
                    HStack(spacing: 4) {
                        Text("/")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.secondaryText)
                        HiddenAmountDots()
                    }
                    
                    HiddenAmountDots()
                } else {
                    // 현재 자산
                    Text(currentAmount)
                        .font(.Exit.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.Exit.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    // 목표 자산
                    Text("/ \(targetAmount)")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    // 퍼센트
                    Text(percentText)
                        .font(.Exit.title2)
                        .foregroundStyle(Color.Exit.accent)
                        .fontWeight(.heavy)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .padding(.horizontal, ExitSpacing.lg)
        }
        .padding(ExitSpacing.md)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Hidden Amount Dots

/// 금액 숨김용 도트 컴포넌트
struct HiddenAmountDots: View {
    var dotCount: Int = 4
    var dotSize: CGFloat = 8
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<dotCount, id: \.self) { _ in
                Circle()
                    .fill(Color.Exit.tertiaryText)
                    .frame(width: dotSize, height: dotSize)
            }
        }
    }
}

// MARK: - Compact Progress Ring

struct CompactProgressRing: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    
    @State private var animatedProgress: Double = 0
    
    init(progress: Double, size: CGFloat = 60, lineWidth: CGFloat = 6) {
        self.progress = progress
        self.size = size
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.Exit.divider, lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient.exitAccent,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        
        VStack(spacing: 40) {
            ProgressRingView(
                progress: 0.28,
                currentAmount: "10억 7,500만원",
                targetAmount: "42억 2,750만원",
                percentText: "28%",
                hideAmounts: false
            )
            .frame(width: 200, height: 200)
            
            ProgressRingView(
                progress: 0.28,
                currentAmount: "7,500만원",
                targetAmount: "4억 2,750만원",
                percentText: "28%",
                hideAmounts: true
            )
            .frame(width: 200, height: 200)
        }
    }
    .preferredColorScheme(.dark)
}
