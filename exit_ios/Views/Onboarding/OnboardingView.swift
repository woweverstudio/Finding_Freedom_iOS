//
//  OnboardingView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI
import SwiftData

/// 온보딩 메인 뷰
struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appState) private var appState
    @State private var viewModel = OnboardingViewModel()
    
    var body: some View {
        ZStack {
            // 배경
            Color.Exit.background
                .ignoresSafeArea()
            
            if viewModel.showWelcome {
                WelcomeView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        viewModel.showWelcome = false
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .leading)))
            } else {
                VStack(spacing: 0) {
                    // 진행률 표시
                    progressIndicator
                    
                    // 메인 컨텐츠 (스와이프 비활성화)
                    stepContent(for: viewModel.currentStep)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                    
                    // 하단 버튼
                    bottomButton
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: viewModel.showWelcome)
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: ExitSpacing.sm) {
            ForEach(OnboardingStep.allCases, id: \.self) { step in
                Capsule()
                    .fill(step.rawValue <= viewModel.currentStep.rawValue ? Color.Exit.accent : Color.Exit.divider)
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
            }
        }
        .padding(.horizontal, ExitSpacing.lg)
        .padding(.top, ExitSpacing.lg)
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private func stepContent(for step: OnboardingStep) -> some View {
        VStack(spacing: ExitSpacing.xl) {
            Spacer()
            
            // 제목
            VStack(spacing: ExitSpacing.sm) {
                Text(step.title)
                    .font(.Exit.title)
                    .foregroundStyle(Color.Exit.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(step.subtitle)
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, ExitSpacing.lg)
            
            // 입력 영역
            amountDisplay(for: step)
            
            Spacer()
            
            // 키보드 (금액 입력 단계만)
            if viewModel.showsNumberKeyboard && step == viewModel.currentStep {
                CustomNumberKeyboard(
                    value: $viewModel.currentInputValue,
                    showNegativeToggle: viewModel.showsNegativeToggle
                )
            }
        }
    }
    
    // MARK: - Amount Display
    
    private func amountDisplay(for step: OnboardingStep) -> some View {
        let value: Double = {
            switch step {
            case .desiredIncome:
                return viewModel.desiredMonthlyIncome
            case .currentAssets:
                return viewModel.currentNetAssets
            case .monthlyInvestment:
                return viewModel.monthlyInvestment
            }
        }()
        
        return VStack(spacing: ExitSpacing.sm) {
            Text(ExitNumberFormatter.formatInputDisplay(abs(value)))
                .font(.Exit.numberDisplay)
                .foregroundStyle(value < 0 ? Color.Exit.warning : Color.Exit.primaryText)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.15), value: value)
            
            Text(ExitNumberFormatter.formatToEokManWon(value))
                .font(.Exit.title3)
                .foregroundStyle(Color.Exit.accent)
        }
    }
    
    // MARK: - Bottom Buttons
    
    private var bottomButton: some View {
        HStack(spacing: ExitSpacing.md) {
            // 이전 버튼 (1스텝에서는 숨김)
            if viewModel.currentStep.rawValue > 0 {
                Button {
                    viewModel.goToPreviousStep()
                } label: {
                    Text("이전")
                        .exitSecondaryButton()
                }
            }
            
            // 다음/완료 버튼
            Button {
                if viewModel.isLastStep {
                    appState.resetToHomeTab() // 탭을 홈으로 초기화
                    viewModel.completeOnboarding(context: modelContext)
                } else {
                    viewModel.goToNextStep()
                }
            } label: {
                Text(viewModel.isLastStep ? "시작하기" : "다음")
                    .exitPrimaryButton(isEnabled: viewModel.canProceed)
            }
            .disabled(!viewModel.canProceed)
        }
        .padding(.horizontal, ExitSpacing.md)
        .padding(.bottom, ExitSpacing.xl)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .modelContainer(for: [UserProfile.self, MonthlyUpdate.self], inMemory: true)
        .preferredColorScheme(.dark)
}
