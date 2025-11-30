//
//  RecordComponents.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI
import Charts

// MARK: - 월별 차트 데이터

struct MonthChartData: Identifiable {
    var id: Int { month }
    let month: Int
    let depositAmount: Double
    let passiveIncome: Double
    
    var total: Double { depositAmount + passiveIncome }
    
    /// 월 이름 (1월, 2월 등)
    var monthLabel: String {
        "\(month)월"
    }
}

/// 차트용 스택 데이터 타입
enum ChartCategory: String, CaseIterable {
    case salary = "월급"
    case passive = "월급 외 수익"
    
    var color: Color {
        switch self {
        case .salary: return Color.Exit.secondaryText.opacity(0.6)
        case .passive: return Color.Exit.accent
        }
    }
}

// MARK: - 요약 카드

struct RecordSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            Text(title)
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)            
            
            Text(value)
                .font(.Exit.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ExitSpacing.md)
        .background(Color.Exit.secondaryCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
    }
}

// MARK: - 12개월 막대 차트 (Swift Charts)

struct YearlyBarChart: View {
    let data: [MonthChartData]
    @State private var animatedData: [MonthChartData] = []
    @State private var showAnnotations: Bool = false
    
    private var hasAnyData: Bool {
        data.contains { $0.total > 0 }
    }
    
    private var maxAmount: Double {
        let maxTotal = data.map { $0.total }.max() ?? 0
        return max(maxTotal, 1)
    }
    
    /// 애니메이션용 데이터 (모든 값이 0인 상태)
    private var zeroData: [MonthChartData] {
        data.map { MonthChartData(month: $0.month, depositAmount: 0, passiveIncome: 0) }
    }
    
    var body: some View {
        VStack(spacing: ExitSpacing.sm) {
            Chart {
                ForEach(animatedData) { item in
                    // 월급 막대 (회색) - 먼저 그려서 아래에 위치
                    BarMark(
                        x: .value("월", item.monthLabel),
                        y: .value("월급", item.depositAmount)
                    )
                    .foregroundStyle(Color.Exit.secondaryText.opacity(0.4))
                    .cornerRadius(4)
                    
                    // 월급 외 수익 막대 (accent) - 스택되어 위에 위치
                    BarMark(
                        x: .value("월", item.monthLabel),
                        y: .value("월급 외 수익", item.passiveIncome)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.Exit.accent, Color.Exit.accent.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(4)
                    .annotation(position: .top, spacing: 4) {
                        if item.total > 0 && showAnnotations {
                            Text(ExitNumberFormatter.formatToManWonShort(item.total))
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(Color.Exit.secondaryText)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel {
                        if let month = value.as(String.self) {
                            Text(month.replacingOccurrences(of: "월", with: ""))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.Exit.secondaryText)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(Color.Exit.divider)
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(ExitNumberFormatter.formatToManWonShort(amount))
                                .font(.system(size: 9, weight: .regular))
                                .foregroundStyle(Color.Exit.tertiaryText)
                        }
                    }
                }
            }
            .chartYScale(domain: 0...(maxAmount * 1.2))
            .chartPlotStyle { plotArea in
                plotArea
                    .background(Color.clear)
            }
            
            // 범례
            HStack(spacing: ExitSpacing.lg) {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.Exit.secondaryText.opacity(0.4))
                        .frame(width: 12, height: 8)
                    Text("월급")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
                
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.Exit.accent)
                        .frame(width: 12, height: 8)
                    Text("월급 외 수익")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
            }
        }
        .onAppear {
            startAnimation()
        }
        .onChange(of: data.map { $0.month }) { _, _ in
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // 초기화: 모든 막대 높이를 0으로
        animatedData = zeroData
        showAnnotations = false
        
        // 아래에서 위로 올라오는 애니메이션
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedData = data
            }
            
            // 애니메이션 완료 후 어노테이션 표시
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeIn(duration: 0.2)) {
                    showAnnotations = true
                }
            }
        }
    }
}

// MARK: - 입금 기록 Row

struct DepositHistoryRow: View {
    let update: MonthlyUpdate
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    /// 카테고리별 금액 데이터
    private var categoryAmounts: [(icon: String, label: String, amount: Double)] {
        var items: [(String, String, Double)] = []
        
        if update.salaryAmount > 0 {
            items.append(("briefcase.fill", "월급", update.salaryAmount))
        }
        if update.dividendAmount > 0 {
            items.append(("chart.line.uptrend.xyaxis", "배당", update.dividendAmount))
        }
        if update.interestAmount > 0 {
            items.append(("percent", "이자", update.interestAmount))
        }
        if update.rentAmount > 0 {
            items.append(("house.fill", "월세", update.rentAmount))
        }
        if update.otherAmount > 0 {
            items.append(("ellipsis.circle.fill", "기타", update.otherAmount))
        }
        
        return items
    }
    
    /// 총 입금액
    private var totalDeposit: Double {
        let categoryTotal = update.salaryAmount + update.dividendAmount + update.interestAmount + update.rentAmount + update.otherAmount
        if categoryTotal > 0 {
            return categoryTotal
        }
        return update.depositAmount + update.passiveIncome
    }
    
    private var monthText: String {
        guard update.yearMonth.count >= 6 else { return "" }
        let monthStr = String(update.yearMonth.suffix(2))
        if let month = Int(monthStr) {
            return "\(month)월"
        }
        return ""
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: ExitSpacing.md) {
            // 월 + 총액 (배경 없음)
            VStack(spacing: 4) {
                Text(monthText)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.Exit.primaryText)
                
                Text(ExitNumberFormatter.formatToManWon(totalDeposit))
                    .font(.Exit.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.accent)
            }
            .frame(width: 64)
            
            // 카테고리별 금액 (FlowLayout 스타일)
            VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                ForEach(categoryAmounts, id: \.label) { item in
                    HStack(spacing: 6) {
                        Text(item.label)
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.secondaryText)
                        
                        Text(ExitNumberFormatter.formatToManWon(item.amount))
                            .font(.Exit.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.Exit.primaryText)
                    }
                }
            }
            
            Spacer()
            
            // 버튼 영역 (세로 정렬)
            VStack(spacing: ExitSpacing.sm) {
                // 수정 버튼
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.Exit.secondaryText)
                        .frame(width: 60, height: 28)
                        .background(Color.Exit.secondaryCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
                }
                .buttonStyle(.plain)
                
                // 삭제 버튼
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.Exit.warning)
                        .frame(width: 60, height: 28)
                        .background(Color.Exit.warning.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

