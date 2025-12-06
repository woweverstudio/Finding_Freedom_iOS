//
//  DashboardView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 대시보드 탭 (메인 홈 화면)
struct DashboardView: View {
    @Environment(\.appState) private var appState
    @State private var showFormulaSheet = false
    @State private var isHeaderExpanded = false
    
    /// Pull-to-expand 트리거 임계값 (음수 = 위로 당김)
    private let pullThreshold: CGFloat = -60
    /// Pull-to-close 트리거 임계값 (양수 = 아래로 스크롤)
    private let closeThreshold: CGFloat = 80
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 헤더 (탭하면 인라인 편집 패널 펼쳐짐)
            PlanHeaderView(hideAmounts: appState.hideAmounts, isExpanded: $isHeaderExpanded)
            
            // 스크롤 컨텐츠
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ExitSpacing.lg) {
                        // D-DAY 헤더
                        dDayHeader
                        
                        // 진행률 섹션
                        progressSection
                        
                        // 조정 안내 (10년 이상 남았을 때만 표시)
                        adjustmentHintCard
                        
                        // 계산방법 보기 버튼
                        calculateFormulaButton
                    }
                    .padding(.vertical, ExitSpacing.lg)
                    .id("container")
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { oldValue, newValue in
                    // 위로 당겼을 때 (음수 오프셋) 헤더 확장
                    if newValue < pullThreshold && !isHeaderExpanded {
                        HapticService.shared.medium()
                        
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isHeaderExpanded = true
                        }
                    }
                    
                    // expanded 상태에서 아래로 스크롤하면 적용 (닫기)
                    // PlanHeaderView의 onChange에서 자동으로 설정이 적용됨
                    if newValue > closeThreshold && isHeaderExpanded {
                        proxy.scrollTo("container", anchor: .top)
                        HapticService.shared.light()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isHeaderExpanded = false
                            
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - D-DAY Header
    
    private var dDayHeader: some View {
        VStack(spacing: ExitSpacing.md) {
            dDayMainTitle
        }
        .padding(.vertical, ExitSpacing.lg)
        .padding(.horizontal, ExitSpacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: ExitRadius.xl)
                .fill(LinearGradient.exitCard)
                .exitCardShadow()
        )
        .padding(.horizontal, ExitSpacing.md)
    }
    
    private var dDayMainTitle: some View {
        Group {
            if let result = appState.retirementResult {
                if result.isRetirementReady {
                    // 이미 은퇴 가능한 경우
                    retirementReadyView(result: result)
                } else {
                    VStack(spacing: ExitSpacing.sm) {
                        Text("회사 탈출까지")
                            .font(.Exit.body)
                            .foregroundStyle(Color.Exit.secondaryText)
                        
                        // 파친코 스타일 롤링 애니메이션
                        DDayRollingView(
                            months: result.monthsToRetirement,
                            animationID: appState.dDayAnimationTrigger
                        )
                        
                        Text("남았습니다.")
                            .font(.Exit.body)
                            .foregroundStyle(Color.Exit.secondaryText)
                    }
                }
            } else {
                Text("계산 중...")
                    .font(.Exit.title2)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
        }
    }
    
    /// 은퇴 가능 상태 뷰
    private func retirementReadyView(result: RetirementCalculationResult) -> some View {
        VStack(spacing: ExitSpacing.md) {
            Text("🎉")
                .font(.system(size: 40))
            
            Text("은퇴 가능합니다!")
                .font(.Exit.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.Exit.accent)
            
            if let requiredRate = result.requiredReturnRate {
                VStack(spacing: ExitSpacing.xs) {
                    Text("필요 수익률")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    Text(String(format: "연 %.2f%%", requiredRate))
                        .font(.Exit.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(requiredRate < 4 ? Color.Exit.positive : Color.Exit.accent)
                }
            }
        }
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: ExitSpacing.lg) {
            // 진행률 링 차트 + 토글 버튼
            if let result = appState.retirementResult {
                ZStack(alignment: .bottom) {
                    ProgressRingView(
                        progress: appState.progressValue,
                        currentAmount: ExitNumberFormatter.formatToEokManWon(result.currentAssets),
                        targetAmount: ExitNumberFormatter.formatToEokManWon(result.targetAssets),
                        percentText: ExitNumberFormatter.formatPercentInt(result.progressPercent),
                        hideAmounts: appState.hideAmounts,
                        animationID: appState.dDayAnimationTrigger
                    )
                    .frame(width: 200, height: 200)
                    
                    HStack {
                        Spacer()
                        // 금액 숨김 토글 (우측 하단)
                        amountVisibilityToggle
                    }
                }
            }
            
            // 상세 계산 설명
            detailedCalculationCard
        }
        .padding(.horizontal, ExitSpacing.md)
        .sheet(isPresented: $showFormulaSheet) {
            CalculationFormulaSheet()
        }
    }
    
    // MARK: - Adjustment Hint Card
    
    @ViewBuilder
    private var adjustmentHintCard: some View {
        // 10년(120개월) 이상 남았을 때만 표시
        if let result = appState.retirementResult, result.monthsToRetirement >= 120 {
            HStack(spacing: ExitSpacing.md) {
                // 아이콘
                ZStack {
                    Circle()
                        .fill(Color.Exit.accent.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.Exit.accent)
                }
                
                // 텍스트
                VStack(alignment: .leading, spacing: 2) {
                    Text("시간을 앞당길 수 있어요!")
                        .font(.Exit.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.Exit.primaryText)
                    
                    Text("위로 당기거나 상단을 눌러 설정을 조정해보세요")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
                
                Spacer()
            }
            .padding(ExitSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: ExitRadius.lg)
                    .fill(Color.Exit.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: ExitRadius.lg)
                            .stroke(Color.Exit.accent.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, ExitSpacing.md)
        }
    }
    
    // MARK: - Amount Visibility Toggle
    
    private var amountVisibilityToggle: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                appState.hideAmounts.toggle()
            }
        } label: {
            Text(appState.hideAmounts ? "금액 보기" : "금액 숨김")
                .font(.Exit.caption2)
                .fontWeight(.medium)
                .foregroundStyle(appState.hideAmounts ? Color.Exit.accent : Color.Exit.tertiaryText)
                .padding(.horizontal, ExitSpacing.md)
                .padding(.vertical, ExitSpacing.sm)
                .background(
                    Capsule()
                        .fill(Color.Exit.cardBackground)
                        .overlay(
                            Capsule()
                                .stroke(appState.hideAmounts ? Color.Exit.accent : Color.Exit.divider, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
    
    private var detailedCalculationCard: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            if let profile = appState.userProfile, let result = appState.retirementResult {
                // 현재 자산 / 목표 자산 (1줄 유지, 자동 축소)
                AssetProgressRow(
                    currentAssets: ExitNumberFormatter.formatToEokManWon(result.currentAssets),
                    targetAssets: ExitNumberFormatter.formatToEokManWon(result.targetAssets),
                    percent: ExitNumberFormatter.formatPercentInt(result.progressPercent),
                    isHidden: appState.hideAmounts
                )
                
                Divider()
                    .background(Color.Exit.divider)
                
                // 설명 텍스트
                if result.isRetirementReady, let requiredRate = result.requiredReturnRate {
                    // 은퇴 가능: 필요 수익률 역산 결과 표시
                    VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                        HStack(spacing: 0) {
                            Text("현재 자산 ")
                                .foregroundStyle(Color.Exit.secondaryText)
                            Text(ExitNumberFormatter.formatToEokManWon(result.currentAssets))
                                .foregroundStyle(Color.Exit.accent)
                                .fontWeight(.semibold)
                                .blur(radius: appState.hideAmounts ? 5 : 0)
                            Text("으로")
                                .foregroundStyle(Color.Exit.secondaryText)
                        }
                        .font(.Exit.subheadline)
                        
                        HStack(spacing: 0) {
                            Text("매월 ")
                                .foregroundStyle(Color.Exit.secondaryText)
                            Text(ExitNumberFormatter.formatToManWon(profile.desiredMonthlyIncome))
                                .foregroundStyle(Color.Exit.accent)
                                .fontWeight(.semibold)
                            Text(" 현금흐름을 만들려면")
                                .foregroundStyle(Color.Exit.secondaryText)
                        }
                        .font(.Exit.subheadline)
                        
                        HStack(spacing: 0) {
                            Text("연 ")
                                .foregroundStyle(Color.Exit.secondaryText)
                            Text(String(format: "%.2f%%", requiredRate))
                                .foregroundStyle(requiredRate < 4 ? Color.Exit.positive : Color.Exit.accent)
                                .fontWeight(.bold)
                            Text(" 수익률만 달성하면 됩니다")
                                .foregroundStyle(Color.Exit.secondaryText)
                        }
                        .font(.Exit.subheadline)
                        
                        // 수익률 수준 코멘트
                        if requiredRate < 3 {
                            requiredRateComment("매우 안정적인 수익률입니다 (예금/채권 수준)", color: Color.Exit.positive)
                        } else if requiredRate < 5 {
                            requiredRateComment("안정적인 수익률입니다 (배당주/채권 수준)", color: Color.Exit.positive)
                        } else if requiredRate < 7 {
                            requiredRateComment("합리적인 수익률입니다 (인덱스펀드 수준)", color: Color.Exit.accent)
                        } else {
                            requiredRateComment("다소 높은 수익률이 필요합니다", color: Color.Exit.caution)
                        }
                    }
                } else if result.monthsToRetirement > 0 {
                    VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                        HStack(spacing: 0) {
                            Text("매월 ")
                                .foregroundStyle(Color.Exit.secondaryText)
                            Text(ExitNumberFormatter.formatToManWon(profile.desiredMonthlyIncome))
                                .foregroundStyle(Color.Exit.accent)
                                .fontWeight(.semibold)
                            Text("의 현금흐름을 만들기 위해")
                                .foregroundStyle(Color.Exit.secondaryText)
                        }
                        .font(.Exit.subheadline)
                        
                        HStack(spacing: 0) {
                            Text("매월 ")
                                .foregroundStyle(Color.Exit.secondaryText)
                            Text(ExitNumberFormatter.formatToManWon(profile.monthlyInvestment))
                                .foregroundStyle(Color.Exit.accent)
                                .fontWeight(.semibold)
                            Text("씩 연복리 ")
                                .foregroundStyle(Color.Exit.secondaryText)
                            Text(String(format: "%.1f%%", profile.preRetirementReturnRate))
                                .foregroundStyle(Color.Exit.accent)
                                .fontWeight(.semibold)
                            Text("로 투자하면")
                                .foregroundStyle(Color.Exit.secondaryText)
                        }
                        .font(.Exit.subheadline)
                        
                        HStack(spacing: 0) {
                            Text(result.dDayString)
                                .foregroundStyle(Color.Exit.accent)
                                .fontWeight(.bold)
                            Text(" 남았습니다.")
                                .font(.Exit.subheadline)
                                .foregroundStyle(Color.Exit.secondaryText)
                        }
                    }
                }
            }
        }
        .padding(ExitSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
    }
    
    /// 필요 수익률 코멘트
    private func requiredRateComment(_ text: String, color: Color) -> some View {
        HStack(spacing: ExitSpacing.xs) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(color)
            
            Text(text)
                .font(.Exit.caption)
                .foregroundStyle(color)
        }
        .padding(.top, ExitSpacing.xs)
    }
    
    private var calculateFormulaButton: some View {
        // 계산방법 보기 버튼
        Button {
            showFormulaSheet = true
        } label: {
            Text("계산방법 보기")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.tertiaryText)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        DashboardView()
    }
    .preferredColorScheme(.dark)
    .environment(\.appState, AppStateManager())
}
