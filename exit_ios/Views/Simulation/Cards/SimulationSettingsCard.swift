//
//  SimulationSettingsCard.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 시뮬레이션 설정 카드
struct SimulationSettingsCard: View {
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            // 헤더
            ExitCardHeader(icon: "slider.horizontal.3", title: "시뮬레이션 설정")
            
            // 다시 실행 버튼
            ExitCTAButton(
                title: "다시 시뮬레이션",
                icon: "arrow.clockwise",
                size: .medium,
                action: onRefresh
            )
            
            // Pro 기능 안내
            HStack(spacing: ExitSpacing.sm) {
                Image(systemName: "crown.fill")
                    .foregroundStyle(Color.Exit.caution)
                Text("Pro에서 변동성과 시뮬레이션 횟수 조정 가능")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            .padding(ExitSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.Exit.secondaryCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
        }
        .exitCard()
        .padding(.horizontal, ExitSpacing.md)
    }
}

