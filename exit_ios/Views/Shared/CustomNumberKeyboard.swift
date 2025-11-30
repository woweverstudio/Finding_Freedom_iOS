//
//  CustomNumberKeyboard.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 커스텀 숫자 키보드 컴포넌트
struct CustomNumberKeyboard: View {
    @Binding var value: Double
    var showNegativeToggle: Bool = false
    var onConfirm: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: ExitSpacing.sm) {
            // 빠른 금액 버튼 (가로 스크롤)
            quickAmountButtons
            
            // 숫자 패드
            numberPad
        }
        .padding(.horizontal, ExitSpacing.md)
        .padding(.vertical, ExitSpacing.md)
        .background(Color.Exit.background)
    }
    
    // MARK: - Quick Amount Buttons
    
    private var quickAmountButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ExitSpacing.sm) {
                if showNegativeToggle {
                    QuickButton(title: value >= 0 ? "음수" : "양수") {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            value = -value
                        }
                    }
                }
                
                QuickButton(title: "+10만") {
                    addAmount(100_000)
                }
                
                QuickButton(title: "+100만") {
                    addAmount(1_000_000)
                }
                
                QuickButton(title: "+1000만") {
                    addAmount(10_000_000)
                }
                
                QuickButton(title: "+1억") {
                    addAmount(100_000_000)
                }
                
                QuickButton(title: "초기화", isDestructive: true) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        value = 0
                    }
                }
            }
            .padding(.horizontal, ExitSpacing.xs)
        }
    }
    
    // MARK: - Number Pad
    
    private var numberPad: some View {
        VStack(spacing: ExitSpacing.sm) {
            // Row 1: 1, 2, 3
            HStack(spacing: ExitSpacing.sm) {
                NumberKey(digit: "1") { appendDigit("1") }
                NumberKey(digit: "2") { appendDigit("2") }
                NumberKey(digit: "3") { appendDigit("3") }
            }
            
            // Row 2: 4, 5, 6
            HStack(spacing: ExitSpacing.sm) {
                NumberKey(digit: "4") { appendDigit("4") }
                NumberKey(digit: "5") { appendDigit("5") }
                NumberKey(digit: "6") { appendDigit("6") }
            }
            
            // Row 3: 7, 8, 9
            HStack(spacing: ExitSpacing.sm) {
                NumberKey(digit: "7") { appendDigit("7") }
                NumberKey(digit: "8") { appendDigit("8") }
                NumberKey(digit: "9") { appendDigit("9") }
            }
            
            // Row 4: ., 0, ←
            HStack(spacing: ExitSpacing.sm) {
                NumberKey(digit: "00") { appendDigit("00") }
                NumberKey(digit: "0") { appendDigit("0") }
                NumberKey(digit: "←", isAction: true) { deleteLastDigit() }
            }
        }
    }
    
    // MARK: - Actions
    
    private func addAmount(_ amount: Double) {
        let newValue = value + amount
        if newValue <= 100_000_000_000 {  // 1000억 제한
            withAnimation(.easeInOut(duration: 0.15)) {
                value = newValue
            }
        }
    }
    
    private func appendDigit(_ digit: String) {
        let isNegative = value < 0
        let absValue = abs(value)
        var currentString = String(Int(absValue))
        
        if currentString == "0" {
            currentString = digit
        } else {
            currentString += digit
        }
        
        if let newValue = Double(currentString), newValue <= 100_000_000_000 {
            withAnimation(.easeInOut(duration: 0.1)) {
                value = isNegative ? -newValue : newValue
            }
        }
    }
    
    private func deleteLastDigit() {
        let isNegative = value < 0
        var currentString = String(Int(abs(value)))
        
        if currentString.count > 1 {
            currentString.removeLast()
            let newValue = Double(currentString) ?? 0
            withAnimation(.easeInOut(duration: 0.1)) {
                value = isNegative ? -newValue : newValue
            }
        } else {
            withAnimation(.easeInOut(duration: 0.1)) {
                value = 0
            }
        }
    }
}

// MARK: - Quick Button

private struct QuickButton: View {
    let title: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button {
            HapticService.shared.soft()
            action()
        } label: {
            Text(title)
                .font(.Exit.caption)
                .fontWeight(.medium)
                .foregroundStyle(isDestructive ? Color.Exit.warning : Color.Exit.accent)
                .padding(.horizontal, ExitSpacing.md)
                .padding(.vertical, ExitSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: ExitRadius.sm)
                        .fill(isDestructive ? Color.Exit.warning.opacity(0.15) : Color.Exit.accent.opacity(0.15))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ExitRadius.sm)
                        .stroke(isDestructive ? Color.Exit.warning.opacity(0.3) : Color.Exit.accent.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Number Key

private struct NumberKey: View {
    let digit: String
    var isAction: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button {
            HapticService.shared.soft()
            action()
        } label: {
            Text(digit)
                .font(.Exit.keypad)
                .foregroundStyle(isAction ? Color.Exit.accent : Color.Exit.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: ExitRadius.md)
                        .fill(Color.Exit.secondaryCardBackground)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        
        VStack {
            Spacer()
            
            Text("75,000,000")
                .font(.Exit.numberDisplay)
                .foregroundStyle(Color.Exit.primaryText)
            
            Text("7,500만원")
                .font(.Exit.title3)
                .foregroundStyle(Color.Exit.accent)
            
            Spacer()
            
            CustomNumberKeyboard(value: .constant(75_000_000), showNegativeToggle: true)
        }
    }
    .preferredColorScheme(.dark)
}

