//
//  PortfolioEmptyView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  포트폴리오 분석 소개 및 구매 유도 화면
//

import SwiftUI
import StoreKit

/// 포트폴리오 분석 소개 및 구매 유도 화면
/// - 유료 기능 소개
/// - 구매자도 다시 볼 수 있는 팝업으로 사용 가능
struct PortfolioEmptyView: View {
    @Environment(\.appState) private var appState
    
    let onStart: () -> Void
    let isPurchased: Bool
    
    @State private var isPurchasing: Bool = false
    
    init(
        onStart: @escaping () -> Void,
        isPurchased: Bool = false
    ) {
        self.onStart = onStart
        self.isPurchased = isPurchased
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: ExitSpacing.xxl) {
                // Hero 섹션
                heroSection
                
                // 왜 필요한가? 섹션
                whyNeedSection
                
                // 어떻게 작동하나? 섹션
                howItWorksSection
                
                // 무엇을 알 수 있는가? 섹션
                whatYouGetSection
                
                // 가격 및 가치 제안
                valuePropositionSection
                
                Spacer()
                    .frame(height: 10)
            }
            .padding(.top, ExitSpacing.lg)
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: ExitSpacing.lg) {
            // 프리미엄 아이콘
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
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "00D4AA"), Color(hex: "00F5C4")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: Color.Exit.accent.opacity(0.3), radius: 20, x: 0, y: 10)
            }
            
            VStack(spacing: ExitSpacing.sm) {
                HStack(spacing: ExitSpacing.xs) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "FFD700"))
                    
                    Text("프리미엄 기능")
                        .font(.Exit.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: "FFD700"))
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "FFD700"))
                }
                
                Text("포트폴리오 분석")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.Exit.primaryText)
                
                Text("보유 종목을 분석해서\n포트폴리오의 강점과 약점을 알려드려요.")
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // MARK: - Why Need Section
    
    private var whyNeedSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            sectionHeader(icon: "lightbulb.fill", title: "왜 포트폴리오 분석이 필요할까요?")
            
            // 문제 제기 카드
            VStack(alignment: .leading, spacing: ExitSpacing.md) {
                problemCard(
                    emoji: "🤔",
                    title: "종목만 보면 안 돼요",
                    description: "\"삼성전자 좋아요!\" \"애플 사세요!\" 하지만 내 포트폴리오 전체는 어떤가요?"
                )
                
                problemCard(
                    emoji: "📊",
                    title: "숨겨진 위험이 있어요",
                    description: "각 종목은 괜찮아 보여도, 포트폴리오 전체가 한 섹터에 몰려있을 수 있어요. 분산투자가 제대로 되고 있는지 확인이 필요해요."
                )
                
                problemCard(
                    emoji: "🎯",
                    title: "정확한 성과 파악이 어려워요",
                    description: "\"작년에 10% 올랐어요!\" 하지만 변동성은? 위험 대비 수익은? 단순 수익률만으로는 부족해요."
                )
                
                problemCard(
                    emoji: "💡",
                    title: "개선 방향을 모르겠어요",
                    description: "포트폴리오의 강점과 약점, 그리고 구체적인 개선 제안이 필요해요."
                )
            }
            .padding(ExitSpacing.lg)
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        }
        .padding(.horizontal, ExitSpacing.md)
    }
    
    private func problemCard(emoji: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: ExitSpacing.md) {
            Text(emoji)
                .font(.system(size: 32))
            
            VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                Text(title)
                    .font(.Exit.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Text(description)
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    // MARK: - How It Works Section
    
    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            sectionHeader(icon: "gearshape.2.fill", title: "어떻게 작동하나요?")
            
            VStack(alignment: .leading, spacing: ExitSpacing.xl) {
                // 1. 종목 데이터 수집
                VStack(alignment: .leading, spacing: ExitSpacing.md) {
                    stepHeader(number: "1", title: "보유 종목 정보를 입력해요")
                    
                    VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                        Text("보유하고 있는 종목과 비중을 입력하면, 앱이 각 종목의 과거 5년간 가격과 배당 데이터를 자동으로 불러와요.")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                // 2. 포트폴리오 수익률 계산
                VStack(alignment: .leading, spacing: ExitSpacing.md) {
                    stepHeader(number: "2", title: "포트폴리오 전체 수익률을 계산해요")
                    
                    VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                        Text("각 종목의 비중을 고려해서 포트폴리오 전체의 일별 수익률을 계산해요. 마치 여러 종목을 하나의 펀드처럼 합쳐서 보는 거예요.")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // 시각화
                        portfolioCalculationVisualization
                    }
                }
                
                // 3. 지표 계산
                VStack(alignment: .leading, spacing: ExitSpacing.md) {
                    stepHeader(number: "3", title: "금융공학 지표를 계산해요")
                    
                    VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                        Text("포트폴리오 수익률 데이터로부터 다양한 지표를 계산해요:")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                            bulletPoint(text: "CAGR: 연평균 복리 수익률 (가격 + 배당 포함)")
                            bulletPoint(text: "변동성: 수익률의 들쭉날쭉함 정도")
                            bulletPoint(text: "Sharpe Ratio: 위험 대비 수익률")
                            bulletPoint(text: "MDD: 최대 낙폭 (최악의 하락폭)")
                        }
                    }
                }
                
                // 4. 종합 평가
                VStack(alignment: .leading, spacing: ExitSpacing.md) {
                    stepHeader(number: "4", title: "종합 점수와 인사이트를 제공해요")
                    
                    VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                        Text("수익성, 안정성, 효율성을 종합해서 점수를 매기고, 포트폴리오의 강점과 개선이 필요한 부분을 알려드려요.")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(ExitSpacing.lg)
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        }
        .padding(.horizontal, ExitSpacing.md)
    }
    
    private func stepHeader(number: String, title: String) -> some View {
        HStack(spacing: ExitSpacing.sm) {
            Text(number)
                .font(.Exit.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.Exit.accent)
                .clipShape(Circle())
            
            Text(title)
                .font(.Exit.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.Exit.primaryText)
        }
    }
    
    private var portfolioCalculationVisualization: some View {
        VStack(spacing: ExitSpacing.sm) {
            HStack(spacing: ExitSpacing.xs) {
                // 종목 1
                VStack(spacing: 4) {
                    Text("삼성전자")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.secondaryText)
                    Text("40%")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.Exit.accent)
                }
                .padding(.horizontal, ExitSpacing.sm)
                .padding(.vertical, ExitSpacing.xs)
                .background(Color.Exit.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                
                Text("+")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                // 종목 2
                VStack(spacing: 4) {
                    Text("애플")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.secondaryText)
                    Text("30%")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.Exit.accent)
                }
                .padding(.horizontal, ExitSpacing.sm)
                .padding(.vertical, ExitSpacing.xs)
                .background(Color.Exit.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                
                Text("+")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                // 종목 3
                VStack(spacing: 4) {
                    Text("...")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
                
                Image(systemName: "arrow.right")
                    .foregroundStyle(Color.Exit.accent)
                
                // 포트폴리오
                VStack(spacing: 4) {
                    Text("포트폴리오")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.secondaryText)
                    Text("100%")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.Exit.positive)
                }
                .padding(.horizontal, ExitSpacing.sm)
                .padding(.vertical, ExitSpacing.xs)
                .background(Color.Exit.positive.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            Text("각 종목의 비중을 고려해서 하나의 포트폴리오로 합쳐요")
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.tertiaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ExitSpacing.sm)
    }
    
    private func bulletPoint(text: String) -> some View {
        HStack(alignment: .top, spacing: ExitSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.Exit.accent)
            
            Text(text)
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - What You Get Section
    
    private var whatYouGetSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            sectionHeader(icon: "gift.fill", title: "무엇을 알 수 있나요?")
            
            VStack(spacing: ExitSpacing.md) {
                featureCard(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: Color.Exit.positive,
                    title: "수익률 분석",
                    description: "CAGR, 배당 포함 총수익률, 가격 수익률을 정확히 계산해요."
                )
                
                featureCard(
                    icon: "shield.lefthalf.filled",
                    iconColor: Color.Exit.caution,
                    title: "위험 분석",
                    description: "변동성, 최대 낙폭(MDD), Sharpe Ratio로 위험을 정량화해요."
                )
                
                featureCard(
                    icon: "star.fill",
                    iconColor: Color(hex: "FFD700"),
                    title: "종합 점수",
                    description: "수익성(40점) + 안정성(30점) + 효율성(30점) = 총 100점 만점으로 평가해요."
                )
                
                featureCard(
                    icon: "chart.pie.fill",
                    iconColor: Color.Exit.accent,
                    title: "섹터/지역 배분",
                    description: "포트폴리오가 어떤 섹터와 지역에 집중되어 있는지 시각화해요."
                )
                
                featureCard(
                    icon: "lightbulb.fill",
                    iconColor: Color(hex: "FF6B6B"),
                    title: "AI 인사이트",
                    description: "포트폴리오의 강점과 약점, 구체적인 개선 제안을 제공해요."
                )
                
                featureCard(
                    icon: "dollarsign.circle.fill",
                    iconColor: Color(hex: "34C759"),
                    title: "배당 분석",
                    description: "배당률, 배당 성장률, 종목별 배당 기여도를 분석해요."
                )
            }
        }
        .padding(.horizontal, ExitSpacing.md)
    }
    
    private func featureCard(icon: String, iconColor: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: ExitSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: ExitRadius.md)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                Text(title)
                    .font(.Exit.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Text(description)
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(ExitSpacing.md)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
    }
    
    // MARK: - Value Proposition Section
    
    private var valuePropositionSection: some View {
        VStack(spacing: ExitSpacing.lg) {
            // 신뢰도 섹션
            VStack(spacing: ExitSpacing.md) {
                HStack(spacing: ExitSpacing.sm) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.Exit.accent)
                    
                    Text("금융공학에서 검증된 지표")
                        .font(.Exit.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.Exit.primaryText)
                }
                
                Text("CAGR, Sharpe Ratio, MDD 등은 월스트리트와 연기금에서 실제로 사용하는 표준 지표예요. 복잡한 금융공학을 누구나 쉽게 이해할 수 있도록 설명과 함께 제공해요.")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(ExitSpacing.lg)
            .frame(maxWidth: .infinity)
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
            
            // 플로팅 구매 버튼
            floatingPurchaseButton
        }
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // MARK: - Floating Purchase Button
    
    private var floatingPurchaseButton: some View {
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
                            let success = await appState.storeKit.purchasePortfolioAnalysis()
                            isPurchasing = false
                            if success {
                                // PortfolioView의 onChange가 화면 전환 처리
                            }
                        }
                    }
                }
            )
            
            // 복원 버튼 또는 안내 텍스트
            if !isPurchased {
                HStack(spacing: ExitSpacing.md) {
                    Text("한 번 구매로 평생 & 무한 사용")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.primaryText)
                    
                    Button {
                        Task {
                            await appState.storeKit.restorePurchases()
                        }
                    } label: {
                        Text("이전 구매 복원")
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.accent)
                    }
                }
            } else {
                Text("약 3~10초 소요됩니다")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            
            // 에러 메시지
            if let error = appState.storeKit.errorMessage {
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
        } else if let product = appState.storeKit.portfolioAnalysisProduct {
            return "프리미엄 구매 • \(product.displayPrice)"
        } else {
            return "제품 정보 불러오기 실패"
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: ExitSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.Exit.accent)
            
            Text(title)
                .font(.Exit.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.Exit.primaryText)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        
        PortfolioEmptyView(
            onStart: {},
            isPurchased: false
        )
    }
}
