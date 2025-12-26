//
//  PortfolioCharts.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  포트폴리오 분석용 차트 컴포넌트
//

import SwiftUI
import Charts

// MARK: - 과거 5년 성과 차트

/// 포트폴리오 과거 5년 성과 차트 (종목별 라인 포함)
struct PortfolioHistoricalChart: View {
    let data: PortfolioHistoricalData
    
    /// 무지개 색상 팔레트 (10개)
    private let rainbowColors: [Color] = [
        Color(red: 0.95, green: 0.35, blue: 0.35),  // 빨강
        Color(red: 0.95, green: 0.55, blue: 0.30),  // 주황
        Color(red: 0.95, green: 0.75, blue: 0.25),  // 노랑
        Color(red: 0.45, green: 0.80, blue: 0.45),  // 연두
        Color(red: 0.30, green: 0.70, blue: 0.55),  // 청록
        Color(red: 0.35, green: 0.60, blue: 0.85),  // 하늘
        Color(red: 0.40, green: 0.45, blue: 0.85),  // 파랑
        Color(red: 0.60, green: 0.40, blue: 0.85),  // 보라
        Color(red: 0.80, green: 0.45, blue: 0.75),  // 자주
        Color(red: 0.90, green: 0.50, blue: 0.55),  // 분홍
    ]
    
    /// 종목 인덱스별 색상
    private func stockColor(at index: Int) -> Color {
        rainbowColors[index % rainbowColors.count]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            // 헤더
            HStack(spacing: ExitSpacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("과거 5년 성과")
                        .font(.Exit.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.Exit.primaryText)
                    
                    Text("종목별 백테스트 결과 (배당 포함)")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
                
                Spacer()
                
                // 총 수익률
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%+.1f%%", data.totalReturn * 100))
                        .font(.Exit.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(data.totalReturn >= 0 ? Color.Exit.accent : Color.Exit.warning)
                    
                    Text("포트폴리오")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.tertiaryText)
                }
            }
            
            // 차트
            historicalChart
            
            // 범례 (포트폴리오 + 종목별)
            legendView
            
            // 도움말
            HStack(alignment: .top, spacing: ExitSpacing.sm) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.Exit.accent)
                
                Text("현재 포트폴리오 구성으로 5년 전부터 투자했다면 어땠을지 보여줘요. 데이터가 없는 종목은 있는 기간부터 표시돼요.")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
            }
            .padding(ExitSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.Exit.secondaryCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
    }
    
    // 차트 Y축 최소값 계산 (종목별 데이터도 포함)
    private var chartYMin: Double {
        var allValues = data.values
        for stock in data.stockPerformances {
            allValues.append(contentsOf: stock.values)
        }
        return min(allValues.min() ?? 0.5, 0.8)
    }
    
    // 차트 Y축 최대값 계산
    private var chartYMax: Double {
        var allValues = data.values
        for stock in data.stockPerformances {
            allValues.append(contentsOf: stock.values)
        }
        return max(allValues.max() ?? 2.0, 1.5)
    }
    
    private var historicalChart: some View {
        Chart {
            // 1. 종목별 라인 (얇게, 각 색상) - 월별 데이터
            ForEach(Array(data.stockPerformances.enumerated()), id: \.element.id) { stockIndex, stock in
                ForEach(Array(stock.values.enumerated()), id: \.offset) { valueIndex, value in
                    if valueIndex < stock.dates.count {
                        LineMark(
                            x: .value("날짜", stock.dates[valueIndex]),
                            y: .value("가치", value),
                            series: .value("종목", stock.ticker)
                        )
                        .foregroundStyle(stockColor(at: stockIndex).opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                        .interpolationMethod(.catmullRom)
                    }
                }
            }
            
            // 2. 포트폴리오 메인 라인 (진하게) - 월별 데이터
            ForEach(Array(data.values.enumerated()), id: \.offset) { index, value in
                if index < data.dates.count {
                    LineMark(
                        x: .value("날짜", data.dates[index]),
                        y: .value("가치", value),
                        series: .value("종목", "포트폴리오")
                    )
                    .foregroundStyle(Color.Exit.accent)
                    .lineStyle(StrokeStyle(lineWidth: 3.5))
                    .interpolationMethod(.catmullRom)
                }
            }
            
            // 3. 기준선 (1.0 = 시작점)
            RuleMark(y: .value("기준", 1.0))
                .foregroundStyle(Color.Exit.divider)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
        .frame(height: 260)
        .chartYScale(domain: chartYMin...chartYMax)
        .chartXAxis {
            // X축: 연단위로 표시
            AxisMarks(values: .stride(by: .year)) { value in
                AxisGridLine()
                    .foregroundStyle(Color.Exit.divider.opacity(0.3))
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(yearFormatter.string(from: date))
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.tertiaryText)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                    .foregroundStyle(Color.Exit.divider.opacity(0.5))
                AxisValueLabel {
                    if let val = value.as(Double.self) {
                        Text(String(format: "%.0f%%", (val - 1) * 100))
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.tertiaryText)
                    }
                }
            }
        }
        .chartLegend(.hidden)
    }
    
    /// 연도 포맷터
    private var yearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy"  // 21, 22 형식
        return formatter
    }
    
    /// 범례 뷰
    private var legendView: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            // 포트폴리오 범례 (맨 위, 강조)
            HStack(spacing: ExitSpacing.sm) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.Exit.accent)
                    .frame(width: 24, height: 4)
                
                Text("포트폴리오")
                    .font(.Exit.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Spacer()
                
                Text(String(format: "%+.1f%%", data.totalReturn * 100))
                    .font(.Exit.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(data.totalReturn >= 0 ? Color.Exit.accent : Color.Exit.warning)
            }
            
            Divider()
                .background(Color.Exit.divider)
            
            // 종목별 범례 (2열 그리드)
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: ExitSpacing.sm),
                GridItem(.flexible(), spacing: ExitSpacing.sm)
            ], spacing: ExitSpacing.xs) {
                ForEach(Array(data.stockPerformances.enumerated()), id: \.element.id) { index, stock in
                    stockLegendItem(stock: stock, colorIndex: index)
                }
            }
        }
        .padding(ExitSpacing.sm)
        .background(Color.Exit.secondaryCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
    }
    
    /// 종목별 범례 아이템
    private func stockLegendItem(stock: StockHistoricalPerformance, colorIndex: Int) -> some View {
        HStack(spacing: ExitSpacing.xs) {
            RoundedRectangle(cornerRadius: 1)
                .fill(stockColor(at: colorIndex))
                .frame(width: 16, height: 2)
            
            Text(stock.ticker)
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.secondaryText)
                .lineLimit(1)
            
            Spacer()
            
            Text(String(format: "%+.0f%%", stock.totalReturn * 100))
                .font(.Exit.caption2)
                .fontWeight(.medium)
                .foregroundStyle(stock.totalReturn >= 0 ? stockColor(at: colorIndex) : Color.Exit.warning)
        }
    }
}

// MARK: - 미래 10년 시뮬레이션 차트

/// 포트폴리오 미래 10년 시뮬레이션 차트
struct PortfolioProjectionChart: View {
    let projection: PortfolioProjectionResult
    let cagr: Double
    let volatility: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            // 헤더
            HStack(spacing: ExitSpacing.sm) {
                Text("🔮")
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("10년 후 예측")
                        .font(.Exit.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.Exit.primaryText)
                    
                    Text("몬테카를로 시뮬레이션 (\(projection.totalSimulations.formatted())회)")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
                
                Spacer()
            }
            
            // 차트
            projectionChart
            
            // 범례
            legendView
            
            // 결과 요약
            resultSummary
            
            // 시뮬레이션 조건
            simulationConditions
            
            // 도움말
            helpSection
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
    }
    
    private var projectionChart: some View {
        Chart {
            // 범위 영역 (최고-최악 사이를 회색으로 채움)
            ForEach(0..<projection.bestCase.count, id: \.self) { index in
                AreaMark(
                    x: .value("월", index),
                    yStart: .value("최악", projection.worstCase[index]),
                    yEnd: .value("최고", projection.bestCase[index])
                )
                .foregroundStyle(Color.Exit.tertiaryText.opacity(0.2))
            }
            
            // 최고 시나리오 (회색 점선)
            ForEach(0..<projection.bestCase.count, id: \.self) { index in
                LineMark(
                    x: .value("월", index),
                    y: .value("최고", projection.bestCase[index]),
                    series: .value("시나리오", "최고")
                )
                .foregroundStyle(Color.Exit.tertiaryText.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            }
            
            // 최악 시나리오 (회색 점선)
            ForEach(0..<projection.worstCase.count, id: \.self) { index in
                LineMark(
                    x: .value("월", index),
                    y: .value("최악", projection.worstCase[index]),
                    series: .value("시나리오", "최악")
                )
                .foregroundStyle(Color.Exit.tertiaryText.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            }
            
            // 중앙값 (accent 실선 - 마지막에 그려서 위로)
            ForEach(0..<projection.median.count, id: \.self) { index in
                LineMark(
                    x: .value("월", index),
                    y: .value("중앙값", projection.median[index]),
                    series: .value("시나리오", "중앙값")
                )
                .foregroundStyle(Color.Exit.accent)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
            }
            
            // 시작점 마커
            PointMark(
                x: .value("월", 0),
                y: .value("시작", 1.0)
            )
            .foregroundStyle(Color.Exit.primaryText)
            .symbolSize(60)
            
            // 중앙값 종료점 마커
            PointMark(
                x: .value("월", projection.median.count - 1),
                y: .value("종료", projection.median.last ?? 1.0)
            )
            .foregroundStyle(Color.Exit.accent)
            .symbolSize(80)
            
            // 기준선 (1.0 = 시작점)
            RuleMark(y: .value("기준", 1.0))
                .foregroundStyle(Color.Exit.divider)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
        .frame(height: 220)
        .chartYScale(domain: max(0, (projection.worstCase.min() ?? 0.5) * 0.9)...(projection.bestCase.max() ?? 3.0) * 1.1)
        .chartXAxis {
            // 2년마다 표시 (24개월 간격)
            AxisMarks(values: .stride(by: 24)) { value in
                AxisGridLine()
                    .foregroundStyle(Color.Exit.divider.opacity(0.3))
                AxisValueLabel {
                    if let month = value.as(Int.self) {
                        Text("\(month / 12)년")
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.tertiaryText)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                    .foregroundStyle(Color.Exit.divider.opacity(0.3))
                AxisValueLabel {
                    if let val = value.as(Double.self) {
                        Text(formatMultiplier(val))
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.tertiaryText)
                    }
                }
            }
        }
    }
    
    private var legendView: some View {
        HStack(spacing: ExitSpacing.lg) {
            legendItem(color: Color.Exit.accent, style: .solid, label: "예상 중앙값")
            legendItem(color: Color.Exit.tertiaryText.opacity(0.6), style: .dashed, label: "60% 범위")
        }
    }
    
    private func legendItem(color: Color, style: LegendLineStyle, label: String) -> some View {
        HStack(spacing: ExitSpacing.xs) {
            if style == .solid {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 20, height: 3)
            } else {
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(color)
                            .frame(width: 4, height: 2)
                    }
                }
            }
            
            Text(label)
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.secondaryText)
        }
    }
    
    enum LegendLineStyle {
        case solid
        case dashed
    }
    
    private var resultSummary: some View {
        VStack(spacing: ExitSpacing.sm) {
            // 퍼센트 카드
            HStack(spacing: ExitSpacing.md) {
                resultCard(
                    label: "낙관적",
                    value: projection.finalReturnRange.best,
                    subtitle: "상위 20%",
                    color: .Exit.positive
                )
                
                resultCard(
                    label: "예상",
                    value: projection.finalReturnRange.median,
                    subtitle: "중앙값",
                    color: .Exit.accent,
                    isHighlighted: true
                )
                
                resultCard(
                    label: "보수적",
                    value: projection.finalReturnRange.worst,
                    subtitle: "하위 20%",
                    color: .Exit.caution
                )
            }
            
            // 1억 기준 예상 금액
            exampleAmountView
        }
    }
    
    /// 1억 기준 예상 금액 뷰
    private var exampleAmountView: some View {
        HStack(spacing: ExitSpacing.sm) {
            Text("💰")
                .font(.system(size: 14))
            
            Text("1억 투자 시")
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.tertiaryText)
            
            Spacer()
            
            HStack(spacing: ExitSpacing.xs) {
                // 보수적
                Text(formatAmount(1.0 + projection.finalReturnRange.worst))
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.caution)
                
                Text("~")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
                
                // 예상 (중앙값)
                Text(formatAmount(1.0 + projection.finalReturnRange.median))
                    .font(.Exit.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.accent)
                
                Text("~")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
                
                // 낙관적
                Text(formatAmount(1.0 + projection.finalReturnRange.best))
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.positive)
            }
        }
        .padding(.horizontal, ExitSpacing.md)
        .padding(.vertical, ExitSpacing.sm)
        .background(Color.Exit.secondaryCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
    }
    
    /// 1억 기준 금액 포맷 (예: 2.8억)
    private func formatAmount(_ multiplier: Double) -> String {
        let amount = multiplier  // 1억 기준이므로 배수 = 억 단위
        if amount >= 10 {
            return String(format: "%.0f억", amount)
        } else {
            return String(format: "%.1f억", amount)
        }
    }
    
    private func resultCard(label: String, value: Double, subtitle: String, color: Color, isHighlighted: Bool = false) -> some View {
        VStack(spacing: ExitSpacing.xs) {
            Text(label)
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.tertiaryText)
            
            Text(formatPercentWithComma(value))
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(color)
            
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundStyle(Color.Exit.tertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ExitSpacing.sm)
        .background(isHighlighted ? color.opacity(0.1) : Color.Exit.secondaryCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
    }
    
    /// 천단위 콤마가 포함된 퍼센트 포맷
    private func formatPercentWithComma(_ value: Double) -> String {
        let percent = value * 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        
        let formatted = formatter.string(from: NSNumber(value: percent)) ?? "\(Int(percent))"
        return percent >= 0 ? "+\(formatted)%" : "\(formatted)%"
    }
    
    private var simulationConditions: some View {
        HStack(spacing: ExitSpacing.lg) {
            VStack(spacing: 2) {
                Text("기대 수익률")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
                Text(String(format: "%.1f%%", cagr * 100))
                    .font(.Exit.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            Divider()
                .frame(height: 24)
            
            VStack(spacing: 2) {
                Text("변동성")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
                Text(String(format: "%.1f%%", volatility * 100))
                    .font(.Exit.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            Divider()
                .frame(height: 24)
            
            VStack(spacing: 2) {
                Text("시뮬레이션")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
                Text("\(projection.totalSimulations.formatted())회")
                    .font(.Exit.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.Exit.primaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ExitSpacing.sm)
        .padding(.horizontal, ExitSpacing.md)
        .background(Color.Exit.secondaryCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
    }
    
    private var helpSection: some View {
        HStack(alignment: .top, spacing: ExitSpacing.sm) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.Exit.accent)
            
            VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                Text("시뮬레이션 이해하기")
                    .font(.Exit.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                Text("과거 수익률과 변동성을 기반으로 미래를 예측해요. 회색 범위는 60%의 시나리오가 포함되는 구간이에요. 실제 결과는 다를 수 있어요.")
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
    
    private func formatMultiplier(_ value: Double) -> String {
        if value == 1.0 {
            return "시작"
        } else if value < 1.0 {
            return String(format: "%.1fx", value)
        } else {
            return String(format: "%.1fx", value)
        }
    }
}

// MARK: - Preview

#Preview("과거 성과") {
    // 월별 샘플 데이터 생성 (5년 = 60개월)
    let calendar = Calendar.current
    let now = Date()
    
    // 월별 날짜 배열 생성 (5년 전부터 현재까지)
    func generateMonthlyDates(months: Int) -> [Date] {
        var dates: [Date] = []
        for i in (0..<months).reversed() {
            if let date = calendar.date(byAdding: .month, value: -i, to: now) {
                dates.append(date)
            }
        }
        return dates
    }
    
    // 월별 가치 생성 (랜덤 변동 포함)
    func generateMonthlyValues(months: Int, cagr: Double, volatility: Double) -> [Double] {
        var values: [Double] = [1.0]
        var currentValue = 1.0
        let monthlyReturn = pow(1 + cagr, 1.0/12.0) - 1
        
        for i in 1..<months {
            let randomVariation = Double.random(in: -volatility...volatility)
            currentValue *= (1 + monthlyReturn + randomVariation)
            values.append(currentValue)
        }
        return values
    }
    
    let months = 60
    let portfolioDates = generateMonthlyDates(months: months)
    let portfolioValues = generateMonthlyValues(months: months, cagr: 0.12, volatility: 0.03)
    
    return ZStack {
        Color.Exit.background.ignoresSafeArea()
        
        PortfolioHistoricalChart(
            data: PortfolioHistoricalData(
                dates: portfolioDates,
                yearLabels: ["2020", "2021", "2022", "2023", "2024", "2025"],
                values: portfolioValues,
                stockPerformances: [
                    StockHistoricalPerformance(
                        ticker: "AAPL",
                        name: "애플",
                        dates: portfolioDates,
                        values: generateMonthlyValues(months: months, cagr: 0.25, volatility: 0.05)
                    ),
                    StockHistoricalPerformance(
                        ticker: "MSFT",
                        name: "마이크로소프트",
                        dates: portfolioDates,
                        values: generateMonthlyValues(months: months, cagr: 0.18, volatility: 0.04)
                    ),
                    StockHistoricalPerformance(
                        ticker: "VOO",
                        name: "S&P 500 ETF",
                        dates: portfolioDates,
                        values: generateMonthlyValues(months: months, cagr: 0.10, volatility: 0.03)
                    ),
                    StockHistoricalPerformance(
                        ticker: "SCHD",
                        name: "Schwab Dividend ETF",
                        dates: generateMonthlyDates(months: 36),  // 3년 데이터만
                        values: generateMonthlyValues(months: 36, cagr: 0.08, volatility: 0.02)
                    )
                ]
            )
        )
        .padding()
    }
}

#Preview("미래 예측") {
    // 간단한 월별 데이터 생성 (120개월 = 10년)
    let months = 120
    var best: [Double] = [1.0]
    var med: [Double] = [1.0]
    var worst: [Double] = [1.0]
    
    for i in 1...months {
        let t = Double(i) / 12.0
        best.append(1.0 * exp(0.18 * t))  // 상위 10%
        med.append(1.0 * exp(0.10 * t))   // 중앙값
        worst.append(1.0 * exp(0.02 * t)) // 하위 10%
    }
    
    return ZStack {
        Color.Exit.background.ignoresSafeArea()
        
        PortfolioProjectionChart(
            projection: PortfolioProjectionResult(
                initialValue: 1.0,
                bestCase: best,
                median: med,
                worstCase: worst,
                totalSimulations: 5000
            ),
            cagr: 0.10,
            volatility: 0.18
        )
        .padding()
    }
}

