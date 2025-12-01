//
//  DistributionChart.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI
import Charts

/// 목표 달성 시점 분포 차트
struct DistributionChart: View {
    let yearDistributionData: [(year: Int, count: Int)]
    let result: MonteCarloResult
    
    // Computed properties로 분리
    private var maxCount: Int {
        yearDistributionData.map(\.count).max() ?? 1
    }
    
    private var minYear: Int {
        yearDistributionData.map(\.year).min() ?? 0
    }
    
    private var maxYear: Int {
        yearDistributionData.map(\.year).max() ?? 10
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            headerView
            
            Divider()
                .background(Color.Exit.divider)
            
            descriptionText
            
            if !yearDistributionData.isEmpty {
                chartView
                footerView
            }
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Image(systemName: "chart.bar.fill")
                .foregroundStyle(Color.Exit.accent)
            Text("목표 달성 시점 분포")
                .font(.Exit.title3)
                .foregroundStyle(Color.Exit.primaryText)
            
            Spacer()
            
            Text("\(result.successCount.formatted())건 성공")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
        }
    }
    
    private var descriptionText: some View {
        Text("10,000번 시뮬레이션에서 몇 년 차에 목표를 달성했는지 분포")
            .font(.Exit.caption)
            .foregroundStyle(Color.Exit.secondaryText)
            .padding(.bottom, ExitSpacing.xs)
    }
    
    private var chartView: some View {
        Chart {
            ForEach(yearDistributionData, id: \.year) { data in
                BarMark(
                    x: .value("연도", data.year),
                    y: .value("성공 횟수", data.count)
                )
                .foregroundStyle(
                    data.count == maxCount ?
                    Color.Exit.accent.gradient :
                    Color.Exit.accent.opacity(0.6).gradient
                )
                .cornerRadius(4)
            }
        }
        .frame(height: 240)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.Exit.divider)
                AxisValueLabel {
                    if let year = value.as(Int.self) {
                        Text("\(year)년")
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.secondaryText)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.Exit.divider)
                AxisValueLabel {
                    if let count = value.as(Int.self) {
                        Text("\(count)회")
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.secondaryText)
                    }
                }
            }
        }
        .chartXScale(domain: .automatic(includesZero: false))
    }
    
    private var footerView: some View {
        HStack(spacing: ExitSpacing.xs) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color.Exit.accent)
            
            Text("가장 많이 나온 결과: \(result.medianMonths / 12)년 (\(maxCount)회)")
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.secondaryText)
        }
        .padding(.top, ExitSpacing.sm)
    }
    
}

