//
//  RetirementShortTermChart.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI
import Charts

/// 은퇴 후 단기(1~10년) 자산 변화 차트
struct RetirementShortTermChart: View {
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
    
    // 단기 데이터 (0~10년, 최대 11개 포인트)
    private var shortTermYears: Int { 10 }
    
    private var bestShortTerm: [Double] {
        Array(result.bestPath.yearlyAssets.prefix(shortTermYears + 1))
    }
    
    private var medianShortTerm: [Double] {
        Array(result.medianPath.yearlyAssets.prefix(shortTermYears + 1))
    }
    
    private var worstShortTerm: [Double] {
        Array(result.worstPath.yearlyAssets.prefix(shortTermYears + 1))
    }
    
    private var deterministicShortTerm: [Double] {
        Array(result.deterministicPath.yearlyAssets.prefix(shortTermYears + 1))
    }
    
    // 10년 후 자산 변화율
    private var medianChangeRate: Double {
        guard let first = medianShortTerm.first, first > 0,
              let last = medianShortTerm.last else { return 0 }
        return (last - first) / first * 100
    }
    
    private var worstChangeRate: Double {
        guard let first = worstShortTerm.first, first > 0,
              let last = worstShortTerm.last else { return 0 }
        return (last - first) / first * 100
    }
    
    // 금액 간략 포맷
    private func formatSimple(_ amount: Double) -> String {
        if amount <= 0 { return "0원" }
        let eok = amount / 100_000_000
        if eok >= 1 {
            return String(format: "%.1f억", eok)
        } else {
            let man = amount / 10_000
            return String(format: "%.0f만원", man)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            // 헤더
            headerSection
            
            // 핵심 메시지
            keyMessageSection
            
            // 차트
            shortTermChart
            
            // 범례
            legendSection
            
            // 연도별 상세
            yearlyDetailSection
            
            // 해석 도움말
            interpretationSection
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.xs) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(Color.Exit.accent)
                Text("은퇴 초반 10년, 어떻게 될까?")
                    .font(.Exit.title3)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            Text("은퇴 직후가 가장 중요해요. 처음 10년의 시장 상황이 전체를 좌우합니다.")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
        }
    }
    
    // MARK: - Key Message
    
    private var keyMessageSection: some View {
        HStack(spacing: ExitSpacing.md) {
            // 평균 케이스
            VStack(spacing: ExitSpacing.xs) {
                Text("평균적으로")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
                
                Text(formatSimple(medianShortTerm.last ?? 0))
                    .font(.Exit.body)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.Exit.accent)
                
                Text(medianChangeRate >= 0 ? "+\(String(format: "%.0f", medianChangeRate))%" : "\(String(format: "%.0f", medianChangeRate))%")
                    .font(.Exit.caption)
                    .foregroundStyle(medianChangeRate >= 0 ? Color.Exit.positive : Color.Exit.caution)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ExitSpacing.md)
            .background(Color.Exit.accent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
            
            // 불운 케이스
            VStack(spacing: ExitSpacing.xs) {
                Text("불운하면")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
                
                Text(formatSimple(worstShortTerm.last ?? 0))
                    .font(.Exit.body)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.Exit.caution)
                
                Text(worstChangeRate >= 0 ? "+\(String(format: "%.0f", worstChangeRate))%" : "\(String(format: "%.0f", worstChangeRate))%")
                    .font(.Exit.caption)
                    .foregroundStyle(worstChangeRate >= 0 ? Color.Exit.positive : Color.Exit.caution)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ExitSpacing.md)
            .background(Color.Exit.caution.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        }
    }
    
    // MARK: - Chart
    
    private var shortTermChart: some View {
        Chart {
            // 불운 경로
            ForEach(Array(worstShortTerm.enumerated()), id: \.offset) { index, asset in
                LineMark(
                    x: .value("년", index),
                    y: .value("자산", asset),
                    series: .value("시나리오", "불운")
                )
                .foregroundStyle(Color.Exit.caution)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }
            
            // 기존 예측
            ForEach(Array(deterministicShortTerm.enumerated()), id: \.offset) { index, asset in
                LineMark(
                    x: .value("년", index),
                    y: .value("자산", asset),
                    series: .value("시나리오", "기존")
                )
                .foregroundStyle(Color.Exit.tertiaryText)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                .interpolationMethod(.catmullRom)
            }
            
            // 평균 경로 (마지막에 그려서 위에 표시)
            ForEach(Array(medianShortTerm.enumerated()), id: \.offset) { index, asset in
                LineMark(
                    x: .value("년", index),
                    y: .value("자산", asset),
                    series: .value("시나리오", "평균")
                )
                .foregroundStyle(Color.Exit.accent)
                .lineStyle(StrokeStyle(lineWidth: 3))
                .interpolationMethod(.catmullRom)
            }
            
            // 시작점
            PointMark(x: .value("년", 0), y: .value("자산", targetAsset))
                .foregroundStyle(Color.Exit.accent)
                .symbolSize(80)
        }
        .frame(height: 180)
        .chartXAxis {
            AxisMarks(values: Array(0...10)) { value in
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
    
    // MARK: - Legend
    
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
    
    // MARK: - Yearly Detail
    
    private var yearlyDetailSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            Text("연도별 예상 자산")
                .font(.Exit.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.Exit.secondaryText)
            
            // 주요 연도만 표시 (1, 3, 5, 7, 10년)
            let keyYears = [1, 3, 5, 7, 10]
            
            HStack(spacing: ExitSpacing.xs) {
                ForEach(keyYears, id: \.self) { year in
                    if year < medianShortTerm.count {
                        yearColumn(year: year, amount: medianShortTerm[year])
                    }
                }
            }
        }
    }
    
    private func yearColumn(year: Int, amount: Double) -> some View {
        VStack(spacing: ExitSpacing.xs) {
            Text("\(year)년")
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.tertiaryText)
            
            Text(formatSimple(amount))
                .font(.Exit.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.Exit.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ExitSpacing.sm)
        .background(Color.Exit.secondaryCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
    }
    
    // MARK: - Interpretation
    
    private var interpretationSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            Divider()
                .background(Color.Exit.divider)
            
            HStack(alignment: .top, spacing: ExitSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.Exit.accent)
                
                VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                    Text("왜 처음 10년이 중요할까요?")
                        .font(.Exit.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    Text("은퇴 직후 시장이 하락하면(불운) 회복할 시간이 부족해요. 반면 처음 몇 년이 좋으면 여유가 생겨요. 이를 '시퀀스 리스크'라고 해요.")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(ExitSpacing.sm)
            .background(Color.Exit.accent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
        }
    }
}

