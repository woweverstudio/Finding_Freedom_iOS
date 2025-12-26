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
    
    /// 종목별 표시/숨김 상태 (기본적으로 모든 종목 표시)
    @State private var visibleStocks: Set<String> = []
    /// 포트폴리오 라인 표시 여부
    @State private var showPortfolio: Bool = true
    /// 초기화 여부
    @State private var isInitialized: Bool = false
    
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
            
            // 종목 필터 토글 버튼들
            stockFilterView
            
            // 도움말
            HStack(alignment: .top, spacing: ExitSpacing.sm) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.Exit.accent)
                
                Text("종목을 탭해서 차트에서 보이거나 숨길 수 있어요. 데이터가 없는 종목은 있는 기간부터 표시돼요.")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            .padding(ExitSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.Exit.secondaryCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .onAppear {
            // 처음 표시될 때 모든 종목 활성화
            if !isInitialized {
                visibleStocks = Set(data.stockPerformances.map { $0.ticker })
                isInitialized = true
            }
        }
    }
    
    private var historicalChart: some View {
        Chart {
            // 1. 포트폴리오 메인 라인 (진하게) - 토글 상태에 따라 표시
            if showPortfolio {
                ForEach(Array(data.values.enumerated()), id: \.offset) { index, value in
                    if index < data.dates.count {
                        LineMark(
                            x: .value("날짜", data.dates[index]),
                            y: .value("가치", value),
                            series: .value("종목", "포트폴리오")
                        )
                        .foregroundStyle(Color.Exit.accent)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                    }
                }
            }
            
            // 2. 종목별 라인 (얇게, 각 색상) - 보이는 종목만 표시
            ForEach(Array(data.stockPerformances.enumerated()), id: \.element.id) { stockIndex, stock in
                if visibleStocks.contains(stock.ticker) {
                    ForEach(Array(stock.values.enumerated()), id: \.offset) { valueIndex, value in
                        if valueIndex < stock.dates.count {
                            LineMark(
                                x: .value("날짜", stock.dates[valueIndex]),
                                y: .value("가치", value),
                                series: .value("종목", stock.ticker)
                            )
                            .foregroundStyle(stockColor(at: stockIndex).opacity(0.85))
                            .lineStyle(StrokeStyle(lineWidth: 1))
                            .interpolationMethod(.catmullRom)
                        }
                    }
                }
            }
            
            // 3. 기준선 (1.0 = 시작점)
            RuleMark(y: .value("기준", 1.0))
                .foregroundStyle(Color.Exit.divider)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
        .frame(height: 260)
        .chartYScale(domain: dynamicChartYMin...dynamicChartYMax)
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
        .animation(.easeInOut(duration: 0.3), value: visibleStocks)
        .animation(.easeInOut(duration: 0.3), value: showPortfolio)
    }
    
    // 동적 Y축 최소값 (보이는 종목만 고려)
    private var dynamicChartYMin: Double {
        var allValues: [Double] = []
        
        if showPortfolio {
            allValues.append(contentsOf: data.values)
        }
        
        for stock in data.stockPerformances {
            if visibleStocks.contains(stock.ticker) {
                allValues.append(contentsOf: stock.values)
            }
        }
        
        if allValues.isEmpty {
            return 0.5
        }
        
        return min(allValues.min() ?? 0.5, 0.8)
    }
    
    // 동적 Y축 최대값 (보이는 종목만 고려)
    private var dynamicChartYMax: Double {
        var allValues: [Double] = []
        
        if showPortfolio {
            allValues.append(contentsOf: data.values)
        }
        
        for stock in data.stockPerformances {
            if visibleStocks.contains(stock.ticker) {
                allValues.append(contentsOf: stock.values)
            }
        }
        
        if allValues.isEmpty {
            return 2.0
        }
        
        return max(allValues.max() ?? 2.0, 1.5)
    }
    
    /// 연도 포맷터
    private var yearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy"  // 21, 22 형식
        return formatter
    }
    
    /// 종목 필터 토글 뷰
    private var stockFilterView: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            // 포트폴리오 토글 행
            portfolioToggleRow
            
            Divider()
                .background(Color.Exit.divider)
            
            // 종목별 토글 (2열 그리드)
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: ExitSpacing.md),
                GridItem(.flexible(), spacing: ExitSpacing.md)
            ], spacing: ExitSpacing.md) {
                ForEach(Array(data.stockPerformances.enumerated()), id: \.element.id) { index, stock in
                    stockToggleRow(stock: stock, colorIndex: index)
                }
            }
        }
    }
    
    /// 포트폴리오 토글 행
    private var portfolioToggleRow: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showPortfolio.toggle()
            }
        } label: {
            HStack(spacing: ExitSpacing.sm) {
                // 체크박스 아이콘
                Image(systemName: showPortfolio ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18))
                    .foregroundStyle(showPortfolio ? Color.Exit.accent : Color.Exit.tertiaryText)
                
                Text("포트폴리오")
                    .font(.Exit.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(showPortfolio ? Color.Exit.primaryText : Color.Exit.tertiaryText)
                
                Spacer()
                
                Text(String(format: "%+.1f%%", data.totalReturn * 100))
                    .font(.Exit.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(showPortfolio ? (data.totalReturn >= 0 ? Color.Exit.accent : Color.Exit.warning) : Color.Exit.tertiaryText)
            }
        }
        .buttonStyle(.plain)
    }
    
    /// 종목별 토글 행
    private func stockToggleRow(stock: StockHistoricalPerformance, colorIndex: Int) -> some View {
        let isVisible = visibleStocks.contains(stock.ticker)
        let color = stockColor(at: colorIndex)
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isVisible {
                    visibleStocks.remove(stock.ticker)
                } else {
                    visibleStocks.insert(stock.ticker)
                }
            }
        } label: {
            HStack(spacing: ExitSpacing.xs) {
                // 체크박스 아이콘
                Image(systemName: isVisible ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18))
                    .foregroundStyle(isVisible ? color : Color.Exit.tertiaryText)
                
                Text(stock.ticker)
                    .font(.Exit.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isVisible ? Color.Exit.primaryText : Color.Exit.tertiaryText)
                    .lineLimit(1)
                
                Spacer()
                
                Text(String(format: "%+.0f%%", stock.totalReturn * 100))
                    .font(.Exit.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isVisible ? (stock.totalReturn >= 0 ? color : Color.Exit.warning) : Color.Exit.tertiaryText)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 미래 5년 시뮬레이션 차트

/// 포트폴리오 미래 5년 시뮬레이션 차트 (1억 기준, 월별 변동성 표현)
struct PortfolioProjectionChart: View {
    let projection: PortfolioProjectionResult
    let cagr: Double
    let volatility: Double
    
    /// 월별 차트 데이터 (억 단위 변환)
    private var monthlyChartData: (months: [Int], best: [Double], median: [Double], worst: [Double]) {
        let months = Array(0...projection.totalMonths)
        let best = projection.monthlyBestCase.map { $0 / 100_000_000 }
        let median = projection.monthlyMedian.map { $0 / 100_000_000 }
        let worst = projection.monthlyWorstCase.map { $0 / 100_000_000 }
        return (months, best, median, worst)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            // 헤더
            HStack(spacing: ExitSpacing.sm) {
                Text("🔮")
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("5년 후 예측")
                        .font(.Exit.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.Exit.primaryText)
                    
                    Text("1억 투자 기준 · 몬테카를로 시뮬레이션")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
                
                Spacer()
            }
            
            // 차트 (월별 변동성 표현)
            projectionChart
            
            // 범례
            legendView
            
            // 연도별 예상 금액 테이블
            yearlyAmountTable
            
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
        let data = monthlyChartData
        
        return Chart {
            // 범위 영역 (최고-최악 사이를 채움) - 월별
            ForEach(data.months, id: \.self) { month in
                AreaMark(
                    x: .value("월", month),
                    yStart: .value("최악", data.worst[month]),
                    yEnd: .value("최고", data.best[month])
                )
                .foregroundStyle(Color.Exit.accent.opacity(0.12))
            }
            
            // 최고 시나리오 (점선) - 월별
            ForEach(data.months, id: \.self) { month in
                LineMark(
                    x: .value("월", month),
                    y: .value("최고", data.best[month]),
                    series: .value("시나리오", "최고")
                )
                .foregroundStyle(Color.Exit.positive.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1))
            }
            
            // 최악 시나리오 (점선) - 월별
            ForEach(data.months, id: \.self) { month in
                LineMark(
                    x: .value("월", month),
                    y: .value("최악", data.worst[month]),
                    series: .value("시나리오", "최악")
                )
                .foregroundStyle(Color.Exit.caution.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1))
            }
            
            // 중앙값 (실선) - 월별
            ForEach(data.months, id: \.self) { month in
                LineMark(
                    x: .value("월", month),
                    y: .value("중앙값", data.median[month]),
                    series: .value("시나리오", "중앙값")
                )
                .foregroundStyle(Color.Exit.accent)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
            
            // 연도별 포인트 마커 (12개월마다)
            ForEach(0...projection.totalYears, id: \.self) { year in
                let monthIndex = year * 12
                PointMark(
                    x: .value("월", monthIndex),
                    y: .value("중앙값", data.median[monthIndex])
                )
                .foregroundStyle(Color.Exit.accent)
                .symbolSize(year == 0 ? 60 : 40)
            }
            
            // 기준선 (1억)
            RuleMark(y: .value("기준", 1.0))
                .foregroundStyle(Color.Exit.divider)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
        .frame(height: 240)
        .chartYScale(domain: max(0.5, data.worst.min()! * 0.9)...data.best.max()! * 1.1)
        .chartXAxis {
            // 연도 단위로 레이블 표시 (12개월 간격)
            AxisMarks(values: Array(stride(from: 0, through: projection.totalMonths, by: 12))) { value in
                AxisGridLine()
                    .foregroundStyle(Color.Exit.divider.opacity(0.3))
                AxisValueLabel {
                    if let month = value.as(Int.self) {
                        let year = month / 12
                        Text(year == 0 ? "현재" : "\(year)년")
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
                        Text(formatBillions(val))
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.tertiaryText)
                    }
                }
            }
        }
    }
    
    /// 억 단위 포맷 (차트 Y축용)
    private func formatBillions(_ value: Double) -> String {
        if value >= 1.0 {
            return String(format: "%.1f억", value)
        } else {
            return String(format: "%.0f만", value * 10000)
        }
    }
    
    private var legendView: some View {
        HStack(spacing: ExitSpacing.lg) {
            legendItem(color: Color.Exit.accent, style: .solid, label: "예상 중앙값")
            legendItem(color: Color.Exit.positive.opacity(0.6), style: .dashed, label: "낙관적 (상위 20%)")
            legendItem(color: Color.Exit.caution.opacity(0.6), style: .dashed, label: "보수적 (하위 20%)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func legendItem(color: Color, style: LegendLineStyle, label: String) -> some View {
        HStack(spacing: ExitSpacing.xs) {
            if style == .solid {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 16, height: 3)
            } else {
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(color)
                            .frame(width: 3, height: 2)
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
    
    /// 연도별 예상 금액 테이블
    private var yearlyAmountTable: some View {
        VStack(spacing: ExitSpacing.xs) {
            // 헤더
            HStack {
                Text("")
                    .frame(width: 40, alignment: .leading)
                
                ForEach(1...projection.totalYears, id: \.self) { year in
                    Text("\(year)년 후")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.tertiaryText)
                        .frame(maxWidth: .infinity)
                }
            }
            
            Divider()
                .background(Color.Exit.divider)
            
            // 낙관적
            HStack {
                Text("😊")
                    .frame(width: 40, alignment: .leading)
                
                ForEach(1...projection.totalYears, id: \.self) { year in
                    Text(formatAmountShort(projection.bestCase[year]))
                        .font(.Exit.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.Exit.positive)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 중앙값
            HStack {
                Text("📊")
                    .frame(width: 40, alignment: .leading)
                
                ForEach(1...projection.totalYears, id: \.self) { year in
                    Text(formatAmountShort(projection.median[year]))
                        .font(.Exit.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.Exit.accent)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 보수적
            HStack {
                Text("😰")
                    .frame(width: 40, alignment: .leading)
                
                ForEach(1...projection.totalYears, id: \.self) { year in
                    Text(formatAmountShort(projection.worstCase[year]))
                        .font(.Exit.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.Exit.caution)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(ExitSpacing.sm)
        .background(Color.Exit.secondaryCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
    }
    
    /// 금액 짧은 포맷 (예: 1.2억)
    private func formatAmountShort(_ amount: Double) -> String {
        let billions = amount / 100_000_000
        if billions >= 10 {
            return String(format: "%.0f억", billions)
        } else if billions >= 1 {
            return String(format: "%.1f억", billions)
        } else {
            let thousands = amount / 10000
            return String(format: "%.0f만", thousands)
        }
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
                
                Text("과거 수익률과 변동성을 기반으로 미래를 예측해요. 색칠된 범위는 60%의 시나리오가 포함되는 구간이에요.")
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
    // 월별 + 연도별 금액 데이터 생성 (5년, 1억 기준)
    let initialAmount = 100_000_000.0  // 1억
    let years = 5
    let totalMonths = years * 12
    
    // 월별 데이터 (변동성 포함)
    var monthlyBest: [Double] = [initialAmount]
    var monthlyMed: [Double] = [initialAmount]
    var monthlyWorst: [Double] = [initialAmount]
    
    var bestValue = initialAmount
    var medValue = initialAmount
    var worstValue = initialAmount
    
    for month in 1...totalMonths {
        // 월별 성장률에 변동성 추가
        let monthlyBestGrowth = pow(1.15, 1.0/12.0) + Double.random(in: -0.02...0.03)
        let monthlyMedGrowth = pow(1.10, 1.0/12.0) + Double.random(in: -0.025...0.025)
        let monthlyWorstGrowth = pow(1.03, 1.0/12.0) + Double.random(in: -0.015...0.02)
        
        bestValue *= monthlyBestGrowth
        medValue *= monthlyMedGrowth
        worstValue *= monthlyWorstGrowth
        
        monthlyBest.append(bestValue)
        monthlyMed.append(medValue)
        monthlyWorst.append(worstValue)
    }
    
    // 연도별 데이터 (12개월마다 추출)
    var yearlyBest: [Double] = [initialAmount]
    var yearlyMed: [Double] = [initialAmount]
    var yearlyWorst: [Double] = [initialAmount]
    
    for year in 1...years {
        let monthIndex = year * 12
        yearlyBest.append(monthlyBest[monthIndex])
        yearlyMed.append(monthlyMed[monthIndex])
        yearlyWorst.append(monthlyWorst[monthIndex])
    }
    
    return ZStack {
        Color.Exit.background.ignoresSafeArea()
        
        ScrollView {
            PortfolioProjectionChart(
                projection: PortfolioProjectionResult(
                    initialAmount: initialAmount,
                    monthlyBestCase: monthlyBest,
                    monthlyMedian: monthlyMed,
                    monthlyWorstCase: monthlyWorst,
                    bestCase: yearlyBest,
                    median: yearlyMed,
                    worstCase: yearlyWorst,
                    totalSimulations: 5000
                ),
                cagr: 0.10,
                volatility: 0.18
            )
            .padding()
        }
    }
}


