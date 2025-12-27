//
//  CalculationFormulaSheet.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

struct CalculationFormulaSheet: View {
    @Environment(\.appState) private var appState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.Exit.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: ExitSpacing.xl) {
                        // 목표 자산 계산
                        targetAssetSection
                            .padding(.top, ExitSpacing.lg)
                        
                        Divider()
                            .background(Color.Exit.divider)
                        
                        // D-DAY 계산
                        dDaySection
                        
                        Divider()
                            .background(Color.Exit.divider)
                        
                        // 참고 사항
                        noteSection
                    }
                    .padding(ExitSpacing.lg)
                }
                .scrollIndicators(.hidden)
            }
        }
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Target Asset Section
    
    private var targetAssetSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            // 헤더
            HStack(spacing: ExitSpacing.sm) {
                Image(systemName: "target")
                    .foregroundStyle(Color.Exit.accent)
                Text("목표 자산 계산")
                    .font(.Exit.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            // 공식 (분수 형태)
            HStack(spacing: ExitSpacing.sm) {
                Text("목표 자산")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.accent)
                
                Text("=")
                    .foregroundStyle(Color.Exit.primaryText)
                
                VStack(spacing: 6) {
                    Text("희망 월수입 × 12")
                        .foregroundStyle(Color.Exit.primaryText)
                    
                    Rectangle()
                        .fill(Color.Exit.divider)
                        .frame(height: 1)
                    
                    HStack(spacing: 6) {
                        Text("은퇴 후 수익률")
                            .foregroundStyle(Color.Exit.accent)
                        Text("-")
                        Text("물가상승률")
                            .foregroundStyle(Color.Exit.caution)
                    }
                }
            }
            .font(.Exit.body)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, ExitSpacing.md)
            
            // 현재 값 예시
            if let profile = appState.userProfile, let result = appState.retirementResult {
                VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                    Text("현재 설정값:")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.tertiaryText)
                    
                    FormulaValueRow(
                        label: "희망 월수입",
                        value: ExitNumberFormatter.formatToManWon(profile.desiredMonthlyIncome)
                    )
                    FormulaValueRow(
                        label: "은퇴 후 수익률",
                        value: String(format: "%.1f%%", profile.postRetirementReturnRate),
                        valueColor: Color.Exit.accent
                    )
                    
                    FormulaValueRow(
                        label: "계산된 목표 자산",
                        value: ExitNumberFormatter.formatToEokManWon(result.targetAssets),
                        valueColor: Color.Exit.accent,
                        isBold: true
                    )
                }
            }
        }
    }
    
    // MARK: - D-DAY Section
    
    private var dDaySection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            // 헤더
            HStack(spacing: ExitSpacing.sm) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(Color.Exit.accent)
                Text("D-DAY 계산")
                    .font(.Exit.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            Text("월복리 시뮬레이션으로 목표 도달 시점 계산")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            
            // 과정 설명
            VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                FormulaStep(number: 1, text: "매월 초 투자금 추가")
                FormulaStep(number: 2, text: "매월 말 은퇴 전 수익률로 복리 적용")
                FormulaStep(number: 3, text: "목표 자산 도달까지 반복")
            }
            .padding(.vertical, ExitSpacing.sm)
            
            // 월 수익률 공식
            HStack(spacing: ExitSpacing.sm) {
                Text("월 수익률")
                    .foregroundStyle(Color.Exit.accent)
                Text("=")
                Text("(1 + 은퇴 전 연 수익률)^(1/12) - 1")
            }
            .font(.Exit.caption)
            .foregroundStyle(Color.Exit.primaryText)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, ExitSpacing.sm)
            
            // 현재 값 예시
            if let profile = appState.userProfile, let result = appState.retirementResult {
                VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                    Text("현재 설정값:")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.tertiaryText)
                    
                    FormulaValueRow(
                        label: "현재 자산",
                        value: ExitNumberFormatter.formatToEokManWon(result.currentAssets)
                    )
                    FormulaValueRow(
                        label: "목표 자산",
                        value: ExitNumberFormatter.formatToEokManWon(result.targetAssets)
                    )
                    FormulaValueRow(
                        label: "월 투자금",
                        value: ExitNumberFormatter.formatToManWon(profile.monthlyInvestment)
                    )
                    FormulaValueRow(
                        label: "은퇴 전 수익률",
                        value: String(format: "%.1f%%", profile.preRetirementReturnRate),
                        valueColor: Color.Exit.accent
                    )
                    
                    FormulaValueRow(
                        label: "목표 도달까지",
                        value: result.dDayString,
                        valueColor: Color.Exit.accent,
                        isBold: true
                    )
                }
            }
        }
    }
    
    // MARK: - Note Section
    
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            HStack(spacing: ExitSpacing.sm) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Color.Exit.caution)
                Text("참고 사항")
                    .font(.Exit.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                FormulaSheetNoteItem(text: "실제 투자 수익률은 변동될 수 있습니다.")
                FormulaSheetNoteItem(text: "물가 상승률, 세금 등 변수에 따라 달라질 수 있습니다.")
                FormulaSheetNoteItem(text: "본 계산은 참고용이며 투자 조언이 아닙니다.")
            }
        }
    }
}

// MARK: - Formula Step

private struct FormulaStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: ExitSpacing.sm) {
            Text("\(number)")
                .font(.Exit.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Color.Exit.accent)
                .clipShape(Circle())
            
            Text(text)
                .font(.Exit.body)
                .foregroundStyle(Color.Exit.primaryText)
        }
    }
}

// MARK: - Formula Value Row

private struct FormulaValueRow: View {
    let label: String
    let value: String
    var valueColor: Color = Color.Exit.primaryText
    var isBold: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            Spacer()
            Text(value)
                .font(isBold ? .Exit.body : .Exit.caption)
                .fontWeight(isBold ? .bold : .regular)
                .foregroundStyle(valueColor)
        }
    }
}

// MARK: - Note Item

private struct FormulaSheetNoteItem: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: ExitSpacing.sm) {
            Text("•")
                .foregroundStyle(Color.Exit.caution)
            Text(text)
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
        }
    }
}

// MARK: - Preview

#Preview {
    CalculationFormulaSheet()
        .preferredColorScheme(.dark)
        .environment(\.appState, AppStateManager())
}
