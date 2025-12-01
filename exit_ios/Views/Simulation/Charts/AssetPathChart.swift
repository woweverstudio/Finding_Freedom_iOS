//
//  AssetPathChart.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI
import Charts

/// 자산 변화 예측 차트
struct AssetPathChart: View {
    let paths: RepresentativePaths
    let scenario: Scenario
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            // 헤더
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundStyle(Color.Exit.accent)
                Text("자산 변화 예측")
                    .font(.Exit.title3)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Spacer()
                
                Text("3가지 시나리오")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            
            Divider()
                .background(Color.Exit.divider)
            
            // 차트
            Chart {
                // 최선의 경로
                ForEach(Array(paths.best.monthlyAssets.enumerated()), id: \.offset) { index, amount in
                    LineMark(
                        x: .value("월", index),
                        y: .value("자산", amount),
                        series: .value("경로", "최선")
                    )
                    .foregroundStyle(Color.Exit.positive)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
                
                // 최악의 경로
                ForEach(Array(paths.worst.monthlyAssets.enumerated()), id: \.offset) { index, amount in
                    LineMark(
                        x: .value("월", index),
                        y: .value("자산", amount),
                        series: .value("경로", "최악")
                    )
                    .foregroundStyle(Color.Exit.caution)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
                
                // 중앙값 경로 (마지막에 그려서 위에 표시)
                ForEach(Array(paths.median.monthlyAssets.enumerated()), id: \.offset) { index, amount in
                    LineMark(
                        x: .value("월", index),
                        y: .value("자산", amount),
                        series: .value("경로", "중앙값")
                    )
                    .foregroundStyle(Color.Exit.accent)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .interpolationMethod(.catmullRom)
                }
                
                // 목표 자산 선
                let targetAsset = RetirementCalculator.calculateTargetAssets(
                    desiredMonthlyIncome: scenario.desiredMonthlyIncome,
                    postRetirementReturnRate: scenario.postRetirementReturnRate,
                    inflationRate: scenario.inflationRate
                )
                
                RuleMark(
                    y: .value("목표", targetAsset)
                )
                .foregroundStyle(Color.Exit.accent.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                .annotation(position: .top, alignment: .trailing) {
                    Text("목표 자산")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.tertiaryText)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.Exit.background.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .frame(height: 280)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let months = value.as(Int.self) {
                            let years = months / 12
                            Text("\(years)년")
                                .font(.Exit.caption2)
                                .foregroundStyle(Color.Exit.tertiaryText)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(ExitNumberFormatter.formatToEokManWon(amount))
                                .font(.Exit.caption2)
                                .foregroundStyle(Color.Exit.tertiaryText)
                        }
                    }
                }
            }
            
            // 범례
            HStack(spacing: ExitSpacing.md) {
                legendItem(color: Color.Exit.positive, label: "최선 (10%)")
                legendItem(color: Color.Exit.accent, label: "중앙값 (50%)")
                legendItem(color: Color.Exit.caution, label: "최악 (10%)")
            }
            .padding(.top, ExitSpacing.sm)
            
            // 설명
            Text("현재 계획대로 진행 시 자산이 어떻게 변할지 3가지 경우를 보여줍니다")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: ExitSpacing.xs) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 20, height: 3)
            
            Text(label)
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.secondaryText)
        }
    }
}

