//
//  SimulationInfoCard.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 시뮬레이션 정보 카드
struct SimulationInfoCard: View {
    let scenario: Scenario
    let currentAssetAmount: Double
    let effectiveVolatility: Double
    let totalSimulations: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Color.Exit.accent)
                Text("시뮬레이션 정보")
                    .font(.Exit.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            VStack(spacing: ExitSpacing.xs) {
                infoRow(label: "현재 자산", value: ExitNumberFormatter.formatToEokManWon(currentAssetAmount), isAccent: true)
                infoRow(label: "월 저축액", value: ExitNumberFormatter.formatToManWon(scenario.monthlyInvestment), isAccent: true)
                infoRow(label: "목표 월수입", value: ExitNumberFormatter.formatToManWon(scenario.desiredMonthlyIncome), isAccent: true)
                
                Divider()
                    .background(Color.Exit.divider)
                    .padding(.vertical, 2)
                
                infoRow(label: "평균 수익률", value: String(format: "%.1f%%", scenario.preRetirementReturnRate))
                infoRow(label: "수익률 변동성", value: String(format: "%.1f%%", effectiveVolatility))
                infoRow(label: "시뮬레이션 횟수", value: "\(totalSimulations.formatted())회")
            }
        }
        .padding(ExitSpacing.md)
        .background(Color.Exit.secondaryCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    private func infoRow(label: String, value: String, isAccent: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            Spacer()
            Text(value)
                .font(.Exit.caption)
                .fontWeight(isAccent ? .semibold : .medium)
                .foregroundStyle(isAccent ? Color.Exit.accent : Color.Exit.primaryText)
        }
    }
}

