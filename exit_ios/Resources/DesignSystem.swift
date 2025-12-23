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
        // MARK: Background
        
        /// 앱 배경색 (#0A0A0A)
        static let background = Color(hex: "0A0A0A")
        
        /// 카드 배경색 (#121212)
        static let cardBackground = Color(hex: "121212")
        
        /// 보조 카드 배경색 (#1A1A1A)
        static let secondaryCardBackground = Color(hex: "1A1A1A")
        
        // MARK: Text
        
        /// 주요 텍스트 (#FFFFFF)
        static let primaryText = Color.white
        
        /// 보조 텍스트 (#A0A0A0)
        static let secondaryText = Color(hex: "A0A0A0")
        
        /// 비활성 텍스트 (#666666)
        static let tertiaryText = Color(hex: "666666")
        
        // MARK: Semantic
        
        /// 액센트 - 청록 (#00D4AA)
        static let accent = Color(hex: "00D4AA")
        
        /// 긍정 - 초록 (#34C759)
        static let positive = Color(hex: "34C759")
        
        /// 주의 - 주황 (#FF9500)
        static let caution = Color(hex: "FF9500")
        
        /// 경고 - 빨강 (#FF3B30)
        static let warning = Color(hex: "FF3B30")
        
        // MARK: UI Elements
        
        /// 구분선 (#2A2A2A)
        static let divider = Color(hex: "2A2A2A")
        
        /// 비활성 배경 (#333333)
        static let disabledBackground = Color(hex: "333333")
    }
}

// MARK: - Color Hex Init

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
    /// 액센트 그라데이션 (청록)
    static let exitAccent = LinearGradient(
        colors: [Color(hex: "00D4AA"), Color(hex: "00B894")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 카드 배경 그라데이션
    static let exitCard = LinearGradient(
        colors: [Color(hex: "1A1A1A"), Color(hex: "121212")],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Typography

extension Font {
    /// Exit 앱 타이포그래피
    enum Exit {
        // MARK: Headings
        
        /// 제목 (32pt Bold)
        static let title = Font.system(size: 32, weight: .bold)
        
        /// 중형 제목 (24pt Semibold)
        static let title2 = Font.system(size: 24, weight: .semibold)
        
        /// 소형 제목 (20pt Semibold)
        static let title3 = Font.system(size: 20, weight: .semibold)
        
        // MARK: Body
        
        /// 본문 (18pt Medium)
        static let body = Font.system(size: 18, weight: .medium)
        
        /// 서브 본문 (16pt Regular)
        static let subheadline = Font.system(size: 16, weight: .regular)
        
        // MARK: Captions
        
        /// 캡션 (14pt Regular)
        static let caption = Font.system(size: 14, weight: .regular)
        
        /// 소형 캡션 (12pt Regular)
        static let caption2 = Font.system(size: 12, weight: .regular)
        
        /// 캡션 강조 (13pt Semibold Rounded)
        static let caption3 = Font.system(size: 13, weight: .semibold, design: .rounded)
        
        // MARK: Numbers
        
        /// 대형 숫자 (42pt Heavy Tabular)
        static let numberDisplay = Font.system(size: 42, weight: .heavy).monospacedDigit()
        
        /// 숫자 (24pt Semibold Tabular)
        static let number = Font.system(size: 24, weight: .semibold).monospacedDigit()
        
        /// 키패드 숫자 (28pt Medium)
        static let keypad = Font.system(size: 28, weight: .medium)
    }
}

// MARK: - Spacing

enum ExitSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

enum ExitRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

// MARK: - Shadow Extensions

extension View {
    /// 카드 그림자
    func exitCardShadow() -> some View {
        shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    /// 버튼 그림자 (액센트)
    func exitButtonShadow() -> some View {
        shadow(color: Color.Exit.accent.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Card Styles

/// 카드 스타일 옵션
enum ExitCardSize {
    case small   // padding: md, radius: md
    case medium  // padding: md, radius: lg
    case large   // padding: lg, radius: lg
    
    var padding: CGFloat {
        switch self {
        case .small, .medium: return ExitSpacing.md
        case .large: return ExitSpacing.lg
        }
    }
    
    var radius: CGFloat {
        switch self {
        case .small: return ExitRadius.md
        case .medium, .large: return ExitRadius.lg
        }
    }
}

struct ExitCardModifier: ViewModifier {
    let size: ExitCardSize
    let hasShadow: Bool
    
    func body(content: Content) -> some View {
        content
            .padding(size.padding)
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: size.radius))
            .if(hasShadow) { view in
                view.exitCardShadow()
            }
    }
}

extension View {
    /// 카드 스타일 적용
    func exitCard(_ size: ExitCardSize = .large, shadow: Bool = false) -> some View {
        modifier(ExitCardModifier(size: size, hasShadow: shadow))
    }
    
    /// 조건부 modifier
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Button Styles

struct ExitPrimaryButtonModifier: ViewModifier {
    var isEnabled: Bool = true
    
    func body(content: Content) -> some View {
        content
            .font(.Exit.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                isEnabled 
                    ? LinearGradient.exitAccent 
                    : LinearGradient(colors: [Color.Exit.disabledBackground], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
    }
}

struct ExitSecondaryButtonModifier: ViewModifier {
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

struct ExitPromptButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(ExitSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: ExitRadius.lg)
                    .fill(Color.Exit.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: ExitRadius.lg)
                            .stroke(Color.Exit.accent, lineWidth: 1)
                    )
            )
    }
}

extension View {
    /// Primary 버튼 스타일
    func exitPrimaryButton(isEnabled: Bool = true) -> some View {
        modifier(ExitPrimaryButtonModifier(isEnabled: isEnabled))
    }
    
    /// Secondary 버튼 스타일
    func exitSecondaryButton() -> some View {
        modifier(ExitSecondaryButtonModifier())
    }
    
    /// Prompt 버튼 스타일 (테두리 강조)
    func exitPromptButton() -> some View {
        modifier(ExitPromptButtonModifier())
    }
}

// MARK: - CTA Button Component

/// Exit 앱의 공통 CTA 버튼
struct ExitCTAButton: View {
    let title: String
    var icon: String? = nil
    var style: Style = .primary
    var size: Size = .large
    var isEnabled: Bool = true
    var isLoading: Bool = false
    let action: () -> Void
    
    enum Style {
        case primary    // 액센트 그라데이션 배경
        case secondary  // 카드 배경 + 테두리
    }
    
    enum Size {
        case large   // 56pt, body 폰트
        case medium  // 52pt, caption 폰트
        case small   // 48pt, caption 폰트
        
        var height: CGFloat {
            switch self {
            case .large: return 56
            case .medium: return 52
            case .small: return 48
            }
        }
        
        var font: Font {
            switch self {
            case .large: return .Exit.body
            case .medium, .small: return .Exit.caption
            }
        }
        
        var iconSize: CGFloat { 14 }
        
        var radius: CGFloat {
            switch self {
            case .large: return ExitRadius.lg
            case .medium, .small: return ExitRadius.md
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ExitSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(style == .primary ? .white : Color.Exit.primaryText)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: size.iconSize, weight: .semibold))
                    }
                    
                    Text(title)
                        .font(size.font)
                        .fontWeight(.semibold)
                }
            }
            .foregroundStyle(style == .primary ? .white : Color.Exit.primaryText)
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: size.radius))
            .overlay(overlayView)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            if isEnabled {
                LinearGradient.exitAccent
            } else {
                LinearGradient(colors: [Color.Exit.disabledBackground], startPoint: .leading, endPoint: .trailing)
            }
        case .secondary:
            Color.Exit.cardBackground
        }
    }
    
    @ViewBuilder
    private var overlayView: some View {
        if style == .secondary {
            RoundedRectangle(cornerRadius: size.radius)
                .stroke(Color.Exit.divider, lineWidth: 1)
        }
    }
}

// MARK: - Section Header Component

/// 섹션 헤더 컴포넌트
struct ExitSectionHeader: View {
    let icon: String
    let title: String
    var iconColor: Color = Color.Exit.accent
    
    var body: some View {
        HStack(spacing: ExitSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(iconColor)
            
            Text(title)
                .font(.Exit.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.Exit.primaryText)
        }
    }
}

// MARK: - Card Header Component

/// 카드 내부 헤더 컴포넌트
struct ExitCardHeader: View {
    let icon: String
    let title: String
    var iconColor: Color = Color.Exit.accent
    var showDivider: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.Exit.title3)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            if showDivider {
                Divider()
                    .background(Color.Exit.divider)
            }
        }
    }
}

// MARK: - Previews

#Preview("CTA Buttons") {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        
        VStack(spacing: ExitSpacing.lg) {
            ExitCTAButton(
                title: "시뮬레이션 시작",
                icon: "play.fill",
                action: {}
            )
            
            ExitCTAButton(
                title: "분석하기",
                icon: "chart.bar.xaxis",
                isEnabled: false,
                action: {}
            )
            
            ExitCTAButton(
                title: "입금하기",
                icon: "plus.circle.fill",
                size: .medium,
                action: {}
            )
            
            ExitCTAButton(
                title: "자산 업데이트",
                icon: "arrow.triangle.2.circlepath",
                style: .secondary,
                size: .medium,
                action: {}
            )
            
            ExitCTAButton(
                title: "분석 중...",
                isLoading: true,
                action: {}
            )
        }
        .padding(ExitSpacing.lg)
    }
}

#Preview("Cards") {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        
        VStack(spacing: ExitSpacing.lg) {
            VStack(alignment: .leading, spacing: ExitSpacing.md) {
                ExitCardHeader(icon: "chart.pie.fill", title: "포트폴리오 분석")
                
                Text("카드 컨텐츠 예시")
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            .exitCard()
            
            Text("작은 카드")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.primaryText)
                .frame(maxWidth: .infinity)
                .exitCard(.small)
        }
        .padding(ExitSpacing.lg)
    }
}
