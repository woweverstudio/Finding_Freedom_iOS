//
//  PortfolioAllocationChart.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  포트폴리오 비중 시각화 차트
//

import SwiftUI
import Charts

/// 포트폴리오 비중 차트 데이터
struct AllocationChartData: Identifiable {
    let id = UUID()
    let ticker: String
    let name: String
    let weight: Double
    
    var weightPercent: String {
        String(format: "%.0f%%", weight * 100)
    }
}

/// 포트폴리오 비중 막대 차트
struct PortfolioAllocationChart: View {
    let holdings: [PortfolioHoldingDisplay]
    
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
    
    private var chartData: [AllocationChartData] {
        holdings
            .sorted { $0.weight > $1.weight }
            .map { holding in
                AllocationChartData(
                    ticker: holding.ticker,
                    name: holding.name,
                    weight: holding.weight
                )
            }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            // 헤더
            HStack(spacing: ExitSpacing.sm) {
                Text("📊")
                    .font(.system(size: 20))
                
                Text("포트폴리오 구성")
                    .font(.Exit.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            // 막대 차트
            VStack(spacing: ExitSpacing.sm) {
                ForEach(Array(chartData.enumerated()), id: \.element.id) { index, item in
                    allocationBar(item, colorIndex: index)
                }
            }
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
    }
    
    private func allocationBar(_ item: AllocationChartData, colorIndex: Int) -> some View {
        let barColor = rainbowColors[colorIndex % rainbowColors.count]
        
        return HStack(spacing: ExitSpacing.md) {
            // 티커 및 이름
            Text(item.ticker)
                .font(.Exit.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.Exit.primaryText)
                .frame(width: 60, alignment: .leading)
            
            // 막대 그래프
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 배경
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.Exit.background)
                        .frame(height: 16)
                    
                    // 비중 막대
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geometry.size.width * item.weight, height: 16)
                }
            }
            .frame(height: 16)
            
            // 비중 %
            Text(item.weightPercent)
                .font(.Exit.caption)
                .fontWeight(.medium)
                .foregroundStyle(barColor)
                .frame(width: 40, alignment: .trailing)
        }
    }
}
