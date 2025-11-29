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
    
    /// 안전 점수 결과
    var safetyScoreResult: SafetyScoreResult?
    
    /// 이전 안전 점수 (변화량 계산용)
    var previousSafetyScore: Double = 0
    
    // MARK: - Sheet States
    
    /// 입금 시트 표시
    var showDepositSheet: Bool = false
    
    /// 자산 업데이트 시트 표시
    var showAssetUpdateSheet: Bool = false
    
    /// 시나리오 설정 시트 표시
    var showScenarioSheet: Bool = false
    
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
    
    /// 안전 점수 총점
    var totalSafetyScore: Int {
        Int(safetyScoreResult?.totalScore ?? 0)
    }
    
    /// 안전 점수 변화량 텍스트
    var safetyScoreChangeText: String {
        guard let result = safetyScoreResult else { return "" }
        return ExitNumberFormatter.formatScoreChange(result.scoreChange)
    }
    
    /// 안전 점수 세부 항목
    var safetyScoreDetails: [(title: String, score: Int, maxScore: Int)] {
        guard let result = safetyScoreResult else {
            return [
                ("목표 충족", 0, 25),
                ("수익률 안전성", 0, 25),
                ("자산 다각화", 0, 25),
                ("자산 성장성", 0, 25)
            ]
        }
        return [
            ("목표 충족", Int(result.goalFulfillmentScore), 25),
            ("수익률 안전성", Int(result.returnSafetyScore), 25),
            ("자산 다각화", Int(result.diversificationScore), 25),
            ("자산 성장성", Int(result.growthScore), 25)
        ]
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
        
        // 안전 점수 계산
        let currentUpdate = monthlyUpdates.first
        let previousUpdate = monthlyUpdates.dropFirst().first
        
        safetyScoreResult = SafetyScoreCalculator.calculate(
            monthlyPassiveIncome: currentUpdate?.passiveIncome ?? 0,
            desiredMonthlyIncome: scenario.desiredMonthlyIncome,
            currentAssets: currentUpdate?.totalAssets ?? scenario.currentNetAssets,
            previousAssets: previousUpdate?.totalAssets ?? scenario.currentNetAssets,
            assetTypeCount: currentUpdate?.assetTypes.count ?? 0,
            inflationRate: scenario.inflationRate,
            previousTotalScore: previousSafetyScore
        )
        
        previousSafetyScore = safetyScoreResult?.totalScore ?? 0
    }
    
    // MARK: - Actions
    
    /// 시나리오 선택
    func selectScenario(_ scenario: Scenario) {
        guard let context = modelContext else { return }
        
        ScenarioManager.activateScenario(scenario, in: scenarios, context: context)
        activeScenario = scenario
        calculateResults()
    }
    
    /// 입금 처리
    func submitDeposit() {
        guard let context = modelContext, let scenario = activeScenario else { return }
        
        // 입금 날짜 기준 연월
        let yearMonth = MonthlyUpdate.yearMonth(from: depositDate)
        
        if let existingUpdate = monthlyUpdates.first(where: { $0.yearMonth == yearMonth }) {
            existingUpdate.depositAmount += depositAmount
            existingUpdate.depositDate = depositDate
            existingUpdate.recordedAt = Date()
        } else {
            let newUpdate = MonthlyUpdate(
                yearMonth: yearMonth,
                depositAmount: depositAmount,
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
}

