//
//  ScenarioTabBar.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 시나리오 탭 바 컴포넌트
struct ScenarioTabBar: View {
    let scenarios: [Scenario]
    let selectedScenario: Scenario?
    let onSelect: (Scenario) -> Void
    let onSettings: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ExitSpacing.sm) {
                // 시나리오 설정 버튼
                Button(action: onSettings) {
                    HStack(spacing: ExitSpacing.xs) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.Exit.caption)
                        Text("설정")
                            .font(.Exit.caption)
                    }
                    .foregroundStyle(Color.Exit.secondaryText)
                    .padding(.horizontal, ExitSpacing.md)
                    .padding(.vertical, ExitSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: ExitRadius.full)
                            .stroke(Color.Exit.divider, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                // 시나리오 칩들
                ForEach(scenarios, id: \.id) { scenario in
                    ScenarioChip(
                        name: scenario.name,
                        isSelected: scenario.id == selectedScenario?.id
                    ) {
                        onSelect(scenario)
                    }
                }
            }
            .padding(.horizontal, ExitSpacing.md)
        }
    }
}

// MARK: - Scenario Chip

private struct ScenarioChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.Exit.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Color.white : Color.Exit.secondaryText)
                .padding(.horizontal, ExitSpacing.md)
                .padding(.vertical, ExitSpacing.sm)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient.exitAccent
                        } else {
                            Color.Exit.secondaryCardBackground
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.full))
                .overlay(
                    RoundedRectangle(cornerRadius: ExitRadius.full)
                        .stroke(isSelected ? Color.clear : Color.Exit.divider, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        
        VStack {
            let scenarios = [
                Scenario(name: "내 계획", desiredMonthlyIncome: 3_000_000, monthlyInvestment: 2_000_000, isActive: true),
                Scenario(name: "물가폭등", desiredMonthlyIncome: 3_000_000, monthlyInvestment: 2_000_000),
                Scenario(name: "주식폭락", desiredMonthlyIncome: 3_000_000, monthlyInvestment: 2_000_000),
                Scenario(name: "로또당첨", desiredMonthlyIncome: 3_000_000, assetOffset: 1_000_000_000, monthlyInvestment: 2_000_000)
            ]
            
            ScenarioTabBar(
                scenarios: scenarios,
                selectedScenario: scenarios.first,
                onSelect: { _ in },
                onSettings: { }
            )
        }
    }
    .preferredColorScheme(.dark)
}

