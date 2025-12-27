//
//  AllocationChart.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  배분 차트 컴포넌트
//

import SwiftUI

/// 섹터/지역 배분 카드
struct AllocationCard: View {
    let title: String
    let emoji: String
    let allocations: [AllocationItem]
    
    struct AllocationItem: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let weight: Double
        let color: Color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            // 헤더
            HStack(spacing: ExitSpacing.sm) {
                Text(emoji)
                    .font(.system(size: 20))
                
                Text(title)
                    .font(.Exit.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            Divider()
                .background(Color.Exit.divider)
            
            // 도넛 차트 + 범례
            HStack(spacing: ExitSpacing.lg) {
                // 도넛 차트
                DonutChart(allocations: allocations)
                    .frame(width: 100, height: 100)
                
                // 범례
                VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                    ForEach(allocations) { item in
                        HStack(spacing: ExitSpacing.sm) {
                            Text(item.icon)
                                .font(.system(size: 14))
                            
                            Text(item.name)
                                .font(.Exit.caption)
                                .foregroundStyle(Color.Exit.primaryText)
                            
                            Spacer()
                            
                            Text(String(format: "%.1f%%", item.weight * 100))
                                .font(.Exit.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(item.color)
                        }
                    }
                }
            }
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
    }
}

/// 도넛 차트
struct DonutChart: View {
    let allocations: [AllocationCard.AllocationItem]
    
    var body: some View {
        ZStack {
            ForEach(Array(allocations.enumerated()), id: \.element.id) { index, item in
                let startAngle = startAngle(for: index)
                let endAngle = endAngle(for: index)
                
                Circle()
                    .trim(from: startAngle, to: endAngle)
                    .stroke(item.color, style: StrokeStyle(lineWidth: 16, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }
            
            // 중앙 원
            Circle()
                .fill(Color.Exit.cardBackground)
                .frame(width: 60, height: 60)
        }
    }
    
    private func startAngle(for index: Int) -> CGFloat {
        let total = allocations.prefix(index).reduce(0) { $0 + $1.weight }
        return CGFloat(total)
    }
    
    private func endAngle(for index: Int) -> CGFloat {
        let total = allocations.prefix(index + 1).reduce(0) { $0 + $1.weight }
        return CGFloat(total)
    }
}

/// 섹터 배분 카드 (헬퍼)
struct SectorAllocationCard: View {
    let allocations: [SectorAllocation]
    
    private var items: [AllocationCard.AllocationItem] {
        let colors: [Color] = [
            Color.Exit.chart1,
            Color.Exit.chart5,
            Color.Exit.chart2,
            Color.Exit.chart3,
            Color.Exit.chart8,
            Color.Exit.chart6
        ]
        
        return allocations.enumerated().map { index, allocation in
            AllocationCard.AllocationItem(
                name: allocation.sector,
                icon: allocation.emoji,
                weight: allocation.weight,
                color: colors[index % colors.count]
            )
        }
    }
    
    var body: some View {
        AllocationCard(
            title: "섹터 배분",
            emoji: "🏭",
            allocations: items
        )
    }
}

/// 지역 배분 카드 (헬퍼)
struct RegionAllocationCard: View {
    let allocations: [RegionAllocation]
    
    private var items: [AllocationCard.AllocationItem] {
        allocations.map { allocation in
            AllocationCard.AllocationItem(
                name: allocation.region,
                icon: allocation.flag,
                weight: allocation.weight,
                color: allocation.region == "미국" ? Color.Exit.chart1 : Color.Exit.chart4
            )
        }
    }
    
    var body: some View {
        AllocationCard(
            title: "지역 배분",
            emoji: "🌍",
            allocations: items
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        SectorAllocationCard(allocations: [
            SectorAllocation(sector: "Technology", weight: 0.6, emoji: "💻"),
            SectorAllocation(sector: "ETF", weight: 0.25, emoji: "📊"),
            SectorAllocation(sector: "Energy", weight: 0.15, emoji: "🔋")
        ])
        
        RegionAllocationCard(allocations: [
            RegionAllocation(region: "미국", flag: "🇺🇸", weight: 0.7),
            RegionAllocation(region: "한국", flag: "🇰🇷", weight: 0.3)
        ])
    }
    .padding()
    .background(Color.Exit.background)
}

