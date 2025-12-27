//
//  ScoreCard.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  포트폴리오 점수 카드
//

import SwiftUI

/// 컴팩트 종합 점수 카드
struct PortfolioScoreCard: View {
    let score: PortfolioScore
    
    var body: some View {
        VStack(spacing: ExitSpacing.md) {
            // 상단: 등급 + 점수 + 설명
            HStack(spacing: ExitSpacing.md) {
                // 등급 배지
                ZStack {
                    Circle()
                        .fill(score.gradeColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(score.total) / 100)
                        .stroke(
                            score.gradeColor,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                    
                    Text(score.grade)
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(score.gradeColor)
                }
                
                // 점수 및 설명
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(score.total)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(score.gradeColor)
                        
                        Text("점")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.secondaryText)
                    }
                    
                    Text(score.gradeDescription)
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
                
                Spacer()
            }
            
            // 하단: 세부 점수 프로그레스 바
            HStack(spacing: ExitSpacing.md) {
                CompactScoreBar(
                    title: "수익성",
                    score: score.profitability,
                    maxScore: 40,
                    color: .Exit.accent
                )
                
                CompactScoreBar(
                    title: "안정성",
                    score: score.stability,
                    maxScore: 30,
                    color: .Exit.positive
                )
                
                CompactScoreBar(
                    title: "효율성",
                    score: score.efficiency,
                    maxScore: 30,
                    color: Color.Exit.chart5
                )
            }
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
    }
}

/// 컴팩트 점수 프로그레스 바
struct CompactScoreBar: View {
    let title: String
    let score: Int
    let maxScore: Int
    let color: Color
    
    var progress: Double {
        Double(score) / Double(maxScore)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 타이틀 + 점수
            HStack {
                Text(title)
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                Spacer()
                
                Text("\(score)/\(maxScore)")
                    .font(.Exit.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(color)
            }
            
            // 프로그레스 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

/// 세부 점수 아이템 (기존 - 레거시 호환용)
struct ScoreDetailItem: View {
    let title: String
    let score: Int
    let maxScore: Int
    let color: Color
    
    var progress: Double {
        Double(score) / Double(maxScore)
    }
    
    var body: some View {
        VStack(spacing: ExitSpacing.sm) {
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
            Text("최대 \(maxScore)")
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.tertiaryText)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        PortfolioScoreCard(
            score: PortfolioScore(
                total: 82,
                profitability: 32,
                stability: 24,
                efficiency: 26
            )
        )
        
        PortfolioScoreCard(
            score: PortfolioScore(
                total: 47,
                profitability: 16,
                stability: 11,
                efficiency: 20
            )
        )
    }
    .padding()
    .background(Color.Exit.background)
}
