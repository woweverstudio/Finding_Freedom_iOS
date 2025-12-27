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
            scrollContent
        }
    }
    
    // MARK: - Scroll Content
    
    private var scrollContent: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: ExitSpacing.lg) {
                    // D-DAY 헤더
                    DDayHeaderCard(
                        result: appState.retirementResult,
                        animationTrigger: appState.dDayAnimationTrigger,
                        showFormulaSheet: $showFormulaSheet
                    )
                    
                    // 진행률 섹션
                    ProgressSectionView(
                        result: appState.retirementResult,
                        progressValue: appState.progressValue,
                        animationTrigger: appState.dDayAnimationTrigger,
                        hideAmounts: Binding(
                            get: { appState.hideAmounts },
                            set: { appState.hideAmounts = $0 }
                        ),
                        showFormulaSheet: $showFormulaSheet
                    )
                    
                    // 상세 계산 카드
                    DetailedCalculationCard(
                        profile: appState.userProfile,
                        result: appState.retirementResult,
                        hideAmounts: appState.hideAmounts
                    )
                    
                    // 포트폴리오 분석 유도 버튼
                    PromptButton(
                        title: "📈 내 수익률을 모르겠다면?",
                        subtitle: "포트폴리오 분석으로 예상 수익률 확인하기",
                        destinationTab: .portfolio
                    )
                    
                    // 자산 성장 차트 (은퇴 전 사용자만)
                    assetGrowthChartIfNeeded
                    
                    // 시뮬레이션 유도 버튼
                    PromptButton(
                        title: "🎲 만약 주식이 떨어지면?",
                        subtitle: "30,000가지 미래로 더 자세히 분석해드려요",
                        destinationTab: .simulation
                    )
                }
                .padding(.vertical, ExitSpacing.lg)
                .id("container")
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y
            } action: { oldValue, newValue in
                handleScrollChange(newValue: newValue, proxy: proxy)
            }
        }
    }
    
    // MARK: - Asset Growth Chart
    
    @ViewBuilder
    private var assetGrowthChartIfNeeded: some View {
        if let result = appState.retirementResult,
           let profile = appState.userProfile,
           !result.isRetirementReady {
            AssetGrowthChart(
                currentAsset: result.currentAssets,
                targetAsset: result.targetAssets,
                monthlyInvestment: profile.monthlyInvestment,
                preRetirementReturnRate: profile.preRetirementReturnRate,
                monthsToRetirement: result.monthsToRetirement,
                animationID: appState.dDayAnimationTrigger
            )
        }
    }
    
    // MARK: - Scroll Handling
    
    private func handleScrollChange(newValue: CGFloat, proxy: ScrollViewProxy) {
        // 위로 당겼을 때 (음수 오프셋) 헤더 확장
        if newValue < pullThreshold && !isHeaderExpanded {
            HapticService.shared.medium()
            
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isHeaderExpanded = true
            }
        }
        
        // expanded 상태에서 아래로 스크롤하면 적용 (닫기)
        if newValue > closeThreshold && isHeaderExpanded {
            proxy.scrollTo("container", anchor: .top)
            HapticService.shared.light()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isHeaderExpanded = false
            }
        }
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
