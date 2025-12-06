//
//  OnboardingViewModel.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import Foundation
import SwiftData
import Observation

/// 온보딩 단계
enum OnboardingStep: Int, CaseIterable {
    case desiredIncome = 0      // 희망 월 수입
    case currentAssets = 1      // 현재 순자산
    case monthlyInvestment = 2  // 월 투자 금액
    
    var title: String {
        switch self {
        case .desiredIncome:
            return "은퇴 후 희망 월 현금흐름"
        case .currentAssets:
            return "현재 순자산"
        case .monthlyInvestment:
            return "월 평균 저축·투자 금액"
        }
    }
    
    var subtitle: String {
        switch self {
        case .desiredIncome:
            return "매달 얼마가 있으면 일 안 해도 될까요?"
        case .currentAssets:
            return "투자 가능한 자산만 입력해주세요"
        case .monthlyInvestment:
            return "월급 등 근로 소득만 포함 (배당/이자 재투자 제외)"
        }
    }
    
    var defaultValue: Double {
        switch self {
        case .desiredIncome:
            return 3_000_000  // 300만원
        case .currentAssets:
            return 0
        case .monthlyInvestment:
            return 500_000   // 50만원
        }
    }
}

@Observable
final class OnboardingViewModel {
    // MARK: - State
    
    /// 환영 화면 표시 여부
    var showWelcome: Bool = true
    
    /// 현재 온보딩 단계
    var currentStep: OnboardingStep = .desiredIncome
    
    /// 희망 월 수입 (원 단위)
    var desiredMonthlyIncome: Double = 3_000_000
    
    /// 현재 순자산 (원 단위)
    var currentNetAssets: Double = 0
    
    /// 월 투자 금액 (원 단위)
    var monthlyInvestment: Double = 500_000
    
    /// 온보딩 완료 여부
    var isCompleted: Bool = false
    
    /// 현재 입력 값 (숫자 키보드용)
    var currentInputValue: Double {
        get {
            switch currentStep {
            case .desiredIncome:
                return desiredMonthlyIncome
            case .currentAssets:
                return currentNetAssets
            case .monthlyInvestment:
                return monthlyInvestment
            }
        }
        set {
            switch currentStep {
            case .desiredIncome:
                desiredMonthlyIncome = newValue
            case .currentAssets:
                currentNetAssets = newValue
            case .monthlyInvestment:
                monthlyInvestment = newValue
            }
        }
    }
    
    /// 음수/양수 토글 표시 여부
    var showsNegativeToggle: Bool {
        currentStep == .currentAssets
    }
    
    /// 숫자 키보드 표시 여부
    var showsNumberKeyboard: Bool {
        true
    }
    
    // MARK: - Computed
    
    /// 다음 단계로 이동 가능 여부
    var canProceed: Bool {
        switch currentStep {
        case .desiredIncome:
            return desiredMonthlyIncome > 0
        case .currentAssets:
            return true  // 0원도 허용
        case .monthlyInvestment:
            return monthlyInvestment >= 0
        }
    }
    
    /// 마지막 단계 여부
    var isLastStep: Bool {
        currentStep == .monthlyInvestment
    }
    
    /// 진행률 (0~1)
    var progress: Double {
        Double(currentStep.rawValue + 1) / Double(OnboardingStep.allCases.count)
    }
    
    // MARK: - Actions
    
    /// 다음 단계로 이동
    func goToNextStep() {
        guard canProceed else { return }
        
        if let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = nextStep
            }
        }
    }
    
    /// 이전 단계로 이동
    func goToPreviousStep() {
        if let prevStep = OnboardingStep(rawValue: currentStep.rawValue - 1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = prevStep
            }
        }
    }
    
    /// 온보딩 완료 및 데이터 저장
    func completeOnboarding(context: ModelContext) {
        // UserProfile 저장
        let profile = UserProfile(
            desiredMonthlyIncome: desiredMonthlyIncome,
            currentNetAssets: currentNetAssets,
            monthlyInvestment: monthlyInvestment
        )
        context.insert(profile)
        
        // Asset 생성 (앱 전체 단일 자산)
        let asset = Asset(amount: currentNetAssets)
        context.insert(asset)
        
        // AssetSnapshot 생성 (초기 스냅샷)
        let snapshot = AssetSnapshot(
            yearMonth: AssetSnapshot.currentYearMonth(),
            amount: currentNetAssets
        )
        context.insert(snapshot)
        
        // 초기 MonthlyUpdate 생성
        let initialUpdate = MonthlyUpdate(
            yearMonth: MonthlyUpdate.currentYearMonth(),
            depositAmount: 0,
            passiveIncome: 0,
            totalAssets: currentNetAssets
        )
        context.insert(initialUpdate)
        
        try? context.save()
        
        withAnimation {
            isCompleted = true
        }
    }
    
    /// 값 초기화 (현재 단계)
    func resetCurrentValue() {
        currentInputValue = currentStep.defaultValue
    }
    
    // MARK: - Number Input
    
    /// 숫자 입력
    func appendDigit(_ digit: String) {
        let currentString = String(Int(currentInputValue))
        let newString = currentString == "0" ? digit : currentString + digit
        if let value = Double(newString), value <= 100_000_000_000 {  // 1000억 제한
            currentInputValue = value
        }
    }
    
    /// 마지막 자릿수 삭제
    func deleteLastDigit() {
        var currentString = String(Int(currentInputValue))
        if currentString.count > 1 {
            currentString.removeLast()
            currentInputValue = Double(currentString) ?? 0
        } else {
            currentInputValue = 0
        }
    }
    
    /// 빠른 금액 추가
    func addQuickAmount(_ amount: Double) {
        let newValue = currentInputValue + amount
        if newValue >= 0 && newValue <= 100_000_000_000 {
            currentInputValue = newValue
        }
    }
    
    /// 음수/양수 토글
    func toggleSign() {
        currentInputValue = -currentInputValue
    }
    
    /// 소수점 추가 (현재 미사용)
    func addDecimalPoint() {
        // 만원 단위이므로 소수점 미사용
    }
}

// SwiftUI Animation import
import SwiftUI

private func withAnimation<Result>(_ animation: Animation? = .default, _ body: () throws -> Result) rethrows -> Result {
    try SwiftUI.withAnimation(animation, body)
}
