//
//  RecordView.swift
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
    
    // 애니메이션 상태
    @State private var showYearSelector = false
    @State private var showSummary = false
    @State private var showChart = false
    @State private var showHistory = false
    
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
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: ExitSpacing.lg) {
                    // 년도 선택
                    yearSelector
                        .opacity(showYearSelector ? 1 : 0)
                        .offset(y: showYearSelector ? 0 : -20)
                    
                    // 요약 카드
                    summarySection
                        .opacity(showSummary ? 1 : 0)
                        .offset(y: showSummary ? 0 : 30)
                    
                    // 막대 차트
                    barChartSection
                        .opacity(showChart ? 1 : 0)
                        .offset(y: showChart ? 0 : 30)
                    
                    // 입금 기록 리스트
                    depositHistorySection
                        .opacity(showHistory ? 1 : 0)
                        .offset(y: showHistory ? 0 : 30)
                    
                    // 플로팅 버튼 공간
                    Spacer()
                        .frame(height: 80)
                }
                .padding(.vertical, ExitSpacing.lg)
            }
            
            // 플로팅 액션 버튼
            FloatingActionButtons(viewModel: viewModel)
        }
        .onAppear {
            startEntryAnimation()
        }
    }
    
    // MARK: - 진입 애니메이션
    
    private func startEntryAnimation() {
        // 리셋
        showYearSelector = false
        showSummary = false
        showChart = false
        showHistory = false
        
        // 순차적으로 나타나기
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
            showYearSelector = true
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
            showSummary = true
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.35)) {
            showChart = true
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5)) {
            showHistory = true
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
    
    // MARK: - "내 계획" 시나리오 찾기
    
    private var myPlanScenario: Scenario? {
        viewModel.scenarios.first { $0.isSystemScenario } ?? viewModel.activeScenario
    }
    
    /// 입금 달성도 점수 (0~100)
    private var depositScore: Int {
        guard let scenario = myPlanScenario else { return 0 }
        guard !filteredUpdates.isEmpty else { return 0 }
        
        let monthlyTarget = scenario.monthlyInvestment
        guard monthlyTarget > 0 else { return 100 }
        
        // 각 월별 달성률 계산
        var totalAchievement: Double = 0
        for update in filteredUpdates {
            let actualDeposit = update.salaryAmount + update.dividendAmount + update.interestAmount + update.rentAmount + update.otherAmount
            let deposit = actualDeposit > 0 ? actualDeposit : (update.depositAmount + update.passiveIncome)
            let achievement = min(deposit / monthlyTarget, 1.0) // 100% 상한
            totalAchievement += achievement
        }
        
        let averageAchievement = totalAchievement / Double(filteredUpdates.count)
        return min(Int(averageAchievement * 100), 100)
    }
    
    /// 월 평균 패시브인컴
    private var yearAveragePassiveIncome: Double {
        guard !filteredUpdates.isEmpty else { return 0 }
        return yearTotalPassiveIncome / Double(filteredUpdates.count)
    }
    
    /// 패시브인컴 달성도 점수 (0~100)
    private var passiveIncomeScore: Int {
        guard let scenario = myPlanScenario else { return 0 }
        guard !filteredUpdates.isEmpty else { return 0 }
        
        let targetIncome = scenario.desiredMonthlyIncome
        guard targetIncome > 0 else { return 100 }
        
        // 월 평균 패시브인컴 vs 목표 현금흐름
        let achievement = min(yearAveragePassiveIncome / targetIncome, 1.0) // 100% 상한
        return Int(achievement * 100)
    }
    
    /// 종합 계획 달성 점수 (입금 50% + 패시브인컴 50%)
    private var planScore: Int {
        (depositScore + passiveIncomeScore) / 2
    }
    
    /// 점수에 따른 색상
    private func scoreColor(for score: Int) -> Color {
        switch score {
        case 80...100: return Color.Exit.accent
        case 60..<80: return Color.Exit.positive
        case 40..<60: return Color.Exit.caution
        default: return Color.Exit.warning
        }
    }
    
    /// 종합 점수 색상
    private var totalScoreColor: Color {
        scoreColor(for: planScore)
    }
    
    /// 점수에 따른 메시지
    private var scoreMessage: String {
        switch planScore {
        case 90...100: return "완벽해요!"
        case 80..<90: return "훌륭해요"
        case 70..<80: return "잘하고 있어요"
        case 60..<70: return "조금만 더"
        case 50..<60: return "분발해요"
        default: return "힘내세요"
        }
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
            
            // 컴팩트 요약 표
            VStack(spacing: ExitSpacing.md) {
                RecordSummaryRow(label: "총 입금액", value: ExitNumberFormatter.formatToEokManWon(yearTotalDeposit))
                RecordSummaryRow(label: "총 패시브인컴", value: ExitNumberFormatter.formatToManWon(yearTotalPassiveIncome))
                RecordSummaryRow(label: "월 평균 입금", value: ExitNumberFormatter.formatToManWon(yearAverageDeposit))
            }
            
            // 계획 달성 점수
            if let scenario = myPlanScenario, !filteredUpdates.isEmpty {
                VStack(spacing: ExitSpacing.md) {
                    // 종합 점수 헤더
                    Divider()
                        .background(Color.Exit.divider)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("계획 달성도")
                                .font(.Exit.caption)
                                .foregroundStyle(Color.Exit.secondaryText)
                            Text("입금 50% + 패시브인컴 50%")
                                .font(.Exit.caption2)
                                .foregroundStyle(Color.Exit.tertiaryText)
                        }
                        
                        Spacer()
                        
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(planScore)")
                                .font(.system(size: 32, weight: .heavy, design: .rounded))
                                .foregroundStyle(totalScoreColor)
                            Text("점")
                                .font(.Exit.caption)
                                .foregroundStyle(Color.Exit.secondaryText)
                        }
                    }
                    
                    // 종합 프로그레스 바
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.Exit.divider)
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(totalScoreColor)
                                .frame(width: geometry.size.width * CGFloat(planScore) / 100, height: 8)
                        }
                    }
                    .frame(height: 8)
                    
                    HStack {
                        Text(scoreMessage)
                            .font(.Exit.caption2)
                            .foregroundStyle(totalScoreColor)
                        Spacer()
                    }
                    
                    Divider()
                        .background(Color.Exit.divider)
                    
                    // 세부 점수
                    VStack(spacing: ExitSpacing.sm) {
                        // 입금 달성도
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("입금 달성도")
                                    .font(.Exit.caption2)
                                    .foregroundStyle(Color.Exit.secondaryText)
                                Text("목표 \(ExitNumberFormatter.formatToManWon(scenario.monthlyInvestment))/월")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.Exit.tertiaryText)
                            }
                            
                            Spacer()
                            
                            // 미니 프로그레스 바
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.Exit.divider)
                                        .frame(height: 4)
                                    
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(scoreColor(for: depositScore))
                                        .frame(width: geometry.size.width * CGFloat(depositScore) / 100, height: 4)
                                }
                            }
                            .frame(width: 60, height: 4)
                            
                            Text("\(depositScore)점")
                                .font(.Exit.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(scoreColor(for: depositScore))
                                .frame(width: 40, alignment: .trailing)
                        }
                        
                        // 패시브인컴 달성도
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("패시브인컴 달성도")
                                    .font(.Exit.caption2)
                                    .foregroundStyle(Color.Exit.secondaryText)
                                Text("목표 \(ExitNumberFormatter.formatToManWon(scenario.desiredMonthlyIncome))/월")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.Exit.tertiaryText)
                            }
                            
                            Spacer()
                            
                            // 미니 프로그레스 바
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.Exit.divider)
                                        .frame(height: 4)
                                    
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(scoreColor(for: passiveIncomeScore))
                                        .frame(width: geometry.size.width * CGFloat(passiveIncomeScore) / 100, height: 4)
                                }
                            }
                            .frame(width: 60, height: 4)
                            
                            Text("\(passiveIncomeScore)점")
                                .font(.Exit.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(scoreColor(for: passiveIncomeScore))
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                    
                    // 현재 실적 요약
                    HStack {
                        Text("현재 월평균 패시브인컴: \(ExitNumberFormatter.formatToManWon(yearAveragePassiveIncome))")
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.tertiaryText)
                        Spacer()
                    }
                }
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
                VStack(spacing: ExitSpacing.md) {
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
                        
                        Divider()
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

