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
    @State private var viewModel = OnboardingViewModel()
    
    var body: some View {
        ZStack {
            // 배경
            Color.Exit.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 진행률 표시
                progressIndicator
                
                // 메인 컨텐츠 (스와이프 비활성화)
                stepContent(for: viewModel.currentStep)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                
                // 하단 버튼
                bottomButton
            }
        }
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
            if step == .assetTypes {
                assetTypeSelection
            } else {
                amountDisplay(for: step)
            }
            
            // 힌트
            if let hint = step.hint {
                Text(hint)
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.tertiaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ExitSpacing.xl)
            }
            
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
            case .assetTypes:
                return 0
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
    
    // MARK: - Asset Type Selection
    
    private var assetTypeSelection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: ExitSpacing.md) {
            ForEach(UserProfile.availableAssetTypes, id: \.self) { type in
                AssetTypeButton(
                    title: type,
                    isSelected: viewModel.selectedAssetTypes.contains(type)
                ) {
                    viewModel.toggleAssetType(type)
                }
            }
        }
        .padding(.horizontal, ExitSpacing.lg)
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
                    viewModel.completeOnboarding(context: modelContext)
                } else {
                    viewModel.goToNextStep()
                }
            } label: {
                Text(viewModel.isLastStep ? "완료하고 시작하기" : "다음")
                    .exitPrimaryButton(isEnabled: viewModel.canProceed)
            }
            .disabled(!viewModel.canProceed)
        }
        .padding(.horizontal, ExitSpacing.lg)
        .padding(.bottom, ExitSpacing.xl)
    }
}

// MARK: - Asset Type Button

private struct AssetTypeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.Exit.body)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.Exit.accent)
                }
            }
            .foregroundStyle(isSelected ? Color.Exit.primaryText : Color.Exit.secondaryText)
            .padding(ExitSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: ExitRadius.md)
                    .fill(isSelected ? Color.Exit.accent.opacity(0.15) : Color.Exit.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ExitRadius.md)
                    .stroke(isSelected ? Color.Exit.accent : Color.Exit.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .modelContainer(for: [UserProfile.self, Scenario.self, MonthlyUpdate.self], inMemory: true)
        .preferredColorScheme(.dark)
}

