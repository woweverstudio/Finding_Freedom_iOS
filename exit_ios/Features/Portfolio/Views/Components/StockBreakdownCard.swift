//
//  StockBreakdownCard.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  종목별 상세 지표 카드
//

import SwiftUI

// StockMetricBreakdown과 DividendStockBreakdown은 
// PortfolioAnalysis.swift에 정의되어 있습니다.

/// 종목별 지표 분해 카드 (확장 가능)
struct StockBreakdownCard: View {
    let title: String
    let subtitle: String
    let emoji: String
    let portfolioValue: String
    let portfolioValueColor: Color
    let portfolioRawValue: Double  // 원시 값 (비교용)
    let stocks: [StockMetricBreakdown]
    let benchmarks: [BenchmarkMetric]  // 비교군
    let isHigherBetter: Bool  // 높을수록 좋은지 (Sharpe: true, MDD: false, Volatility: false)
    let showContribution: Bool  // 기여도 컬럼 표시 여부 (CAGR에서만 true)
    let onInfoTap: () -> Void
    
    @State private var isExpanded = false
    
    /// 확장 가능 여부 (종목이 2개 이상일 때만)
    private var canExpand: Bool {
        stocks.count > 1
    }
    
    /// 기본 생성자 (비교군 없음 - 기존 호환성)
    init(
        title: String,
        subtitle: String,
        emoji: String,
        portfolioValue: String,
        portfolioValueColor: Color,
        stocks: [StockMetricBreakdown],
        isHigherBetter: Bool,
        showContribution: Bool = false,
        onInfoTap: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.emoji = emoji
        self.portfolioValue = portfolioValue
        self.portfolioValueColor = portfolioValueColor
        self.portfolioRawValue = 0
        self.stocks = stocks
        self.benchmarks = []
        self.isHigherBetter = isHigherBetter
        self.showContribution = showContribution
        self.onInfoTap = onInfoTap
    }
    
    /// 비교군 포함 생성자
    init(
        title: String,
        subtitle: String,
        emoji: String,
        portfolioValue: String,
        portfolioValueColor: Color,
        portfolioRawValue: Double,
        stocks: [StockMetricBreakdown],
        benchmarks: [BenchmarkMetric],
        isHigherBetter: Bool,
        showContribution: Bool = false,
        onInfoTap: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.emoji = emoji
        self.portfolioValue = portfolioValue
        self.portfolioValueColor = portfolioValueColor
        self.portfolioRawValue = portfolioRawValue
        self.stocks = stocks
        self.benchmarks = benchmarks
        self.isHigherBetter = isHigherBetter
        self.showContribution = showContribution
        self.onInfoTap = onInfoTap
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            headerView
            
            // 비교군 섹션 (항상 표시)
            if !benchmarks.isEmpty {
                benchmarkSection
            }
            
            // 확장된 종목별 상세
            if isExpanded && canExpand {
                expandedContent
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: ExitSpacing.md) {
            // 이모지
            Text(emoji)
                .font(.system(size: 28))
                .frame(width: 44, height: 44)
                .background(portfolioValueColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
            
            // 타이틀
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.Exit.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Text(subtitle)
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.tertiaryText)
            }
            
            Spacer()
            
            // 포트폴리오 값
            Text(portfolioValue)
                .font(.Exit.title3)
                .fontWeight(.bold)
                .foregroundStyle(portfolioValueColor)
            
            // 정보 버튼
            Button(action: onInfoTap) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.Exit.tertiaryText)
            }
            .buttonStyle(.plain)
        }
        .padding(ExitSpacing.md)
    }
    
    // MARK: - Expanded Content
    
    private var expandedContent: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.Exit.divider)
            
            VStack(spacing: ExitSpacing.sm) {
                // 컬럼 헤더
                HStack {
                    Text("종목")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("비중")
                        .frame(width: 50, alignment: .trailing)
                    Text("값")
                        .frame(width: showContribution ? 70 : 80, alignment: .trailing)
                    if showContribution {
                        Text("반영")
                            .frame(width: 60, alignment: .trailing)
                    }
                }
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.tertiaryText)
                .padding(.horizontal, ExitSpacing.md)
                .padding(.top, ExitSpacing.md)
                
                // 종목별 행
                ForEach(stocks) { stock in
                    stockRow(stock)
                }
                
                // 요약
//                summaryRow
            }
            .padding(.bottom, ExitSpacing.md)
        }
    }
    
    private func stockRow(_ stock: StockMetricBreakdown) -> some View {
        HStack(spacing: ExitSpacing.sm) {
            // 종목 정보
            HStack(spacing: ExitSpacing.xs) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(stock.name)
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.primaryText)
                        .lineLimit(1)
                    
                    Text(stock.ticker)
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.tertiaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 비중
            Text(String(format: "%.0f%%", stock.weight * 100))
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
                .frame(width: 50, alignment: .trailing)
            
            // 값
            Text(stock.formattedValue)
                .font(.Exit.caption)
                .fontWeight(.medium)
                .foregroundStyle(valueColor(for: stock))
                .frame(width: showContribution ? 70 : 80, alignment: .trailing)
        }
        .padding(.horizontal, ExitSpacing.md)
        .padding(.vertical, ExitSpacing.xs)
        .background(highlightBackground(for: stock))
    }
    
    private var summaryRow: some View {
        VStack(spacing: ExitSpacing.xs) {
            Divider()
                .background(Color.Exit.divider)
                .padding(.horizontal, ExitSpacing.md)
            
            HStack {
                // 최고/최저 종목 하이라이트
                if let best = bestStock, let worst = worstStock {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: isHigherBetter ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .foregroundStyle(Color.Exit.positive)
                            Text(isHigherBetter ? "최고:" : "최저:")
                                .foregroundStyle(Color.Exit.secondaryText)
                            Text(best.name)
                                .foregroundStyle(Color.Exit.positive)
                                .fontWeight(.medium)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: isHigherBetter ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                .foregroundStyle(Color.Exit.warning)
                            Text(isHigherBetter ? "최저:" : "최고:")
                                .foregroundStyle(Color.Exit.secondaryText)
                            Text(worst.name)
                                .foregroundStyle(Color.Exit.warning)
                                .fontWeight(.medium)
                        }
                    }
                    .font(.Exit.caption2)
                }
                
                Spacer()
                
                // 포트폴리오 합계
                VStack(alignment: .trailing, spacing: 2) {
                    Text("포트폴리오")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.tertiaryText)
                    Text(portfolioValue)
                        .font(.Exit.body)
                        .fontWeight(.bold)
                        .foregroundStyle(portfolioValueColor)
                }
            }
            .padding(.horizontal, ExitSpacing.md)
            .padding(.top, ExitSpacing.xs)
        }
    }
    
    // MARK: - Benchmark Section
    
    private var benchmarkSection: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.Exit.divider)
            
            VStack(spacing: ExitSpacing.xs) {
                // 비교 바
                BenchmarkComparisonBar(
                    portfolioValue: portfolioRawValue,
                    portfolioLabel: portfolioValue,
                    portfolioColor: portfolioValueColor,
                    benchmarks: benchmarks,
                    isHigherBetter: isHigherBetter
                )
                .padding(.horizontal, ExitSpacing.md)
                .padding(.top, ExitSpacing.sm)
                
                // 종목 상세 확장 버튼 (종목이 2개 이상일 때만)
                if canExpand {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isExpanded.toggle()
                        }
                        HapticService.shared.light()
                    } label: {
                        HStack(spacing: 4) {
                            Text(isExpanded ? "종목 상세 접기" : "종목 상세 보기")
                                .font(.Exit.caption)
                                .foregroundStyle(Color.Exit.tertiaryText)
                            
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.Exit.tertiaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ExitSpacing.sm)
                    }
                    .buttonStyle(.plain)
                } else {
                    Spacer()
                        .frame(height: ExitSpacing.sm)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var bestStock: StockMetricBreakdown? {
        if isHigherBetter {
            return stocks.max(by: { $0.value < $1.value })
        } else {
            return stocks.min(by: { abs($0.value) < abs($1.value) })
        }
    }
    
    private var worstStock: StockMetricBreakdown? {
        if isHigherBetter {
            return stocks.min(by: { $0.value < $1.value })
        } else {
            return stocks.max(by: { abs($0.value) < abs($1.value) })
        }
    }
    
    private func valueColor(for stock: StockMetricBreakdown) -> Color {
        // rank는 이미 "좋은 순서"로 정렬됨 (rank 1 = 가장 좋은 종목)
        if stock.rank == 1 {
            return Color.Exit.positive  // 가장 좋은 종목 → 초록색
        } else if stock.rank == stocks.count {
            return Color.Exit.warning   // 가장 나쁜 종목 → 빨간색
        }
        return Color.Exit.primaryText
    }
    
    private func highlightBackground(for stock: StockMetricBreakdown) -> Color {
        // rank는 이미 "좋은 순서"로 정렬됨 (rank 1 = 가장 좋은 종목)
        if stock.rank == 1 {
            return Color.Exit.positive.opacity(0.08)  // 가장 좋은 종목 → 초록 배경
        } else if stock.rank == stocks.count {
            return Color.Exit.warning.opacity(0.08)   // 가장 나쁜 종목 → 빨간 배경
        }
        return Color.clear
    }
    
}

/// 배당 종목별 분해 카드
struct DividendBreakdownCard: View {
    let portfolioYield: Double
    let stocks: [DividendStockBreakdown]
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                HapticService.shared.light()
            } label: {
                headerView
            }
            .buttonStyle(.plain)
            
            // 확장된 상세
            if isExpanded {
                expandedContent
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
    }
    
    private var headerView: some View {
        HStack(spacing: ExitSpacing.md) {
            Text("💰")
                .font(.system(size: 28))
                .frame(width: 44, height: 44)
                .background(Color.Exit.accent.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("배당 정보")
                    .font(.Exit.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Text("종목별 배당률 및 성장률")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.tertiaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.2f%%", portfolioYield * 100))
                    .font(.Exit.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(portfolioYield >= 0.03 ? Color.Exit.accent : Color.Exit.primaryText)
                
                Text("포트폴리오")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
            }
            
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.Exit.tertiaryText)
        }
        .padding(ExitSpacing.md)
    }
    
    private var expandedContent: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.Exit.divider)
            
            VStack(spacing: ExitSpacing.sm) {
                // 컬럼 헤더
                HStack {
                    Text("종목")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("배당률")
                        .frame(width: 60, alignment: .trailing)
                    Text("성장률")
                        .frame(width: 60, alignment: .trailing)
                    Text("기여")
                        .frame(width: 50, alignment: .trailing)
                }
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.tertiaryText)
                .padding(.horizontal, ExitSpacing.md)
                .padding(.top, ExitSpacing.md)
                
                ForEach(stocks) { stock in
                    dividendStockRow(stock)
                }
                
                // 고배당 종목 하이라이트
                if let highYield = stocks.filter({ $0.yield >= 0.03 }).first {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundStyle(Color.Exit.accent)
                        Text("\(highYield.name)이(가) 포트폴리오 배당에 크게 기여해요!")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.secondaryText)
                        Spacer()
                    }
                    .padding(.horizontal, ExitSpacing.md)
                    .padding(.top, ExitSpacing.xs)
                }
                
                // 무배당 종목 안내
                let noDividendStocks = stocks.filter { $0.yield == 0 }
                if !noDividendStocks.isEmpty {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(Color.Exit.tertiaryText)
                        Text("\(noDividendStocks.map { $0.name }.joined(separator: ", "))은(는) 배당이 없어요")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.tertiaryText)
                        Spacer()
                    }
                    .padding(.horizontal, ExitSpacing.md)
                    .padding(.top, ExitSpacing.xs)
                }
            }
            .padding(.bottom, ExitSpacing.md)
        }
    }
    
    private func dividendStockRow(_ stock: DividendStockBreakdown) -> some View {
        HStack(spacing: ExitSpacing.sm) {
            // 종목 정보
            HStack(spacing: ExitSpacing.xs) {
                Text(stock.emoji)
                    .font(.system(size: 14))
                
                Text(stock.name)
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.primaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 배당률
            Text(stock.yield > 0 ? String(format: "%.2f%%", stock.yield * 100) : "-")
                .font(.Exit.caption)
                .fontWeight(.medium)
                .foregroundStyle(stock.yield >= 0.03 ? Color.Exit.accent : (stock.yield > 0 ? Color.Exit.primaryText : Color.Exit.tertiaryText))
                .frame(width: 60, alignment: .trailing)
            
            // 성장률
            if stock.growthRate > 0 {
                Text(String(format: "+%.1f%%", stock.growthRate * 100))
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.positive)
                    .frame(width: 60, alignment: .trailing)
            } else {
                Text("-")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.tertiaryText)
                    .frame(width: 60, alignment: .trailing)
            }
            
            // 기여도
            Text(String(format: "%.1f%%", stock.contribution * 100))
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.secondaryText)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.horizontal, ExitSpacing.md)
        .padding(.vertical, ExitSpacing.xs)
        .background(stock.yield >= 0.03 ? Color.Exit.accent.opacity(0.08) : Color.clear)
    }
}

// MARK: - Benchmark Comparison Chart (Swift Charts)

import Charts

/// 비교군 막대 차트 데이터
struct BenchmarkBarData: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let displayValue: String
    let isPortfolio: Bool
    let color: Color
}

/// 비교군 대비 포트폴리오를 수평 막대그래프로 시각화
struct BenchmarkComparisonBar: View {
    let portfolioValue: Double
    let portfolioLabel: String
    let portfolioColor: Color
    let benchmarks: [BenchmarkMetric]
    let isHigherBetter: Bool
    
    /// 차트 데이터 생성
    private var chartData: [BenchmarkBarData] {
        var data: [BenchmarkBarData] = []
        
        // 포트폴리오 추가
        data.append(BenchmarkBarData(
            name: "내 포트폴리오",
            value: isHigherBetter ? portfolioValue : abs(portfolioValue),
            displayValue: portfolioLabel,
            isPortfolio: true,
            color: portfolioColor
        ))
        
        // 벤치마크들 추가
        for benchmark in benchmarks {
            data.append(BenchmarkBarData(
                name: benchmark.name,
                value: isHigherBetter ? benchmark.value : abs(benchmark.value),
                displayValue: benchmark.formattedValue,
                isPortfolio: false,
                color: Color.Exit.tertiaryText
            ))
        }
        
        // 값 기준 정렬 (높은 순)
        return data.sorted { $0.value > $1.value }
    }
    
    /// 포트폴리오가 벤치마크보다 좋은지
    private func isBetterThan(_ benchmark: BenchmarkMetric) -> Bool {
        if isHigherBetter {
            return portfolioValue > benchmark.value
        } else {
            return abs(portfolioValue) < abs(benchmark.value)
        }
    }
    
    /// 차트 최대값 (annotation 공간 포함)
    private var chartMaxValue: Double {
        let maxVal = chartData.map { $0.value }.max() ?? 1
        return maxVal * 1.5  // annotation 표시 공간 확보
    }
    
    var body: some View {
        // 수평 막대 차트
        Chart(chartData) { item in
            BarMark(
                x: .value("Value", item.value),
                y: .value("Name", item.name)
            )
            .foregroundStyle(item.isPortfolio ? item.color : Color.Exit.divider)
            .cornerRadius(4)
            .annotation(position: .trailing, spacing: 6) {
                Text(item.displayValue)
                    .font(.Exit.caption)
                    .fontWeight(item.isPortfolio ? .bold : .regular)
                    .foregroundStyle(item.isPortfolio ? item.color : Color.Exit.secondaryText)
            }
        }
        .chartXScale(domain: 0...chartMaxValue)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let name = value.as(String.self) {
                        let item = chartData.first(where: { $0.name == name })
                        let isPortfolio = item?.isPortfolio == true
                        
                        Text(name)
                            .font(.Exit.caption)
                            .foregroundStyle(isPortfolio ? Color.Exit.primaryText : Color.Exit.tertiaryText)
                            .fontWeight(isPortfolio ? .semibold : .regular)
                    }
                }
            }
        }
        .frame(height: CGFloat(chartData.count * 32 + 8))
        .padding(.trailing, ExitSpacing.sm)  // 우측 여백 추가
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            StockBreakdownCard(
                title: "위험조정수익률",
                subtitle: "Sharpe Ratio",
                emoji: "⚖️",
                portfolioValue: "1.25",
                portfolioValueColor: .Exit.positive,
                portfolioRawValue: 1.25,
                stocks: [
                    StockMetricBreakdown(ticker: "SCHD", name: "슈왑 배당 ETF", emoji: "📊", value: 1.8, formattedValue: "1.80", weight: 0.3, contribution: 0.54, isPositive: true, rank: 1),
                    StockMetricBreakdown(ticker: "VTI", name: "뱅가드 ETF", emoji: "📊", value: 1.5, formattedValue: "1.50", weight: 0.3, contribution: 0.45, isPositive: true, rank: 2),
                    StockMetricBreakdown(ticker: "NVDA", name: "엔비디아", emoji: "💻", value: 0.8, formattedValue: "0.80", weight: 0.4, contribution: 0.32, isPositive: false, rank: 3)
                ],
                benchmarks: BenchmarkMetric.benchmarks(for: .sharpeRatio),
                isHigherBetter: true,
                onInfoTap: {}
            )
            
            StockBreakdownCard(
                title: "변동성",
                subtitle: "Volatility",
                emoji: "🎢",
                portfolioValue: "22.5%",
                portfolioValueColor: .Exit.caution,
                portfolioRawValue: 0.225,
                stocks: [
                    StockMetricBreakdown(ticker: "SCHD", name: "슈왑 배당 ETF", emoji: "📊", value: 0.15, formattedValue: "15.0%", weight: 0.3, contribution: 0.045, isPositive: true, rank: 1),
                    StockMetricBreakdown(ticker: "NVDA", name: "엔비디아", emoji: "💻", value: 0.45, formattedValue: "45.0%", weight: 0.4, contribution: 0.18, isPositive: false, rank: 2)
                ],
                benchmarks: BenchmarkMetric.benchmarks(for: .volatility),
                isHigherBetter: false,
                onInfoTap: {}
            )
            
            DividendBreakdownCard(
                portfolioYield: 0.0215,
                stocks: [
                    DividendStockBreakdown(ticker: "SCHD", name: "슈왑 배당", emoji: "📊", weight: 0.3, yield: 0.0342, growthRate: 0.112, contribution: 0.0103),
                    DividendStockBreakdown(ticker: "VTI", name: "뱅가드", emoji: "📊", weight: 0.3, yield: 0.0127, growthRate: 0.058, contribution: 0.0038),
                    DividendStockBreakdown(ticker: "NVDA", name: "엔비디아", emoji: "💻", weight: 0.4, yield: 0.0012, growthRate: 0, contribution: 0.0005)
                ]
            )
        }
        .padding()
    }
    .background(Color.Exit.background)
}

