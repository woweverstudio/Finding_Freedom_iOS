//
//  ScenarioManager.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import Foundation
import SwiftData

/// 시나리오 관리 유스케이스
/// 시나리오 CRUD 및 적용 로직
enum ScenarioManager {
    
    /// 최대 시나리오 개수
    static let maxScenarios = 10
    
    // MARK: - 시나리오 생성
    
    /// 온보딩 완료 후 기본 시나리오들 생성
    /// - Parameters:
    ///   - desiredMonthlyIncome: 희망 월 수입
    ///   - monthlyInvestment: 월 투자금액
    ///   - context: SwiftData ModelContext
    static func createInitialScenarios(
        desiredMonthlyIncome: Double,
        monthlyInvestment: Double,
        context: ModelContext
    ) {
        let scenarios = Scenario.createDefaultScenarios(
            desiredMonthlyIncome: desiredMonthlyIncome,
            monthlyInvestment: monthlyInvestment
        )
        
        for scenario in scenarios {
            context.insert(scenario)
        }
        
        try? context.save()
    }
    
    /// 새 시나리오 추가
    /// - Parameters:
    ///   - name: 시나리오 이름
    ///   - basedOn: 기준 시나리오 (옵션)
    ///   - scenarios: 현재 시나리오 목록
    ///   - context: SwiftData ModelContext
    /// - Returns: 생성된 시나리오 (실패 시 nil)
    static func createScenario(
        name: String,
        basedOn: Scenario? = nil,
        in scenarios: [Scenario],
        context: ModelContext
    ) -> Scenario? {
        guard scenarios.count < maxScenarios else {
            return nil  // 최대 개수 초과
        }
        
        let newScenario: Scenario
        
        if let base = basedOn {
            newScenario = base.duplicate(withName: name)
        } else {
            newScenario = Scenario()
            newScenario.name = name
        }
        
        context.insert(newScenario)
        try? context.save()
        
        return newScenario
    }
    
    // MARK: - 시나리오 활성화
    
    /// 특정 시나리오를 활성화 (다른 시나리오는 비활성화)
    /// - Parameters:
    ///   - scenario: 활성화할 시나리오
    ///   - allScenarios: 모든 시나리오 목록
    ///   - context: SwiftData ModelContext
    static func activateScenario(
        _ scenario: Scenario,
        in allScenarios: [Scenario],
        context: ModelContext
    ) {
        for s in allScenarios {
            s.isActive = (s.id == scenario.id)
            s.updatedAt = Date()
        }
        try? context.save()
    }
    
    // MARK: - 시나리오 업데이트
    
    /// 시나리오 값 업데이트
    /// - Parameters:
    ///   - scenario: 업데이트할 시나리오
    ///   - updates: 업데이트할 필드들
    ///   - context: SwiftData ModelContext
    static func updateScenario(
        _ scenario: Scenario,
        desiredMonthlyIncome: Double? = nil,
        assetOffset: Double? = nil,
        monthlyInvestment: Double? = nil,
        preRetirementReturnRate: Double? = nil,
        postRetirementReturnRate: Double? = nil,
        inflationRate: Double? = nil,
        context: ModelContext
    ) {
        if let value = desiredMonthlyIncome {
            scenario.desiredMonthlyIncome = value
        }
        if let value = assetOffset {
            scenario.assetOffset = value
        }
        if let value = monthlyInvestment {
            scenario.monthlyInvestment = value
        }
        if let value = preRetirementReturnRate {
            scenario.preRetirementReturnRate = value
        }
        if let value = postRetirementReturnRate {
            scenario.postRetirementReturnRate = value
        }
        if let value = inflationRate {
            scenario.inflationRate = value
        }
        
        scenario.updatedAt = Date()
        try? context.save()
    }
    
    /// 시나리오 이름 변경
    static func renameScenario(
        _ scenario: Scenario,
        to newName: String,
        context: ModelContext
    ) {
        scenario.name = newName
        scenario.updatedAt = Date()
        try? context.save()
    }
    
    // MARK: - 시나리오 삭제
    
    /// 시나리오 삭제
    /// - Note: 활성 시나리오 삭제 시 다른 시나리오를 활성화
    static func deleteScenario(
        _ scenario: Scenario,
        from allScenarios: [Scenario],
        context: ModelContext
    ) {
        let wasActive = scenario.isActive
        context.delete(scenario)
        
        // 삭제된 시나리오가 활성 상태였으면 첫 번째 시나리오를 활성화
        if wasActive, let first = allScenarios.first(where: { $0.id != scenario.id }) {
            first.isActive = true
        }
        
        try? context.save()
    }
    
    // MARK: - 시나리오 복제
    
    /// 시나리오 복제
    static func duplicateScenario(
        _ scenario: Scenario,
        in allScenarios: [Scenario],
        context: ModelContext
    ) -> Scenario? {
        guard allScenarios.count < maxScenarios else {
            return nil
        }
        
        let newName = "\(scenario.name) 복사본"
        let duplicated = scenario.duplicate(withName: newName)
        
        context.insert(duplicated)
        try? context.save()
        
        return duplicated
    }
}
