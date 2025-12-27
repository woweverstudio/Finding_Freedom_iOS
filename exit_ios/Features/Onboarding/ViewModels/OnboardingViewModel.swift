//
//  OnboardingViewModel.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import Foundation
import SwiftData
import Observation

/// 투자 상태
enum InvestmentStatus: Int, CaseIterable {
    case none = 0           // 투자안함 - 0%
    case savings = 1        // 예적금 - 2%
    case stockBeginner = 2  // 주식을 하지만 잘 모름 - 5%
    case ownPortfolio = 3   // 나만의 포트폴리오 - 10%
    
    var returnRate: Double {
        switch self {
        case .none:
            return 0.0
        case .savings:
            return 2.0
        case .stockBeginner:
            return 5.0
        case .ownPortfolio:
            return 10.0
        }
    }
    
    var title: String {
        switch self {
        case .none:
            return "투자 안 함"
        case .savings:
            return "예적금"
        case .stockBeginner:
            return "주식을 하지만 잘 모름"
        case .ownPortfolio:
            return "나만의 주식 포트폴리오가 있음"
        }
    }
    
    var description: String {
        switch self {
        case .none:
            return "현금으로만 보유"
        case .savings:
            return "은행 예금, 적금 위주"
        case .stockBeginner:
            return "주식 투자 경험은 있지만 확신이 없음"
        case .ownPortfolio:
            return "나만의 투자 전략이 있음"
        }
    }
}

/// 온보딩 단계
enum OnboardingStep: Int, CaseIterable {
    case desiredIncome = 0      // 희망 월 수입
    case currentAssets = 1      // 현재 순자산
    case monthlyInvestment = 2  // 월 투자 금액
    case investmentStatus = 3   // 현재 투자 상태
    
    var title: String {
        switch self {
        case .desiredIncome:
            return "은퇴 후 희망 수입"
        case .currentAssets:
            return "현재 순자산"
        case .monthlyInvestment:
            return "월 평균 저축·투자 금액"
        case .investmentStatus:
            return "현재 투자 상태"
        }
    }
    
    var subtitle: String {
        switch self {
        case .desiredIncome:
            return "매달 얼마가 있으면 일 안 해도 될까요?"
        case .currentAssets:
            return "투자 가능한 자산만 입력해주세요"
        case .monthlyInvestment:
            return "월급 등 근로 소득만 포함"
        case .investmentStatus:
            return "현재 투자 방식을 선택해주세요"
        }
    }
    
    var defaultValue: Double {
        switch self {
        case .desiredIncome:
            return 3_000_000  // 300만원
        case .currentAssets:
            return 0
        case .monthlyInvestment:
            return 0
        case .investmentStatus:
            return 0
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
    var monthlyInvestment: Double = 0
    
    /// 선택된 투자 상태
    var selectedInvestmentStatus: InvestmentStatus? = nil
    
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
            case .investmentStatus:
                return 0
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
            case .investmentStatus:
                break
            }
        }
    }
    
    /// 음수/양수 토글 표시 여부
    var showsNegativeToggle: Bool {
        currentStep == .currentAssets
    }
    
    /// 숫자 키보드 표시 여부
    var showsNumberKeyboard: Bool {
        currentStep != .investmentStatus
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
        case .investmentStatus:
            return selectedInvestmentStatus != nil
        }
    }
    
    /// 마지막 단계 여부
    var isLastStep: Bool {
        currentStep == .investmentStatus
    }
    
    /// 진행률 (0~1)
    var progress: Double {
        Double(currentStep.rawValue + 1) / Double(OnboardingStep.allCases.count)
    }
    
    // MARK: - Actions
    
    /// 투자 상태 선택
    func selectInvestmentStatus(_ status: InvestmentStatus) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedInvestmentStatus = status
        }
    }
    
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
        // 선택된 투자 상태에 따른 수익률 설정
        let returnRate = selectedInvestmentStatus?.returnRate ?? 6.5
        
        // UserProfile 저장
        let profile = UserProfile(
            desiredMonthlyIncome: desiredMonthlyIncome,
            currentNetAssets: currentNetAssets,
            monthlyInvestment: monthlyInvestment,
            preRetirementReturnRate: returnRate
        )
        context.insert(profile)
        
        try? context.save()
        
        withAnimation {
            isCompleted = true
        }
    }
    
    /// 값 초기화 (현재 단계)
    func resetCurrentValue() {
        if currentStep == .investmentStatus {
            selectedInvestmentStatus = nil
        } else {
            currentInputValue = currentStep.defaultValue
        }
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
