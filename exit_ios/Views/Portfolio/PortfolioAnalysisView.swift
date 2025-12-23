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
                    // 점수 카드
                    if let result = viewModel.analysisResult {
                        PortfolioScoreCard(score: result.score)
                        
                        // ✨ 과거 5년 성과 차트
                        if let historicalData = viewModel.historicalData,
                           !historicalData.values.isEmpty {
                            PortfolioHistoricalChart(data: historicalData)
                        }
                        
                        // ✨ 미래 10년 시뮬레이션 차트
                        if let projectionData = viewModel.projectionData {
                            PortfolioProjectionChart(
                                projection: projectionData,
                                cagr: result.cagrWithDividends,
                                volatility: result.volatility
                            )
                        }
                        
                        // 수익성 지표 (CAGR)
                        cagrSection(result: result)
                        
                        // 위험 지표
                        riskSection(result: result)
                        
                        // 배당 정보 (종목별 상세)
                        DividendBreakdownCard(
                            portfolioYield: result.dividendYield,
                            stocks: viewModel.dividendBreakdown
                        )
                        
                        // 수익률 요약
                        returnSummaryCard(result: result)
                        
                        // 섹터/지역 배분
                        if !viewModel.sectorAllocation.isEmpty {
                            SectorAllocationCard(allocations: viewModel.sectorAllocation)
                        }
                        
                        if !viewModel.regionAllocation.isEmpty {
                            RegionAllocationCard(allocations: viewModel.regionAllocation)
                        }
                        
                        // 인사이트
                        if !viewModel.insights.isEmpty {
                            insightsSection
                        }
                    }
                    
                    // 다시 분석 / 포트폴리오 수정 버튼
                    actionButtons
                }
                .padding(ExitSpacing.lg)
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
        .padding(.horizontal, ExitSpacing.lg)
        .padding(.vertical, ExitSpacing.md)
    }
    
    // MARK: - CAGR Section
    
    private func cagrSection(result: PortfolioAnalysisResult) -> some View {
        StockBreakdownCard(
            title: "연평균 수익률",
            subtitle: "CAGR (배당 포함)",
            emoji: "📈",
            portfolioValue: String(format: "%.1f%%", result.cagrWithDividends * 100),
            portfolioValueColor: cagrColor(result.cagrWithDividends),
            portfolioRawValue: result.cagrWithDividends,
            stocks: viewModel.cagrBreakdown,
            benchmarks: BenchmarkMetric.benchmarks(for: .cagr),
            isHigherBetter: true,
            onInfoTap: { selectedMetric = .cagr(result.cagrWithDividends) }
        )
    }
    
    // MARK: - Return Summary Card
    
    private func returnSummaryCard(result: PortfolioAnalysisResult) -> some View {
        MetricGroupCard(
            title: "수익률 요약",
            emoji: "💰",
            metrics: [
                .init(
                    label: "5년 총 수익률",
                    value: String(format: "%.1f%%", result.totalReturn * 100),
                    color: result.totalReturn >= 0 ? .Exit.positive : .Exit.warning,
                    isHighlighted: true
                ),
                .init(
                    label: "└ 가격 상승분",
                    value: String(format: "%.1f%%", result.priceReturn * 100),
                    color: .Exit.secondaryText,
                    isHighlighted: false
                ),
                .init(
                    label: "└ 배당 수익분",
                    value: String(format: "%.1f%%", result.dividendReturn * 100),
                    color: .Exit.secondaryText,
                    isHighlighted: false
                )
            ]
        )
    }
    
    private func cagrColor(_ value: Double) -> Color {
        if value >= 0.15 { return .Exit.accent }
        else if value >= 0.10 { return .Exit.positive }
        else if value >= 0.05 { return .Exit.caution }
        else { return .Exit.warning }
    }
    
    // MARK: - Risk Section
    
    private func riskSection(result: PortfolioAnalysisResult) -> some View {
        VStack(spacing: ExitSpacing.md) {
            // Sharpe Ratio (종목별 상세)
            StockBreakdownCard(
                title: "위험조정수익률",
                subtitle: "Sharpe Ratio",
                emoji: "⚖️",
                portfolioValue: String(format: "%.2f", result.sharpeRatio),
                portfolioValueColor: sharpeColor(result.sharpeRatio),
                portfolioRawValue: result.sharpeRatio,
                stocks: viewModel.sharpeBreakdown,
                benchmarks: BenchmarkMetric.benchmarks(for: .sharpeRatio),
                isHigherBetter: true,
                onInfoTap: { selectedMetric = .sharpeRatio(result.sharpeRatio) }
            )
            
            // 변동성 (종목별 상세)
            StockBreakdownCard(
                title: "변동성",
                subtitle: "Volatility",
                emoji: "🎢",
                portfolioValue: String(format: "%.1f%%", result.volatility * 100),
                portfolioValueColor: volatilityColor(result.volatility),
                portfolioRawValue: result.volatility,
                stocks: viewModel.volatilityBreakdown,
                benchmarks: BenchmarkMetric.benchmarks(for: .volatility),
                isHigherBetter: false,  // 낮을수록 좋음
                onInfoTap: { selectedMetric = .volatility(result.volatility) }
            )
            
            // MDD (종목별 상세)
            StockBreakdownCard(
                title: "최대 낙폭",
                subtitle: "MDD",
                emoji: "📉",
                portfolioValue: String(format: "%.1f%%", result.mdd * 100),
                portfolioValueColor: mddColor(result.mdd),
                portfolioRawValue: result.mdd,
                stocks: viewModel.mddBreakdown,
                benchmarks: BenchmarkMetric.benchmarks(for: .mdd),
                isHigherBetter: false,  // 낮을수록(절대값) 좋음
                onInfoTap: { selectedMetric = .mdd(result.mdd) }
            )
        }
    }
    
    // MARK: - Color Helpers
    
    private func sharpeColor(_ value: Double) -> Color {
        if value >= 1.5 { return .Exit.accent }
        else if value >= 1.0 { return .Exit.positive }
        else if value >= 0.5 { return .Exit.caution }
        else { return .Exit.warning }
    }
    
    private func volatilityColor(_ value: Double) -> Color {
        if value <= 0.15 { return .Exit.accent }
        else if value <= 0.25 { return .Exit.positive }
        else if value <= 0.35 { return .Exit.caution }
        else { return .Exit.warning }
    }
    
    private func mddColor(_ value: Double) -> Color {
        let absValue = abs(value)
        if absValue <= 0.15 { return .Exit.accent }
        else if absValue <= 0.25 { return .Exit.positive }
        else if absValue <= 0.35 { return .Exit.caution }
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
            size: .small,
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

