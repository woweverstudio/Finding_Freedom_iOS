//
//  AssetPathChart.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI
import Charts

/// 자산 변화 예측 차트 + FIRE 달성 시점 비교 (통합 카드)
struct AssetPathChart: View {
    let paths: RepresentativePaths
    let scenario: Scenario
    let result: MonteCarloResult?
    let originalDDayMonths: Int
    
    // 시뮬레이션 조건 표시용
    var currentAssetAmount: Double = 0
    var effectiveVolatility: Double = 0
    
    init(paths: RepresentativePaths, scenario: Scenario, result: MonteCarloResult? = nil, originalDDayMonths: Int = 0, currentAssetAmount: Double = 0, effectiveVolatility: Double = 0) {
        self.paths = paths
        self.scenario = scenario
        self.result = result
        self.originalDDayMonths = originalDDayMonths
        self.currentAssetAmount = currentAssetAmount
        self.effectiveVolatility = effectiveVolatility
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            // 1. 타이틀
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundStyle(Color.Exit.accent)
                Text("자산 변화 예측")
                    .font(.Exit.title3)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            // 2. 차트 및 데이터
            assetChart
            
            legendView
            
            // FIRE 달성 시점 비교 (result가 있을 때만)
            if let result = result, originalDDayMonths > 0 {
                timelineSection(result: result)
            }
            
            // 3. 도움말
            helpSection
            
            // 4. 시뮬레이션 조건
            if currentAssetAmount > 0 {
                simulationConditionSection
            }
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // MARK: - Help Section
    
    private var helpSection: some View {
        HStack(alignment: .top, spacing: ExitSpacing.sm) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.Exit.accent)
            
            VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                Text("이 그래프가 알려주는 것")
                    .font(.Exit.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                Text("시장 상황에 따라 자산이 어떻게 변할지 3가지 시나리오로 보여줘요. 행운(상위 10%)부터 불운(하위 10%)까지, 대부분의 경우가 이 범위 안에 들어요.")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(ExitSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Exit.secondaryCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
    }
    
    // MARK: - Simulation Condition
    
    private var simulationConditionSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
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
                dataItem(label: "수익률", value: String(format: "%.1f%%", scenario.preRetirementReturnRate))
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
    
    // MARK: - Asset Chart
    
    private var assetChart: some View {
        Chart {
            // 행운의 경로 (상위 10%)
            ForEach(Array(paths.best.monthlyAssets.enumerated()), id: \.offset) { index, amount in
                LineMark(
                    x: .value("월", index),
                    y: .value("자산", amount),
                    series: .value("경로", "행운")
                )
                .foregroundStyle(Color.Exit.positive)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }
            
            // 불운의 경로 (하위 10%)
            ForEach(Array(paths.worst.monthlyAssets.enumerated()), id: \.offset) { index, amount in
                LineMark(
                    x: .value("월", index),
                    y: .value("자산", amount),
                    series: .value("경로", "불운")
                )
                .foregroundStyle(Color.Exit.caution)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }
            
            // 평균 경로 (마지막에 그려서 위에 표시)
            ForEach(Array(paths.median.monthlyAssets.enumerated()), id: \.offset) { index, amount in
                LineMark(
                    x: .value("월", index),
                    y: .value("자산", amount),
                    series: .value("경로", "평균")
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
            
            RuleMark(y: .value("목표", targetAsset))
                .foregroundStyle(Color.Exit.accent.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
        }
        .frame(height: 220)
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
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(ExitNumberFormatter.formatChartAxis(amount))
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.tertiaryText)
                    }
                }
            }
        }
    }
    
    // MARK: - Legend
    
    private var legendView: some View {
        HStack(spacing: ExitSpacing.lg) {
            legendItem(color: Color.Exit.positive, label: "행운(상위10%)")
            legendItem(color: Color.Exit.accent, label: "평균(50%)")
            legendItem(color: Color.Exit.caution, label: "불운(하위10%)")
        }
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: ExitSpacing.xs) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 16, height: 3)
            
            Text(label)
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.secondaryText)
        }
    }
    
    // MARK: - Timeline Section
    
    private func timelineSection(result: MonteCarloResult) -> some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            Text("목표 자산 달성 시점")
                .font(.Exit.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.Exit.primaryText)
            
            // 타임라인 차트
            timelineChart(result: result)
            
            // 요약 텍스트
            timelineSummary(result: result)
        }
    }
    
    private func timelineChart(result: MonteCarloResult) -> some View {
        let timelineData: [(label: String, months: Int, color: Color, icon: String)] = [
            ("행운", result.bestCase10Percent, Color.Exit.positive, "🍀"),
            ("평균", result.medianMonths, Color.Exit.accent, "📊"),
            ("불운", result.worstCase10Percent, Color.Exit.caution, "🌧️"),
            ("기존 예측", originalDDayMonths, Color.Exit.tertiaryText, "📌")
        ]
        
        let maxMonths = timelineData.map { $0.months }.max() ?? 1
        
        return VStack(spacing: ExitSpacing.sm) {
            ForEach(timelineData, id: \.label) { item in
                HStack(spacing: ExitSpacing.sm) {
                    // 라벨
                    HStack(spacing: 4) {
                        Text(item.icon)
                            .font(.system(size: 12))
                        Text(item.label)
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.secondaryText)
                    }
                    .frame(width: 70, alignment: .leading)
                    
                    // 바 차트
                    GeometryReader { geometry in
                        let barWidth = (CGFloat(item.months) / CGFloat(maxMonths)) * geometry.size.width
                        
                        ZStack(alignment: .leading) {
                            // 배경
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.Exit.divider)
                                .frame(height: 24)
                            
                            // 바
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.color.opacity(0.8))
                                .frame(width: max(barWidth, 40), height: 24)
                            
                            // 값 표시
                            Text(formatYears(item.months))
                                .font(.Exit.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(barWidth > 60 ? .white : item.color)
                                .padding(.horizontal, 8)
                                .frame(width: max(barWidth, 40), alignment: barWidth > 60 ? .trailing : .leading)
                                .offset(x: barWidth > 60 ? 0 : max(barWidth, 40))
                        }
                    }
                    .frame(height: 24)
                }
            }
        }
    }
    
    private func timelineSummary(result: MonteCarloResult) -> some View {
        let diff = result.medianMonths - originalDDayMonths
        
        let message: String
        if abs(diff) <= 6 {
            message = "기존 예측과 비슷해요 👍"
        } else if diff > 0 {
            message = "시장 변동성 고려 시 +\(formatYears(diff)) 예상"
        } else {
            message = "운이 좋으면 \(formatYears(abs(diff))) 단축 가능"
        }
        
        return HStack(spacing: ExitSpacing.xs) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color.Exit.accent)
            Text(message)
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
        }
        .padding(ExitSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Exit.accent.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
    }
    
    private func formatYears(_ months: Int) -> String {
        let years = months / 12
        let remainingMonths = months % 12
        
        if remainingMonths == 0 {
            return "\(years)년"
        } else if years == 0 {
            return "\(remainingMonths)개월"
        } else {
            return "\(years)년 \(remainingMonths)개월"
        }
    }
}
