//
//  PortfolioPromotionView.swift
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
        case .whyNeed: return "개별 종목만 보면 놓치는 것들이 있어요"
        case .howItWorks: return "포트폴리오 전체를 하나로 분석해요"
        case .whatYouGet: return "금융공학 기반의 정밀한 분석 결과"
        case .purchase: return "지금 바로 포트폴리오를 점검해보세요"
        }
    }
}

/// 포트폴리오 분석 소개 및 구매 유도 화면
struct PortfolioPromotionView: View {
    @Environment(\.appState) private var appState
    @Environment(\.storeService) private var storeService
    
    let onStart: () -> Void
    let isPurchased: Bool
    
    @State private var currentStep: PromotionStep = .whyNeed
    @State private var isPurchasing: Bool = false
    
    init(
        onStart: @escaping () -> Void,
        isPurchased: Bool = false
    ) {
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
                    .multilineTextAlignment(.center)
                
                Text(currentStep.subtitle)
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.secondaryText)
                    .multilineTextAlignment(.center)
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
    
    // MARK: - Step 1: Why Need
    
    private var step1Content: some View {
        HStack(spacing: ExitSpacing.lg) {
            // 개별 종목
            VStack(spacing: ExitSpacing.md) {
                RoundedRectangle(cornerRadius: ExitRadius.md)
                    .fill(Color.Exit.cardBackground)
                    .frame(width: 120, height: 80)
                    .overlay {
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.Exit.secondaryText.opacity(0.5))
                                .frame(width: 20, height: 40)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.Exit.secondaryText.opacity(0.7))
                                .frame(width: 20, height: 50)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.Exit.secondaryText.opacity(0.6))
                                .frame(width: 20, height: 35)
                        }
                    }
                
                Text("개별 종목")
                    .font(.Exit.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            
            Image(systemName: "arrow.right")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.Exit.accent)
            
            // 포트폴리오 전체
            VStack(spacing: ExitSpacing.md) {
                RoundedRectangle(cornerRadius: ExitRadius.md)
                    .fill(Color.Exit.accent.opacity(0.15))
                    .frame(width: 120, height: 80)
                    .overlay {
                        ZStack {
                            Circle()
                                .trim(from: 0, to: 0.4)
                                .stroke(Color.Exit.accent, lineWidth: 12)
                                .frame(width: 50, height: 50)
                            Circle()
                                .trim(from: 0.4, to: 0.7)
                                .stroke(Color.Exit.positive, lineWidth: 12)
                                .frame(width: 50, height: 50)
                            Circle()
                                .trim(from: 0.7, to: 1.0)
                                .stroke(Color.Exit.caution, lineWidth: 12)
                                .frame(width: 50, height: 50)
                        }
                        .rotationEffect(.degrees(-90))
                    }
                
                Text("포트폴리오 전체")
                    .font(.Exit.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.Exit.accent)
            }
        }
    }
    
    // MARK: - Step 2: How It Works
    
    private var step2Content: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            stepRow(number: "1", text: "보유 종목과 비중을 입력")
            stepRow(number: "2", text: "5년간 가격/배당 데이터 자동 수집")
            stepRow(number: "3", text: "금융공학 지표로 종합 평가")
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
    
    // MARK: - Step 3: What You Get
    
    private var step3Content: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            featureItem(number: "1", title: "수익률 분석", description: "CAGR, 총수익률")
            featureItem(number: "2", title: "위험 분석", description: "변동성, MDD, Sharpe")
            featureItem(number: "3", title: "종합 점수", description: "100점 만점 평가")
            featureItem(number: "4", title: "배분 현황", description: "섹터/지역 시각화")
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
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.Exit.accent)
                    )
                    .shadow(color: Color.Exit.accent.opacity(0.3), radius: 20, x: 0, y: 10)
            }
            
            Text("포트폴리오 분석")
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
                icon: isPurchased ? "chart.pie.fill" : "sparkles",
                isLoading: isPurchasing,
                action: {
                    if isPurchased {
                        onStart()
                    } else {
                        Task {
                            isPurchasing = true
                            let success = await storeService.purchasePortfolioAnalysis()
                            isPurchasing = false
                            if success {
                                // PortfolioView의 onChange가 화면 전환 처리
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
            return "포트폴리오 분석 시작"
        } else if let product = storeService.portfolioAnalysisProduct {
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
        
        PortfolioPromotionView(
            onStart: {},
            isPurchased: false
        )
    }
}
