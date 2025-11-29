//
//  SafetyScoreTabView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 안전점수 탭 전체 뷰
struct SafetyScoreTabView: View {
    @Bindable var viewModel: HomeViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: ExitSpacing.lg) {
                // 안전 점수 카드
                SafetyScoreCard(
                    totalScore: viewModel.totalSafetyScore,
                    scoreChange: viewModel.safetyScoreChangeText,
                    details: viewModel.safetyScoreDetails,
                    alwaysExpanded: true
                )
                .padding(.horizontal, ExitSpacing.md)
                
                // 점수 산출 근거 섹션
                scoreBreakdownSection
                
                // 입금 기록 섹션
                depositHistorySection
            }
            .padding(.vertical, ExitSpacing.lg)
        }
    }
    
    // MARK: - 점수 산출 근거 섹션
    
    private var scoreBreakdownSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            // 헤더
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundStyle(Color.Exit.accent)
                Text("점수 산출 근거")
                    .font(.Exit.title3)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            Divider()
                .background(Color.Exit.divider)
            
            // 각 항목별 설명
            VStack(spacing: ExitSpacing.lg) {
                // 1. 목표 충족
                ScoreBreakdownCard(
                    icon: "target",
                    title: "목표 충족",
                    score: viewModel.safetyScoreDetails[safe: 0]?.score ?? 0,
                    maxScore: 25,
                    description: "현재 패시브인컴이 목표 월수입의 몇 %를 달성했는지 측정합니다.",
                    details: goalFulfillmentDetails
                )
                
                // 2. 수익률 안전성
                ScoreBreakdownCard(
                    icon: "shield.lefthalf.filled",
                    title: "수익률 안전성",
                    score: viewModel.safetyScoreDetails[safe: 1]?.score ?? 0,
                    maxScore: 25,
                    description: "현재 자산 대비 패시브인컴 비율이 안전한 3~8% 구간에 있는지 평가합니다.",
                    details: returnSafetyDetails
                )
                
                // 3. 자산 다각화
                ScoreBreakdownCard(
                    icon: "chart.pie",
                    title: "자산 다각화",
                    score: viewModel.safetyScoreDetails[safe: 2]?.score ?? 0,
                    maxScore: 25,
                    description: "7개 자산군 중 몇 가지를 보유하고 있는지 평가합니다.",
                    details: diversificationDetails
                )
                
                // 4. 자산 성장성
                ScoreBreakdownCard(
                    icon: "arrow.up.right",
                    title: "자산 성장성",
                    score: viewModel.safetyScoreDetails[safe: 3]?.score ?? 0,
                    maxScore: 25,
                    description: "물가상승률을 제외한 실질 자산 증가율을 측정합니다.",
                    details: growthDetails
                )
            }
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // MARK: - 입금 기록 섹션
    
    private var depositHistorySection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            // 헤더
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(Color.Exit.accent)
                Text("입금 기록")
                    .font(.Exit.title3)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Spacer()
                
                if !viewModel.monthlyUpdates.isEmpty {
                    Text("총 \(viewModel.monthlyUpdates.count)건")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
            }
            
            Divider()
                .background(Color.Exit.divider)
            
            if viewModel.monthlyUpdates.isEmpty {
                // 기록 없음
                VStack(spacing: ExitSpacing.md) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.Exit.tertiaryText)
                    
                    Text("아직 입금 기록이 없습니다")
                        .font(.Exit.body)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    Text("하단의 '입금하기' 버튼을 눌러\n첫 입금을 기록해보세요")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.tertiaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, ExitSpacing.xxl)
            } else {
                // 입금 기록 리스트
                VStack(spacing: ExitSpacing.sm) {
                    ForEach(viewModel.monthlyUpdates, id: \.id) { update in
                        DepositHistoryRow(update: update)
                    }
                }
                
                // 총 입금액 요약
                totalDepositSummary
            }
        }
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .padding(.horizontal, ExitSpacing.md)
    }
    
    // MARK: - 총 입금액 요약
    
    private var totalDepositSummary: some View {
        let totalDeposit = viewModel.monthlyUpdates.reduce(0) { $0 + $1.depositAmount }
        let totalPassiveIncome = viewModel.monthlyUpdates.reduce(0) { $0 + $1.passiveIncome }
        
        return VStack(spacing: ExitSpacing.sm) {
            Divider()
                .background(Color.Exit.divider)
            
            HStack {
                VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                    Text("총 입금액")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                    Text(ExitNumberFormatter.formatToEokManWon(totalDeposit))
                        .font(.Exit.title3)
                        .foregroundStyle(Color.Exit.accent)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: ExitSpacing.xs) {
                    Text("총 패시브인컴")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                    Text(ExitNumberFormatter.formatToManWon(totalPassiveIncome))
                        .font(.Exit.title3)
                        .foregroundStyle(Color.Exit.caution)
                }
            }
            .padding(.top, ExitSpacing.sm)
        }
    }
    
    // MARK: - Computed Details
    
    private var goalFulfillmentDetails: [String] {
        let currentPassive = viewModel.monthlyUpdates.first?.passiveIncome ?? 0
        let desiredMonthly = viewModel.activeScenario?.desiredMonthlyIncome ?? 0
        let ratio = desiredMonthly > 0 ? (currentPassive / desiredMonthly) * 100 : 0
        
        return [
            "현재 월 패시브인컴: \(ExitNumberFormatter.formatToManWon(currentPassive))",
            "목표 월수입: \(ExitNumberFormatter.formatToManWon(desiredMonthly))",
            "달성률: \(String(format: "%.1f", ratio))%"
        ]
    }
    
    private var returnSafetyDetails: [String] {
        let currentPassive = viewModel.monthlyUpdates.first?.passiveIncome ?? 0
        let currentAssets = viewModel.monthlyUpdates.first?.totalAssets ?? viewModel.activeScenario?.currentNetAssets ?? 0
        let annualPassive = currentPassive * 12
        let returnRate = currentAssets > 0 ? (annualPassive / currentAssets) * 100 : 0
        
        var safetyStatus = ""
        if returnRate >= 3 && returnRate <= 8 {
            safetyStatus = "안전 구간 ✓"
        } else if returnRate < 3 {
            safetyStatus = "보수적 (수익률 향상 권장)"
        } else {
            safetyStatus = "공격적 (리스크 관리 필요)"
        }
        
        return [
            "연환산 패시브인컴: \(ExitNumberFormatter.formatToManWon(annualPassive))",
            "현재 총자산: \(ExitNumberFormatter.formatToEokManWon(currentAssets))",
            "수익률: \(String(format: "%.2f", returnRate))%",
            safetyStatus
        ]
    }
    
    private var diversificationDetails: [String] {
        let assetTypes = viewModel.monthlyUpdates.first?.assetTypes ?? []
        let allAssetTypes = ["주식", "채권", "부동산", "현금", "금", "암호화폐", "기타"]
        
        var details = ["보유 자산군: \(assetTypes.count)/7개"]
        
        if !assetTypes.isEmpty {
            details.append("보유: \(assetTypes.joined(separator: ", "))")
        }
        
        let missing = allAssetTypes.filter { !assetTypes.contains($0) }
        if !missing.isEmpty && missing.count < 5 {
            details.append("미보유: \(missing.joined(separator: ", "))")
        }
        
        return details
    }
    
    private var growthDetails: [String] {
        let currentAssets = viewModel.monthlyUpdates.first?.totalAssets ?? viewModel.activeScenario?.currentNetAssets ?? 0
        let previousAssets = viewModel.monthlyUpdates.dropFirst().first?.totalAssets ?? currentAssets
        let inflationRate = viewModel.activeScenario?.inflationRate ?? 2.5
        
        let monthlyGrowth = previousAssets > 0 ? ((currentAssets - previousAssets) / previousAssets) * 100 : 0
        let monthlyInflation = inflationRate / 12
        let realGrowth = monthlyGrowth - monthlyInflation
        
        return [
            "이번 달 자산: \(ExitNumberFormatter.formatToEokManWon(currentAssets))",
            "지난 달 자산: \(ExitNumberFormatter.formatToEokManWon(previousAssets))",
            "명목 성장률: \(String(format: "%+.2f", monthlyGrowth))%",
            "실질 성장률: \(String(format: "%+.2f", realGrowth))% (물가상승률 \(String(format: "%.1f", inflationRate))% 반영)"
        ]
    }
}

// MARK: - 점수 산출 상세 카드

private struct ScoreBreakdownCard: View {
    let icon: String
    let title: String
    let score: Int
    let maxScore: Int
    let description: String
    let details: [String]
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            // 헤더 (탭 가능)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(scoreColor)
                        .frame(width: 24)
                    
                    Text(title)
                        .font(.Exit.body)
                        .foregroundStyle(Color.Exit.primaryText)
                    
                    Spacer()
                    
                    Text("\(score)/\(maxScore)")
                        .font(.Exit.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(scoreColor)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.Exit.secondaryText)
                }
            }
            .buttonStyle(.plain)
            
            // 점수 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.Exit.divider)
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(scoreGradient)
                        .frame(width: geometry.size.width * CGFloat(score) / CGFloat(maxScore), height: 6)
                }
            }
            .frame(height: 6)
            
            // 확장 영역
            if isExpanded {
                VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                    Text(description)
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    // 상세 데이터
                    VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                        ForEach(details, id: \.self) { detail in
                            HStack(spacing: ExitSpacing.sm) {
                                Circle()
                                    .fill(Color.Exit.accent)
                                    .frame(width: 4, height: 4)
                                Text(detail)
                                    .font(.Exit.caption)
                                    .foregroundStyle(Color.Exit.primaryText)
                            }
                        }
                    }
                    .padding(ExitSpacing.sm)
                    .background(Color.Exit.secondaryCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(ExitSpacing.md)
        .background(Color.Exit.secondaryCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
    }
    
    private var scoreColor: Color {
        let percentage = Double(score) / Double(maxScore)
        if percentage >= 0.8 {
            return Color.Exit.accent
        } else if percentage >= 0.5 {
            return Color.Exit.caution
        } else {
            return Color.Exit.warning
        }
    }
    
    private var scoreGradient: LinearGradient {
        let percentage = Double(score) / Double(maxScore)
        if percentage >= 0.8 {
            return LinearGradient.exitAccent
        } else if percentage >= 0.5 {
            return LinearGradient(colors: [Color.Exit.caution, Color.Exit.caution.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
        } else {
            return LinearGradient(colors: [Color.Exit.warning, Color.Exit.warning.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
        }
    }
}

// MARK: - 입금 기록 Row

private struct DepositHistoryRow: View {
    let update: MonthlyUpdate
    
    var body: some View {
        HStack(spacing: ExitSpacing.md) {
            // 날짜 뱃지
            VStack(spacing: 2) {
                Text(yearText)
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
                Text(monthText)
                    .font(.Exit.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            .frame(width: 50)
            .padding(.vertical, ExitSpacing.sm)
            .background(Color.Exit.secondaryCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
            
            // 내용
            VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                // 입금액
                if update.depositAmount > 0 {
                    HStack(spacing: ExitSpacing.xs) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.Exit.accent)
                        Text("입금")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.secondaryText)
                        Text(ExitNumberFormatter.formatToManWon(update.depositAmount))
                            .font(.Exit.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.Exit.accent)
                    }
                }
                
                // 패시브인컴
                if update.passiveIncome > 0 {
                    HStack(spacing: ExitSpacing.xs) {
                        Image(systemName: "banknote.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.Exit.caution)
                        Text("패시브인컴")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.secondaryText)
                        Text(ExitNumberFormatter.formatToManWon(update.passiveIncome))
                            .font(.Exit.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.Exit.caution)
                    }
                }
                
                // 총 자산
                HStack(spacing: ExitSpacing.xs) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.Exit.secondaryText)
                    Text("총자산")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.tertiaryText)
                    Text(ExitNumberFormatter.formatToEokManWon(update.totalAssets))
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
            }
            
            Spacer()
            
            // 자산 종류 뱃지
            if !update.assetTypes.isEmpty {
                VStack(alignment: .trailing, spacing: ExitSpacing.xs) {
                    Text("\(update.assetTypes.count)종")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.accent)
                        .padding(.horizontal, ExitSpacing.sm)
                        .padding(.vertical, 2)
                        .background(Color.Exit.accent.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(ExitSpacing.md)
        .background(Color.Exit.secondaryCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
    }
    
    private var yearText: String {
        guard update.yearMonth.count >= 4 else { return "" }
        return String(update.yearMonth.prefix(4))
    }
    
    private var monthText: String {
        guard update.yearMonth.count >= 6 else { return "" }
        let monthStr = String(update.yearMonth.suffix(2))
        if let month = Int(monthStr) {
            return "\(month)월"
        }
        return ""
    }
}

// MARK: - Array Safe Access Extension

private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        SafetyScoreTabView(viewModel: HomeViewModel())
    }
    .preferredColorScheme(.dark)
}

