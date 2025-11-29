//
//  HomeViewModel.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import Foundation
import SwiftData
import Observation
import SwiftUI

@Observable
final class HomeViewModel {
    // MARK: - Dependencies
    
    private var modelContext: ModelContext?
    
    // MARK: - State
    
    /// 현재 활성 시나리오
    var activeScenario: Scenario?
    
    /// 모든 시나리오
    var scenarios: [Scenario] = []
    
    /// 사용자 프로필
    var userProfile: UserProfile?
    
    /// 월별 업데이트 기록
    var monthlyUpdates: [MonthlyUpdate] = []
    
    /// 은퇴 계산 결과
    var retirementResult: RetirementCalculationResult?
    
    // MARK: - Sheet States
    
    /// 입금 시트 표시
    var showDepositSheet: Bool = false
    
    /// 자산 업데이트 시트 표시
    var showAssetUpdateSheet: Bool = false
    
    /// 시나리오 설정 시트 표시
    var showScenarioSheet: Bool = false
    
    /// 수정할 월 (nil이면 새로 입력, 값이 있으면 해당 월 수정)
    var editingYearMonth: String? = nil
    
    // MARK: - Input States
    
    /// 입금액 입력
    var depositAmount: Double = 0
    
    /// 입금 날짜 (기본값: 오늘)
    var depositDate: Date = Date()
    
    /// 현재 총 자산 입력
    var totalAssetsInput: Double = 0
    
    /// 보유 자산 종류
    var selectedAssetTypes: Set<String> = []
    
    // MARK: - Computed Properties
    
    /// D-DAY 메인 텍스트
    var dDayMainText: String {
        guard let result = retirementResult else {
            return "계산 중..."
        }
        if result.monthsToRetirement == 0 {
            return "이미 은퇴 가능합니다! 🎉"
        }
        return "회사 탈출까지 \(result.dDayString) 남았습니다."
    }
    
    /// D-DAY 서브 텍스트
    var dDaySubText: String {
        guard let scenario = activeScenario, let result = retirementResult else {
            return ""
        }
        let monthlyFormatted = ExitNumberFormatter.formatToManWon(scenario.monthlyInvestment)
        let incomeFormatted = ExitNumberFormatter.formatToManWon(scenario.desiredMonthlyIncome)
        
        if result.monthsToRetirement == 0 {
            return "축하합니다! 목표 달성!"
        }
        return "매월 \(monthlyFormatted)씩 넣으면\n\(result.dDayString) 후 일 안하고 월 \(incomeFormatted) 놀고먹기 가능"
    }
    
    /// 진행률 표시 텍스트
    var progressText: String {
        guard let scenario = activeScenario, let result = retirementResult else {
            return "0만원 / 0만원 (0%)"
        }
        let current = ExitNumberFormatter.formatToEokManWon(scenario.currentNetAssets)
        let target = ExitNumberFormatter.formatToEokManWon(result.targetAssets)
        let percent = ExitNumberFormatter.formatPercentInt(result.progressPercent)
        return "\(current) / \(target) (\(percent))"
    }
    
    /// 진행률 (0~1)
    var progressValue: Double {
        (retirementResult?.progressPercent ?? 0) / 100
    }
    
    /// 총 입금액
    var totalDepositAmount: Double {
        monthlyUpdates.reduce(0) { sum, record in
            let categoryTotal = record.salaryAmount + record.dividendAmount + record.interestAmount + record.rentAmount + record.otherAmount
            if categoryTotal > 0 {
                return sum + categoryTotal
            }
            return sum + record.depositAmount + record.passiveIncome
        }
    }
    
    /// 총 패시브인컴
    var totalPassiveIncome: Double {
        monthlyUpdates.reduce(0) { sum, record in
            let newPassive = record.dividendAmount + record.interestAmount + record.rentAmount
            if newPassive > 0 {
                return sum + newPassive
            }
            return sum + record.passiveIncome
        }
    }
    
    /// 최근 6개월 입금 데이터 (차트용)
    var recentDeposits: [MonthlyUpdate] {
        Array(monthlyUpdates.prefix(6).reversed())
    }
    
    /// 이번 달 입금액
    var currentMonthDeposit: Double {
        let currentYearMonth = MonthlyUpdate.currentYearMonth()
        guard let record = monthlyUpdates.first(where: { $0.yearMonth == currentYearMonth }) else { return 0 }
        let categoryTotal = record.salaryAmount + record.dividendAmount + record.interestAmount + record.rentAmount + record.otherAmount
        if categoryTotal > 0 {
            return categoryTotal
        }
        return record.depositAmount + record.passiveIncome
    }
    
    /// 지난 달 입금액
    var previousMonthDeposit: Double {
        let calendar = Calendar.current
        guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date()) else { return 0 }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMM"
        let yearMonth = formatter.string(from: lastMonth)
        guard let record = monthlyUpdates.first(where: { $0.yearMonth == yearMonth }) else { return 0 }
        let categoryTotal = record.salaryAmount + record.dividendAmount + record.interestAmount + record.rentAmount + record.otherAmount
        if categoryTotal > 0 {
            return categoryTotal
        }
        return record.depositAmount + record.passiveIncome
    }
    
    /// 월 평균 입금액
    var averageMonthlyDeposit: Double {
        guard !monthlyUpdates.isEmpty else { return 0 }
        return totalDepositAmount / Double(monthlyUpdates.count)
    }
    
    // MARK: - Initialization
    
    func configure(with context: ModelContext) {
        self.modelContext = context
        loadData()
    }
    
    // MARK: - Data Loading
    
    func loadData() {
        guard let context = modelContext else { return }
        
        // UserProfile 로드
        let profileDescriptor = FetchDescriptor<UserProfile>()
        userProfile = try? context.fetch(profileDescriptor).first
        
        // Scenarios 로드
        let scenarioDescriptor = FetchDescriptor<Scenario>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        scenarios = (try? context.fetch(scenarioDescriptor)) ?? []
        activeScenario = scenarios.first(where: { $0.isActive }) ?? scenarios.first
        
        // MonthlyUpdates 로드
        let updateDescriptor = FetchDescriptor<MonthlyUpdate>(
            sortBy: [SortDescriptor(\.yearMonth, order: .reverse)]
        )
        monthlyUpdates = (try? context.fetch(updateDescriptor)) ?? []
        
        // 계산 실행
        calculateResults()
        
        // 입력 필드 초기값 설정
        if let lastUpdate = monthlyUpdates.first {
            totalAssetsInput = lastUpdate.totalAssets
            selectedAssetTypes = Set(lastUpdate.assetTypes)
        } else if let profile = userProfile {
            totalAssetsInput = profile.currentNetAssets
            selectedAssetTypes = Set(profile.assetTypes)
        }
    }
    
    // MARK: - Calculations
    
    func calculateResults() {
        guard let scenario = activeScenario else { return }
        
        // 은퇴 계산
        retirementResult = RetirementCalculator.calculate(from: scenario)
    }
    
    // MARK: - Actions
    
    /// 시나리오 선택
    func selectScenario(_ scenario: Scenario) {
        guard let context = modelContext else { return }
        
        ScenarioManager.activateScenario(scenario, in: scenarios, context: context)
        activeScenario = scenario
        calculateResults()
    }
    
    /// 입금 처리 (레거시)
    /// - Parameters:
    ///   - isPassiveIncome: 패시브인컴 여부 (배당금, 이자, 월세 등)
    ///   - depositType: 입금 유형 이름 (기록용)
    func submitDeposit(isPassiveIncome: Bool = false, depositType: String = "") {
        guard let context = modelContext, let scenario = activeScenario else { return }
        
        // 입금 날짜 기준 연월
        let yearMonth = MonthlyUpdate.yearMonth(from: depositDate)
        
        if let existingUpdate = monthlyUpdates.first(where: { $0.yearMonth == yearMonth }) {
            // 기존 기록 업데이트
            if isPassiveIncome {
                existingUpdate.passiveIncome += depositAmount
            } else {
                existingUpdate.depositAmount += depositAmount
            }
            existingUpdate.totalAssets += depositAmount
            existingUpdate.depositDate = depositDate
            existingUpdate.recordedAt = Date()
        } else {
            // 새 기록 생성
            let newUpdate = MonthlyUpdate(
                yearMonth: yearMonth,
                depositAmount: isPassiveIncome ? 0 : depositAmount,
                passiveIncome: isPassiveIncome ? depositAmount : 0,
                totalAssets: scenario.currentNetAssets + depositAmount,
                assetTypes: Array(selectedAssetTypes),
                depositDate: depositDate
            )
            context.insert(newUpdate)
        }
        
        // 시나리오 자산 업데이트
        scenario.currentNetAssets += depositAmount
        scenario.updatedAt = Date()
        
        try? context.save()
        
        // 초기화 및 재계산
        depositAmount = 0
        depositDate = Date()
        loadData()
        showDepositSheet = false
    }
    
    /// 카테고리별 입금 처리 (신규)
    /// - Parameters:
    ///   - yearMonth: 연월 문자열 (yyyyMM)
    ///   - salaryAmount: 월급/보너스
    ///   - dividendAmount: 배당금
    ///   - interestAmount: 이자 수입
    ///   - rentAmount: 월세/임대료
    ///   - otherAmount: 기타 입금
    func submitCategoryDeposit(
        yearMonth: String,
        salaryAmount: Double,
        dividendAmount: Double,
        interestAmount: Double,
        rentAmount: Double,
        otherAmount: Double
    ) {
        guard let context = modelContext, let scenario = activeScenario else { return }
        
        let newTotalDeposit = salaryAmount + dividendAmount + interestAmount + rentAmount + otherAmount
        
        if let existingUpdate = monthlyUpdates.first(where: { $0.yearMonth == yearMonth }) {
            // 기존 기록의 이전 총액 계산
            let previousTotal = existingUpdate.salaryAmount + existingUpdate.dividendAmount + 
                               existingUpdate.interestAmount + existingUpdate.rentAmount + existingUpdate.otherAmount
            
            // 레거시 필드도 고려 (마이그레이션 안 된 데이터)
            let legacyTotal = existingUpdate.depositAmount + existingUpdate.passiveIncome
            let actualPreviousTotal = max(previousTotal, legacyTotal)
            
            // 카테고리별 금액 업데이트
            existingUpdate.salaryAmount = salaryAmount
            existingUpdate.dividendAmount = dividendAmount
            existingUpdate.interestAmount = interestAmount
            existingUpdate.rentAmount = rentAmount
            existingUpdate.otherAmount = otherAmount
            
            // 레거시 필드 동기화
            existingUpdate.depositAmount = salaryAmount + otherAmount
            existingUpdate.passiveIncome = dividendAmount + interestAmount + rentAmount
            
            // 총 자산 업데이트 (차이만큼 반영)
            let difference = newTotalDeposit - actualPreviousTotal
            existingUpdate.totalAssets += difference
            existingUpdate.recordedAt = Date()
            
            // 시나리오 자산 업데이트
            scenario.currentNetAssets += difference
        } else {
            // 새 기록 생성
            let newUpdate = MonthlyUpdate(
                yearMonth: yearMonth,
                salaryAmount: salaryAmount,
                dividendAmount: dividendAmount,
                interestAmount: interestAmount,
                rentAmount: rentAmount,
                otherAmount: otherAmount,
                totalAssets: scenario.currentNetAssets + newTotalDeposit,
                assetTypes: Array(selectedAssetTypes)
            )
            context.insert(newUpdate)
            
            // 시나리오 자산 업데이트
            scenario.currentNetAssets += newTotalDeposit
        }
        
        scenario.updatedAt = Date()
        
        try? context.save()
        
        // 데이터 리로드 및 시트 닫기
        loadData()
        showDepositSheet = false
    }
    
    /// 자산 변동 업데이트
    func submitAssetUpdate() {
        guard let context = modelContext, let scenario = activeScenario else { return }
        
        let yearMonth = MonthlyUpdate.currentYearMonth()
        
        if let existingUpdate = monthlyUpdates.first(where: { $0.yearMonth == yearMonth }) {
            existingUpdate.totalAssets = totalAssetsInput
            existingUpdate.assetTypes = Array(selectedAssetTypes)
            existingUpdate.recordedAt = Date()
        } else {
            let newUpdate = MonthlyUpdate(
                yearMonth: yearMonth,
                depositAmount: 0,
                passiveIncome: 0,
                totalAssets: totalAssetsInput,
                assetTypes: Array(selectedAssetTypes)
            )
            context.insert(newUpdate)
        }
        
        // 시나리오 자산 업데이트
        scenario.currentNetAssets = totalAssetsInput
        scenario.updatedAt = Date()
        
        try? context.save()
        
        loadData()
        showAssetUpdateSheet = false
    }
    
    /// 자산 종류 토글
    func toggleAssetType(_ type: String) {
        if selectedAssetTypes.contains(type) {
            selectedAssetTypes.remove(type)
        } else {
            selectedAssetTypes.insert(type)
        }
    }
    
    // MARK: - Scenario Management
    
    /// 시나리오 복제
    func duplicateScenario(_ scenario: Scenario) {
        guard let context = modelContext else { return }
        if let duplicated = ScenarioManager.duplicateScenario(scenario, in: scenarios, context: context) {
            scenarios.append(duplicated)
        }
    }
    
    /// 시나리오 삭제
    func deleteScenario(_ scenario: Scenario) {
        guard let context = modelContext, scenarios.count > 1 else { return }
        ScenarioManager.deleteScenario(scenario, from: scenarios, context: context)
        loadData()
    }
    
    /// 시나리오 이름 변경
    func renameScenario(_ scenario: Scenario, to newName: String) {
        guard let context = modelContext else { return }
        ScenarioManager.renameScenario(scenario, to: newName, context: context)
    }
    
    /// 시나리오 업데이트
    func updateScenario(_ scenario: Scenario) {
        guard let context = modelContext else { return }
        scenario.updatedAt = Date()
        try? context.save()
        
        if scenario.isActive {
            calculateResults()
        }
    }
    
    /// 새 시나리오 생성
    func createNewScenario(name: String) {
        guard let context = modelContext else { return }
        if let newScenario = ScenarioManager.createScenario(
            name: name,
            basedOn: activeScenario,
            in: scenarios,
            context: context
        ) {
            scenarios.append(newScenario)
        }
    }
    
    // MARK: - Monthly Update Management
    
    /// 입금 기록 삭제
    func deleteMonthlyUpdate(_ update: MonthlyUpdate) {
        guard let context = modelContext else { return }
        
        // 시나리오 자산에서 해당 입금액 차감
        if let scenario = activeScenario {
            scenario.currentNetAssets -= (update.depositAmount + update.passiveIncome)
            scenario.updatedAt = Date()
        }
        
        // 삭제
        context.delete(update)
        try? context.save()
        
        // 데이터 다시 로드
        loadData()
    }
}

