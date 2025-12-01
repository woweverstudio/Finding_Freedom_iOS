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
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(Color.Exit.accent)
                Text("시뮬레이션 설정")
                    .font(.Exit.title3)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            Divider()
                .background(Color.Exit.divider)
            
            // 다시 실행 버튼
            Button {
                onRefresh()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                    Text("다시 시뮬레이션")
                        .font(.Exit.body)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, ExitSpacing.md)
                .background(LinearGradient.exitAccent)
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
            }
            .buttonStyle(.plain)
            
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
        .padding(ExitSpacing.lg)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
        .padding(.horizontal, ExitSpacing.md)
    }
}

