//
//  DesignSystem.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

// MARK: - Colors

extension Color {
    /// Exit 앱 디자인 시스템 색상
    enum Exit {
        /// 배경 색상 (#0A0A0A)
        static let background = Color(hex: "0A0A0A")
        
        /// 카드 배경 색상 (#121212)
        static let cardBackground = Color(hex: "121212")
        
        /// 보조 카드 배경 (#1A1A1A)
        static let secondaryCardBackground = Color(hex: "1A1A1A")
        
        /// 주요 텍스트 색상 (#FFFFFF)
        static let primaryText = Color.white
        
        /// 서브 텍스트 색상 (#A0A0A0)
        static let secondaryText = Color(hex: "A0A0A0")
        
        /// 비활성 텍스트 색상 (#666666)
        static let tertiaryText = Color(hex: "666666")
        
        /// 액센트 색상 - 청록 (#00D4AA)
        static let accent = Color(hex: "00D4AA")
        
        /// 경고 색상 - 빨강 (#FF3B30)
        static let warning = Color(hex: "FF3B30")
        
        /// 주의 색상 - 주황 (#FF9500)
        static let caution = Color(hex: "FF9500")
        
        /// 구분선 색상
        static let divider = Color(hex: "2A2A2A")
        
        /// 버튼 비활성 배경
        static let disabledBackground = Color(hex: "333333")
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradients

extension LinearGradient {
    /// Exit 앱 액센트 그라데이션
    static let exitAccent = LinearGradient(
        colors: [Color(hex: "00D4AA"), Color(hex: "00B894")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 경고 그라데이션 (빨강 → 주황 → 청록)
    static let exitWarning = LinearGradient(
        colors: [Color(hex: "FF3B30"), Color(hex: "FF9500"), Color(hex: "00D4AA")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// 카드 배경 그라데이션
    static let exitCard = LinearGradient(
        colors: [Color(hex: "1A1A1A"), Color(hex: "121212")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// 다크 그라데이션 배경
    static let exitBackground = LinearGradient(
        colors: [Color(hex: "0F0F0F"), Color(hex: "0A0A0A")],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Typography

extension Font {
    /// Exit 앱 타이포그래피
    enum Exit {
        /// 대형 제목 (42pt Heavy)
        static let largeTitle = Font.system(size: 42, weight: .heavy, design: .default)
        
        /// 제목 (32pt Bold)
        static let title = Font.system(size: 32, weight: .bold, design: .default)
        
        /// 중형 제목 (24pt Semibold)
        static let title2 = Font.system(size: 24, weight: .semibold, design: .default)
        
        /// 소형 제목 (20pt Semibold)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
        
        /// 본문 (18pt Medium)
        static let body = Font.system(size: 18, weight: .medium, design: .default)
        
        /// 서브 본문 (16pt Regular)
        static let subheadline = Font.system(size: 16, weight: .regular, design: .default)
        
        /// 캡션 (14pt Regular)
        static let caption = Font.system(size: 14, weight: .regular, design: .default)
        
        /// 소형 캡션 (12pt Regular)
        static let caption2 = Font.system(size: 12, weight: .regular, design: .default)
        
        /// 대형 숫자 (96pt Heavy, Tabular)
        static let scoreDisplay = Font.system(size: 96, weight: .heavy, design: .default).monospacedDigit()
        
        /// 중형 숫자 (48pt Heavy, Tabular)
        static let numberDisplay = Font.system(size: 48, weight: .heavy, design: .default).monospacedDigit()
        
        /// 숫자 (24pt Semibold, Tabular)
        static let number = Font.system(size: 24, weight: .semibold, design: .default).monospacedDigit()
        
        /// 키패드 숫자 (28pt Medium)
        static let keypad = Font.system(size: 28, weight: .medium, design: .default)
    }
}

// MARK: - Spacing & Sizing

enum ExitSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum ExitRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let full: CGFloat = 9999
}

// MARK: - Shadows

extension View {
    /// Exit 카드 그림자
    func exitCardShadow() -> some View {
        self.shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    /// Exit 버튼 그림자
    func exitButtonShadow() -> some View {
        self.shadow(color: Color.Exit.accent.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - View Modifiers

struct ExitCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(ExitSpacing.lg)
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
            .exitCardShadow()
    }
}

struct ExitPrimaryButtonStyle: ViewModifier {
    var isEnabled: Bool = true
    
    func body(content: Content) -> some View {
        content
            .font(.Exit.subheadline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                isEnabled ? LinearGradient.exitAccent : LinearGradient(colors: [Color.Exit.disabledBackground], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
            .exitButtonShadow()
    }
}

struct ExitSecondaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.Exit.subheadline)
            .foregroundStyle(Color.Exit.secondaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: ExitRadius.md)
                    .stroke(Color.Exit.divider, lineWidth: 1)
            )
    }
}

extension View {
    func exitCard() -> some View {
        modifier(ExitCardStyle())
    }
    
    func exitPrimaryButton(isEnabled: Bool = true) -> some View {
        modifier(ExitPrimaryButtonStyle(isEnabled: isEnabled))
    }
    
    func exitSecondaryButton() -> some View {
        modifier(ExitSecondaryButtonStyle())
    }
}

