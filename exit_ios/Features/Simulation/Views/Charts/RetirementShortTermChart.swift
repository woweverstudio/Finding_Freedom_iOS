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
    let userProfile: UserProfile
    var spendingRatio: Double = 1.0
    
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
    
    // 단기 데이터 (0~10년, 최대 11개 포인트)
    private var shortTermYears: Int { 10 }
    
    // 10년 기준으로 정렬된 경로 사용 (단기 분석에 적합)
    private var veryBestShortTerm: [Double] {
        Array(result.shortTermVeryBestPath.yearlyAssets.prefix(shortTermYears + 1))
    }
    
    private var luckyShortTerm: [Double] {
        Array(result.shortTermLuckyPath.yearlyAssets.prefix(shortTermYears + 1))
    }
    
    private var medianShortTerm: [Double] {
        Array(result.shortTermMedianPath.yearlyAssets.prefix(shortTermYears + 1))
    }
    
    private var unluckyShortTerm: [Double] {
        Array(result.shortTermUnluckyPath.yearlyAssets.prefix(shortTermYears + 1))
    }
    
    private var veryWorstShortTerm: [Double] {
        Array(result.shortTermVeryWorstPath.yearlyAssets.prefix(shortTermYears + 1))
    }
    
    private var deterministicShortTerm: [Double] {
        Array(result.deterministicPath.yearlyAssets.prefix(shortTermYears + 1))
    }
    
    // 10년 후 자산 변화율 계산
    private func changeRate(for data: [Double]) -> Double {
        guard let first = data.first, first > 0,
              let last = data.last else { return 0 }
        return (last - first) / first * 100
    }
    
    // 금액 간략 포맷 (억단위로 표시, 소수점 둘째자리)
    private func formatSimple(_ amount: Double) -> String {
        if amount <= 0 { return "0원" }
        let eok = amount / 100_000_000
        if eok >= 1 {
            return String(format: "%.2f억", eok)
        } else if eok >= 0.01 {
            // 100만원 이상 억단위로 표시 (예: 7430만원 → 0.74억)
            return String(format: "%.2f억", eok)
        } else {
            let man = amount / 10_000
            return String(format: "%.0f만원", man)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            // 1. 타이틀 + 설명
            headerSection
            
            // 1.5. 기준 설명
            contextSection
            
            // 2. 차트 및 데이터
            keyMessageSection
            
            shortTermChart
            
            legendSection
            
            yearlyDetailSection
            
            // 3. 도움말
            helpSection
            
            // 4. 시뮬레이션 조건
            simulationConditionSection
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
                Text("왜 처음 10년이 중요할까요?")
                    .font(.Exit.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                Text("은퇴 직후 시장이 하락하면(불행) 회복할 시간이 부족해요. 반면 처음 몇 년이 좋으면 여유가 생겨요. 이를 '시퀀스 리스크'라고 해요.")
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
        let actualSpending = userProfile.desiredMonthlyIncome * spendingRatio
        let spendingDisplayValue = spendingRatio < 1.0
            ? "\(ExitNumberFormatter.formatToManWon(actualSpending))(\(String(format: "%.0f", spendingRatio * 100))%)"
            : ExitNumberFormatter.formatToManWon(actualSpending)
        
        return VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            Text("📊 시뮬레이션 조건")
                .font(.Exit.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.Exit.secondaryText)
            
            HStack(spacing: ExitSpacing.sm) {
                dataItem(label: "시작 자산", value: ExitNumberFormatter.formatChartAxis(startingAsset))
                dataItem(label: "월 지출", value: spendingDisplayValue)
                dataItem(label: "수익률", value: String(format: "%.1f%%", userProfile.postRetirementReturnRate))
            }
        }
    }
    
    private func dataItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.tertiaryText)
                .lineLimit(1)
            Text(value)
                .font(.Exit.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.Exit.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
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
                Text("10년 후")
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
    
    // MARK: - Key Message (5개 시나리오)
    
    private var keyMessageSection: some View {
        VStack(spacing: ExitSpacing.sm) {
            // 첫 번째 줄: 매우 행운, 행운, 평균
            HStack(spacing: ExitSpacing.xs) {
                scenarioCard(
                    title: "매우 행운",
                    amount: veryBestShortTerm.last ?? 0,
                    changeRate: changeRate(for: veryBestShortTerm),
                    backgroundColor: Color.Exit.positive.opacity(0.15),
                    accentColor: Color.Exit.positive
                )
                
                scenarioCard(
                    title: "행운",
                    amount: luckyShortTerm.last ?? 0,
                    changeRate: changeRate(for: luckyShortTerm),
                    backgroundColor: Color.Exit.accent.opacity(0.15),
                    accentColor: Color.Exit.accent
                )
                
                scenarioCard(
                    title: "평균",
                    amount: medianShortTerm.last ?? 0,
                    changeRate: changeRate(for: medianShortTerm),
                    backgroundColor: Color.Exit.primaryText.opacity(0.1),
                    accentColor: Color.Exit.primaryText
                )
            }
            
            // 두 번째 줄: 불행, 매우 불행
            HStack(spacing: ExitSpacing.xs) {
                scenarioCard(
                    title: "불행",
                    amount: unluckyShortTerm.last ?? 0,
                    changeRate: changeRate(for: unluckyShortTerm),
                    backgroundColor: Color.Exit.caution.opacity(0.15),
                    accentColor: Color.Exit.caution
                )
                
                scenarioCard(
                    title: "매우 불행",
                    amount: veryWorstShortTerm.last ?? 0,
                    changeRate: changeRate(for: veryWorstShortTerm),
                    backgroundColor: Color.Exit.warning.opacity(0.15),
                    accentColor: Color.Exit.warning
                )
            }
        }
    }
    
    private func scenarioCard(title: String, amount: Double, changeRate: Double, backgroundColor: Color, accentColor: Color) -> some View {
        VStack(spacing: ExitSpacing.xs) {
            Text(title)
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.secondaryText)
            
            Text(formatSimple(amount))
                .font(.Exit.caption)
                .fontWeight(.bold)
                .foregroundStyle(accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(changeRate >= 0 ? "+\(String(format: "%.0f", changeRate))%" : "\(String(format: "%.0f", changeRate))%")
                .font(.Exit.caption2)
                .foregroundStyle(changeRate >= 0 ? Color.Exit.positive : Color.Exit.warning)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ExitSpacing.sm)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
    }
    
    // MARK: - Chart
    
    private var shortTermChart: some View {
        Chart {
            // 매우 불행 경로 (하위 10%) - 빨간색
            ForEach(Array(veryWorstShortTerm.enumerated()), id: \.offset) { index, asset in
                LineMark(
                    x: .value("년", index),
                    y: .value("자산", asset),
                    series: .value("시나리오", "매우불행")
                )
                .foregroundStyle(Color.Exit.warning)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }
            
            // 불행 경로 (70%) - 노란색
            ForEach(Array(unluckyShortTerm.enumerated()), id: \.offset) { index, asset in
                LineMark(
                    x: .value("년", index),
                    y: .value("자산", asset),
                    series: .value("시나리오", "불행")
                )
                .foregroundStyle(Color.Exit.caution)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }
            
            // 기존 예측 - 회색 점선
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
            
            // 평균 경로 (50%) - 흰색/회색
            ForEach(Array(medianShortTerm.enumerated()), id: \.offset) { index, asset in
                LineMark(
                    x: .value("년", index),
                    y: .value("자산", asset),
                    series: .value("시나리오", "평균")
                )
                .foregroundStyle(Color.Exit.primaryText.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)
            }
            
            // 행운 경로 (30%) - 엑센트
            ForEach(Array(luckyShortTerm.enumerated()), id: \.offset) { index, asset in
                LineMark(
                    x: .value("년", index),
                    y: .value("자산", asset),
                    series: .value("시나리오", "행운")
                )
                .foregroundStyle(Color.Exit.accent)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }
            
            // 매우 행운 경로 (10%) - 초록색
            ForEach(Array(veryBestShortTerm.enumerated()), id: \.offset) { index, asset in
                LineMark(
                    x: .value("년", index),
                    y: .value("자산", asset),
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
        }
        .frame(height: 200)
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
    
    // MARK: - Yearly Detail
    
    private var yearlyDetailSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            Text("연도별 예상 자산 (평균)")
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
}
