//
//  RecordTabView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 기록 탭 전체 뷰
struct RecordTabView: View {
    @Bindable var viewModel: HomeViewModel
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var updateToDelete: MonthlyUpdate?
    @State private var showDeleteConfirmation: Bool = false
    
    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
    
    /// 선택 가능한 년도 목록 (데이터가 있는 년도들 + 현재 년도)
    private var availableYears: [Int] {
        var years = Set<Int>()
        years.insert(currentYear)
        
        for update in viewModel.monthlyUpdates {
            if update.yearMonth.count >= 4,
               let year = Int(String(update.yearMonth.prefix(4))) {
                years.insert(year)
            }
        }
        
        return years.sorted(by: >)
    }
    
    /// 선택한 년도의 입금 기록
    private var filteredUpdates: [MonthlyUpdate] {
        viewModel.monthlyUpdates.filter { update in
            guard update.yearMonth.count >= 4,
                  let year = Int(String(update.yearMonth.prefix(4))) else { return false }
            return year == selectedYear
        }
    }
    
    /// 선택한 년도 총 입금액
    private var yearTotalDeposit: Double {
        filteredUpdates.reduce(0) { update, record in
            let categoryTotal = record.salaryAmount + record.dividendAmount + record.interestAmount + record.rentAmount + record.otherAmount
            if categoryTotal > 0 {
                return update + categoryTotal
            }
            return update + record.depositAmount + record.passiveIncome
        }
    }
    
    /// 선택한 년도 총 패시브인컴
    private var yearTotalPassiveIncome: Double {
        filteredUpdates.reduce(0) { update, record in
            let newPassive = record.dividendAmount + record.interestAmount + record.rentAmount
            if newPassive > 0 {
                return update + newPassive
            }
            return update + record.passiveIncome
        }
    }
    
    /// 선택한 년도 월 평균 입금
    private var yearAverageDeposit: Double {
        let monthsWithData = filteredUpdates.filter { $0.depositAmount > 0 }.count
        guard monthsWithData > 0 else { return 0 }
        return yearTotalDeposit / Double(monthsWithData)
    }
    
    /// 12개월 차트용 데이터
    private var yearlyChartData: [MonthChartData] {
        (1...12).map { month in
            let yearMonth = String(format: "%04d%02d", selectedYear, month)
            let update = filteredUpdates.first { $0.yearMonth == yearMonth }
            
            var depositAmount: Double = 0
            var passiveIncome: Double = 0
            
            if let record = update {
                let categoryTotal = record.salaryAmount + record.dividendAmount + record.interestAmount + record.rentAmount + record.otherAmount
                if categoryTotal > 0 {
                    depositAmount = record.salaryAmount + record.otherAmount
                    passiveIncome = record.dividendAmount + record.interestAmount + record.rentAmount
                } else {
                    depositAmount = record.depositAmount
                    passiveIncome = record.passiveIncome
                }
            }
            
            return MonthChartData(
                month: month,
                depositAmount: depositAmount,
                passiveIncome: passiveIncome
            )
        }
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: ExitSpacing.lg) {
                // 년도 선택
                yearSelector
                
                // 요약 카드
                summarySection
                
                // 막대 차트
                barChartSection
                
                // 입금 기록 리스트
                depositHistorySection
            }
            .padding(.vertical, ExitSpacing.lg)
        }
    }
    
    // MARK: - 년도 선택
    
    private var yearSelector: some View {
        HStack(spacing: ExitSpacing.sm) {
            // 이전 년도 버튼
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedYear -= 1
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.Exit.secondaryText)
                    .frame(width: 44, height: 44)
                    .background(Color.Exit.secondaryCardBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // 년도 표시
            Text("\(String(selectedYear))년")
                .font(.Exit.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.Exit.primaryText)
            
            Spacer()
            
            // 다음 년도 버튼 (현재 년도 이후 비활성화)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if selectedYear < currentYear {
                        selectedYear += 1
                    }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(selectedYear >= currentYear ? Color.Exit.tertiaryText : Color.Exit.secondaryText)
                    .frame(width: 44, height: 44)
                    .background(Color.Exit.secondaryCardBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(selectedYear >= currentYear)
        }
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // MARK: - 요약 섹션
    
    private var summarySection: some View {
        VStack(spacing: ExitSpacing.md) {
            // 헤더
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .foregroundStyle(Color.Exit.accent)
                Text("\(String(selectedYear))년 입금 현황")
                    .font(.Exit.title3)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Spacer()
                
                if !filteredUpdates.isEmpty {
                    Text("\(filteredUpdates.count)개월 기록")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
            }
            
            Divider()
                .background(Color.Exit.divider)
            
            // 요약 카드들
            HStack(spacing: ExitSpacing.md) {
                RecordSummaryCard(
                    title: "총 입금액",
                    value: ExitNumberFormatter.formatToEokManWon(yearTotalDeposit),
                    icon: "plus.circle.fill",
                    color: Color.Exit.accent
                )
                
                RecordSummaryCard(
                    title: "총 패시브인컴",
                    value: ExitNumberFormatter.formatToManWon(yearTotalPassiveIncome),
                    icon: "banknote.fill",
                    color: Color.Exit.accent
                )
            }
            
            HStack(spacing: ExitSpacing.md) {
                RecordSummaryCard(
                    title: "월 평균 입금",
                    value: ExitNumberFormatter.formatToManWon(yearAverageDeposit),
                    icon: "chart.line.uptrend.xyaxis",
                    color: Color.Exit.accent.opacity(0.8)
                )
                
                RecordSummaryCard(
                    title: "기록된 달",
                    value: "\(filteredUpdates.count)개월",
                    icon: "calendar",
                    color: filteredUpdates.isEmpty ? Color.Exit.tertiaryText : Color.Exit.accent
                )
            }
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // MARK: - 막대 차트 섹션
    
    private var barChartSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            // 헤더
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(Color.Exit.accent)
                Text("월별 입금 추이")
                    .font(.Exit.title3)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            Divider()
                .background(Color.Exit.divider)
            
            // 막대 차트 (12개월)
            YearlyBarChart(data: yearlyChartData)
                .frame(height: 200)
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // MARK: - 입금 기록 섹션
    
    private var depositHistorySection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            // 헤더
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(Color.Exit.accent)
                Text("입금 기록")
                    .font(.Exit.title3)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Spacer()
                
                if !filteredUpdates.isEmpty {
                    Text("총 \(filteredUpdates.count)건")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
            }
            
            Divider()
                .background(Color.Exit.divider)
            
            if filteredUpdates.isEmpty {
                // 기록 없음
                VStack(spacing: ExitSpacing.md) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.Exit.tertiaryText)
                    
                    Text("\(String(selectedYear))년 입금 기록이 없습니다")
                        .font(.Exit.body)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    if selectedYear == currentYear {
                        Text("하단의 '입금하기' 버튼을 눌러\n첫 입금을 기록해보세요")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.tertiaryText)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, ExitSpacing.xxl)
            } else {
                // 입금 기록 리스트
                VStack(spacing: ExitSpacing.sm) {
                    ForEach(filteredUpdates.sorted(by: { $0.yearMonth > $1.yearMonth }), id: \.id) { update in
                        DepositHistoryRow(
                            update: update,
                            onEdit: {
                                viewModel.editingYearMonth = update.yearMonth
                                viewModel.showDepositSheet = true
                            },
                            onDelete: {
                                updateToDelete = update
                                showDeleteConfirmation = true
                            }
                        )
                    }
                }
            }
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .padding(.horizontal, ExitSpacing.md)
        .alert("입금 기록 삭제", isPresented: $showDeleteConfirmation) {
            Button("취소", role: .cancel) {
                updateToDelete = nil
            }
            Button("삭제", role: .destructive) {
                if let update = updateToDelete {
                    withAnimation {
                        viewModel.deleteMonthlyUpdate(update)
                    }
                    updateToDelete = nil
                }
            }
        } message: {
            if let update = updateToDelete {
                Text("\(formatYearMonth(update.yearMonth)) 기록을 삭제하시겠습니까?\n입금액과 패시브인컴이 현재 자산에서 차감됩니다.")
            }
        }
    }
    
    private func formatYearMonth(_ yearMonth: String) -> String {
        guard yearMonth.count >= 6 else { return yearMonth }
        let year = String(yearMonth.prefix(4))
        let monthStr = String(yearMonth.suffix(2))
        if let month = Int(monthStr) {
            return "\(year)년 \(month)월"
        }
        return yearMonth
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        RecordTabView(viewModel: HomeViewModel())
    }
    .preferredColorScheme(.dark)
}
