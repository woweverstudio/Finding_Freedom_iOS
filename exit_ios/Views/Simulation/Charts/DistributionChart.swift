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
    
    // 시뮬레이션 조건 표시용
    var scenario: Scenario? = nil
    var currentAssetAmount: Double = 0
    var effectiveVolatility: Double = 0
    
    // 총 성공 횟수
    private var totalSuccess: Int {
        yearDistributionData.reduce(0) { $0 + $1.count }
    }
    
    // 확률로 변환된 데이터
    private var probabilityData: [(year: Int, probability: Double)] {
        guard totalSuccess > 0 else { return [] }
        return yearDistributionData.map { (year: $0.year, probability: Double($0.count) / Double(totalSuccess) * 100) }
    }
    
    // 가장 가능성 높은 연도
    private var mostLikelyYear: Int {
        yearDistributionData.max(by: { $0.count < $1.count })?.year ?? 0
    }
    
    // 가장 가능성 높은 확률
    private var mostLikelyProbability: Double {
        probabilityData.max(by: { $0.probability < $1.probability })?.probability ?? 0
    }
    
    // 80% 확률 구간 계산
    private var probabilityRange: (start: Int, end: Int) {
        guard totalSuccess > 0 else { return (0, 0) }
        
        let sortedData = yearDistributionData.sorted(by: { $0.year < $1.year })
        var cumulative = 0
        var startYear = sortedData.first?.year ?? 0
        var endYear = sortedData.last?.year ?? 0
        
        // 10% 지점 찾기
        for data in sortedData {
            cumulative += data.count
            if Double(cumulative) / Double(totalSuccess) >= 0.1 {
                startYear = data.year
                break
            }
        }
        
        // 90% 지점 찾기
        cumulative = 0
        for data in sortedData {
            cumulative += data.count
            if Double(cumulative) / Double(totalSuccess) >= 0.9 {
                endYear = data.year
                break
            }
        }
        
        return (startYear, endYear)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            // 핵심 메시지
            keyMessageSection
            
            // 시각적 타임라인
            timelineVisualization
            
            // 해석 도움말
            interpretationHelp
            
            // 시뮬레이션 조건
            if let scenario = scenario {
                simulationConditionSection(scenario: scenario)
            }
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // MARK: - Simulation Condition
    
    private func simulationConditionSection(scenario: Scenario) -> some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            Divider()
                .background(Color.Exit.divider)
            
            Text("📊 시뮬레이션 조건")
                .font(.Exit.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.Exit.secondaryText)
            
            let targetAsset = RetirementCalculator.calculateTargetAssets(
                desiredMonthlyIncome: scenario.desiredMonthlyIncome,
                postRetirementReturnRate: scenario.postRetirementReturnRate,
                inflationRate: scenario.inflationRate
            )
            
            HStack(spacing: ExitSpacing.md) {
                dataItem(label: "현재 자산", value: ExitNumberFormatter.formatChartAxis(currentAssetAmount))
                dataItem(label: "목표 자산", value: ExitNumberFormatter.formatChartAxis(targetAsset))
                dataItem(label: "월 투자", value: ExitNumberFormatter.formatToManWon(scenario.monthlyInvestment))
                dataItem(label: "변동성", value: String(format: "%.0f%%", effectiveVolatility))
            }
        }
    }
    
    private func dataItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.tertiaryText)
            Text(value)
                .font(.Exit.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.Exit.primaryText)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Key Message Section
    
    private var keyMessageSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            HStack {
                Image(systemName: "target")
                    .foregroundStyle(Color.Exit.accent)
                Text("언제 달성할 가능성이 높을까?")
                    .font(.Exit.title3)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            // 핵심 수치
            HStack(alignment: .bottom, spacing: ExitSpacing.sm) {
                Text("\(mostLikelyYear)년차")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.Exit.accent)
                
                Text("에 달성할 가능성이 가장 높아요")
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.secondaryText)
                    .padding(.bottom, 4)
            }
        }
    }
    
    // MARK: - Timeline Visualization
    
    private var timelineVisualization: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            // 간단한 확률 바 차트
            Chart {
                ForEach(probabilityData, id: \.year) { data in
                    BarMark(
                        x: .value("연도", data.year),
                        y: .value("확률", data.probability)
                    )
                    .foregroundStyle(
                        data.year == mostLikelyYear ?
                        Color.Exit.accent.gradient :
                        Color.Exit.accent.opacity(0.4).gradient
                    )
                    .cornerRadius(4)
                }
                
                // 가장 가능성 높은 연도 강조
                if mostLikelyYear > 0 {
                    RuleMark(x: .value("최다", mostLikelyYear))
                        .foregroundStyle(Color.Exit.accent.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
            }
            .frame(height: 140)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisValueLabel {
                        if let year = value.as(Int.self) {
                            Text("\(year)년")
                                .font(.Exit.caption2)
                                .foregroundStyle(Color.Exit.tertiaryText)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 10, 20, 30]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.Exit.divider)
                    AxisValueLabel {
                        if let prob = value.as(Int.self) {
                            Text("\(prob)%")
                                .font(.Exit.caption2)
                                .foregroundStyle(Color.Exit.tertiaryText)
                        }
                    }
                }
            }
            
            // 범위 표시
            HStack(spacing: ExitSpacing.lg) {
                rangeIndicator(
                    icon: "clock",
                    label: "빠르면",
                    value: "\(probabilityRange.start)년",
                    color: Color.Exit.positive
                )
                
                rangeIndicator(
                    icon: "target",
                    label: "대부분",
                    value: "\(mostLikelyYear)년",
                    color: Color.Exit.accent
                )
                
                rangeIndicator(
                    icon: "clock.badge.exclamationmark",
                    label: "늦으면",
                    value: "\(probabilityRange.end)년",
                    color: Color.Exit.caution
                )
            }
        }
    }
    
    private func rangeIndicator(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: ExitSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            
            Text(label)
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.tertiaryText)
            
            Text(value)
                .font(.Exit.body)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Interpretation Help
    
    private var interpretationHelp: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            Divider()
                .background(Color.Exit.divider)
            
            HStack(alignment: .top, spacing: ExitSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.Exit.accent)
                
                VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                    Text("이 그래프가 알려주는 것")
                        .font(.Exit.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    Text("막대가 높을수록 그 시점에 목표를 달성할 확률이 높아요. 대부분(\(Int(80))%)은 \(probabilityRange.start)~\(probabilityRange.end)년 사이에 달성해요.")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(ExitSpacing.sm)
            .background(Color.Exit.secondaryCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
        }
    }
}
