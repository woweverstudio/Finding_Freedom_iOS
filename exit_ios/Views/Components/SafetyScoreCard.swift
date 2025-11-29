//
//  SafetyScoreCard.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 안전 점수 카드 컴포넌트
struct SafetyScoreCard: View {
    let totalScore: Int
    let scoreChange: String
    let details: [(title: String, score: Int, maxScore: Int)]
    var alwaysExpanded: Bool = false
    
    @State private var isExpanded: Bool = false
    @State private var animatedScore: Double = 0
    
    var body: some View {
        VStack(spacing: ExitSpacing.md) {
            // 헤더
            headerSection
            
            // 세부 항목 (alwaysExpanded가 true면 항상 표시)
            if isExpanded || alwaysExpanded {
                detailsSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .exitCard()
        .onTapGesture {
            if !alwaysExpanded {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                animatedScore = Double(totalScore)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                Text("안전 점수 총합")
                    .font(.Exit.subheadline)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                HStack(alignment: .firstTextBaseline, spacing: ExitSpacing.sm) {
                    Text("\(Int(animatedScore))")
                        .font(.system(size: 64, weight: .heavy, design: .default))
                        .monospacedDigit()
                        .foregroundStyle(scoreColor)
                        .contentTransition(.numericText())
                    
                    Text("점")
                        .font(.Exit.title2)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    if !scoreChange.isEmpty {
                        Text(scoreChange)
                            .font(.Exit.body)
                            .foregroundStyle(scoreChange.contains("↑") ? Color.Exit.accent : Color.Exit.warning)
                    }
                }
            }
            
            Spacer()
            
            // 점수 게이지
            ZStack {
                Circle()
                    .stroke(Color.Exit.divider, lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: animatedScore / 100)
                    .stroke(
                        scoreGradient,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                // alwaysExpanded면 chevron 숨김
                if !alwaysExpanded {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
            }
            .frame(width: 60, height: 60)
        }
    }
    
    // MARK: - Details Section
    
    private var detailsSection: some View {
        VStack(spacing: ExitSpacing.sm) {
            ForEach(details.indices, id: \.self) { index in
                ScoreDetailRow(
                    title: details[index].title,
                    score: details[index].score,
                    maxScore: details[index].maxScore
                )
            }
        }
    }
    
    // MARK: - Computed
    
    private var scoreColor: Color {
        if totalScore >= 80 {
            return Color.Exit.accent
        } else if totalScore >= 60 {
            return Color.Exit.caution
        } else {
            return Color.Exit.warning
        }
    }
    
    private var scoreGradient: LinearGradient {
        if totalScore >= 80 {
            return LinearGradient.exitAccent
        } else if totalScore >= 60 {
            return LinearGradient(colors: [Color.Exit.caution, Color.Exit.caution.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
        } else {
            return LinearGradient(colors: [Color.Exit.warning, Color.Exit.warning.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
        }
    }
}

// MARK: - Score Detail Row

private struct ScoreDetailRow: View {
    let title: String
    let score: Int
    let maxScore: Int
    
    @State private var animatedProgress: Double = 0
    
    private var progress: Double {
        Double(score) / Double(maxScore)
    }
    
    var body: some View {
        HStack(spacing: ExitSpacing.md) {
            Text(title)
                .font(.Exit.subheadline)
                .foregroundStyle(Color.Exit.secondaryText)
                .frame(width: 100, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.Exit.divider)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient.exitAccent)
                        .frame(width: geometry.size.width * animatedProgress, height: 8)
                }
            }
            .frame(height: 8)
            
            Text("\(score)/\(maxScore)")
                .font(.Exit.caption)
                .monospacedDigit()
                .foregroundStyle(Color.Exit.primaryText)
                .frame(width: 50, alignment: .trailing)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animatedProgress = progress
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        
        VStack(spacing: 20) {
            SafetyScoreCard(
                totalScore: 84,
                scoreChange: "↑5점",
                details: [
                    ("목표 충족", 18, 25),
                    ("수익률 안전성", 25, 25),
                    ("자산 다각화", 21, 25),
                    ("자산 성장성", 20, 25)
                ],
                alwaysExpanded: true
            )
            .padding()
        }
    }
    .preferredColorScheme(.dark)
}
