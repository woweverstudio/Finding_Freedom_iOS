//
//  RetirementProjectionChart.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI
import Charts

/// 은퇴 후 자산 변화 예측 차트 (몬테카를로 시뮬레이션 기반)
struct RetirementProjectionChart: View {
    let result: RetirementSimulationResult
    let scenario: Scenario
    
    // 목표 자산 계산
    private var targetAsset: Double {
        RetirementCalculator.calculateTargetAssets(
            desiredMonthlyIncome: scenario.desiredMonthlyIncome,
            postRetirementReturnRate: scenario.postRetirementReturnRate,
            inflationRate: scenario.inflationRate
        )
    }
    
    // 행운 케이스 최종 자산
    private var bestFinalAsset: Double {
        result.bestPath.finalAsset
    }
    
    // 금액 간략 포맷 (억 단위만)
    private func formatSimple(_ amount: Double) -> String {
        if amount <= 0 {
            return "0원"
        }
        let eok = amount / 100_000_000
        if eok >= 1 {
            return String(format: "약 %.0f억", eok)
        } else {
            let man = amount / 10_000
            return String(format: "약 %.0f만원", man)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            // 헤더
            headerSection
            
            // 핵심 메시지 (테이블 형식)
            keyMessageTable
            
            // 차트 (평균, 불운, 기존예측만)
            projectionChart
            
            // 범례
            legendSection
            
            // 해석
            interpretationSection
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            Image(systemName: "hourglass")
                .foregroundStyle(Color.Exit.accent)
            Text("목표 달성 후, 얼마나 버틸 수 있을까?")
                .font(.Exit.title3)
                .foregroundStyle(Color.Exit.primaryText)
        }
    }
    
    // MARK: - Key Message Table
    
    private var keyMessageTable: some View {
        VStack(spacing: 0) {
            // 헤더 행
            HStack {
                Text("시나리오")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
                    .frame(width: 70, alignment: .leading)
                
                Text("결과")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("40년 후")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
                    .frame(width: 80, alignment: .trailing)
            }
            .padding(.horizontal, ExitSpacing.md)
            .padding(.vertical, ExitSpacing.sm)
            .background(Color.Exit.divider.opacity(0.5))
            
            // 행운 행
            tableRow(
                icon: "🍀",
                label: "행운",
                result: result.bestPath.depletionYear != nil ? "\(result.bestPath.depletionYear!)년 후 소진" : "자산 유지",
                detail: formatSimple(result.bestPath.finalAsset),
                color: Color.Exit.positive
            )
            
            Divider().background(Color.Exit.divider)
            
            // 평균 행
            tableRow(
                icon: "📊",
                label: "평균",
                result: result.medianPath.depletionYear != nil ? "\(result.medianPath.depletionYear!)년 후 소진" : "자산 유지",
                detail: formatSimple(result.medianPath.finalAsset),
                color: Color.Exit.accent
            )
            
            Divider().background(Color.Exit.divider)
            
            // 불운 행
            tableRow(
                icon: "🌧️",
                label: "불운",
                result: result.worstPath.depletionYear != nil ? "\(result.worstPath.depletionYear!)년 후 소진" : "자산 유지",
                detail: formatSimple(result.worstPath.finalAsset),
                color: Color.Exit.caution
            )
        }
        .background(Color.Exit.secondaryCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
    }
    
    private func tableRow(icon: String, label: String, result: String, detail: String, color: Color) -> some View {
        HStack {
            HStack(spacing: ExitSpacing.xs) {
                Text(icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            .frame(width: 70, alignment: .leading)
            
            Text(result)
                .font(.Exit.caption)
                .fontWeight(.medium)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(detail)
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.tertiaryText)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal, ExitSpacing.md)
        .padding(.vertical, ExitSpacing.sm)
    }
    
    // MARK: - Chart (행운 제외)
    
    private var projectionChart: some View {
        Chart {
            // 불운 경로 (하위 10%)
            ForEach(Array(result.worstPath.yearlyAssets.enumerated()), id: \.offset) { index, asset in
                LineMark(
                    x: .value("년", index),
                    y: .value("자산", max(0, asset)),
                    series: .value("시나리오", "불운")
                )
                .foregroundStyle(Color.Exit.caution)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }
            
            // 기존 예측 (변동성 없음)
            ForEach(Array(result.deterministicPath.yearlyAssets.enumerated()), id: \.offset) { index, asset in
                LineMark(
                    x: .value("년", index),
                    y: .value("자산", max(0, asset)),
                    series: .value("시나리오", "기존")
                )
                .foregroundStyle(Color.Exit.tertiaryText)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                .interpolationMethod(.catmullRom)
            }
            
            // 평균 경로 (중앙값) - 마지막에 그려서 위에 표시
            ForEach(Array(result.medianPath.yearlyAssets.enumerated()), id: \.offset) { index, asset in
                LineMark(
                    x: .value("년", index),
                    y: .value("자산", max(0, asset)),
                    series: .value("시나리오", "평균")
                )
                .foregroundStyle(Color.Exit.accent)
                .lineStyle(StrokeStyle(lineWidth: 3))
                .interpolationMethod(.catmullRom)
            }
            
            // 시작점 표시
            PointMark(
                x: .value("년", 0),
                y: .value("자산", targetAsset)
            )
            .foregroundStyle(Color.Exit.accent)
            .symbolSize(80)
            
            // 0선
            RuleMark(y: .value("zero", 0))
                .foregroundStyle(Color.Exit.warning.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.Exit.divider)
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
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.Exit.divider)
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(ExitNumberFormatter.formatToEokManWon(amount))
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.tertiaryText)
                    }
                }
            }
        }
    }
    
    // MARK: - Legend (행운 제외)
    
    private var legendSection: some View {
        HStack(spacing: ExitSpacing.lg) {
            legendItem(color: Color.Exit.accent, label: "평균(50%)", isDashed: false)
            legendItem(color: Color.Exit.caution, label: "불운(하위10%)", isDashed: false)
            legendItem(color: Color.Exit.tertiaryText, label: "기존예측", isDashed: true)
        }
    }
    
    private func legendItem(color: Color, label: String, isDashed: Bool) -> some View {
        HStack(spacing: ExitSpacing.xs) {
            if isDashed {
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(color)
                            .frame(width: 4, height: 2)
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 14, height: 3)
            }
            
            Text(label)
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.secondaryText)
        }
    }
    
    // MARK: - Interpretation
    
    private var interpretationSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            Divider()
                .background(Color.Exit.divider)
            
            // 데이터 요약
            VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                Text("📊 시뮬레이션 조건")
                    .font(.Exit.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                HStack(spacing: ExitSpacing.lg) {
                    dataItem(label: "목표 자산", value: ExitNumberFormatter.formatToEokManWon(targetAsset))
                    dataItem(label: "월 지출", value: ExitNumberFormatter.formatToManWon(scenario.desiredMonthlyIncome))
                    dataItem(label: "수익률", value: String(format: "%.1f%%", scenario.postRetirementReturnRate))
                }
            }
            
            // 해석 도움말
            HStack(alignment: .top, spacing: ExitSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.Exit.accent)
                
                Text("시장 상황에 따라 자산 수명이 크게 달라져요. 불운한 시기에 은퇴하면 더 빨리 소진될 수 있으니 여유 있게 준비하세요!")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(ExitSpacing.sm)
            .background(Color.Exit.accent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
        }
    }
    
    private func dataItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.tertiaryText)
            Text(value)
                .font(.Exit.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.Exit.primaryText)
        }
    }
}
