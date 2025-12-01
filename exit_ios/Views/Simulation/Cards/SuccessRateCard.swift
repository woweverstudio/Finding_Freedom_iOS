//
//  SuccessRateCard.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 성공률 카드
struct SuccessRateCard: View {
    let result: MonteCarloResult
    
    var body: some View {
        VStack(spacing: ExitSpacing.lg) {
            // 큰 성공률 표시
            VStack(spacing: ExitSpacing.sm) {
                Text("FIRE 달성 확률")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(Int(result.successRate * 100))")
                        .font(.system(size: 72, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(hex: result.confidenceLevel.color))
                    
                    Text("%")
                        .font(.Exit.title)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
                
                Text(result.confidenceLevel.rawValue)
                    .font(.Exit.body)
                    .foregroundStyle(Color(hex: result.confidenceLevel.color))
                    .padding(.horizontal, ExitSpacing.md)
                    .padding(.vertical, ExitSpacing.xs)
                    .background(
                        Capsule()
                            .fill(Color(hex: result.confidenceLevel.color).opacity(0.15))
                    )
            }
            
            Divider()
                .background(Color.Exit.divider)
            
            // 설명 텍스트
            VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                Text("\(result.totalSimulations.formatted())번의 시뮬레이션 결과")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                Text(successRateMessage)
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.xl))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    private var successRateMessage: String {
        switch result.confidenceLevel {
        case .veryHigh:
            return "현재 계획대로라면 목표 달성이 거의 확실합니다! 훌륭해요 🎉"
        case .high:
            return "목표 달성 가능성이 높습니다. 현재 계획을 유지하세요"
        case .moderate:
            return "계획대로 진행하면 달성 가능합니다. 입금을 조금 더 늘리면 더 안전해요"
        case .low:
            return "목표 달성이 불확실합니다. 월 저축액을 늘리거나 목표를 조정하세요"
        case .veryLow:
            return "현재 계획으로는 목표 달성이 어렵습니다. 계획을 재검토하세요"
        }
    }
}

