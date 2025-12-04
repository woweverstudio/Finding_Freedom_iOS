//
//  AppStateManager.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import Foundation
import SwiftData
import Observation
import SwiftUI

/// 앱 전역 상태 관리자
/// Environment로 주입되어 모든 View에서 접근 가능
@Observable
final class AppStateManager {
    // MARK: - Dependencies
    
    private var modelContext: ModelContext?
    
    // MARK: - Data State (DB에서 로드)
    
    /// 현재 자산 (앱 전체 단일)
    var currentAsset: Asset?
    
    /// 활성 시나리오
    var activeScenario: Scenario?
    
    /// 모든 시나리오
    var scenarios: [Scenario] = []
    
    /// 사용자 프로필
    var userProfile: UserProfile?
    
    /// 월별 업데이트 기록
    var monthlyUpdates: [MonthlyUpdate] = []
    
    /// 자산 스냅샷 히스토리
    var assetSnapshots: [AssetSnapshot] = []
    
    /// 은퇴 계산 결과 (자동 계산)
    var retirementResult: RetirementCalculationResult?
    
    // MARK: - UI State
    
    /// 현재 선택된 탭
    var selectedTab: MainTab = .dashboard
    
    /// 금액 숨김 여부
    var hideAmounts: Bool = false
    
    // MARK: - Sheet States
    
    /// 입금 시트 표시
    var showDepositSheet: Bool = false
    
    /// 자산 업데이트 시트 표시
    var showAssetUpdateSheet: Bool = false
    
    /// 시나리오 설정 시트 표시
    var showScenarioSheet: Bool = false
    
    /// 입금 완료 후 자산 업데이트 확인 표시
    var showAssetUpdateConfirm: Bool = false
    
    /// 수정할 월 (nil이면 새로 입력, 값이 있으면 해당 월 수정)
    var editingYearMonth: String? = nil
    
    // MARK: - Input States
    
    /// 입금액 입력
    var depositAmount: Double = 0
    
    /// 입금 날짜 (기본값: 오늘)
    var depositDate: Date = Date()
    
    /// 현재 총 자산 입력
    var totalAssetsInput: Double = 0
    
    // MARK: - Computed Properties
    
    /// 현재 자산 금액
    var currentAssetAmount: Double {
        currentAsset?.amount ?? 0
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
    
    /// 자산 마지막 업데이트 일자 표시
    var lastAssetUpdateText: String {
        guard let asset = currentAsset else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: asset.updatedAt)
    }
    
    // MARK: - Initialization
    
    func configure(with context: ModelContext) {
        guard modelContext == nil else { return }
        self.modelContext = context
        loadData()
    }
    
    // MARK: - Data Loading
    
    func loadData() {
        guard let context = modelContext else { return }
        
        // Asset 로드 (단일)
        let assetDescriptor = FetchDescriptor<Asset>()
        currentAsset = try? context.fetch(assetDescriptor).first
        
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
        
        // AssetSnapshots 로드
        let snapshotDescriptor = FetchDescriptor<AssetSnapshot>(
            sortBy: [SortDescriptor(\.yearMonth, order: .reverse)]
        )
        assetSnapshots = (try? context.fetch(snapshotDescriptor)) ?? []
        
        // 계산 실행
        calculateResults()
        
        // 입력 필드 초기값 설정
        if let asset = currentAsset {
            totalAssetsInput = asset.amount
        } else if let profile = userProfile {
            totalAssetsInput = profile.currentNetAssets
        }
    }
    
    // MARK: - Calculations
    
    func calculateResults() {
        guard let scenario = activeScenario else { return }
        
        retirementResult = RetirementCalculator.calculate(
            from: scenario,
            currentAsset: currentAssetAmount
        )
    }
    
    // MARK: - Scenario Actions
    
    /// 시나리오 선택
    func selectScenario(_ scenario: Scenario) {
        guard let context = modelContext else { return }
        
        ScenarioManager.activateScenario(scenario, in: scenarios, context: context)
        activeScenario = scenario
        calculateResults()
    }
    
    /// 시나리오 복제
    func duplicateScenario(_ scenario: Scenario) {
        guard let context = modelContext else { return }
        if let duplicated = ScenarioManager.duplicateScenario(scenario, in: scenarios, context: context) {
            scenarios.append(duplicated)
        }
    }
    
    /// 시나리오 삭제
    func deleteScenario(_ scenario: Scenario) {
        guard let context = modelContext, scenarios.count > 1, scenario.isDeletable else { return }
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
    
    // MARK: - Deposit Actions
    
    /// 입금 처리 (레거시)
    func submitDeposit(isPassiveIncome: Bool = false, depositType: String = "") {
        guard let context = modelContext else { return }
        
        let yearMonth = MonthlyUpdate.yearMonth(from: depositDate)
        
        if let existingUpdate = monthlyUpdates.first(where: { $0.yearMonth == yearMonth }) {
            if isPassiveIncome {
                existingUpdate.passiveIncome += depositAmount
            } else {
                existingUpdate.depositAmount += depositAmount
            }
            existingUpdate.totalAssets = currentAssetAmount + depositAmount
            existingUpdate.depositDate = depositDate
            existingUpdate.recordedAt = Date()
        } else {
            let newUpdate = MonthlyUpdate(
                yearMonth: yearMonth,
                depositAmount: isPassiveIncome ? 0 : depositAmount,
                passiveIncome: isPassiveIncome ? depositAmount : 0,
                totalAssets: currentAssetAmount + depositAmount,
                depositDate: depositDate
            )
            context.insert(newUpdate)
        }
        
        try? context.save()
        
        depositAmount = 0
        depositDate = Date()
        loadData()
        showDepositSheet = false
    }
    
    /// 카테고리별 입금 처리
    func submitCategoryDeposit(
        yearMonth: String,
        salaryAmount: Double,
        dividendAmount: Double,
        interestAmount: Double,
        rentAmount: Double,
        otherAmount: Double
    ) {
        guard let context = modelContext else { return }
        
        if let existingUpdate = monthlyUpdates.first(where: { $0.yearMonth == yearMonth }) {
            existingUpdate.salaryAmount = salaryAmount
            existingUpdate.dividendAmount = dividendAmount
            existingUpdate.interestAmount = interestAmount
            existingUpdate.rentAmount = rentAmount
            existingUpdate.otherAmount = otherAmount
            existingUpdate.depositAmount = salaryAmount + otherAmount
            existingUpdate.passiveIncome = dividendAmount + interestAmount + rentAmount
            existingUpdate.totalAssets = currentAssetAmount
            existingUpdate.recordedAt = Date()
        } else {
            let newUpdate = MonthlyUpdate(
                yearMonth: yearMonth,
                salaryAmount: salaryAmount,
                dividendAmount: dividendAmount,
                interestAmount: interestAmount,
                rentAmount: rentAmount,
                otherAmount: otherAmount,
                totalAssets: currentAssetAmount
            )
            context.insert(newUpdate)
        }
        
        try? context.save()
        loadData()
        showDepositSheet = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.showAssetUpdateConfirm = true
        }
    }
    
    /// 입금 기록 삭제
    func deleteMonthlyUpdate(_ update: MonthlyUpdate) {
        guard let context = modelContext else { return }
        context.delete(update)
        try? context.save()
        loadData()
    }
    
    // MARK: - Asset Actions
    
    /// 자산 변동 업데이트
    func submitAssetUpdate() {
        guard let context = modelContext else { return }
        
        let yearMonth = AssetSnapshot.currentYearMonth()
        
        if let asset = currentAsset {
            asset.update(amount: totalAssetsInput)
        } else {
            let newAsset = Asset(amount: totalAssetsInput)
            context.insert(newAsset)
            currentAsset = newAsset
        }
        
        if let existingSnapshot = assetSnapshots.first(where: { $0.yearMonth == yearMonth }) {
            existingSnapshot.amount = totalAssetsInput
            existingSnapshot.snapshotDate = Date()
        } else {
            let newSnapshot = AssetSnapshot(
                yearMonth: yearMonth,
                amount: totalAssetsInput
            )
            context.insert(newSnapshot)
        }
        
        if let existingUpdate = monthlyUpdates.first(where: { $0.yearMonth == yearMonth }) {
            existingUpdate.totalAssets = totalAssetsInput
            existingUpdate.recordedAt = Date()
        }
        
        try? context.save()
        
        loadData()
        showAssetUpdateSheet = false
        showAssetUpdateConfirm = false
    }
}

// MARK: - Environment Key

struct AppStateManagerKey: EnvironmentKey {
    static let defaultValue: AppStateManager = AppStateManager()
}

extension EnvironmentValues {
    var appState: AppStateManager {
        get { self[AppStateManagerKey.self] }
        set { self[AppStateManagerKey.self] = newValue }
    }
}
