//
//  SimulationMainView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI
import SwiftData
import StoreKit

/// 시뮬레이션 메인 뷰 - 구매자/체험 완료자의 Entry Point
struct SimulationMainView: View {
    @Environment(\.storeService) private var storeService
    @Query private var userProfiles: [UserProfile]
    
    let hasResult: Bool
    let isTrialMode: Bool  // 체험 모드 여부 (미구매 + 체험 안함)
    let onStart: () -> Void
    let onViewResult: () -> Void
    
    /// 체험 사용 여부 (DB에서 직접 확인)
    private var hasUsedTrial: Bool {
        userProfiles.first?.hasUsedSimulationTrial ?? false
    }
    
    /// 시작 버튼을 표시할지 여부
    /// - 구매 완료: true
    /// - 미구매 + 체험 안함 (isTrialMode이고 아직 체험 미사용): true
    /// - 미구매 + 체험 완료: false (구매 버튼 표시)
    private var canStart: Bool {
        storeService.hasMontecarloSimulation || (isTrialMode && !hasUsedTrial)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: ExitSpacing.xxl) {
                    // Hero 섹션
                    heroSection
                    
                    // 기능 소개 섹션
                    featuresSection
                    
                    Spacer(minLength: ExitSpacing.xxl)
                }
                .padding(.top, ExitSpacing.xxl)
            }
            
            // 하단 버튼 영역
            actionButtons
        }
        .background(Color.Exit.background)
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: ExitSpacing.xl) {
            // 아이콘
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.Exit.accent.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                
                Circle()
                    .fill(Color.Exit.cardBackground)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 52))
                            .foregroundStyle(Color.Exit.accent)
                    )
                    .shadow(color: Color.Exit.accent.opacity(0.3), radius: 24, x: 0, y: 12)
            }
            
            // 타이틀
            VStack(spacing: ExitSpacing.sm) {
                Text("몬테카를로 시뮬레이션")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.Exit.primaryText)
                
                Text("30,000가지 미래를 분석합니다")
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
        }
        .padding(.horizontal, ExitSpacing.lg)
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(spacing: ExitSpacing.md) {
            featureRow(
                icon: "percent",
                title: "성공 확률",
                description: "목표 달성 가능성을 퍼센트로 확인"
            )
            
            featureRow(
                icon: "chart.xyaxis.line",
                title: "자산 변화 예측",
                description: "행운 / 평균 / 불운 3가지 시나리오"
            )
            
            featureRow(
                icon: "calendar",
                title: "달성 시점 분포",
                description: "예상 소요 기간을 분포로 확인"
            )
            
            featureRow(
                icon: "chart.line.downtrend.xyaxis",
                title: "은퇴 후 40년 분석",
                description: "장기 자산 변화 시뮬레이션"
            )
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.xl))
        .padding(.horizontal, ExitSpacing.lg)
    }
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: ExitSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.Exit.accent)
                .frame(width: 40, height: 40)
                .background(Color.Exit.accent.opacity(0.12))
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
            
            Spacer()
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: ExitSpacing.sm) {
            if canStart {
                // 구매 완료 또는 체험 가능: 시작 버튼
                ExitCTAButton(
                    title: storeService.hasMontecarloSimulation ? "시뮬레이션 시작" : "무료 체험 시작",
                    icon: "play.fill",
                    action: onStart
                )
                
                // 이전 결과가 있으면 결과 보기 버튼 추가 (구매 완료일 때만)
                if hasResult && storeService.hasMontecarloSimulation {
                    ExitButton(
                        title: "이전 결과 보기",
                        icon: "clock.arrow.circlepath",
                        style: .secondary,
                        size: .large,
                        action: onViewResult
                    )
                }
            } else {
                // 체험 완료 + 미구매: 구매 버튼
                ExitCTAButton(
                    title: purchaseButtonTitle,
                    icon: "sparkles",
                    action: {
                        Task {
                            await storeService.purchaseMontecarloSimulation()
                        }
                    }
                )
                
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
            }
        }
        .padding(.horizontal, ExitSpacing.md)
        .padding(.bottom, ExitSpacing.lg)
        .padding(.top, ExitSpacing.md)
        .background(Color.Exit.background)
    }
    
    private var purchaseButtonTitle: String {
        if let product = storeService.montecarloProduct {
            return "프리미엄 구매 • \(product.displayPrice)"
        } else {
            return "프리미엄 구매"
        }
    }
}

// MARK: - Preview

#Preview {
    SimulationMainView(
        hasResult: true,
        isTrialMode: false,
        onStart: {},
        onViewResult: {}
    )
}

