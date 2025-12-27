//
//  SimulationPromotionView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI
import StoreKit

// MARK: - Step Enum

private enum PromotionStep: Int, CaseIterable {
    case whyNeed = 0
    case howItWorks = 1
    case whatYouGet = 2
    case purchase = 3
    
    var title: String {
        switch self {
        case .whyNeed: return "왜 필요할까요?"
        case .howItWorks: return "어떻게 작동하나요?"
        case .whatYouGet: return "무엇을 알 수 있나요?"
        case .purchase: return "시작할 준비가 되셨나요?"
        }
    }
    
    var subtitle: String {
        switch self {
        case .whyNeed: return "단순 계산으로는 알 수 없는 것들이 있어요"
        case .howItWorks: return "30,000가지 미래를 만들어 분석해요"
        case .whatYouGet: return "확률 기반의 현실적인 분석 결과"
        case .purchase: return "지금 바로 당신의 은퇴 계획을 분석해보세요"
        }
    }
}

/// 몬테카를로 시뮬레이션 소개 및 구매 유도 화면
struct SimulationPromotionView: View {
    @Environment(\.appState) private var appState
    @Environment(\.storeService) private var storeService
    
    let userProfile: UserProfile?
    let currentAssetAmount: Double
    let onStart: () -> Void
    let isPurchased: Bool
    
    @State private var currentStep: PromotionStep = .whyNeed
    @State private var isPurchasing: Bool = false
    
    init(
        userProfile: UserProfile?,
        currentAssetAmount: Double,
        onStart: @escaping () -> Void,
        isPurchased: Bool = false
    ) {
        self.userProfile = userProfile
        self.currentAssetAmount = currentAssetAmount
        self.onStart = onStart
        self.isPurchased = isPurchased
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단: 스텝 인디케이터
            progressIndicator
                .padding(.horizontal, ExitSpacing.lg)
                .padding(.top, ExitSpacing.lg)
            
            // 컨텐츠 영역
            stepContent
                .padding(.horizontal, ExitSpacing.lg)
                .padding(.top, ExitSpacing.xxl)
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            
            // 하단: 네비게이션 버튼
            navigationButtons
                .padding(.horizontal, ExitSpacing.md)
                .padding(.bottom, ExitSpacing.xl)
        }
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: ExitSpacing.sm) {
            ForEach(PromotionStep.allCases, id: \.self) { step in
                Capsule()
                    .fill(step.rawValue <= currentStep.rawValue ? Color.Exit.accent : Color.Exit.divider)
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        VStack(spacing: ExitSpacing.xl) {
            // 타이틀
            VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                Text(currentStep.title)
                    .font(.Exit.title)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Text(currentStep.subtitle)
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 스텝별 컨텐츠
            Group {
                switch currentStep {
                case .whyNeed:
                    step1Content
                case .howItWorks:
                    step2Content
                case .whatYouGet:
                    step3Content
                case .purchase:
                    step4Content
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            
            Spacer()
        }
    }
    
    // MARK: - Step 1: Why Need (단순화)
    
    private var step1Content: some View {
        HStack(spacing: ExitSpacing.lg) {
            // 단순 계산
            VStack(spacing: ExitSpacing.md) {
                RoundedRectangle(cornerRadius: ExitRadius.md)
                    .fill(Color.Exit.cardBackground)
                    .frame(width: 120, height: 80)
                    .overlay {
                        Path { path in
                            path.move(to: CGPoint(x: 15, y: 60))
                            path.addLine(to: CGPoint(x: 105, y: 20))
                        }
                        .stroke(Color.Exit.secondaryText, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    }
                
                Text("단순 계산")
                    .font(.Exit.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            
            Image(systemName: "arrow.right")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.Exit.accent)
            
            // 시뮬레이션
            VStack(spacing: ExitSpacing.md) {
                RoundedRectangle(cornerRadius: ExitRadius.md)
                    .fill(Color.Exit.accent.opacity(0.15))
                    .frame(width: 120, height: 80)
                    .overlay {
                        Path { path in
                            path.move(to: CGPoint(x: 15, y: 55))
                            path.addCurve(
                                to: CGPoint(x: 105, y: 20),
                                control1: CGPoint(x: 40, y: 70),
                                control2: CGPoint(x: 75, y: 10)
                            )
                        }
                        .stroke(Color.Exit.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    }
                
                Text("실제 주식 움직임")
                    .font(.Exit.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.Exit.accent)
            }
        }
    }
    
    // MARK: - Step 2: How It Works (단순화)
    
    private var step2Content: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            stepRow(number: "1", text: "무작위 수익률로 미래를 예측")
            stepRow(number: "2", text: "30,000번 반복으로 신뢰도 확보")
            stepRow(number: "3", text: "행운 / 평균 / 불운 3가지 시나리오 제공")
        }
        .padding(ExitSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
    }
    
    private func stepRow(number: String, text: String) -> some View {
        HStack(spacing: ExitSpacing.md) {
            Text(number)
                .font(.Exit.body)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.Exit.accent)
                .clipShape(Circle())
            
            Text(text)
                .font(.Exit.body)
                .foregroundStyle(Color.Exit.primaryText)
        }
    }
    
    // MARK: - Step 3: What You Get (단순화 - 숫자 리스트)
    
    private var step3Content: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            featureItem(number: "1", title: "성공 확률", description: "목표 달성 가능성")
            featureItem(number: "2", title: "자산 변화 예측", description: "3가지 시나리오")
            featureItem(number: "3", title: "달성 시점 분포", description: "예상 소요 기간")
            featureItem(number: "4", title: "은퇴 후 40년 분석", description: "장기 자산 예측")
        }
        .padding(ExitSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
    }
    
    private func featureItem(number: String, title: String, description: String) -> some View {
        HStack(spacing: ExitSpacing.md) {
            Text(number)
                .font(.Exit.body)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.Exit.accent)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.Exit.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Text(description)
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
        }
    }
    
    // MARK: - Step 4: Purchase
    
    private var step4Content: some View {
        VStack(spacing: ExitSpacing.xl) {
            // Hero 아이콘
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.Exit.accent.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Circle()
                    .fill(Color.Exit.cardBackground)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.Exit.accent)
                    )
                    .shadow(color: Color.Exit.accent.opacity(0.3), radius: 20, x: 0, y: 10)
            }
            
            Text("몬테카를로 시뮬레이션")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.Exit.primaryText)
            
            // 구매 버튼
            purchaseSection
        }
        .padding(.horizontal, ExitSpacing.md)
    }
    
    private var purchaseSection: some View {
        VStack(spacing: ExitSpacing.sm) {
            ExitCTAButton(
                title: purchaseButtonTitle,
                icon: isPurchased ? "play.fill" : "sparkles",
                isLoading: isPurchasing,
                action: {
                    if isPurchased {
                        onStart()
                    } else {
                        Task {
                            isPurchasing = true
                            let success = await storeService.purchaseMontecarloSimulation()
                            isPurchasing = false
                            if success {
                                // SimulationView의 onChange가 화면 전환 처리
                            }
                        }
                    }
                }
            )
            
            if !isPurchased {
                HStack(spacing: ExitSpacing.md) {
                    Text("한 번 구매로 평생 사용")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    Button {
                        Task {
                            await storeService.restorePurchases()
                        }
                    } label: {
                        Text("구매 복원")
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.accent)
                    }
                }
            } else {
                Text("약 3~10초 소요됩니다")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            
            if let error = storeService.errorMessage {
                Text(error)
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.warning)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var purchaseButtonTitle: String {
        if isPurchasing {
            return "구매 중..."
        } else if isPurchased {
            return "시뮬레이션 시작"
        } else if let product = storeService.montecarloProduct {
            return "프리미엄 구매 • \(product.displayPrice)"
        } else {
            return "제품 정보 불러오기 실패"
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: ExitSpacing.md) {
            if currentStep.rawValue > 0 {
                ExitButton(
                    title: "이전",
                    style: .secondary,
                    size: .large,
                    action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if let prevStep = PromotionStep(rawValue: currentStep.rawValue - 1) {
                                currentStep = prevStep
                            }
                        }
                    }
                )
            }
            
            if currentStep != .purchase {
                ExitButton(
                    title: "다음",
                    style: .primary,
                    size: .large,
                    action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if let nextStep = PromotionStep(rawValue: currentStep.rawValue + 1) {
                                currentStep = nextStep
                            }
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        
        SimulationPromotionView(
            userProfile: nil,
            currentAssetAmount: 50_000_000,
            onStart: {},
            isPurchased: false
        )
    }
}
