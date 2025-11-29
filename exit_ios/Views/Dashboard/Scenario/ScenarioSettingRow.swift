//
//  ScenarioSettingRow.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 시나리오 설정값 표시 행
struct ScenarioSettingRow: View {
    let label: String
    let value: String
    var isHidden: Bool = false
    var valueColor: Color = Color.Exit.primaryText
    
    var body: some View {
        HStack {
            Text(label)
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.Exit.caption)
                .fontWeight(.medium)
                .foregroundStyle(valueColor)
                .blur(radius: isHidden ? 8 : 0)
                .animation(.easeInOut(duration: 0.2), value: isHidden)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        
        VStack(spacing: 12) {
            ScenarioSettingRow(
                label: "은퇴 후 희망 월수입",
                value: "300만원"
            )
            
            ScenarioSettingRow(
                label: "현재 순자산",
                value: "7,500만원",
                isHidden: true
            )
            
            ScenarioSettingRow(
                label: "은퇴 전 연 목표 수익률",
                value: "6.5%",
                valueColor: Color.Exit.accent
            )
            
            ScenarioSettingRow(
                label: "예상 물가 상승률",
                value: "2.5%",
                valueColor: Color.Exit.caution
            )
        }
        .padding()
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
    }
    .preferredColorScheme(.dark)
}

