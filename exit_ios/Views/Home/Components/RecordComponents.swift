//
//  RecordComponents.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

// MARK: - 월별 차트 데이터

struct MonthChartData: Identifiable {
    let id = UUID()
    let month: Int
    let depositAmount: Double
    let passiveIncome: Double
    
    var total: Double { depositAmount + passiveIncome }
}

// MARK: - 요약 카드

struct RecordSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            HStack(spacing: ExitSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            
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

// MARK: - 12개월 막대 차트

struct YearlyBarChart: View {
    let data: [MonthChartData]
    
    private var maxAmount: Double {
        let maxTotal = data.map { $0.total }.max() ?? 0
        return max(maxTotal, 1)
    }
    
    private var hasAnyData: Bool {
        data.contains { $0.total > 0 }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let barAreaHeight = geometry.size.height - 24
            
            VStack(spacing: 0) {
                // 막대 영역
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(data) { item in
                        VStack(spacing: 1) {
                            Spacer(minLength: 0)
                            
                            // 패시브인컴 부분
                            if item.passiveIncome > 0 {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.Exit.accent.opacity(0.6))
                                    .frame(height: barHeight(for: item.passiveIncome, in: barAreaHeight))
                            }
                            
                            // 입금액 부분
                            if item.depositAmount > 0 {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(LinearGradient.exitAccent)
                                    .frame(height: barHeight(for: item.depositAmount, in: barAreaHeight))
                            }
                            
                            // 빈 막대 (데이터 없을 때)
                            if item.total == 0 {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.Exit.divider)
                                    .frame(height: 4)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: barAreaHeight)
                
                // 월 표시 영역
                HStack(spacing: 4) {
                    ForEach(data) { item in
                        Text("\(item.month)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(item.total > 0 ? Color.Exit.primaryText : Color.Exit.tertiaryText)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 20)
                .padding(.top, 4)
            }
        }
    }
    
    private func barHeight(for amount: Double, in maxHeight: CGFloat) -> CGFloat {
        guard maxAmount > 0, hasAnyData else { return 4 }
        let ratio = amount / maxAmount
        return max(CGFloat(ratio) * maxHeight, 4)
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
        
        // 레거시 데이터 지원
        if items.isEmpty {
            if update.depositAmount > 0 {
                items.append(("plus.circle.fill", "입금", update.depositAmount))
            }
            if update.passiveIncome > 0 {
                items.append(("banknote.fill", "패시브", update.passiveIncome))
            }
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
        HStack(alignment: .center, spacing: ExitSpacing.md) {
            // 월 + 총액 (배경 없음)
            VStack(spacing: 2) {
                Text(monthText)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.Exit.primaryText)
                
                Text(ExitNumberFormatter.formatToManWon(totalDeposit))
                    .font(.Exit.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.accent)
            }
            .frame(width: 52)
            
            // 카테고리별 금액 (FlowLayout 스타일)
            VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                ForEach(categoryAmounts, id: \.label) { item in
                    HStack(spacing: 4) {
                        Image(systemName: item.icon)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.Exit.accent)
                        
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
            VStack(spacing: ExitSpacing.xs) {
                // 수정 버튼
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.Exit.secondaryText)
                        .frame(width: 28, height: 28)
                        .background(Color.Exit.secondaryCardBackground)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                // 삭제 버튼
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.Exit.warning)
                        .frame(width: 28, height: 28)
                        .background(Color.Exit.warning.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(ExitSpacing.md)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
    }
}

