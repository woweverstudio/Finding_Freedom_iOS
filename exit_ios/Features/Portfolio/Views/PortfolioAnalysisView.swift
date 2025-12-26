//
//  PortfolioAnalysisView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  포트폴리오 분석 결과 뷰
//

import SwiftUI

/// 포트폴리오 분석 결과 뷰
struct PortfolioAnalysisView: View {
    @Bindable var viewModel: PortfolioViewModel
    @State private var selectedMetric: PortfolioMetric?
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            headerSection
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: ExitSpacing.lg) {
                    if let result = viewModel.analysisResult {
                        // 1️⃣ 포트폴리오 비중 차트 (최상단)
                        PortfolioAllocationChart(holdings: viewModel.holdings)
                        
                        // 2️⃣ 컴팩트 점수 카드
                        PortfolioScoreCard(score: result.score)
                        
                        // 3️⃣ 주요 지표 섹션
                        metricsSection(result: result)
                        
                        // 4️⃣ 배당 정보 (종목별 상세)
                        DividendBreakdownCard(
                            portfolioYield: result.dividendYield,
                            stocks: viewModel.dividendBreakdown
                        )
                        
                        // 5️⃣ 과거 5년 성과 차트
                        if let historicalData = viewModel.historicalData,
                           !historicalData.values.isEmpty {
                            PortfolioHistoricalChart(data: historicalData)
                        }
                        
                        // 6️⃣ 미래 5년 시뮬레이션 차트
                        if let projectionData = viewModel.projectionData {
                            PortfolioProjectionChart(
                                projection: projectionData,
                                cagr: result.cagrWithDividends,
                                volatility: result.volatility
                            )
                        }
                        
                        // 7️⃣ 투자 인사이트
                        if !viewModel.insights.isEmpty {
                            insightsSection
                        }
                    }
                    
                    // 포트폴리오 수정 버튼
                    actionButtons
                }
                .padding(ExitSpacing.md)
            }
        }
        .sheet(item: $selectedMetric) { metric in
            MetricExplanationSheet(metric: metric, years: 5)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            Button {
                viewModel.backToEdit()
            } label: {
                HStack(spacing: ExitSpacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("편집")
                        .font(.Exit.subheadline)
                }
                .foregroundStyle(Color.Exit.accent)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text("분석 결과")
                .font(.Exit.body)
                .fontWeight(.semibold)
                .foregroundStyle(Color.Exit.primaryText)
            
            Spacer()
            
            // 공유 버튼 (placeholder)
            Button {
                // TODO: 공유 기능
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, ExitSpacing.md)
        .padding(.vertical, ExitSpacing.md)
    }
    
    // MARK: - Metrics Section
    
    /// 주요 지표 섹션 (연평균 수익률, 위험조정 수익률, 변동성, 최대 낙폭)
    private func metricsSection(result: PortfolioAnalysisResult) -> some View {
        VStack(spacing: ExitSpacing.md) {
            // 연평균 수익률 (CAGR)
            StockBreakdownCard(
                title: "연평균 수익률",
                subtitle: "CAGR (배당 포함)",
                emoji: "📈",
                portfolioValue: String(format: "%.1f%%", result.cagrWithDividends * 100),
                portfolioValueColor: cagrColor(result.cagrWithDividends),
                portfolioRawValue: result.cagrWithDividends,
                stocks: viewModel.cagrBreakdown,
                benchmarks: viewModel.benchmarks(for: .cagr),
                isHigherBetter: true,
                onInfoTap: { selectedMetric = .cagr(result.cagrWithDividends) }
            )
            
            // 위험조정수익률 (Sharpe Ratio)
            StockBreakdownCard(
                title: "위험조정수익률",
                subtitle: "Sharpe Ratio",
                emoji: "⚖️",
                portfolioValue: String(format: "%.2f", result.sharpeRatio),
                portfolioValueColor: sharpeColor(result.sharpeRatio),
                portfolioRawValue: result.sharpeRatio,
                stocks: viewModel.sharpeBreakdown,
                benchmarks: viewModel.benchmarks(for: .sharpeRatio),
                isHigherBetter: true,
                onInfoTap: { selectedMetric = .sharpeRatio(result.sharpeRatio) }
            )
            
            // 변동성
            StockBreakdownCard(
                title: "변동성",
                subtitle: "Volatility",
                emoji: "🎢",
                portfolioValue: String(format: "%.1f%%", result.volatility * 100),
                portfolioValueColor: volatilityColor(result.volatility),
                portfolioRawValue: result.volatility,
                stocks: viewModel.volatilityBreakdown,
                benchmarks: viewModel.benchmarks(for: .volatility),
                isHigherBetter: false,
                onInfoTap: { selectedMetric = .volatility(result.volatility) }
            )
            
            // 최대 낙폭 (MDD)
            StockBreakdownCard(
                title: "최대 낙폭",
                subtitle: "MDD",
                emoji: "📉",
                portfolioValue: String(format: "%.1f%%", result.mdd * 100),
                portfolioValueColor: mddColor(result.mdd),
                portfolioRawValue: result.mdd,
                stocks: viewModel.mddBreakdown,
                benchmarks: viewModel.benchmarks(for: .mdd),
                isHigherBetter: false,
                onInfoTap: { selectedMetric = .mdd(result.mdd) }
            )
        }
    }
    
    // MARK: - Color Helpers
    
    private func cagrColor(_ value: Double) -> Color {
        if value >= 0.12 { return .Exit.accent }
        else if value >= 0.08 { return .Exit.positive }
        else if value >= 0.05 { return .Exit.caution }
        else { return .Exit.warning }
    }
    
    private func sharpeColor(_ value: Double) -> Color {
        if value >= 1.2 { return .Exit.accent }
        else if value >= 0.9 { return .Exit.positive }
        else if value >= 0.5 { return .Exit.caution }
        else { return .Exit.warning }
    }
    
    private func volatilityColor(_ value: Double) -> Color {
        if value <= 0.18 { return .Exit.accent }
        else if value <= 0.25 { return .Exit.positive }
        else if value <= 0.35 { return .Exit.caution }
        else { return .Exit.warning }
    }
    
    private func mddColor(_ value: Double) -> Color {
        let absValue = abs(value)
        if absValue <= 0.20 { return .Exit.accent }
        else if absValue <= 0.30 { return .Exit.positive }
        else if absValue <= 0.40 { return .Exit.caution }
        else { return .Exit.warning }
    }
    
    // MARK: - Insights Section
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            HStack(spacing: ExitSpacing.sm) {
                Text("💡")
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("투자 인사이트")
                        .font(.Exit.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.Exit.primaryText)
                    
                    Text("분석 데이터 기반 상세 평가")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
                
                Spacer()
            }
            
            ForEach(viewModel.insights) { insight in
                DetailedInsightCard(insight: insight)
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        ExitCTAButton(
            title: "포트폴리오 수정",
            icon: "pencil",
            action: { viewModel.backToEdit() }
        )
        .padding(.top, ExitSpacing.md)
    }
}

// MARK: - Preview

#Preview {
    let viewModel = PortfolioViewModel()
    
    return ZStack {
        Color.Exit.background.ignoresSafeArea()
        PortfolioAnalysisView(viewModel: viewModel)
    }
}
