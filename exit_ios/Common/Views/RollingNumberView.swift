//
//  RollingNumberView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 파친코 스타일 숫자 롤링 애니메이션 뷰
struct RollingNumberView: View {
    let value: Int
    let font: Font
    let color: Color
    let animationID: UUID
    
    @State private var displayedValue: Int = 0
    @State private var isAnimating: Bool = false
    
    init(value: Int, font: Font = .Exit.title2, color: Color = Color.Exit.accent, animationID: UUID = UUID()) {
        self.value = value
        self.font = font
        self.color = color
        self.animationID = animationID
    }
    
    var body: some View {
        Text("\(displayedValue)")
            .font(font)
            .fontWeight(.heavy)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: Double(displayedValue)))
            .onChange(of: animationID) { _, _ in
                startAnimation()
            }
            .onAppear {
                // 초기 로드 시에도 애니메이션
                startAnimation()
            }
    }
    
    private func startAnimation() {
        guard !isAnimating else { return }
        isAnimating = true
        displayedValue = 0
        
        // 단계별 애니메이션으로 숫자가 올라가는 효과
        let totalDuration: Double = 0.4
        let steps = min(12, max(6, value / 4))
        let stepDuration = totalDuration / Double(steps)
        
        for step in 0...steps {
            let delay = stepDuration * Double(step)
            let progress = Double(step) / Double(steps)
            let targetValue = Int(Double(value) * progress)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.15, dampingFraction: 0.8)) {
                    displayedValue = targetValue
                }
                
                if step == steps {
                    isAnimating = false
                }
            }
        }
    }
}

/// D-Day 롤링 애니메이션 뷰 (X년 Y개월 형식)
struct DDayRollingView: View {
    let months: Int
    let animationID: UUID
    
    @State private var displayedYears: Int = 0
    @State private var displayedMonths: Int = 0
    @State private var isAnimating: Bool = false
    
    private var targetYears: Int { months / 12 }
    private var targetMonths: Int { months % 12 }
    
    var body: some View {
        HStack(spacing: 4) {
            if targetYears > 0 {
                HStack(spacing: 2) {
                    Text("\(displayedYears)")
                        .font(.Exit.title2)
                        .fontWeight(.heavy)
                        .foregroundStyle(Color.Exit.accent)
                        .contentTransition(.numericText(value: Double(displayedYears)))
                    
                    Text("년")
                        .font(.Exit.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.Exit.accent)
                }
            }
            
            HStack(spacing: 2) {
                Text("\(displayedMonths)")
                    .font(.Exit.title2)
                    .fontWeight(.heavy)
                    .foregroundStyle(Color.Exit.accent)
                    .contentTransition(.numericText(value: Double(displayedMonths)))
                
                Text("개월")
                    .font(.Exit.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.accent)
            }
        }
        .onChange(of: animationID) { _, _ in
            startAnimation()
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        guard !isAnimating else { return }
        isAnimating = true
        displayedYears = 0
        displayedMonths = 0
        
        let totalDuration: Double = 0.5
        let steps = 15
        let stepDuration = totalDuration / Double(steps)
        
        for step in 0...steps {
            let delay = stepDuration * Double(step)
            let progress = Double(step) / Double(steps)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.12, dampingFraction: 0.85)) {
                    displayedYears = Int(Double(targetYears) * progress)
                    displayedMonths = Int(Double(targetMonths) * progress)
                }
                
                if step == steps {
                    isAnimating = false                    
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        RollingNumberView(value: 156, font: .Exit.title2, color: Color.Exit.accent)
        
        DDayRollingView(months: 156, animationID: UUID())
    }
    .padding()
    .background(Color.Exit.background)
    .preferredColorScheme(.dark)
}

