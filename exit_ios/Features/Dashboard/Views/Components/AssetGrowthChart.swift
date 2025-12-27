//
//  AssetGrowthChart.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI
import Charts

/// 자산 성장 예측 차트
struct AssetGrowthChart: View {
    let currentAsset: Double
    let targetAsset: Double
    let monthlyInvestment: Double
    let preRetirementReturnRate: Double
    let monthsToRetirement: Int
    let animationID: UUID
    
    @State private var selectedProgress: Double? = nil
    @State private var isInteracting: Bool = false
    
    private var chartData: [ChartPoint] {
        generateChartData()
    }
    
    private var yearsToRetirement: Int {
        max(1, monthsToRetirement / 12)
    }
    
    // Y축 도메인
    private var yMin: Double {
        currentAsset * 0.95
    }
    
    private var yMax: Double {
        targetAsset * 1.05
    }
    
    // Y축 마일스톤 (4등분)
    private var yAxisValues: [Double] {
        let range = yMax - yMin
        return [
            yMin,
            yMin + range * 0.25,
            yMin + range * 0.5,
            yMin + range * 0.75,
            yMax
        ]
    }
    
    // X축 라벨
    private func xAxisLabel(for progress: Double) -> String {
        if progress == 0 {
            return "현재"
        } else if progress == 1.0 {
            let years = monthsToRetirement / 12
            let months = monthsToRetirement % 12
            if months == 0 {
                return "\(years)년"
            } else if years == 0 {
                return "\(months)개월"
            } else {
                return "\(years)년"
            }
        } else {
            let totalMonths = Int(Double(monthsToRetirement) * progress)
            let years = totalMonths / 12
            if years > 0 {
                return "\(years)년"
            } else {
                return "\(totalMonths)개월"
            }
        }
    }
    
    // 선택된 위치의 데이터
    private var selectedData: (date: String, asset: Double)? {
        guard let progress = selectedProgress else { return nil }
        let clampedProgress = max(0, min(1, progress))
        let month = Int(Double(monthsToRetirement) * clampedProgress)
        
        // 날짜 계산
        let date = Calendar.current.date(byAdding: .month, value: month, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        let dateString = formatter.string(from: date)
        
        // 자산 계산
        let asset = calculateAssetAtMonth(month)
        
        return (dateString, asset)
    }
    
    var body: some View {
        ExitCard(style: .filled, radius: ExitRadius.lg) {
            VStack(alignment: .leading, spacing: ExitSpacing.lg) {
                headerSection
                chartSection
                
                // 2년 이상일 때만 연도별 마일스톤 표시
                if yearsToRetirement >= 2 {
                    yearlyMilestonesSection
                }
            }
        }
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            HStack {
                HStack(spacing: ExitSpacing.sm) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(Color.Exit.accent)
                    Text("자산 성장 예측")
                        .font(.Exit.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.Exit.primaryText)
                }
                
                Spacer()
                
                // 인터랙션 토글 버튼
                ExitChip(
                    text: isInteracting ? "탐색 중" : "탐색",
                    isSelected: isInteracting
                ) {
                    HapticService.shared.light()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isInteracting.toggle()
                        if !isInteracting {
                            selectedProgress = nil
                        }
                    }
                }
            }
            
            // 선택된 데이터 표시
            if isInteracting {
                if let data = selectedData {
                    HStack(spacing: ExitSpacing.sm) {
                        Text(data.date)
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.secondaryText)
                        Text(ExitNumberFormatter.formatToEokMan(data.asset))
                            .font(.Exit.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.Exit.accent)
                    }
                    .padding(.horizontal, ExitSpacing.sm)
                    .padding(.vertical, ExitSpacing.xs)
                    .background(Color.Exit.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
                } else {
                    Text("차트를 드래그하여 시점별 자산을 확인하세요")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
            }
        }
    }
    
    // MARK: - Chart
    
    private var chartSection: some View {
        Chart {
            // 그라데이션 영역
            ForEach(chartData) { point in
                AreaMark(
                    x: .value("진행률", point.progress),
                    yStart: .value("시작", yMin),
                    yEnd: .value("자산", point.asset)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.Exit.accent.opacity(0.3),
                            Color.Exit.accent.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            
            // 성장 라인
            ForEach(chartData) { point in
                LineMark(
                    x: .value("진행률", point.progress),
                    y: .value("자산", point.asset)
                )
                .foregroundStyle(Color.Exit.accent)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                .interpolationMethod(.catmullRom)
            }
            
            // 선택된 위치 표시
            if let progress = selectedProgress {
                let clampedProgress = max(0, min(1, progress))
                let month = Int(Double(monthsToRetirement) * clampedProgress)
                let asset = calculateAssetAtMonth(month)
                
                RuleMark(x: .value("선택", clampedProgress))
                    .foregroundStyle(Color.Exit.accent.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                
                PointMark(
                    x: .value("선택", clampedProgress),
                    y: .value("자산", asset)
                )
                .foregroundStyle(Color.Exit.accent)
                .symbolSize(120)
            }
        }
        .frame(height: 180)
        .chartXAxis {
            AxisMarks(values: [0.0, 0.25, 0.5, 0.75, 1.0]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.Exit.divider)
                AxisValueLabel {
                    if let progress = value.as(Double.self) {
                        Text(xAxisLabel(for: progress))
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.tertiaryText)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: yAxisValues) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.Exit.divider)
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(ExitNumberFormatter.formatChartAxis(amount))
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.tertiaryText)
                    }
                }
            }
        }
        .chartXScale(domain: 0...1)
        .chartYScale(domain: yMin...yMax)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let x = value.location.x
                                if let progress = proxy.value(atX: x, as: Double.self) {
                                    selectedProgress = max(0, min(1, progress))
                                }
                            }
                    )
            }
        }
        .allowsHitTesting(isInteracting)
        .id(animationID)
    }
    
    // MARK: - Yearly Milestones
    
    private var yearlyMilestonesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ExitSpacing.sm) {
                ForEach(yearlyMilestones, id: \.year) { milestone in
                    VStack(spacing: ExitSpacing.xs) {
                        Text("\(milestone.year)년")
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.tertiaryText)
                        Text(ExitNumberFormatter.formatToEokMan(milestone.asset))
                            .font(.Exit.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.Exit.primaryText)
                    }
                    .padding(.horizontal, ExitSpacing.md)
                    .padding(.vertical, ExitSpacing.sm)
                    .background(Color.Exit.secondaryCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
                }
            }
        }
    }
    
    private var yearlyMilestones: [YearlyMilestone] {
        let monthlyRate = preRetirementReturnRate / 100 / 12
        var milestones: [YearlyMilestone] = []
        
        for year in 1...yearsToRetirement {
            let month = year * 12
            var asset = currentAsset
            for _ in 0..<month {
                asset = asset * (1 + monthlyRate) + monthlyInvestment
            }
            milestones.append(YearlyMilestone(year: year, asset: asset))
        }
        
        return milestones
    }
    
    // MARK: - Helpers
    
    private func calculateAssetAtMonth(_ month: Int) -> Double {
        let monthlyRate = preRetirementReturnRate / 100 / 12
        var asset = currentAsset
        for _ in 0..<month {
            asset = asset * (1 + monthlyRate) + monthlyInvestment
        }
        return asset
    }
    
    private func generateChartData() -> [ChartPoint] {
        var data: [ChartPoint] = []
        let monthlyRate = preRetirementReturnRate / 100 / 12
        let totalMonths = max(monthsToRetirement, 1)
        
        // 50개 포인트로 더 부드러운 곡선 생성
        let pointCount = 50
        
        for i in 0...pointCount {
            let progress = Double(i) / Double(pointCount)
            let month = Int(Double(totalMonths) * progress)
            
            var asset = currentAsset
            for _ in 0..<month {
                asset = asset * (1 + monthlyRate) + monthlyInvestment
            }
            
            data.append(ChartPoint(progress: progress, asset: asset))
        }
        
        return data
    }
}

// MARK: - Chart Point

private struct ChartPoint: Identifiable {
    let id = UUID()
    let progress: Double
    let asset: Double
}

// MARK: - Yearly Milestone

private struct YearlyMilestone {
    let year: Int
    let asset: Double
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: ExitSpacing.lg) {
            AssetGrowthChart(
                currentAsset: 100_000_000,
                targetAsset: 720_000_000,
                monthlyInvestment: 2_000_000,
                preRetirementReturnRate: 7.0,
                monthsToRetirement: 180,
                animationID: UUID()
            )
            
            AssetGrowthChart(
                currentAsset: 300_000_000,
                targetAsset: 500_000_000,
                monthlyInvestment: 3_000_000,
                preRetirementReturnRate: 5.0,
                monthsToRetirement: 60,
                animationID: UUID()
            )
        }
        .padding(.vertical, ExitSpacing.lg)
    }
    .background(Color.Exit.background)
    .preferredColorScheme(.dark)
}
