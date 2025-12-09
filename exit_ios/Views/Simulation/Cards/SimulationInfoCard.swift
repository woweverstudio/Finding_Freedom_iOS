//
//  SimulationInfoCard.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 시뮬레이션 정보 카드
struct SimulationInfoCard: View {
    let userProfile: UserProfile
    let currentAssetAmount: Double
    let effectiveVolatility: Double
    let result: MonteCarloResult
    
    private var targetAsset: Double {
        RetirementCalculator.calculateTargetAssets(
            desiredMonthlyIncome: userProfile.desiredMonthlyIncome,
            postRetirementReturnRate: userProfile.postRetirementReturnRate
        )
    }
    
    private var preRetirementVolatility: Double {
        SimulationViewModel.calculateVolatility(for: userProfile.preRetirementReturnRate)
    }
    
    private var postRetirementVolatility: Double {
        SimulationViewModel.calculateVolatility(for: userProfile.postRetirementReturnRate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            // 헤더
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Color.Exit.accent)
                Text("시뮬레이션 정보")
                    .font(.Exit.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            // 기본 정보
            infoSection(title: "기본 정보") {
                infoRow(label: "현재 자산", value: ExitNumberFormatter.formatToEokManWon(currentAssetAmount))
                infoRow(label: "월 저축액", value: ExitNumberFormatter.formatToManWon(userProfile.monthlyInvestment))
                infoRow(label: "희망 월수입", value: ExitNumberFormatter.formatToManWon(userProfile.desiredMonthlyIncome))
                infoRow(label: "목표 자산", value: ExitNumberFormatter.formatToEokManWon(targetAsset), valueColor: Color.Exit.accent)
            }
            
            // 은퇴 전 시뮬레이션
            infoSection(title: "은퇴 전 시뮬레이션") {
                infoRow(label: "목표 수익률", value: String(format: "%.1f%%", userProfile.preRetirementReturnRate))
                infoRow(label: "수익률 변동성", value: String(format: "%.1f%%", preRetirementVolatility), valueColor: Color.Exit.secondaryText)
            }
            
            // 은퇴 후 시뮬레이션
            infoSection(title: "은퇴 후 시뮬레이션") {
                infoRow(label: "목표 수익률", value: String(format: "%.1f%%", userProfile.postRetirementReturnRate))
                infoRow(label: "수익률 변동성", value: String(format: "%.1f%%", postRetirementVolatility), valueColor: Color.Exit.secondaryText)
            }
            
            // 시뮬레이션 결과
            infoSection(title: "시뮬레이션 결과") {
                infoRow(label: "시뮬레이션 횟수", value: "\(result.totalSimulations.formatted())회")
                infoRow(label: "성공", value: "\(result.successCount.formatted())회", valueColor: Color.Exit.positive)
                infoRow(label: "실패", value: "\(result.failureCount.formatted())회", valueColor: Color.Exit.warning)
                infoRow(label: "성공률", value: String(format: "%.1f%%", result.successRate * 100), valueColor: Color.Exit.accent)
            }
        }
        .padding(ExitSpacing.md)
        .background(Color.Exit.secondaryCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // MARK: - Components
    
    private func infoSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            Text(title)
                .font(.Exit.caption2)
                .fontWeight(.medium)
                .foregroundStyle(Color.Exit.tertiaryText)
            
            VStack(spacing: ExitSpacing.xs) {
                content()
            }
            .padding(ExitSpacing.sm)
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
        }
    }
    
    private func infoRow(label: String, value: String, valueColor: Color = Color.Exit.primaryText) -> some View {
        HStack {
            Text(label)
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            Spacer()
            Text(value)
                .font(.Exit.caption)
                .fontWeight(.medium)
                .foregroundStyle(valueColor)
        }
    }
}
