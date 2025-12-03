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
    
    @State private var scrollOffset: CGFloat = 0
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
                
                // 무엇을 알 수 있는가? 섹션
                whatYouGetSection
                
                // 데모 차트 섹션
                demoChartSection
                
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
                
                Text("30,000가지 미래를 계산해\n당신의 FIRE 확률을 알려드려요")
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
                    description: "\"10년 후에 정확히 2억\"이 아니라 \"10년 후에 2억 달성할 확률 78%\"처럼 현실적으로 알려드려요."
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
        }
        .padding(.vertical, ExitSpacing.sm)
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
                    description: "\"78% 확률로 목표 달성!\" 처럼 정확한 확률을 알려드려요. 계획이 얼마나 현실적인지 바로 알 수 있어요."
                )
                
                featureCard(
                    icon: "calendar.badge.clock",
                    iconColor: Color.Exit.positive,
                    title: "예상 달성 시점",
                    description: "행운이면 8년, 평균 12년, 불행이면 18년... 다양한 시나리오를 한눈에!"
                )
                
                featureCard(
                    icon: "chart.xyaxis.line",
                    iconColor: Color(hex: "FF9500"),
                    title: "자산 변화 예측 그래프",
                    description: "시간에 따라 내 자산이 어떻게 변할지 3가지 경우(행운/평균/불행)로 시각화해요."
                )
                
                featureCard(
                    icon: "lightbulb.max.fill",
                    iconColor: Color(hex: "FFD700"),
                    title: "맞춤형 조언",
                    description: "확률이 낮다면? 월 저축을 얼마나 늘려야 하는지 등 실질적인 조언을 드려요."
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
    
    // MARK: - Demo Chart Section
    
    private var demoChartSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.lg) {
            sectionHeader(icon: "eye.fill", title: "이런 결과를 볼 수 있어요")
            
            // 데모 성공률 카드
            demoSuccessRateCard
            
            // 데모 자산 변화 차트
            demoAssetChart
            
            // 데모 분포 차트
            demoDistributionChart
        }
        .padding(.horizontal, ExitSpacing.md)
    }
    
    private var demoSuccessRateCard: some View {
        VStack(spacing: ExitSpacing.md) {
            HStack {
                Text("예시")
                    .font(.Exit.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(hex: "FFD700"))
                    .padding(.horizontal, ExitSpacing.sm)
                    .padding(.vertical, ExitSpacing.xs)
                    .background(Color(hex: "FFD700").opacity(0.2))
                    .clipShape(Capsule())
                
                Spacer()
                
                Text("성공 확률 카드")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.tertiaryText)
            }
            
            VStack(spacing: ExitSpacing.sm) {
                Text("계획대로 회사 탈출에 성공할 확률")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("78")
                        .font(.system(size: 64, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.Exit.accent)
                    
                    Text("%")
                        .font(.Exit.title2)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
                
                Text("높음")
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.accent)
                    .padding(.horizontal, ExitSpacing.md)
                    .padding(.vertical, ExitSpacing.xs)
                    .background(Color.Exit.accent.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: ExitRadius.lg)
                .stroke(Color.Exit.accent.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var demoAssetChart: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            HStack {
                Text("예시")
                    .font(.Exit.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(hex: "FFD700"))
                    .padding(.horizontal, ExitSpacing.sm)
                    .padding(.vertical, ExitSpacing.xs)
                    .background(Color(hex: "FFD700").opacity(0.2))
                    .clipShape(Capsule())
                
                Spacer()
                
                Text("자산 변화 예측 차트")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.tertiaryText)
            }
            
            // 간단한 데모 차트
            Chart {
                // 행운
                ForEach(demoChartData.best.indices, id: \.self) { index in
                    LineMark(
                        x: .value("년", index),
                        y: .value("자산", demoChartData.best[index]),
                        series: .value("시나리오", "행운")
                    )
                    .foregroundStyle(Color.Exit.positive)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
                
                // 평균
                ForEach(demoChartData.median.indices, id: \.self) { index in
                    LineMark(
                        x: .value("년", index),
                        y: .value("자산", demoChartData.median[index]),
                        series: .value("시나리오", "평균")
                    )
                    .foregroundStyle(Color.Exit.accent)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .interpolationMethod(.catmullRom)
                }
                
                // 불행
                ForEach(demoChartData.worst.indices, id: \.self) { index in
                    LineMark(
                        x: .value("년", index),
                        y: .value("자산", demoChartData.worst[index]),
                        series: .value("시나리오", "불행")
                    )
                    .foregroundStyle(Color.Exit.caution)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
                
                // 목표선
                RuleMark(y: .value("목표", 100000))
                    .foregroundStyle(Color.Exit.accent.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
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
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine()
                    AxisValueLabel {
                        Text("")
                    }
                }
            }
            
            // 범례
            HStack(spacing: ExitSpacing.md) {
                legendItem(color: Color.Exit.positive, label: "🍀 행운")
                legendItem(color: Color.Exit.accent, label: "📊 평균")
                legendItem(color: Color.Exit.caution, label: "🌧️ 불행")
            }
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: ExitRadius.lg)
                .stroke(Color.Exit.accent.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var demoDistributionChart: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            HStack {
                Text("예시")
                    .font(.Exit.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(hex: "FFD700"))
                    .padding(.horizontal, ExitSpacing.sm)
                    .padding(.vertical, ExitSpacing.xs)
                    .background(Color(hex: "FFD700").opacity(0.2))
                    .clipShape(Capsule())
                
                Spacer()
                
                Text("목표 달성 시점 분포")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.tertiaryText)
            }
            
            Chart {
                ForEach(demoDistributionData, id: \.year) { data in
                    BarMark(
                        x: .value("연도", data.year),
                        y: .value("횟수", data.count)
                    )
                    .foregroundStyle(
                        data.year == 12 ?
                        Color.Exit.accent.gradient :
                        Color.Exit.accent.opacity(0.6).gradient
                    )
                    .cornerRadius(4)
                }
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.Exit.divider)
                    AxisValueLabel {
                        if let year = value.as(Int.self) {
                            Text("\(year)년")
                                .font(.Exit.caption2)
                                .foregroundStyle(Color.Exit.secondaryText)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.Exit.divider)
                }
            }
            
            Text("\"12년 차에 목표 달성하는 경우가 가장 많아요\"")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: ExitRadius.lg)
                .stroke(Color.Exit.accent.opacity(0.3), lineWidth: 1)
        )
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
                    .multilineTextAlignment(.center)
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
    
    // MARK: - Demo Data
    
    private var demoChartData: (best: [Double], median: [Double], worst: [Double]) {
        // 15년치 데이터 (연 단위)
        let best: [Double] = [10000, 18000, 28000, 42000, 58000, 78000, 102000, 130000, 165000, 205000, 250000, 300000, 355000, 415000, 480000]
        let median: [Double] = [10000, 15000, 21000, 28000, 36000, 45000, 56000, 68000, 82000, 98000, 116000, 136000, 158000, 182000, 210000]
        let worst: [Double] = [10000, 12000, 14000, 17000, 21000, 26000, 32000, 39000, 47000, 56000, 67000, 80000, 95000, 112000, 132000]
        return (best, median, worst)
    }
    
    private var demoDistributionData: [(year: Int, count: Int)] {
        [
            (year: 8, count: 450),
            (year: 9, count: 890),
            (year: 10, count: 1420),
            (year: 11, count: 1850),
            (year: 12, count: 2100),
            (year: 13, count: 1680),
            (year: 14, count: 980),
            (year: 15, count: 420),
            (year: 16, count: 150),
            (year: 17, count: 60)
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
