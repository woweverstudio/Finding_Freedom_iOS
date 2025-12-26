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
