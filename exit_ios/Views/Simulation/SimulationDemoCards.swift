//
//  SimulationDemoCards.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI
import Charts

/// 시뮬레이션 데모 카드들 (실제 UI 미리보기용)
struct SimulationDemoCards: View {
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            sectionHeader(icon: "eye.fill", title: "이런 결과를 볼 수 있어요")
                .padding(.horizontal, ExitSpacing.md)
            
            exampleDataNotice
            
            // 1. 성공률 카드
            demoSuccessRateCard
            
            // 2. 자산 변화 예측 차트
            demoAssetPathChart
            
            // 3. 목표 달성 시점 분포
            demoDistributionChart
            
            // 4. 은퇴 후 10년 분석
            demoRetirementShortTermChart
        }
    }
    // MARK: - Example Data Notice
    
    private var exampleDataNotice: some View {
        HStack(spacing: ExitSpacing.md) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.Exit.accent)
            
            VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                Text("아래는 예시 데이터예요")
                    .font(.Exit.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Text("실제 분석은 내 데이터를 기반으로 더 정확하고 상세한 결과를 보여드려요.")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(ExitSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: ExitRadius.lg)
                .fill(Color.Exit.accent.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: ExitRadius.lg)
                        .stroke(Color.Exit.accent.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // MARK: - Demo Success Rate Card
    
    private var demoSuccessRateCard: some View {
        VStack(spacing: ExitSpacing.lg) {
            // 타이틀
            HStack {
                demoBadge
                Spacer()
            }
            
            HStack {
                Image(systemName: "percent")
                    .foregroundStyle(Color.Exit.accent)
                Text("성공 확률")
                    .font(.Exit.title3)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            // 큰 성공률 표시
            VStack(spacing: ExitSpacing.sm) {
                Text("계획대로 회사 탈출에 성공할 확률")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("78")
                        .font(.system(size: 72, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.Exit.accent)
                    
                    Text("%")
                        .font(.Exit.title)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
                
                Text("높음")
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.accent)
                    .padding(.horizontal, ExitSpacing.md)
                    .padding(.vertical, ExitSpacing.xs)
                    .background(
                        Capsule()
                            .fill(Color.Exit.accent.opacity(0.15))
                    )
            }
            
            // 코칭 메시지
            Text("목표 달성 가능성이 높습니다. 현재 계획을 유지하세요")
                .font(.Exit.body)
                .foregroundStyle(Color.Exit.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 도움말
            HStack(alignment: .top, spacing: ExitSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.Exit.accent)
                
                VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                    Text("이 확률이 의미하는 것")
                        .font(.Exit.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    Text("30,000가지 다른 미래를 시뮬레이션해봤어요. 계획보다 10% 넘게 늦어지면 '실패'로 봤어요.")
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
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.xl))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // MARK: - Demo Asset Path Chart
    
    private var demoAssetPathChart: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            HStack {
                demoBadge
                Spacer()
            }
            
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundStyle(Color.Exit.accent)
                Text("자산 변화 예측")
                    .font(.Exit.title3)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            // 차트
            Chart {
                // 행운
                ForEach(Array(demoAssetData.best.enumerated()), id: \.offset) { index, amount in
                    LineMark(
                        x: .value("년", index * 12),
                        y: .value("자산", amount),
                        series: .value("경로", "행운")
                    )
                    .foregroundStyle(Color.Exit.positive)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
                
                // 평균
                ForEach(Array(demoAssetData.median.enumerated()), id: \.offset) { index, amount in
                    LineMark(
                        x: .value("년", index * 12),
                        y: .value("자산", amount),
                        series: .value("경로", "평균")
                    )
                    .foregroundStyle(Color.Exit.accent)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .interpolationMethod(.catmullRom)
                }
                
                // 불행
                ForEach(Array(demoAssetData.worst.enumerated()), id: \.offset) { index, amount in
                    LineMark(
                        x: .value("년", index * 12),
                        y: .value("자산", amount),
                        series: .value("경로", "불행")
                    )
                    .foregroundStyle(Color.Exit.caution)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
                
                // 목표선
                RuleMark(y: .value("목표", 600_000_000))
                    .foregroundStyle(Color.Exit.accent.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let months = value.as(Int.self) {
                            Text("\(months / 12)년")
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
                            Text(formatChartAxis(amount))
                                .font(.Exit.caption2)
                                .foregroundStyle(Color.Exit.tertiaryText)
                        }
                    }
                }
            }
            
            // 범례
            HStack(spacing: ExitSpacing.lg) {
                legendItem(color: Color.Exit.positive, label: "행운(상위10%)")
                legendItem(color: Color.Exit.accent, label: "평균(50%)")
                legendItem(color: Color.Exit.caution, label: "불행(하위10%)")
            }
            
            // 목표 달성 시점 비교
            VStack(alignment: .leading, spacing: ExitSpacing.md) {
                Text("목표 자산 달성 시점")
                    .font(.Exit.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.primaryText)
                
                demoTimelineChart
            }
            
            // 도움말
            HStack(alignment: .top, spacing: ExitSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.Exit.accent)
                
                VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                    Text("이 그래프가 알려주는 것")
                        .font(.Exit.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    Text("시장 상황에 따라 자산이 어떻게 변할지 3가지 시나리오로 보여줘요. 대부분의 경우가 이 범위 안에 들어요.")
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
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    private var demoTimelineChart: some View {
        let timelineData: [(label: String, months: Int, color: Color, icon: String)] = [
            ("행운", 96, Color.Exit.positive, "🍀"),
            ("평균", 144, Color.Exit.accent, "📊"),
            ("불행", 192, Color.Exit.caution, "🌧️"),
            ("기존 예측", 120, Color.Exit.tertiaryText, "📌")
        ]
        
        let maxMonths = 192
        
        return VStack(spacing: ExitSpacing.sm) {
            ForEach(timelineData, id: \.label) { item in
                HStack(spacing: ExitSpacing.sm) {
                    HStack(spacing: 4) {
                        Text(item.icon)
                            .font(.system(size: 12))
                        Text(item.label)
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.secondaryText)
                    }
                    .frame(width: 70, alignment: .leading)
                    
                    GeometryReader { geometry in
                        let barWidth = (CGFloat(item.months) / CGFloat(maxMonths)) * geometry.size.width
                        
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.Exit.divider)
                                .frame(height: 24)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.color.opacity(0.8))
                                .frame(width: max(barWidth, 40), height: 24)
                            
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
    
    // MARK: - Demo Distribution Chart
    
    private var demoDistributionChart: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            HStack {
                demoBadge
                Spacer()
            }
            
            // 타이틀
            HStack {
                Image(systemName: "target")
                    .foregroundStyle(Color.Exit.accent)
                Text("언제 달성할 가능성이 높을까?")
                    .font(.Exit.title3)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            // 핵심 수치
            HStack(alignment: .bottom, spacing: ExitSpacing.sm) {
                Text("12년차")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.Exit.accent)
                
                Text("에 달성할 가능성이 가장 높아요")
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.secondaryText)
                    .padding(.bottom, 4)
            }
            
            // 차트
            Chart {
                ForEach(demoDistributionData, id: \.year) { data in
                    BarMark(
                        x: .value("연도", data.year),
                        y: .value("확률", data.probability),
                        width: .fixed(12)
                    )
                    .foregroundStyle(
                        data.year == 12 ?
                        Color.Exit.accent.gradient :
                        Color.Exit.accent.opacity(0.4).gradient
                    )
                    .cornerRadius(4)
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
                rangeIndicator(icon: "clock", label: "빠르면", value: "8년", color: Color.Exit.positive)
                rangeIndicator(icon: "target", label: "대부분", value: "12년", color: Color.Exit.accent)
                rangeIndicator(icon: "clock.badge.exclamationmark", label: "늦으면", value: "16년", color: Color.Exit.caution)
            }
            
            // 도움말
            HStack(alignment: .top, spacing: ExitSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.Exit.accent)
                
                VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                    Text("이 그래프가 알려주는 것")
                        .font(.Exit.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    Text("막대가 높을수록 그 시점에 목표를 달성할 확률이 높아요. 대부분(80%)은 8~16년 사이에 달성해요.")
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
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // MARK: - Demo Retirement Short Term Chart
    
    private var demoRetirementShortTermChart: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            HStack {
                demoBadge
                Spacer()
            }
            
            // 헤더
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
            
            // 기준 설명
            HStack(spacing: ExitSpacing.md) {
                VStack(spacing: 2) {
                    Text("은퇴 시점")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.secondaryText)
                    Text("6억")
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
            
            // 시나리오 카드
            VStack(spacing: ExitSpacing.sm) {
                HStack(spacing: ExitSpacing.xs) {
                    scenarioCard(title: "매우 행운", amount: "9.2억", change: "+53%", color: Color.Exit.positive)
                    scenarioCard(title: "행운", amount: "7.5억", change: "+25%", color: Color.Exit.accent)
                    scenarioCard(title: "평균", amount: "5.8억", change: "-3%", color: Color.Exit.primaryText)
                }
                
                HStack(spacing: ExitSpacing.xs) {
                    scenarioCard(title: "불행", amount: "4.2억", change: "-30%", color: Color.Exit.caution)
                    scenarioCard(title: "매우 불행", amount: "2.8억", change: "-53%", color: Color.Exit.warning)
                }
            }
            
            // 도움말
            HStack(alignment: .top, spacing: ExitSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.Exit.accent)
                
                VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                    Text("왜 처음 10년이 중요할까요?")
                        .font(.Exit.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    Text("은퇴 직후 시장이 하락하면 회복할 시간이 부족해요. 이를 '시퀀스 리스크'라고 해요.")
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
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    private func scenarioCard(title: String, amount: String, change: String, color: Color) -> some View {
        VStack(spacing: ExitSpacing.xs) {
            Text(title)
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.secondaryText)
            
            Text(amount)
                .font(.Exit.caption)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(change)
                .font(.Exit.caption2)
                .foregroundStyle(change.hasPrefix("+") ? Color.Exit.positive : Color.Exit.warning)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ExitSpacing.sm)
        .background(color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
    }
    
    // MARK: - Helper Views
    
    private var demoBadge: some View {
        Text("예시")
            .font(.Exit.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(Color(hex: "FFD700"))
            .padding(.horizontal, ExitSpacing.sm)
            .padding(.vertical, ExitSpacing.xs)
            .background(Color(hex: "FFD700").opacity(0.2))
            .clipShape(Capsule())
    }
    
    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: ExitSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.Exit.accent)
            
            Text(title)
                .font(.Exit.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.Exit.primaryText)
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
    
    private func formatChartAxis(_ amount: Double) -> String {
        if amount >= 100_000_000 {
            return String(format: "%.1f억", amount / 100_000_000)
        } else if amount >= 10_000 {
            return String(format: "%.0f만", amount / 10_000)
        } else {
            return String(format: "%.0f", amount)
        }
    }
    
    // MARK: - Demo Data
    
    private var demoAssetData: (best: [Double], median: [Double], worst: [Double]) {
        // 15년치 데이터 (연 단위, 월 환산을 위해 index*12로 표시)
        let best: [Double] = [100_000_000, 180_000_000, 280_000_000, 420_000_000, 580_000_000, 780_000_000, 1_020_000_000, 1_300_000_000, 1_650_000_000, 2_050_000_000, 2_500_000_000, 3_000_000_000, 3_550_000_000, 4_150_000_000, 4_800_000_000]
        let median: [Double] = [100_000_000, 150_000_000, 210_000_000, 280_000_000, 360_000_000, 450_000_000, 560_000_000, 680_000_000, 820_000_000, 980_000_000, 1_160_000_000, 1_360_000_000, 1_580_000_000, 1_820_000_000, 2_100_000_000]
        let worst: [Double] = [100_000_000, 120_000_000, 140_000_000, 170_000_000, 210_000_000, 260_000_000, 320_000_000, 390_000_000, 470_000_000, 560_000_000, 670_000_000, 800_000_000, 950_000_000, 1_120_000_000, 1_320_000_000]
        return (best, median, worst)
    }
    
    private var demoDistributionData: [(year: Int, probability: Double)] {
        [
            (year: 8, probability: 4.5),
            (year: 9, probability: 8.9),
            (year: 10, probability: 14.2),
            (year: 11, probability: 18.5),
            (year: 12, probability: 21.0),
            (year: 13, probability: 16.8),
            (year: 14, probability: 9.8),
            (year: 15, probability: 4.2),
            (year: 16, probability: 1.5),
            (year: 17, probability: 0.6)
        ]
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        
        ScrollView {
            SimulationDemoCards()
        }
    }
}

