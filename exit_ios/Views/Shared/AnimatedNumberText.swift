//
//  AnimatedNumberText.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 숫자가 카운트업 애니메이션으로 표시되는 텍스트
struct AnimatedNumberText: View {
    let value: Double
    let formatter: NumberFormatter?

    @State private var displayValue: Double = 0

    init(value: Double, formatter: NumberFormatter? = nil) {
        self.value = value
        self.formatter = formatter
    }

    var body: some View {
        Text(formattedValue)
            .contentTransition(.numericText(value: displayValue))
            .animation(.easeOut(duration: 0.8), value: displayValue)
            .onAppear {
                displayValue = value
            }
            .onChange(of: value) { oldValue, newValue in
                displayValue = newValue
            }
    }

    private var formattedValue: String {
        if let formatter = formatter {
            return formatter.string(from: NSNumber(value: displayValue)) ?? "\(Int(displayValue))"
        } else {
            return ExitNumberFormatter.formatToManWon(displayValue)
        }
    }
}

/// 퍼센트 포맷 애니메이션 숫자
struct AnimatedPercentText: View {
    let value: Double
    
    @State private var displayValue: Double = 0
    
    var body: some View {
        Text("\(displayValue, specifier: "%.1f")%")
            .contentTransition(.numericText(value: displayValue))
            .animation(.easeOut(duration: 0.8), value: displayValue)
            .onAppear {
                displayValue = value
            }
            .onChange(of: value) { oldValue, newValue in
                displayValue = newValue
            }
    }
}

/// 정수 포맷 애니메이션 숫자
struct AnimatedIntText: View {
    let value: Int
    
    @State private var displayValue: Double = 0
    
    var body: some View {
        Text("\(Int(displayValue))")
            .contentTransition(.numericText(value: displayValue))
            .animation(.easeOut(duration: 0.8), value: displayValue)
            .onAppear {
                displayValue = Double(value)
            }
            .onChange(of: value) { oldValue, newValue in
                displayValue = Double(newValue)
            }
    }
}

/// 쉼표 구분된 카운트 애니메이션 숫자 (예: 10,000)
struct AnimatedCountText: View {
    let value: Int
    
    @State private var displayValue: Double = 0
    
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter
    }()
    
    var body: some View {
        Text(formattedValue)
            .contentTransition(.numericText(value: displayValue))
            .animation(.easeOut(duration: 0.8), value: displayValue)
            .onAppear {
                displayValue = Double(value)
            }
            .onChange(of: value) { oldValue, newValue in
                displayValue = Double(newValue)
            }
    }
    
    private var formattedValue: String {
        Self.formatter.string(from: NSNumber(value: Int(displayValue))) ?? "\(Int(displayValue))"
    }
}

