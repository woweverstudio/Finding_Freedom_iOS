//
//  SimulationEmptyView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI
import Charts

/// 몬테카를로 시뮬레이션 소개 및 구매 유도 화면
/// - 유료 기능 소개
/// - 구매자도 다시 볼 수 있는 팝업으로 사용 가능
struct SimulationEmptyView: View {
    let scenario: Scenario?
    let currentAssetAmount: Double
    let onStart: () -> Void
    let isPurchased: Bool
    
    @State private var animateDemo: Bool = false
    
    init(
        scenario: Scenario?,
        currentAssetAmount: Double,
        onStart: @escaping () -> Void,
        isPurchased: Bool = false
    ) {
        self.scenario = scenario
        self.currentAssetAmount = currentAssetAmount
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
                
                // 데모 카드들 (실제 UI와 동일)
                demoCardsSection
                
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
                        Image(systemName: "chart.line.uptrend.xyaxis")
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
                
                Text("몬테카를로 시뮬레이션")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.Exit.primaryText)
                
                Text("30,000가지 미래를 만들어\n당신의 은퇴계획을 분석해드려요.")
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
            sectionHeader(icon: "lightbulb.fill", title: "왜 이 시뮬레이션이 필요할까요?")
            
            // 문제 제기 카드
            VStack(alignment: .leading, spacing: ExitSpacing.md) {
                problemCard(
                    emoji: "🤔",
                    title: "단순 계산의 함정",
                    description: "\"매년 7% 수익이면 10년 후 2억!\" 이런 계산 많이 보셨죠? 하지만 현실은 달라요."
                )
                
                // 시각적 비교
                comparisonView
                
                problemCard(
                    emoji: "📉",
                    title: "실제 주식 시장은?",
                    description: "어떤 해는 +30%, 어떤 해는 -20%... 들쭉날쭉해요. 평균 7%라도 매년 7%가 아니에요!"
                )
                
                problemCard(
                    emoji: "🎯",
                    title: "그래서 확률이 중요해요",
                    description: "\"10년 후에 정확히 2억\"이 아니라 \"10년 후에 2억 달성할 확률 87%\"처럼 현실적으로 알려드려요."
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
    
    private var comparisonView: some View {
        HStack(spacing: ExitSpacing.md) {
            Spacer()
            // 단순 계산
            VStack(spacing: ExitSpacing.sm) {
                Text("단순 계산")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
                
                // 직선 그래프
                ZStack {
                    RoundedRectangle(cornerRadius: ExitRadius.sm)
                        .fill(Color.Exit.secondaryCardBackground)
                        .frame(height: 60)
                    
                    Path { path in
                        path.move(to: CGPoint(x: 10, y: 50))
                        path.addLine(to: CGPoint(x: 80, y: 10))
                    }
                    .stroke(Color.Exit.tertiaryText, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                }
                .frame(width: 90, height: 60)
                
                Text("매년 똑같이 오름")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
            }
            
            Image(systemName: "arrow.right")
                .font(.system(size: 20))
                .foregroundStyle(Color.Exit.accent)
            
            // 시뮬레이션
            VStack(spacing: ExitSpacing.sm) {
                Text("실제 시장")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.accent)
                
                // 변동성 그래프
                ZStack {
                    RoundedRectangle(cornerRadius: ExitRadius.sm)
                        .fill(Color.Exit.accent.opacity(0.1))
                        .frame(height: 60)
                    
                    Path { path in
                        path.move(to: CGPoint(x: 10, y: 45))
                        path.addCurve(
                            to: CGPoint(x: 80, y: 15),
                            control1: CGPoint(x: 30, y: 55),
                            control2: CGPoint(x: 50, y: 5)
                        )
                    }
                    .stroke(Color.Exit.accent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                }
                .frame(width: 90, height: 60)
                
                Text("오르락내리락")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.accent)
            }
            Spacer()
        }
        .padding(.vertical, ExitSpacing.sm)
    }
    
    // MARK: - How It Works Section
    
    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            sectionHeader(icon: "gearshape.2.fill", title: "어떻게 작동하나요?")
            
            VStack(alignment: .leading, spacing: ExitSpacing.xl) {
                // 1. 난수 생성 원리
                VStack(alignment: .leading, spacing: ExitSpacing.md) {
                    stepHeader(number: "1", title: "컴퓨터가 무작위 숫자를 만들어요")
                    
                    VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                        Text("주식 시장의 수익률은 예측할 수 없어요. 올해 +20%일 수도 있고, 내년에 -15%일 수도 있죠.")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.secondaryText)
                        
                        Text("그래서 컴퓨터가 \"난수(무작위 숫자)\"를 이용해서 매년 수익률을 무작위로 정해요. 마치 주사위를 굴리는 것처럼요!")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.secondaryText)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    
                    // 난수 시각화
                    randomNumberVisualization
                }
                
                // 2. 30,000번 반복
                VStack(alignment: .leading, spacing: ExitSpacing.md) {
                    stepHeader(number: "2", title: "이걸 30,000번 반복해요")
                    
                    VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                        Text("한 번만 시뮬레이션하면 우연히 좋은 결과나 나쁜 결과가 나올 수 있어요.")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.secondaryText)
                        
                        Text("그래서 30,000번이나 반복해요! 그러면 \"대부분의 경우\"와 \"특별히 운이 좋거나 나쁜 경우\"를 모두 볼 수 있어요.")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.secondaryText)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    
                    // 반복 시각화
                    repetitionVisualization
                }
                
                // 3. 결과 정렬
                VStack(alignment: .leading, spacing: ExitSpacing.md) {
                    stepHeader(number: "3", title: "결과를 순서대로 줄 세워요")
                    
                    VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                        Text("30,000개의 결과를 \"목표 달성이 빠른 순서\"로 정렬해요.")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.secondaryText)
                        
                        Text("학교에서 시험 점수로 등수를 매기는 것처럼, 30,000개 결과에 1등부터 30,000등까지 순위를 매겨요.")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.secondaryText)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    
                    // 정렬 시각화
                    sortingVisualization
                }
                
                // 4. 대표 시나리오 선택
                VStack(alignment: .leading, spacing: ExitSpacing.md) {
                    stepHeader(number: "4", title: "대표 결과 3개를 보여드려요")
                    
                    Text("30,000개 전부 보여드리면 너무 많으니까, 대표적인 3개만 골라서 보여드려요:")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // 퍼센타일 설명
                    percentileExplanation
                }
                
                // 5. 결론
                VStack(alignment: .leading, spacing: ExitSpacing.md) {
                    stepHeader(number: "5", title: "이렇게 하면 뭐가 좋아요?")
                    
                    VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                        bulletPoint(text: "\"딱 10년 후에 2억!\" 같은 확정적인 예측은 거의 틀려요")
                        bulletPoint(text: "대신 \"빠르면 10년, 보통 12년, 늦으면 14년\"처럼 범위로 알려드려요")
                        bulletPoint(text: "운이 좋을 때와 나쁠 때 모두 대비할 수 있어요!")
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
    
    private var randomNumberVisualization: some View {
        VStack(spacing: ExitSpacing.sm) {
            // 난수 → 수익률 변환 시각화
            HStack(spacing: ExitSpacing.sm) {
                // 주사위
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.Exit.secondaryCardBackground)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "die.face.5.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.Exit.accent)
                }
                
                Image(systemName: "arrow.right")
                    .foregroundStyle(Color.Exit.tertiaryText)
                
                // 난수
                VStack(spacing: 2) {
                    Text("난수")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.tertiaryText)
                    Text("0.7234")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.Exit.accent)
                }
                .padding(.horizontal, ExitSpacing.sm)
                .padding(.vertical, ExitSpacing.xs)
                .background(Color.Exit.secondaryCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                
                Image(systemName: "arrow.right")
                    .foregroundStyle(Color.Exit.tertiaryText)
                
                // 수익률
                VStack(spacing: 2) {
                    Text("수익률")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.tertiaryText)
                    Text("+12.3%")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.Exit.positive)
                }
                .padding(.horizontal, ExitSpacing.sm)
                .padding(.vertical, ExitSpacing.xs)
                .background(Color.Exit.positive.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            Text("이렇게 매년 수익률을 무작위로 정해서 10년, 20년 후 자산을 예측해요.")
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.tertiaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var repetitionVisualization: some View {
        VStack(spacing: ExitSpacing.sm) {
            HStack(spacing: ExitSpacing.xs) {
                ForEach(0..<5, id: \.self) { index in
                    VStack(spacing: 4) {
                        Text("#\(index + 1)")
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.tertiaryText)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.Exit.accent.opacity(0.3 + Double(index) * 0.1))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.Exit.accent)
                            )
                    }
                }
                
                VStack(spacing: 4) {
                    Text("...")
                        .font(.Exit.body)
                        .foregroundStyle(Color.Exit.tertiaryText)
                }
                
                VStack(spacing: 4) {
                    Text("#30000")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.tertiaryText)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.Exit.accent)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                        )
                }
            }
            
            Text("각각의 시뮬레이션이 \"만약 이렇게 되면?\"이라는 하나의 미래예요")
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.tertiaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var sortingVisualization: some View {
        VStack(spacing: ExitSpacing.sm) {
            HStack(spacing: ExitSpacing.xs) {
                ForEach(0..<10, id: \.self) { index in
                    let height = CGFloat(40 - index * 3)
                    VStack(spacing: 2) {
                        if index == 0 {
                            Text("1등")
                                .font(.system(size: 8))
                                .foregroundStyle(Color.Exit.positive)
                        } else if index == 4 {
                            Text("중간")
                                .font(.system(size: 8))
                                .foregroundStyle(Color.Exit.accent)
                        } else if index == 9 {
                            Text("꼴등")
                                .font(.system(size: 8))
                                .foregroundStyle(Color.Exit.caution)
                        } else {
                            Text("임시")
                                .font(.system(size: 8))
                                .foregroundStyle(Color.clear)
                        }
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                index < 3 ? Color.Exit.positive :
                                index < 7 ? Color.Exit.accent :
                                Color.Exit.caution
                            )
                            .frame(width: 20, height: height)
                    }
                }
                
                Text("...")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.tertiaryText)
            }
            
            HStack {
                Text("🏆 빨리 달성")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.positive)
                
                Spacer()
                
                Text("⏰ 늦게 달성")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.caution)
            }
        }
    }
    
    private var percentileExplanation: some View {
        VStack(spacing: ExitSpacing.md) {
            percentileRow(
                emoji: "🍀",
                title: "행운 (상위 10%)",
                subtitle: "3,000등",
                description: "30,000개 결과 중 3,000등의 결과예요.\n\"운이 좋은 케이스에요.\"",
                color: Color.Exit.positive
            )
            
            percentileRow(
                emoji: "📊",
                title: "평균 (50%)",
                subtitle: "15,000등",
                description: "정확히 중간인 15,000등의 결과예요.\n\"가장 가능성 높은, 평범한 경우예요.\"",
                color: Color.Exit.accent
            )
            
            percentileRow(
                emoji: "🌧️",
                title: "불행 (하위 10%)",
                subtitle: "27,000등",
                description: "30,000개 결과 중 27,000등의 결과예요.\n\"운이 정말 나쁜 케이스예요.\"",
                color: Color.Exit.caution
            )
        }
    }
    
    private func percentileRow(emoji: String, title: String, subtitle: String, description: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: ExitSpacing.md) {
            Text(emoji)
                .font(.system(size: 28))
            
            VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                Text(title)
                    .font(.Exit.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
                
                Text(description)
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(ExitSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
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
                    icon: "percent",
                    iconColor: Color.Exit.accent,
                    title: "FIRE 달성 확률",
                    description: "\"78% 확률로 목표 달성!\" 처럼 정확한 확률을 알려드려요."
                )
                
                featureCard(
                    icon: "chart.xyaxis.line",
                    iconColor: Color.Exit.positive,
                    title: "자산 변화 예측",
                    description: "행운/평균/불행 3가지 시나리오로 시각화해요."
                )
                
                featureCard(
                    icon: "target",
                    iconColor: Color(hex: "FF9500"),
                    title: "목표 달성 시점 분포",
                    description: "가장 가능성 높은 달성 시점을 알려드려요."
                )
                
                featureCard(
                    icon: "calendar.badge.clock",
                    iconColor: Color(hex: "FF6B6B"),
                    title: "은퇴 초반 10년 분석",
                    description: "가장 중요한 처음 10년의 시장 리스크를 분석해요."
                )
                
                featureCard(
                    icon: "hourglass",
                    iconColor: Color(hex: "FFD700"),
                    title: "은퇴 후 40년 예측",
                    description: "장기적인 자산 변화와 소진 가능성을 예측해요."
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
    
    // MARK: - Demo Cards Section (실제 UI와 동일)
    
    private var demoCardsSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            sectionHeader(icon: "eye.fill", title: "이런 결과를 볼 수 있어요")
                .padding(.horizontal, ExitSpacing.md)
            
            // 1. 성공률 카드 (실제 SuccessRateCard와 동일한 UI)
            demoSuccessRateCard
            
            // 2. 자산 변화 예측 차트 (실제 AssetPathChart와 동일한 UI)
            demoAssetPathChart
            
            // 3. 목표 달성 시점 분포 (실제 DistributionChart와 동일한 UI)
            demoDistributionChart
            
            // 4. 은퇴 후 10년 분석 (실제 RetirementShortTermChart와 동일한 UI)
            demoRetirementShortTermChart
        }
    }
    
    // MARK: - Demo Success Rate Card
    
    private var demoSuccessRateCard: some View {
        VStack(spacing: ExitSpacing.lg) {
            // 타이틀
            HStack {
                demoBadge
                Spacer()
            }
            
            HStack {
                Image(systemName: "percent")
                    .foregroundStyle(Color.Exit.accent)
                Text("성공 확률")
                    .font(.Exit.title3)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            // 큰 성공률 표시
            VStack(spacing: ExitSpacing.sm) {
                Text("계획대로 회사 탈출에 성공할 확률")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("78")
                        .font(.system(size: 72, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.Exit.accent)
                    
                    Text("%")
                        .font(.Exit.title)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
                
                Text("높음")
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.accent)
                    .padding(.horizontal, ExitSpacing.md)
                    .padding(.vertical, ExitSpacing.xs)
                    .background(
                        Capsule()
                            .fill(Color.Exit.accent.opacity(0.15))
                    )
            }
            
            // 코칭 메시지
            Text("목표 달성 가능성이 높습니다. 현재 계획을 유지하세요")
                .font(.Exit.body)
                .foregroundStyle(Color.Exit.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 도움말
            HStack(alignment: .top, spacing: ExitSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.Exit.accent)
                
                VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                    Text("이 확률이 의미하는 것")
                        .font(.Exit.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    Text("30,000가지 다른 미래를 시뮬레이션해봤어요. 계획보다 10% 넘게 늦어지면 '실패'로 봤어요.")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(ExitSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.Exit.secondaryCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.xl))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // MARK: - Demo Asset Path Chart
    
    private var demoAssetPathChart: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            HStack {
                demoBadge
                Spacer()
            }
            
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundStyle(Color.Exit.accent)
                Text("자산 변화 예측")
                    .font(.Exit.title3)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            // 차트
            Chart {
                // 행운
                ForEach(Array(demoAssetData.best.enumerated()), id: \.offset) { index, amount in
                    LineMark(
                        x: .value("년", index * 12),
                        y: .value("자산", amount),
                        series: .value("경로", "행운")
                    )
                    .foregroundStyle(Color.Exit.positive)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
                
                // 평균
                ForEach(Array(demoAssetData.median.enumerated()), id: \.offset) { index, amount in
                    LineMark(
                        x: .value("년", index * 12),
                        y: .value("자산", amount),
                        series: .value("경로", "평균")
                    )
                    .foregroundStyle(Color.Exit.accent)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .interpolationMethod(.catmullRom)
                }
                
                // 불행
                ForEach(Array(demoAssetData.worst.enumerated()), id: \.offset) { index, amount in
                    LineMark(
                        x: .value("년", index * 12),
                        y: .value("자산", amount),
                        series: .value("경로", "불행")
                    )
                    .foregroundStyle(Color.Exit.caution)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
                
                // 목표선
                RuleMark(y: .value("목표", 600_000_000))
                    .foregroundStyle(Color.Exit.accent.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let months = value.as(Int.self) {
                            Text("\(months / 12)년")
                                .font(.Exit.caption2)
                                .foregroundStyle(Color.Exit.tertiaryText)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(formatChartAxis(amount))
                                .font(.Exit.caption2)
                                .foregroundStyle(Color.Exit.tertiaryText)
                        }
                    }
                }
            }
            
            // 범례
            HStack(spacing: ExitSpacing.lg) {
                legendItem(color: Color.Exit.positive, label: "행운(상위10%)")
                legendItem(color: Color.Exit.accent, label: "평균(50%)")
                legendItem(color: Color.Exit.caution, label: "불행(하위10%)")
            }
            
            // 목표 달성 시점 비교
            VStack(alignment: .leading, spacing: ExitSpacing.md) {
                Text("목표 자산 달성 시점")
                    .font(.Exit.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.primaryText)
                
                demoTimelineChart
            }
            
            // 도움말
            HStack(alignment: .top, spacing: ExitSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.Exit.accent)
                
                VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                    Text("이 그래프가 알려주는 것")
                        .font(.Exit.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    Text("시장 상황에 따라 자산이 어떻게 변할지 3가지 시나리오로 보여줘요. 대부분의 경우가 이 범위 안에 들어요.")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(ExitSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.Exit.secondaryCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    private var demoTimelineChart: some View {
        let timelineData: [(label: String, months: Int, color: Color, icon: String)] = [
            ("행운", 96, Color.Exit.positive, "🍀"),
            ("평균", 144, Color.Exit.accent, "📊"),
            ("불행", 192, Color.Exit.caution, "🌧️"),
            ("기존 예측", 120, Color.Exit.tertiaryText, "📌")
        ]
        
        let maxMonths = 192
        
        return VStack(spacing: ExitSpacing.sm) {
            ForEach(timelineData, id: \.label) { item in
                HStack(spacing: ExitSpacing.sm) {
                    HStack(spacing: 4) {
                        Text(item.icon)
                            .font(.system(size: 12))
                        Text(item.label)
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.secondaryText)
                    }
                    .frame(width: 70, alignment: .leading)
                    
                    GeometryReader { geometry in
                        let barWidth = (CGFloat(item.months) / CGFloat(maxMonths)) * geometry.size.width
                        
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.Exit.divider)
                                .frame(height: 24)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.color.opacity(0.8))
                                .frame(width: max(barWidth, 40), height: 24)
                            
                            Text(formatYears(item.months))
                                .font(.Exit.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(barWidth > 60 ? .white : item.color)
                                .padding(.horizontal, 8)
                                .frame(width: max(barWidth, 40), alignment: barWidth > 60 ? .trailing : .leading)
                                .offset(x: barWidth > 60 ? 0 : max(barWidth, 40))
                        }
                    }
                    .frame(height: 24)
                }
            }
        }
    }
    
    // MARK: - Demo Distribution Chart
    
    private var demoDistributionChart: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            HStack {
                demoBadge
                Spacer()
            }
            
            // 타이틀
            HStack {
                Image(systemName: "target")
                    .foregroundStyle(Color.Exit.accent)
                Text("언제 달성할 가능성이 높을까?")
                    .font(.Exit.title3)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            // 핵심 수치
            HStack(alignment: .bottom, spacing: ExitSpacing.sm) {
                Text("12년차")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.Exit.accent)
                
                Text("에 달성할 가능성이 가장 높아요")
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.secondaryText)
                    .padding(.bottom, 4)
            }
            
            // 차트
            Chart {
                ForEach(demoDistributionData, id: \.year) { data in
                    BarMark(
                        x: .value("연도", data.year),
                        y: .value("확률", data.probability)
                    )
                    .foregroundStyle(
                        data.year == 12 ?
                        Color.Exit.accent.gradient :
                        Color.Exit.accent.opacity(0.4).gradient
                    )
                    .cornerRadius(4)
                }
            }
            .frame(height: 140)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisValueLabel {
                        if let year = value.as(Int.self) {
                            Text("\(year)년")
                                .font(.Exit.caption2)
                                .foregroundStyle(Color.Exit.tertiaryText)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 10, 20, 30]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.Exit.divider)
                    AxisValueLabel {
                        if let prob = value.as(Int.self) {
                            Text("\(prob)%")
                                .font(.Exit.caption2)
                                .foregroundStyle(Color.Exit.tertiaryText)
                        }
                    }
                }
            }
            
            // 범위 표시
            HStack(spacing: ExitSpacing.lg) {
                rangeIndicator(icon: "clock", label: "빠르면", value: "8년", color: Color.Exit.positive)
                rangeIndicator(icon: "target", label: "대부분", value: "12년", color: Color.Exit.accent)
                rangeIndicator(icon: "clock.badge.exclamationmark", label: "늦으면", value: "16년", color: Color.Exit.caution)
            }
            
            // 도움말
            HStack(alignment: .top, spacing: ExitSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.Exit.accent)
                
                VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                    Text("이 그래프가 알려주는 것")
                        .font(.Exit.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    Text("막대가 높을수록 그 시점에 목표를 달성할 확률이 높아요. 대부분(80%)은 8~16년 사이에 달성해요.")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(ExitSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.Exit.secondaryCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // MARK: - Demo Retirement Short Term Chart
    
    private var demoRetirementShortTermChart: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            HStack {
                demoBadge
                Spacer()
            }
            
            // 헤더
            VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(Color.Exit.accent)
                    Text("은퇴 초반 10년, 어떻게 될까?")
                        .font(.Exit.title3)
                        .foregroundStyle(Color.Exit.primaryText)
                }
                
                Text("은퇴 직후가 가장 중요해요. 처음 10년의 시장 상황이 전체를 좌우합니다.")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            
            // 기준 설명
            HStack(spacing: ExitSpacing.md) {
                VStack(spacing: 2) {
                    Text("은퇴 시점")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.secondaryText)
                    Text("6억")
                        .font(.Exit.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.Exit.accent)
                }
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.Exit.secondaryText)
                
                VStack(spacing: 2) {
                    Text("10년 후")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.secondaryText)
                    Text("시장 상황에 따라")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
            }
            .padding(ExitSpacing.md)
            .frame(maxWidth: .infinity)
            .background(Color.Exit.secondaryCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
            
            // 시나리오 카드
            VStack(spacing: ExitSpacing.sm) {
                HStack(spacing: ExitSpacing.xs) {
                    scenarioCard(title: "매우 행운", amount: "9.2억", change: "+53%", color: Color.Exit.positive)
                    scenarioCard(title: "행운", amount: "7.5억", change: "+25%", color: Color.Exit.accent)
                    scenarioCard(title: "평균", amount: "5.8억", change: "-3%", color: Color.Exit.primaryText)
                }
                
                HStack(spacing: ExitSpacing.xs) {
                    scenarioCard(title: "불행", amount: "4.2억", change: "-30%", color: Color.Exit.caution)
                    scenarioCard(title: "매우 불행", amount: "2.8억", change: "-53%", color: Color.Exit.warning)
                }
            }
            
            // 도움말
            HStack(alignment: .top, spacing: ExitSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.Exit.accent)
                
                VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                    Text("왜 처음 10년이 중요할까요?")
                        .font(.Exit.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    Text("은퇴 직후 시장이 하락하면 회복할 시간이 부족해요. 이를 '시퀀스 리스크'라고 해요.")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(ExitSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.Exit.secondaryCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    private func scenarioCard(title: String, amount: String, change: String, color: Color) -> some View {
        VStack(spacing: ExitSpacing.xs) {
            Text(title)
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.secondaryText)
            
            Text(amount)
                .font(.Exit.caption)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(change)
                .font(.Exit.caption2)
                .foregroundStyle(change.hasPrefix("+") ? Color.Exit.positive : Color.Exit.warning)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ExitSpacing.sm)
        .background(color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
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
                    
                    Text("금융공학에서 검증된 방법론")
                        .font(.Exit.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.Exit.primaryText)
                }
                
                Text("몬테카를로 시뮬레이션은 월스트리트 투자은행, 연기금 등에서 실제로 사용하는 분석 기법이에요. 복잡한 금융공학을 누구나 쉽게 사용할 수 있도록 만들었어요.")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(ExitSpacing.lg)
            .frame(maxWidth: .infinity)
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
            
            // 현재 데이터 미리보기
            if let scenario = scenario {
                currentDataPreview(scenario: scenario)
            }
            
            // 플로팅 구매 버튼
            floatingPurchaseButton
        }
        .padding(.horizontal, ExitSpacing.md)
    }
    
    private func currentDataPreview(scenario: Scenario) -> some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(Color.Exit.accent)
                Text("내 데이터로 시뮬레이션해요")
                    .font(.Exit.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            Divider()
                .background(Color.Exit.divider)
            
            VStack(spacing: ExitSpacing.sm) {
                dataPreviewRow(label: "현재 자산", value: ExitNumberFormatter.formatToEokManWon(currentAssetAmount))
                dataPreviewRow(label: "월 저축액", value: ExitNumberFormatter.formatToManWon(scenario.monthlyInvestment))
                dataPreviewRow(label: "목표 월수입", value: ExitNumberFormatter.formatToManWon(scenario.desiredMonthlyIncome))
                dataPreviewRow(label: "예상 수익률", value: String(format: "%.1f%%", scenario.preRetirementReturnRate))
            }
            
            HStack(spacing: ExitSpacing.xs) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.Exit.accent)
                
                Text("이 데이터로 30,000가지 미래를 계산합니다")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.accent)
            }
            .padding(.top, ExitSpacing.xs)
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
    }
    
    private func dataPreviewRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            Spacer()
            Text(value)
                .font(.Exit.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.Exit.primaryText)
        }
    }
    
    // MARK: - Floating Purchase Button
    
    private var floatingPurchaseButton: some View {
        VStack(spacing: ExitSpacing.sm) {
            Button {
                onStart()
            } label: {
                HStack(spacing: ExitSpacing.sm) {
                    if isPurchased {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16))
                        Text("시뮬레이션 시작")
                            .font(.Exit.body)
                            .fontWeight(.semibold)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16))
                        Text("프리미엄 기능 구매하기")
                            .font(.Exit.body)
                            .fontWeight(.semibold)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, ExitSpacing.md)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "00D4AA"), Color(hex: "00B894")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.xl))
                .shadow(color: Color.Exit.accent.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            
            if !isPurchased {
                Text("₩4,900 • 한 번 구매로 평생 사용")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.tertiaryText)
            } else {
                Text("약 3~5초 소요됩니다")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var demoBadge: some View {
        Text("예시")
            .font(.Exit.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(Color(hex: "FFD700"))
            .padding(.horizontal, ExitSpacing.sm)
            .padding(.vertical, ExitSpacing.xs)
            .background(Color(hex: "FFD700").opacity(0.2))
            .clipShape(Capsule())
    }
    
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
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: ExitSpacing.xs) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 16, height: 3)
            
            Text(label)
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.secondaryText)
        }
    }
    
    private func rangeIndicator(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: ExitSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            
            Text(label)
                .font(.Exit.caption2)
                .foregroundStyle(Color.Exit.tertiaryText)
            
            Text(value)
                .font(.Exit.body)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatYears(_ months: Int) -> String {
        let years = months / 12
        let remainingMonths = months % 12
        
        if remainingMonths == 0 {
            return "\(years)년"
        } else if years == 0 {
            return "\(remainingMonths)개월"
        } else {
            return "\(years)년 \(remainingMonths)개월"
        }
    }
    
    private func formatChartAxis(_ amount: Double) -> String {
        if amount >= 100_000_000 {
            return String(format: "%.1f억", amount / 100_000_000)
        } else if amount >= 10_000 {
            return String(format: "%.0f만", amount / 10_000)
        } else {
            return String(format: "%.0f", amount)
        }
    }
    
    // MARK: - Demo Data
    
    private var demoAssetData: (best: [Double], median: [Double], worst: [Double]) {
        // 15년치 데이터 (연 단위, 월 환산을 위해 index*12로 표시)
        let best: [Double] = [100_000_000, 180_000_000, 280_000_000, 420_000_000, 580_000_000, 780_000_000, 1_020_000_000, 1_300_000_000, 1_650_000_000, 2_050_000_000, 2_500_000_000, 3_000_000_000, 3_550_000_000, 4_150_000_000, 4_800_000_000]
        let median: [Double] = [100_000_000, 150_000_000, 210_000_000, 280_000_000, 360_000_000, 450_000_000, 560_000_000, 680_000_000, 820_000_000, 980_000_000, 1_160_000_000, 1_360_000_000, 1_580_000_000, 1_820_000_000, 2_100_000_000]
        let worst: [Double] = [100_000_000, 120_000_000, 140_000_000, 170_000_000, 210_000_000, 260_000_000, 320_000_000, 390_000_000, 470_000_000, 560_000_000, 670_000_000, 800_000_000, 950_000_000, 1_120_000_000, 1_320_000_000]
        return (best, median, worst)
    }
    
    private var demoDistributionData: [(year: Int, probability: Double)] {
        [
            (year: 8, probability: 4.5),
            (year: 9, probability: 8.9),
            (year: 10, probability: 14.2),
            (year: 11, probability: 18.5),
            (year: 12, probability: 21.0),
            (year: 13, probability: 16.8),
            (year: 14, probability: 9.8),
            (year: 15, probability: 4.2),
            (year: 16, probability: 1.5),
            (year: 17, probability: 0.6)
        ]
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        
        SimulationEmptyView(
            scenario: nil,
            currentAssetAmount: 50_000_000,
            onStart: {},
            isPurchased: false
        )
    }
}
