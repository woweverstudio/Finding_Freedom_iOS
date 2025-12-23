//
//  SimulationLoadingView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 시뮬레이션 로딩 화면
struct SimulationLoadingView: View {
    let isSimulating: Bool
    let progress: Double
    let phase: SimulationViewModel.SimulationPhase
    
    var body: some View {
        VStack(spacing: ExitSpacing.xl) {
            Spacer()
            
            // 메인 아이콘 - SF Symbol 로딩 애니메이션
            Image(systemName: "cube.transparent.fill")
                .font(.system(size: 60, weight: .medium))
                .foregroundStyle(Color.Exit.accent)
                .symbolEffect(.rotate, value: progress)
            
            // 제목
            Text("시뮬레이션 진행 중")
                .font(.Exit.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.Exit.primaryText)
            
            // 시뮬레이션 단계
            Text(phase.description)
                .font(.Exit.body)
                .foregroundStyle(Color.Exit.secondaryText)
            
            // 진행률 바
            VStack(spacing: ExitSpacing.sm) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.Exit.divider)
                            .frame(height: 16)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.Exit.accent)
                            .frame(
                                width: geometry.size.width * progress,
                                height: 16
                            )
                            .animation(.easeInOut(duration: 0.2), value: progress)
                    }
                }
                .frame(height: 16)
                
                Text("\(Int(progress * 100))%")
                    .font(.Exit.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.accent)
            }
            .padding(.horizontal, ExitSpacing.xxl)
            
            // 설명
            Text("30,000가지 미래를 시뮬레이션하고 있습니다")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            
            Spacer()
        }
    }
}

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        
        SimulationLoadingView(
            isSimulating: true,
            progress: 0.65,
            phase: .preRetirement
        )
    }
    .preferredColorScheme(.dark)
}
