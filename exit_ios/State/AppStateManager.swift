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
    
    /// 사용자 프로필 (설정값 포함)
    var userProfile: UserProfile?
    
    /// 은퇴 계산 결과 (자동 계산)
    var retirementResult: RetirementCalculationResult?
    
    // MARK: - UI State
    
    /// 현재 선택된 탭
    var selectedTab: MainTab = .dashboard
    
    /// 탭을 홈으로 초기화
    func resetToHomeTab() {
        selectedTab = .dashboard
    }
    
    /// 금액 숨김 여부
    var hideAmounts: Bool = false
    
    /// D-Day 애니메이션 트리거 (설정 변경 시 애니메이션 재시작)
    var dDayAnimationTrigger: UUID = UUID()
    
    /// Plan 설정 변경 트리거 (시뮬레이션 결과 초기화용)
    var planSettingsChangeTrigger: UUID = UUID()
    
    // MARK: - Computed Properties
    
    /// 현재 자산 금액 (UserProfile의 currentNetAssets 사용)
    var currentAssetAmount: Double {
        userProfile?.currentNetAssets ?? 0
    }
    
    /// 진행률 (0~1)
    var progressValue: Double {
        (retirementResult?.progressPercent ?? 0) / 100
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
        
        // UserProfile 로드
        let profileDescriptor = FetchDescriptor<UserProfile>()
        userProfile = try? context.fetch(profileDescriptor).first
        
        // 계산 실행
        calculateResults()
    }
    
    // MARK: - Calculations
    
    func calculateResults() {
        guard let profile = userProfile else { return }
        
        retirementResult = RetirementCalculator.calculate(
            from: profile,
            currentAsset: currentAssetAmount
        )
    }
    
    // MARK: - Settings Actions
    
    /// 설정 업데이트
    func updateSettings(
        desiredMonthlyIncome: Double? = nil,
        currentNetAssets: Double? = nil,
        monthlyInvestment: Double? = nil,
        preRetirementReturnRate: Double? = nil,
        postRetirementReturnRate: Double? = nil
    ) {
        guard let context = modelContext, let profile = userProfile else { return }
        
        profile.updateSettings(
            desiredMonthlyIncome: desiredMonthlyIncome,
            currentNetAssets: currentNetAssets,
            monthlyInvestment: monthlyInvestment,
            preRetirementReturnRate: preRetirementReturnRate,
            postRetirementReturnRate: postRetirementReturnRate
        )
        
        try? context.save()
        calculateResults()
        
        // D-Day 애니메이션 트리거 (0부터 다시 카운트)
        dDayAnimationTrigger = UUID()
        
        // Plan 설정 변경 트리거 (시뮬레이션 결과 초기화용)
        planSettingsChangeTrigger = UUID()
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
