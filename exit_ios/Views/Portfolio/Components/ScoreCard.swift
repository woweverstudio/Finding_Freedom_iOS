//
//  ScoreCard.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  포트폴리오 점수 카드
//

import SwiftUI

/// 종합 점수 카드
struct PortfolioScoreCard: View {
    let score: PortfolioScore
    
    var body: some View {
        VStack(spacing: ExitSpacing.lg) {
            // 등급 배지
            ZStack {
                // 배경 링
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [score.gradeColor.opacity(0.3), score.gradeColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 8
                    )
                    .frame(width: 120, height: 120)
                
                // 진행률 링
                Circle()
                    .trim(from: 0, to: CGFloat(score.total) / 100)
                    .stroke(
                        LinearGradient(
                            colors: [score.gradeColor, score.gradeColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                // 등급 텍스트
                VStack(spacing: 2) {
                    Text(score.grade)
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundStyle(score.gradeColor)
                    
                    Text("\(score.total)점")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
            }
            
            // 등급 설명
            Text(score.gradeDescription)
                .font(.Exit.body)
                .fontWeight(.medium)
                .foregroundStyle(Color.Exit.primaryText)
            
            // 세부 점수
            HStack(spacing: ExitSpacing.lg) {
                ScoreDetailItem(
                    title: "수익성",
                    score: score.profitability,
                    maxScore: 40,
                    color: .Exit.accent
                )
                
                ScoreDetailItem(
                    title: "안정성",
                    score: score.stability,
                    maxScore: 30,
                    color: .Exit.positive
                )
                
                ScoreDetailItem(
                    title: "효율성",
                    score: score.efficiency,
                    maxScore: 30,
                    color: Color(hex: "5856D6")
                )
            }
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
    }
}

/// 세부 점수 아이템
struct ScoreDetailItem: View {
    let title: String
    let score: Int
    let maxScore: Int
    let color: Color
    
    var progress: Double {
        Double(score) / Double(maxScore)
    }
    
    var body: some View {
        VStack(spacing: ExitSpacing.xs) {
            // 프로그레스 링
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                
                Text("\(score)")
                    .font(.Exit.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
            }
            
            // 타이틀
            Text(title)
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.secondaryText)
            
            // 만점
            Text("/\(maxScore)")
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.tertiaryText)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        PortfolioScoreCard(
            score: PortfolioScore(
                total: 82,
                profitability: 32,
                stability: 24,
                efficiency: 26
            )
        )
    }
    .padding()
    .background(Color.Exit.background)
}

