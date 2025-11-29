//
//  DepositSheet.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 입금 카테고리
enum DepositCategory: String, CaseIterable, Identifiable {
    case salary = "월급"
    case dividend = "배당"
    case interest = "이자"
    case rent = "월세"
    case other = "기타"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .salary: return "briefcase.fill"
        case .dividend: return "chart.line.uptrend.xyaxis"
        case .interest: return "percent"
        case .rent: return "house.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .salary: return "월급/보너스"
        case .dividend: return "주식 배당"
        case .interest: return "이자 수입"
        case .rent: return "임대 수입"
        case .other: return "기타 수입"
        }
    }
    
    /// 패시브인컴 여부
    var isPassiveIncome: Bool {
        switch self {
        case .salary, .other:
            return false
        case .dividend, .interest, .rent:
            return true
        }
    }
}

/// 입금 시트 스텝 (3단계)
enum DepositStep: Int, CaseIterable {
    case selectMonth = 0
    case selectCategory = 1
    case enterAmount = 2
    
    var title: String {
        switch self {
        case .selectMonth: return "입금 월 선택"
        case .selectCategory: return "자산군 선택"
        case .enterAmount: return "금액 입력"
        }
    }
}

/// 입금 시트
struct DepositSheet: View {
    @Bindable var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep: DepositStep = .selectMonth
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var isEditMode: Bool = false
    
    // 각 카테고리별 금액
    @State private var salaryAmount: Double = 0
    @State private var dividendAmount: Double = 0
    @State private var interestAmount: Double = 0
    @State private var rentAmount: Double = 0
    @State private var otherAmount: Double = 0
    
    // 현재 선택된 카테고리
    @State private var selectedCategory: DepositCategory = .salary
    
    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
    
    private var currentMonth: Int {
        Calendar.current.component(.month, from: Date())
    }
    
    /// 선택된 년월의 yearMonth 문자열
    private var selectedYearMonth: String {
        String(format: "%04d%02d", selectedYear, selectedMonth)
    }
    
    /// 총 입금액
    private var totalAmount: Double {
        salaryAmount + dividendAmount + interestAmount + rentAmount + otherAmount
    }
    
    /// 기존 기록이 있는 월들의 Set
    private var existingMonthsSet: Set<String> {
        Set(viewModel.monthlyUpdates.map { $0.yearMonth })
    }
    
    /// 현재 선택된 월에 기존 기록이 있는지
    private var hasExistingRecord: Bool {
        existingMonthsSet.contains(selectedYearMonth)
    }
    
    var body: some View {
        ZStack {
            Color.Exit.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 헤더
                sheetHeader
                
                // 진행률 표시 (수정 모드가 아닐 때만)
                if !isEditMode || currentStep != .selectCategory {
                    progressIndicator
                }
                
                // 스텝별 컨텐츠
                Group {
                    switch currentStep {
                    case .selectMonth:
                        DepositMonthStep(
                            selectedYear: $selectedYear,
                            selectedMonth: $selectedMonth,
                            currentYear: currentYear,
                            currentMonth: currentMonth,
                            existingMonths: existingMonthsSet,
                            hasExistingRecord: hasExistingRecord,
                            onNext: {
                                loadExistingRecord()
                                currentStep = .selectCategory
                            }
                        )
                        
                    case .selectCategory:
                        DepositCategoryStep(
                            selectedYear: selectedYear,
                            selectedMonth: selectedMonth,
                            totalAmount: totalAmount,
                            amountForCategory: amountForCategory,
                            onSelectCategory: { category in
                                selectedCategory = category
                                currentStep = .enterAmount
                            },
                            onSave: submitDeposit
                        )
                        
                    case .enterAmount:
                        DepositAmountStep(
                            selectedYear: selectedYear,
                            selectedMonth: selectedMonth,
                            selectedCategory: selectedCategory,
                            amount: bindingForSelectedCategory(),
                            onComplete: {
                                currentStep = .selectCategory
                            }
                        )
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: currentStep)
            }
        }
        .presentationDetents([.large])
        .onAppear {
            setupEditMode()
        }
        .onDisappear {
            // 시트가 닫힐 때 editingYearMonth 초기화
            viewModel.editingYearMonth = nil
        }
    }
    
    /// 수정 모드 설정
    private func setupEditMode() {
        if let editingYearMonth = viewModel.editingYearMonth,
           editingYearMonth.count >= 6,
           let year = Int(String(editingYearMonth.prefix(4))),
           let month = Int(String(editingYearMonth.suffix(2))) {
            // 수정 모드로 설정
            isEditMode = true
            selectedYear = year
            selectedMonth = month
            loadExistingRecord()
            currentStep = .selectCategory
        } else {
            // 새 입력 모드
            isEditMode = false
            loadExistingRecord()
        }
    }
    
    // MARK: - Header
    
    private var sheetHeader: some View {
        HStack {
            Button(action: goBack) {
                Image(systemName: shouldShowCloseButton ? "xmark" : "chevron.left")
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            
            Spacer()
            
            Text(headerTitle)
                .font(.Exit.title3)
                .foregroundStyle(Color.Exit.primaryText)
            
            Spacer()
            
            // 균형을 위한 투명 아이콘
            Image(systemName: "xmark")
                .font(.Exit.body)
                .foregroundStyle(.clear)
        }
        .padding(.horizontal, ExitSpacing.lg)
        .padding(.top, ExitSpacing.lg)
    }
    
    private var shouldShowCloseButton: Bool {
        if isEditMode {
            return currentStep == .selectCategory
        }
        return currentStep == .selectMonth
    }
    
    private var headerTitle: String {
        if isEditMode && currentStep == .selectCategory {
            return "\(String(selectedYear))년 \(selectedMonth)월 수정"
        }
        return currentStep.title
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: ExitSpacing.sm) {
            ForEach(DepositStep.allCases, id: \.rawValue) { step in
                Capsule()
                    .fill(step.rawValue <= currentStep.rawValue ? Color.Exit.accent : Color.Exit.divider)
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .padding(.horizontal, ExitSpacing.lg)
        .padding(.top, ExitSpacing.md)
    }
    
    // MARK: - Navigation
    
    private func goBack() {
        switch currentStep {
        case .selectMonth:
            dismiss()
        case .selectCategory:
            if isEditMode {
                // 수정 모드에서는 바로 닫기
                dismiss()
            } else {
                currentStep = .selectMonth
            }
        case .enterAmount:
            currentStep = .selectCategory
        }
    }
    
    // MARK: - Data Helpers
    
    /// 기존 기록 불러오기
    private func loadExistingRecord() {
        if let existingUpdate = viewModel.monthlyUpdates.first(where: { $0.yearMonth == selectedYearMonth }) {
            salaryAmount = existingUpdate.salaryAmount
            dividendAmount = existingUpdate.dividendAmount
            interestAmount = existingUpdate.interestAmount
            rentAmount = existingUpdate.rentAmount
            otherAmount = existingUpdate.otherAmount
            
            // 레거시 데이터 마이그레이션
            if salaryAmount == 0 && dividendAmount == 0 && interestAmount == 0 && rentAmount == 0 && otherAmount == 0 {
                if existingUpdate.depositAmount > 0 {
                    salaryAmount = existingUpdate.depositAmount
                }
                if existingUpdate.passiveIncome > 0 {
                    dividendAmount = existingUpdate.passiveIncome
                }
            }
        } else {
            salaryAmount = 0
            dividendAmount = 0
            interestAmount = 0
            rentAmount = 0
            otherAmount = 0
        }
    }
    
    /// 카테고리별 금액 반환
    private func amountForCategory(_ category: DepositCategory) -> Double {
        switch category {
        case .salary: return salaryAmount
        case .dividend: return dividendAmount
        case .interest: return interestAmount
        case .rent: return rentAmount
        case .other: return otherAmount
        }
    }
    
    /// 선택된 카테고리에 대한 Binding
    private func bindingForSelectedCategory() -> Binding<Double> {
        switch selectedCategory {
        case .salary:
            return $salaryAmount
        case .dividend:
            return $dividendAmount
        case .interest:
            return $interestAmount
        case .rent:
            return $rentAmount
        case .other:
            return $otherAmount
        }
    }
    
    /// 입금 제출
    private func submitDeposit() {
        viewModel.submitCategoryDeposit(
            yearMonth: selectedYearMonth,
            salaryAmount: salaryAmount,
            dividendAmount: dividendAmount,
            interestAmount: interestAmount,
            rentAmount: rentAmount,
            otherAmount: otherAmount
        )
    }
}

// MARK: - Preview

#Preview {
    DepositSheet(viewModel: HomeViewModel())
        .preferredColorScheme(.dark)
}

