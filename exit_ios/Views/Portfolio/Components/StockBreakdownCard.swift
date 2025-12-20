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
    let stocks: [StockMetricBreakdown]
    let isHigherBetter: Bool  // 높을수록 좋은지 (Sharpe: true, MDD: false, Volatility: false)
    let onInfoTap: () -> Void
    
    @State private var isExpanded = false
    
    /// 확장 가능 여부 (종목이 2개 이상일 때만)
    private var canExpand: Bool {
        stocks.count > 1
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더 (종목이 2개 이상일 때만 탭하면 확장)
            if canExpand {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                    HapticService.shared.light()
                } label: {
                    headerView
                }
                .buttonStyle(.plain)
            } else {
                headerView
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
            
            // 확장 화살표 (종목이 2개 이상일 때만 표시)
            if canExpand {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.Exit.tertiaryText)
            }
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
                        .frame(width: 70, alignment: .trailing)
                    Text("기여")
                        .frame(width: 60, alignment: .trailing)
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
                summaryRow
            }
            .padding(.bottom, ExitSpacing.md)
        }
    }
    
    private func stockRow(_ stock: StockMetricBreakdown) -> some View {
        HStack(spacing: ExitSpacing.sm) {
            // 종목 정보
            HStack(spacing: ExitSpacing.xs) {
                Text(stock.emoji)
                    .font(.system(size: 14))
                
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
                .frame(width: 70, alignment: .trailing)
            
            // 기여도
            HStack(spacing: 2) {
                if stock.contribution != 0 {
                    Image(systemName: contributionIcon(for: stock))
                        .font(.system(size: 8))
                }
                Text(String(format: "%.1f%%", abs(stock.contribution) * 100))
                    .font(.Exit.caption2)
            }
            .foregroundStyle(contributionColor(for: stock))
            .frame(width: 60, alignment: .trailing)
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
        if stock.rank == 1 {
            return isHigherBetter ? Color.Exit.positive : Color.Exit.warning
        } else if stock.rank == stocks.count {
            return isHigherBetter ? Color.Exit.warning : Color.Exit.positive
        }
        return Color.Exit.primaryText
    }
    
    private func contributionColor(for stock: StockMetricBreakdown) -> Color {
        if isHigherBetter {
            return stock.isPositive ? Color.Exit.positive : Color.Exit.warning
        } else {
            return stock.isPositive ? Color.Exit.warning : Color.Exit.positive
        }
    }
    
    private func contributionIcon(for stock: StockMetricBreakdown) -> String {
        stock.isPositive ? "arrow.up" : "arrow.down"
    }
    
    private func highlightBackground(for stock: StockMetricBreakdown) -> Color {
        if stock.rank == 1 {
            return (isHigherBetter ? Color.Exit.positive : Color.Exit.warning).opacity(0.08)
        } else if stock.rank == stocks.count {
            return (isHigherBetter ? Color.Exit.warning : Color.Exit.positive).opacity(0.08)
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
                stocks: [
                    StockMetricBreakdown(ticker: "SCHD", name: "슈왑 배당 ETF", emoji: "📊", value: 1.8, formattedValue: "1.80", weight: 0.3, contribution: 0.54, isPositive: true, rank: 1),
                    StockMetricBreakdown(ticker: "VTI", name: "뱅가드 ETF", emoji: "📊", value: 1.5, formattedValue: "1.50", weight: 0.3, contribution: 0.45, isPositive: true, rank: 2),
                    StockMetricBreakdown(ticker: "NVDA", name: "엔비디아", emoji: "💻", value: 0.8, formattedValue: "0.80", weight: 0.4, contribution: 0.32, isPositive: false, rank: 3)
                ],
                isHigherBetter: true,
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

