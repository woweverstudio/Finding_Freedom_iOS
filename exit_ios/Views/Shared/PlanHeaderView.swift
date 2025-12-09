//
//  PlanHeaderView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

// MARK: - Plan Header View (상단 드롭다운 편집 패널)

/// 상단 네비게이션 바 - 아래로 드래그하면 편집 패널이 펼쳐짐
struct PlanHeaderView: View {
    @Environment(\.appState) private var appState
    
    let hideAmounts: Bool
    
    /// 패널 펼침 상태 (외부에서 바인딩 가능)
    @Binding var isExpanded: Bool
    
    /// 편집 중인 임시 값들 (슬라이더용)
    @State private var editingCurrentAsset: Double = 100_000_000
    @State private var editingMonthlyIncome: Double = 3_000_000
    @State private var editingMonthlyInvestment: Double = 500_000
    @State private var editingPreReturnRate: Double = 6.5
    @State private var editingPostReturnRate: Double = 5.0
    
    /// 기본 이니셜라이저 (외부 바인딩 사용)
    init(hideAmounts: Bool, isExpanded: Binding<Bool>) {
        self.hideAmounts = hideAmounts
        self._isExpanded = isExpanded
    }
    
    /// 편의 이니셜라이저 (내부 상태 사용)
    init(hideAmounts: Bool) {
        self.hideAmounts = hideAmounts
        self._isExpanded = .constant(false)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 메인 헤더 (탭 영역)
            headerButton
            
            // 펼쳐지는 편집 패널
            if isExpanded {
                editPanel
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: ExitRadius.lg)
                .stroke(isExpanded ? Color.Exit.accent.opacity(0.4) : Color.Exit.divider, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)
        .padding(.horizontal, ExitSpacing.md)
        .padding(.vertical, ExitSpacing.xs)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
        .onAppear {
            syncEditingValues()
        }
        .onChange(of: appState.userProfile?.updatedAt) { _, _ in
            syncEditingValues()
        }
        .onChange(of: isExpanded) { oldValue, newValue in
            // 외부에서 닫힐 때 (true -> false) 자동으로 설정 적용
            if oldValue && !newValue {
                applyChangesWithoutAnimation()
            }
        }
    }
    
    // MARK: - Header Button (컴팩트 스타일)
    
    private var headerButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        } label: {
            VStack(spacing: ExitSpacing.md) {
                // 핵심 정보 (한 줄)
                if !isExpanded {
                    infoRow
                    pullIndicator
                }
            }
            .padding(.horizontal, ExitSpacing.md)
            .padding(.top, isExpanded ? ExitSpacing.sm : ExitSpacing.md)
            .padding(.bottom, ExitSpacing.xs)
        }
        .buttonStyle(HeaderButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 10)
                .onEnded { value in
                    // 접힌 상태에서 아래로 스와이프하면 펼치기
                    if !isExpanded && value.translation.height > 20 {
                        HapticService.shared.light()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isExpanded = true
                        }
                    }
                }
        )
    }
    
    // MARK: - Info Row (한 줄 레이아웃)
    
    private var infoRow: some View {
        HStack(spacing: 0) {
            // 현재 자산
            infoItem(
                label: "자산",
                value: hideAmounts ? "•••" : ExitNumberFormatter.formatToEokMan(editingCurrentAsset),
                color: Color.Exit.primaryText
            )
            
            // 월 투자
            infoItem(
                label: "월투자",
                value: ExitNumberFormatter.formatToEokMan(editingMonthlyInvestment),
                color: Color.Exit.positive
            )
            
            // 수익률
            infoItem(
                label: "수익률",
                value: String(format: "%.1f%%", editingPreReturnRate),
                color: Color.Exit.accent
            )
            
            // 목표 월수입
            infoItem(
                label: "목표",
                value: ExitNumberFormatter.formatToEokMan(editingMonthlyIncome),
                color: Color.Exit.accent
            )
        }
    }
    
    // MARK: - Info Item
    
    private func infoItem(
        label: String,
        value: String,
        color: Color
    ) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(Font.Exit.caption2)
                .foregroundStyle(Color.Exit.tertiaryText)
            
            Text(value)
                .font(Font.Exit.caption3)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Pull Indicator
    
    private var pullIndicator: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.Exit.tertiaryText.opacity(0.5))
            .frame(width: 32, height: 4)
    }
    
    // MARK: - Edit Panel (펼쳐지는 편집 영역)
    
    private var editPanel: some View {
        VStack(spacing: ExitSpacing.md) {
            // 현재 자산 (순자산) + 조정 버튼
            assetSliderWithButtons
            
            // 매월 투자금액
            sliderRow(
                label: "매월 투자금액",
                value: $editingMonthlyInvestment,
                range: 0...10_000_000,
                step: 100_000,
                formatter: { ExitNumberFormatter.formatToManWon($0) },
                color: Color.Exit.positive
            )
            
            // 은퇴 전 목표 수익률
            sliderRow(
                label: "은퇴 전 수익률",
                value: $editingPreReturnRate,
                range: 0.5...50.0,
                step: 0.5,
                formatter: { String(format: "%.1f%%", $0) },
                color: Color.Exit.accent
            )
            
            // 은퇴 후 희망 월수입
            sliderRow(
                label: "은퇴 후 희망 월수입",
                value: $editingMonthlyIncome,
                range: 500_000...20_000_000,
                step: 100_000,
                formatter: { ExitNumberFormatter.formatToManWon($0) },
                color: Color.Exit.accent
            )
            
            // 은퇴 후 목표 수익률
            sliderRow(
                label: "은퇴 후 수익률",
                value: $editingPostReturnRate,
                range: 0.5...50.0,
                step: 0.5,
                formatter: { String(format: "%.1f%%", $0) },
                color: Color.Exit.caution
            )
            
            Button {
                applyChanges()
            } label: {
                Text("적용")
                    .exitSecondaryButton()
            }
        }
        .padding(.horizontal, ExitSpacing.md)
        .padding(.bottom, ExitSpacing.md)
    }
    
    // MARK: - Asset Slider with Adjustment Buttons
    
    private var assetSliderWithButtons: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.xs) {
            // 라벨 + 값
            HStack {
                Text("현재 자산")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                Spacer()
                
                Text(ExitNumberFormatter.formatToEokManWon(editingCurrentAsset))
                    .font(.Exit.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            // 슬라이더
            Slider(value: $editingCurrentAsset, in: 0...10_000_000_000, step: 10_000_000)
                .tint(Color.Exit.primaryText)
            
            // 조정 버튼들
            HStack(spacing: ExitSpacing.xs) {
                assetAdjustButton("+10만", amount: 100_000)
                assetAdjustButton("+100만", amount: 1_000_000)
                assetAdjustButton("+1000만", amount: 10_000_000)
                assetAdjustButton("+1억", amount: 100_000_000)
            }
        }
    }
    
    // MARK: - Asset Adjust Button
    
    private func assetAdjustButton(_ title: String, amount: Double) -> some View {
        Button {
            editingCurrentAsset = min(editingCurrentAsset + amount, 10_000_000_000)
        } label: {
            Text(title)
                .font(Font.Exit.caption)
                .foregroundStyle(Color.Exit.accent)
                .padding(.horizontal, ExitSpacing.md)
                .padding(.vertical, ExitSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: ExitRadius.sm)
                        .fill(Color.Exit.accent.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Slider Row
    
    private func sliderRow(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        formatter: @escaping (Double) -> String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: ExitSpacing.xs) {
            HStack {
                Text(label)
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                Spacer()
                
                Text(formatter(value.wrappedValue))
                    .font(.Exit.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
            }
            
            Slider(value: value, in: range, step: step)
                .tint(color)
        }
    }
    
    // MARK: - Helper Methods
    
    private func syncEditingValues() {
        editingCurrentAsset = appState.currentAssetAmount
        
        guard let profile = appState.userProfile else { return }
        editingMonthlyIncome = profile.desiredMonthlyIncome
        editingMonthlyInvestment = profile.monthlyInvestment
        editingPreReturnRate = profile.preRetirementReturnRate
        editingPostReturnRate = profile.postRetirementReturnRate
    }
    
    private func applyChanges() {
        applyChangesWithoutAnimation()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isExpanded = false
        }
    }
    
    /// 설정만 적용 (애니메이션 없이, 외부에서 닫힐 때 사용)
    private func applyChangesWithoutAnimation() {
        // 변경 사항이 있는지 확인
        guard hasChanges else { return }
        
        // 자산 업데이트
        appState.updateCurrentAsset(editingCurrentAsset)
        
        // 설정 업데이트
        appState.updateSettings(
            desiredMonthlyIncome: editingMonthlyIncome,
            monthlyInvestment: editingMonthlyInvestment,
            preRetirementReturnRate: editingPreReturnRate,
            postRetirementReturnRate: editingPostReturnRate
        )
        
        HapticService.shared.success()
    }
    
    /// 편집 중인 값이 기존 값과 다른지 확인
    private var hasChanges: Bool {
        guard let profile = appState.userProfile else { return false }
        
        let assetChanged = abs(editingCurrentAsset - appState.currentAssetAmount) > 1
        let incomeChanged = abs(editingMonthlyIncome - profile.desiredMonthlyIncome) > 1
        let investmentChanged = abs(editingMonthlyInvestment - profile.monthlyInvestment) > 1
        let preRateChanged = abs(editingPreReturnRate - profile.preRetirementReturnRate) > 0.01
        let postRateChanged = abs(editingPostReturnRate - profile.postRetirementReturnRate) > 0.01
        
        return assetChanged || incomeChanged || investmentChanged || preRateChanged || postRateChanged
    }
}

// MARK: - Header Button Style

private struct HeaderButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var isExpanded = false
        
        var body: some View {
            ZStack {
                Color.Exit.background.ignoresSafeArea()
                
                VStack {
                    PlanHeaderView(hideAmounts: false, isExpanded: $isExpanded)
                    
                    Spacer()
                }
            }
            .preferredColorScheme(.dark)
            .environment(\.appState, AppStateManager())
        }
    }
    
    return PreviewWrapper()
}
