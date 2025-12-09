//
//  RetirementProjectionChart.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI
import Charts

/// 은퇴 후 장기(40년) 자산 변화 예측 차트
struct RetirementProjectionChart: View {
    let result: RetirementSimulationResult
    let userProfile: UserProfile
    
    // 시뮬레이션 시작 자산 (실제 시뮬레이션에서 사용된 값)
    private var startingAsset: Double {
        // 시뮬레이션 결과의 첫 번째 데이터 포인트가 시작 자산
        result.medianPath.yearlyAssets.first ?? calculatedTargetAsset
    }
    
    // 계산된 목표 자산 (폴백용)
    private var calculatedTargetAsset: Double {
        RetirementCalculator.calculateTargetAssets(
            desiredMonthlyIncome: userProfile.desiredMonthlyIncome,
            postRetirementReturnRate: userProfile.postRetirementReturnRate
        )
    }
    
    // 각 시나리오 경로 데이터
    private var veryBestPath: [Double] { result.veryBestPath.yearlyAssets }
    private var luckyPath: [Double] { result.luckyPath.yearlyAssets }
    private var medianPath: [Double] { result.medianPath.yearlyAssets }
    private var unluckyPath: [Double] { result.unluckyPath.yearlyAssets }
    private var veryWorstPath: [Double] { result.veryWorstPath.yearlyAssets }
    private var deterministicPath: [Double] { result.deterministicPath.yearlyAssets }
    
    // Y축 최대값 계산 (매우행운 제외, 스케일 안정화)
    private var chartYMax: Double {
        // 행운까지의 최대값 사용 (매우행운은 제외하여 스케일 안정화)
        let maxFromLucky = luckyPath.max() ?? startingAsset
        let maxFromMedian = medianPath.max() ?? startingAsset
        return max(maxFromLucky, maxFromMedian, startingAsset) * 1.1
    }
    
    // 변화율 계산
    private func changeRate(for data: [Double]) -> Double {
        guard let first = data.first, first > 0,
              let last = data.last else { return 0 }
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
    
    // 특정 연도의 자산 가져오기
    private func assetAt(year: Int, from data: [Double]) -> Double {
        guard year < data.count else { return data.last ?? 0 }
        return data[year]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            // 1. 타이틀 + 설명
            headerSection
            
            // 1.5. 기준 설명
            contextSection
            
            // 2. 차트 및 데이터
            keyMessageSection
            
            projectionChart
            
            legendSection
            
            // 3. 연도별 테이블
            yearlyAssetTable
            
            // 4. 도움말
            helpSection
            
            // 5. 시뮬레이션 조건
            simulationConditionSection
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
                Image(systemName: "hourglass")
                    .foregroundStyle(Color.Exit.accent)
                Text("은퇴 후 40년, 어떻게 될까?")
                    .font(.Exit.title3)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            Text("장기적인 관점에서 시장 상황에 따라 자산이 어떻게 변할지 예측합니다.")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
        }
    }
    
    // MARK: - Context Section
    
    private var contextSection: some View {
        HStack(spacing: ExitSpacing.md) {
            VStack(spacing: 2) {
                Text("시작 자산")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.secondaryText)
                Text(formatSimple(startingAsset))
                    .font(.Exit.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.accent)
            }
            
            Image(systemName: "arrow.right")
                .font(.system(size: 16))
                .foregroundStyle(Color.Exit.secondaryText)
            
            VStack(spacing: 2) {
                Text("40년 후")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.secondaryText)
                Text("시장 상황에 따라")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
        }
        .padding(ExitSpacing.md)
        .frame(maxWidth: .infinity)
        .background(Color.Exit.secondaryCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
    }
    
    // MARK: - Key Message Section (5개 시나리오)
    
    private var keyMessageSection: some View {
        VStack(spacing: ExitSpacing.sm) {
            // 첫 번째 줄: 매우 행운, 행운, 평균
            HStack(spacing: ExitSpacing.xs) {
                scenarioCard(
                    title: "매우 행운",
                    amount: veryBestPath.last ?? 0,
                    changeRate: changeRate(for: veryBestPath),
                    depletionYear: result.veryBestPath.depletionYear,
                    backgroundColor: Color.Exit.positive.opacity(0.15),
                    accentColor: Color.Exit.positive
                )
                
                scenarioCard(
                    title: "행운",
                    amount: luckyPath.last ?? 0,
                    changeRate: changeRate(for: luckyPath),
                    depletionYear: result.luckyPath.depletionYear,
                    backgroundColor: Color.Exit.accent.opacity(0.15),
                    accentColor: Color.Exit.accent
                )
                
                scenarioCard(
                    title: "평균",
                    amount: medianPath.last ?? 0,
                    changeRate: changeRate(for: medianPath),
                    depletionYear: result.medianPath.depletionYear,
                    backgroundColor: Color.Exit.primaryText.opacity(0.1),
                    accentColor: Color.Exit.primaryText
                )
            }
            
            // 두 번째 줄: 불행, 매우 불행
            HStack(spacing: ExitSpacing.xs) {
                scenarioCard(
                    title: "불행",
                    amount: unluckyPath.last ?? 0,
                    changeRate: changeRate(for: unluckyPath),
                    depletionYear: result.unluckyPath.depletionYear,
                    backgroundColor: Color.Exit.caution.opacity(0.15),
                    accentColor: Color.Exit.caution
                )
                
                scenarioCard(
                    title: "매우 불행",
                    amount: veryWorstPath.last ?? 0,
                    changeRate: changeRate(for: veryWorstPath),
                    depletionYear: result.veryWorstPath.depletionYear,
                    backgroundColor: Color.Exit.warning.opacity(0.15),
                    accentColor: Color.Exit.warning
                )
            }
        }
    }
    
    private func scenarioCard(title: String, amount: Double, changeRate: Double, depletionYear: Int?, backgroundColor: Color, accentColor: Color) -> some View {
        VStack(spacing: ExitSpacing.xs) {
            Text(title)
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.secondaryText)
            
            if let depletion = depletionYear {
                Text("\(depletion)년 뒤 소진")
                    .font(.Exit.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(accentColor)
            } else {
                Text(formatSimple(amount))
                    .font(.Exit.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            
            if depletionYear == nil {
                Text(changeRate >= 0 ? "+\(String(format: "%.0f", changeRate))%" : "\(String(format: "%.0f", changeRate))%")
                    .font(.Exit.caption2)
                    .foregroundStyle(changeRate >= 0 ? Color.Exit.positive : Color.Exit.warning)
            } else {
                Text("자산 소진")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.warning)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ExitSpacing.sm)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
    }
    
    // MARK: - Chart (모든 시나리오 포함)
    
    private var projectionChart: some View {
        Chart {
            // 매우 불행 경로 (하위 10%) - 빨간색
            ForEach(Array(veryWorstPath.enumerated()), id: \.offset) { index, asset in
                LineMark(
                    x: .value("년", index),
                    y: .value("자산", max(0, asset)),
                    series: .value("시나리오", "매우불행")
                )
                .foregroundStyle(Color.Exit.warning)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }
            
            // 불행 경로 (70%) - 노란색
            ForEach(Array(unluckyPath.enumerated()), id: \.offset) { index, asset in
                LineMark(
                    x: .value("년", index),
                    y: .value("자산", max(0, asset)),
                    series: .value("시나리오", "불행")
                )
                .foregroundStyle(Color.Exit.caution)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }
            
            // 기존 예측 - 회색 점선
            ForEach(Array(deterministicPath.enumerated()), id: \.offset) { index, asset in
                LineMark(
                    x: .value("년", index),
                    y: .value("자산", max(0, asset)),
                    series: .value("시나리오", "기존")
                )
                .foregroundStyle(Color.Exit.tertiaryText)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                .interpolationMethod(.catmullRom)
            }
            
            // 평균 경로 (50%) - 흰색/회색
            ForEach(Array(medianPath.enumerated()), id: \.offset) { index, asset in
                LineMark(
                    x: .value("년", index),
                    y: .value("자산", max(0, asset)),
                    series: .value("시나리오", "평균")
                )
                .foregroundStyle(Color.Exit.primaryText.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)
            }
            
            // 행운 경로 (30%) - 엑센트
            ForEach(Array(luckyPath.enumerated()), id: \.offset) { index, asset in
                LineMark(
                    x: .value("년", index),
                    y: .value("자산", max(0, asset)),
                    series: .value("시나리오", "행운")
                )
                .foregroundStyle(Color.Exit.accent)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }
            
            // 매우 행운 경로 (10%) - 초록색
            ForEach(Array(veryBestPath.enumerated()), id: \.offset) { index, asset in
                LineMark(
                    x: .value("년", index),
                    y: .value("자산", max(0, asset)),
                    series: .value("시나리오", "매우행운")
                )
                .foregroundStyle(Color.Exit.positive)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }
            
            // 시작점
            PointMark(x: .value("년", 0), y: .value("자산", startingAsset))
                .foregroundStyle(Color.Exit.accent)
                .symbolSize(80)
            
            // 0선
            RuleMark(y: .value("zero", 0))
                .foregroundStyle(Color.Exit.warning.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
        .frame(height: 200)
        .chartYScale(domain: 0...chartYMax)
        .clipped()
        .chartXAxis {
            AxisMarks(values: [0, 10, 20, 30, 40]) { value in
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
                        Text(ExitNumberFormatter.formatChartAxis(amount))
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.tertiaryText)
                    }
                }
            }
        }
    }
    
    // MARK: - Legend (2줄)
    
    private var legendSection: some View {
        VStack(spacing: ExitSpacing.xs) {
            // 첫 번째 줄
            HStack(spacing: ExitSpacing.md) {
                legendItem(color: Color.Exit.positive, label: "매우행운(10%)", isDashed: false)
                legendItem(color: Color.Exit.accent, label: "행운(30%)", isDashed: false)
                legendItem(color: Color.Exit.primaryText.opacity(0.7), label: "평균(50%)", isDashed: false)
            }
            
            // 두 번째 줄
            HStack(spacing: ExitSpacing.md) {
                legendItem(color: Color.Exit.caution, label: "불행(70%)", isDashed: false)
                legendItem(color: Color.Exit.warning, label: "매우불행(90%)", isDashed: false)
                legendItem(color: Color.Exit.tertiaryText, label: "기존예측", isDashed: true)
            }
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
    
    // MARK: - Yearly Asset Table
    
    private var yearlyAssetTable: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            Text("연도별 예상 자산")
                .font(.Exit.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.Exit.secondaryText)
            
            VStack(spacing: 0) {
                // 헤더
                HStack(spacing: 0) {
                    Text("시나리오")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.secondaryText)
                        .frame(width: 60, alignment: .leading)
                    
                    ForEach([10, 20, 30, 40], id: \.self) { year in
                        Text("\(year)년")
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.secondaryText)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, ExitSpacing.sm)
                .padding(.vertical, ExitSpacing.xs)
                .background(Color.Exit.divider.opacity(0.5))
                
                // 데이터 행
                assetRow(label: "매우행운", data: veryBestPath, color: Color.Exit.positive)
                assetRow(label: "행운", data: luckyPath, color: Color.Exit.accent)
                assetRow(label: "평균", data: medianPath, color: Color.Exit.primaryText)
                assetRow(label: "불행", data: unluckyPath, color: Color.Exit.caution)
                assetRow(label: "매우불행", data: veryWorstPath, color: Color.Exit.warning)
            }
            .background(Color.Exit.secondaryCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        }
    }
    
    private func assetRow(label: String, data: [Double], color: Color) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.Exit.caption2)
                .foregroundStyle(color)
                .frame(width: 60, alignment: .leading)
            
            ForEach([10, 20, 30, 40], id: \.self) { year in
                let asset = assetAt(year: year, from: data)
                Text(formatSimple(asset))
                    .font(.Exit.caption2)
                    .foregroundStyle(asset > 0 ? Color.Exit.primaryText : Color.Exit.warning)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(.horizontal, ExitSpacing.sm)
        .padding(.vertical, ExitSpacing.xs)
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
                
                Text("40년간 시장 상황에 따라 자산이 크게 달라질 수 있어요. 매우 행운인 경우 차트 범위를 벗어날 수 있으니 상단 카드와 테이블을 함께 확인하세요.")
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
            
            HStack(spacing: ExitSpacing.lg) {
                dataItem(label: "시작 자산", value: ExitNumberFormatter.formatChartAxis(startingAsset))
                dataItem(label: "월 지출", value: ExitNumberFormatter.formatToManWon(userProfile.desiredMonthlyIncome))
                dataItem(label: "수익률", value: String(format: "%.1f%%", userProfile.postRetirementReturnRate))
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
}
