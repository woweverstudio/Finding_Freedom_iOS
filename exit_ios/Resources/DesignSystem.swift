//
//  DesignSystem.swift
//  exit_ios
//
//  Exit Design System
//  Toss Design System 참고 - 무채색 위주, 파란색 액센트, 둥근 radius
//

import SwiftUI

// MARK: - Colors (Assets 기반)

extension Color {
    /// Exit 앱 디자인 시스템 색상
    /// Assets.xcassets/Exit 폴더의 Color Set을 참조하여 다크/라이트 모드 자동 전환
    enum Exit {
        // MARK: Background
        
        /// 앱 배경색 (Light: #F2F2F7 연회색, Dark: #0A0A0A)
        static let background = Color("ExitBackgroundPrimary")
        
        /// 카드 배경색 (Light: #FFFFFF 흰색, Dark: #121212)
        static let cardBackground = Color("ExitBackgroundSecondary")
        
        /// 보조 카드 배경색 (Light: #E8E8E8, Dark: #1A1A1A)
        static let secondaryCardBackground = Color("ExitBackgroundTertiary")
        
        // MARK: Text (Content)
        
        /// 주요 텍스트 (Light: #191F28, Dark: #FFFFFF)
        static let primaryText = Color("ExitContentPrimary")
        
        /// 보조 텍스트 (Light: #4E5968, Dark: #A0A0A0)
        static let secondaryText = Color("ExitContentSecondary")
        
        /// 비활성 텍스트 (Light: #8B95A1, Dark: #666666)
        static let tertiaryText = Color("ExitContentTertiary")
        
        // MARK: Accent (Semantic)
        
        /// 메인 액센트 - 파란색 (Light: #3182F6, Dark: #4A9DFF)
        static let accent = Color("ExitAccentPrimary")
        
        /// 긍정 - 초록 (Light: #00C853, Dark: #34C759)
        static let positive = Color("ExitAccentPositive")
        
        /// 주의 - 주황 (Light: #FF9500, Dark: #FFB340)
        static let caution = Color("ExitAccentWarning")
        
        /// 경고 - 빨강 (Light: #F44336, Dark: #FF453A)
        static let warning = Color("ExitAccentNegative")
        
        // MARK: UI Elements (Component)
        
        /// 구분선 (Light: #E5E8EB, Dark: #2A2A2A)
        static let divider = Color("ExitComponentDivider")
        
        /// 비활성 배경 (Light: #E5E8EB, Dark: #333333)
        static let disabledBackground = Color("ExitComponentDisabled")
        
        // MARK: Chart Colors
        
        /// 차트 색상 팔레트 (8색)
        static let chart1 = Color("ExitChart1")  // 파랑
        static let chart2 = Color("ExitChart2")  // 초록
        static let chart3 = Color("ExitChart3")  // 주황
        static let chart4 = Color("ExitChart4")  // 빨강
        static let chart5 = Color("ExitChart5")  // 보라
        static let chart6 = Color("ExitChart6")  // 청록
        static let chart7 = Color("ExitChart7")  // 노랑
        static let chart8 = Color("ExitChart8")  // 분홍
        
        /// 차트 색상 배열
        static let chartColors: [Color] = [
            chart1, chart2, chart3, chart4, chart5, chart6, chart7, chart8
        ]
    }
}

// MARK: - Color Hex Init (레거시 지원)

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
    /// 액센트 그라데이션 (파란색)
    static let exitAccent = LinearGradient(
        colors: [Color.Exit.accent, Color.Exit.accent.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 카드 배경 그라데이션
    static let exitCard = LinearGradient(
        colors: [Color.Exit.secondaryCardBackground, Color.Exit.cardBackground],
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
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}

// MARK: - Shadow Extensions

extension View {
    /// 카드 그림자 - Elevated 스타일용 (강한 그림자)
    func exitCardShadow() -> some View {
        shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
    }
    
    /// 카드 그림자 - Filled 스타일용 (미세한 그림자, 라이트 모드 카드 구분)
    func exitCardShadowSubtle() -> some View {
        shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    /// 버튼 그림자 (액센트)
    func exitButtonShadow() -> some View {
        shadow(color: Color.Exit.accent.opacity(0.25), radius: 8, x: 0, y: 4)
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

// MARK: - Card Component

/// 카드 스타일 옵션
enum ExitCardStyle {
    case filled     // 배경색 채움
    case outlined   // 테두리만
    case elevated   // 그림자 포함
}

/// Exit 카드 컴포넌트
struct ExitCard<Content: View>: View {
    let style: ExitCardStyle
    let padding: CGFloat
    let radius: CGFloat
    @ViewBuilder let content: () -> Content
    
    init(
        style: ExitCardStyle = .filled,
        padding: CGFloat = ExitSpacing.lg,
        radius: CGFloat = ExitRadius.xl,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.style = style
        self.padding = padding
        self.radius = radius
        self.content = content
    }
    
    var body: some View {
        content()
            .padding(padding)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .overlay(overlayView)
            .if(style == .filled) { view in
                view.exitCardShadowSubtle()
            }
            .if(style == .elevated) { view in
                view.exitCardShadow()
            }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .filled, .elevated:
            Color.Exit.cardBackground
        case .outlined:
            Color.clear
        }
    }
    
    @ViewBuilder
    private var overlayView: some View {
        if style == .outlined {
            RoundedRectangle(cornerRadius: radius)
                .stroke(Color.Exit.divider, lineWidth: 1)
        }
    }
}

// MARK: - Legacy Card Modifier (호환성 유지)

enum ExitCardSize {
    case small   // padding: md, radius: md
    case medium  // padding: md, radius: lg
    case large   // padding: lg, radius: xl
    
    var padding: CGFloat {
        switch self {
        case .small, .medium: return ExitSpacing.md
        case .large: return ExitSpacing.lg
        }
    }
    
    var radius: CGFloat {
        switch self {
        case .small: return ExitRadius.md
        case .medium: return ExitRadius.lg
        case .large: return ExitRadius.xl
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
            .exitCardShadowSubtle() // 기본 미세한 그림자
            .if(hasShadow) { view in
                view.exitCardShadow()
            }
    }
}

extension View {
    /// 카드 스타일 적용 (레거시)
    func exitCard(_ size: ExitCardSize = .large, shadow: Bool = false) -> some View {
        modifier(ExitCardModifier(size: size, hasShadow: shadow))
    }
}

// MARK: - Button Component

/// Exit 버튼 스타일
enum ExitButtonStyle {
    case primary    // 액센트 배경
    case secondary  // 카드 배경 + 테두리
    case text       // 텍스트만
    case destructive // 경고 (빨간색)
}

/// Exit 버튼 사이즈
enum ExitButtonSize {
    case large   // 56pt
    case medium  // 48pt
    case small   // 40pt
    case compact // 32pt
    
    var height: CGFloat {
        switch self {
        case .large: return 56
        case .medium: return 48
        case .small: return 40
        case .compact: return 32
        }
    }
    
    var font: Font {
        switch self {
        case .large: return .Exit.body
        case .medium: return .Exit.subheadline
        case .small, .compact: return .Exit.caption
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .large: return 18
        case .medium: return 16
        case .small: return 14
        case .compact: return 12
        }
    }
    
    var radius: CGFloat {
        switch self {
        case .large: return ExitRadius.lg
        case .medium: return ExitRadius.md
        case .small, .compact: return ExitRadius.sm
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .large: return ExitSpacing.lg
        case .medium: return ExitSpacing.md
        case .small: return ExitSpacing.md
        case .compact: return ExitSpacing.sm
        }
    }
}

/// Exit 버튼 컴포넌트
struct ExitButton: View {
    let title: String
    var icon: String? = nil
    var style: ExitButtonStyle = .primary
    var size: ExitButtonSize = .medium
    var isFullWidth: Bool = true
    var isEnabled: Bool = true
    var isLoading: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ExitSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
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
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, isFullWidth ? 0 : size.horizontalPadding)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: size.radius))
            .overlay(overlayView)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1 : 0.5)
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return Color.Exit.primaryText
        case .text:
            return Color.Exit.accent
        case .destructive:
            return .white
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            if isEnabled {
                Color.Exit.accent
            } else {
                Color.Exit.disabledBackground
            }
        case .secondary:
            Color.Exit.cardBackground
        case .text:
            Color.clear
        case .destructive:
            if isEnabled {
                Color.Exit.warning
            } else {
                Color.Exit.disabledBackground
            }
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

// MARK: - Legacy CTA Button (호환성 유지)

struct ExitCTAButton: View {
    let title: String
    var icon: String? = nil
    var style: Style = .primary
    var size: Size = .large
    var isEnabled: Bool = true
    var isLoading: Bool = false
    let action: () -> Void
    
    enum Style {
        case primary
        case secondary
    }
    
    enum Size {
        case large
        case medium
        case small
        
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
                Color.Exit.accent
            } else {
                Color.Exit.disabledBackground
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

// MARK: - Badge Component

/// Exit 배지 스타일
enum ExitBadgeStyle {
    case filled     // 배경색 채움
    case outlined   // 테두리만
    case subtle     // 연한 배경
}

/// Exit 배지 컴포넌트
struct ExitBadge: View {
    let text: String
    var icon: String? = nil
    var color: Color = Color.Exit.accent
    var style: ExitBadgeStyle = .subtle
    
    var body: some View {
        HStack(spacing: ExitSpacing.xs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }
            
            Text(text)
                .font(.Exit.caption2)
                .fontWeight(.medium)
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, ExitSpacing.sm)
        .padding(.vertical, ExitSpacing.xs)
        .background(backgroundView)
        .clipShape(Capsule())
        .overlay(overlayView)
    }
    
    private var foregroundColor: Color {
        switch style {
        case .filled:
            return .white
        case .outlined, .subtle:
            return color
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .filled:
            color
        case .outlined:
            Color.clear
        case .subtle:
            color.opacity(0.12)
        }
    }
    
    @ViewBuilder
    private var overlayView: some View {
        if style == .outlined {
            Capsule()
                .stroke(color, lineWidth: 1)
        }
    }
}

// MARK: - ListRow Component

/// Exit 리스트 로우 컴포넌트
struct ExitListRow<Leading: View, Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    var leading: (() -> Leading)? = nil
    var trailing: (() -> Trailing)? = nil
    var showChevron: Bool = false
    var showDivider: Bool = true
    var action: (() -> Void)? = nil
    
    init(
        title: String,
        subtitle: String? = nil,
        showChevron: Bool = false,
        showDivider: Bool = true,
        action: (() -> Void)? = nil
    ) where Leading == EmptyView, Trailing == EmptyView {
        self.title = title
        self.subtitle = subtitle
        self.leading = nil
        self.trailing = nil
        self.showChevron = showChevron
        self.showDivider = showDivider
        self.action = action
    }
    
    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder leading: @escaping () -> Leading,
        showChevron: Bool = false,
        showDivider: Bool = true,
        action: (() -> Void)? = nil
    ) where Trailing == EmptyView {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading
        self.trailing = nil
        self.showChevron = showChevron
        self.showDivider = showDivider
        self.action = action
    }
    
    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing,
        showChevron: Bool = false,
        showDivider: Bool = true,
        action: (() -> Void)? = nil
    ) where Leading == EmptyView {
        self.title = title
        self.subtitle = subtitle
        self.leading = nil
        self.trailing = trailing
        self.showChevron = showChevron
        self.showDivider = showDivider
        self.action = action
    }
    
    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder trailing: @escaping () -> Trailing,
        showChevron: Bool = false,
        showDivider: Bool = true,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading
        self.trailing = trailing
        self.showChevron = showChevron
        self.showDivider = showDivider
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: ExitSpacing.md) {
                if let leading = leading {
                    leading()
                }
                
                VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                    Text(title)
                        .font(.Exit.body)
                        .foregroundStyle(Color.Exit.primaryText)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.secondaryText)
                    }
                }
                
                Spacer()
                
                if let trailing = trailing {
                    trailing()
                }
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.Exit.tertiaryText)
                }
            }
            .padding(ExitSpacing.md)
            .contentShape(Rectangle())
            .onTapGesture {
                action?()
            }
            
            if showDivider {
                ExitDivider()
                    .padding(.leading, leading != nil ? 56 : ExitSpacing.md)
            }
        }
    }
}

// MARK: - Divider Component

/// Exit 구분선 컴포넌트
struct ExitDivider: View {
    var color: Color = Color.Exit.divider
    var height: CGFloat = 1
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: height)
    }
}

// MARK: - TextField Component

/// Exit 텍스트필드 컴포넌트
struct ExitTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: ExitSpacing.md) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(Color.Exit.tertiaryText)
            }
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.primaryText)
            } else {
                TextField(placeholder, text: $text)
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.primaryText)
                    .keyboardType(keyboardType)
            }
        }
        .padding(ExitSpacing.md)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: ExitRadius.md)
                .stroke(Color.Exit.divider, lineWidth: 1)
        )
    }
}

// MARK: - Chip Component

/// Exit 칩 컴포넌트
struct ExitChip: View {
    let text: String
    var isSelected: Bool = false
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button {
            action?()
        } label: {
            Text(text)
                .font(.Exit.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : Color.Exit.primaryText)
                .padding(.horizontal, ExitSpacing.md)
                .padding(.vertical, ExitSpacing.sm)
                .background(isSelected ? Color.Exit.accent : Color.Exit.cardBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.Exit.divider, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
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
                ExitDivider()
            }
        }
    }
}

// MARK: - Legacy Button Modifiers (호환성 유지)

struct ExitPrimaryButtonModifier: ViewModifier {
    var isEnabled: Bool = true
    
    func body(content: Content) -> some View {
        content
            .font(.Exit.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(isEnabled ? Color.Exit.accent : Color.Exit.disabledBackground)
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

// MARK: - Previews

#Preview("Colors") {
    ScrollView {
        VStack(spacing: ExitSpacing.lg) {
            // Background Colors
            VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                Text("Background")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                HStack(spacing: ExitSpacing.sm) {
                    colorSwatch("primary", Color.Exit.background)
                    colorSwatch("secondary", Color.Exit.cardBackground)
                    colorSwatch("tertiary", Color.Exit.secondaryCardBackground)
                }
            }
            
            // Content Colors
            VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                Text("Content")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                HStack(spacing: ExitSpacing.sm) {
                    colorSwatch("primary", Color.Exit.primaryText)
                    colorSwatch("secondary", Color.Exit.secondaryText)
                    colorSwatch("tertiary", Color.Exit.tertiaryText)
                }
            }
            
            // Accent Colors
            VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                Text("Accent")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                HStack(spacing: ExitSpacing.sm) {
                    colorSwatch("accent", Color.Exit.accent)
                    colorSwatch("positive", Color.Exit.positive)
                    colorSwatch("warning", Color.Exit.caution)
                    colorSwatch("negative", Color.Exit.warning)
                }
            }
            
            // Chart Colors
            VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                Text("Chart")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                HStack(spacing: ExitSpacing.xs) {
                    ForEach(0..<8) { i in
                        Circle()
                            .fill(Color.Exit.chartColors[i])
                            .frame(width: 32, height: 32)
                    }
                }
            }
        }
        .padding(ExitSpacing.lg)
    }
    .background(Color.Exit.background)
}

@ViewBuilder
private func colorSwatch(_ name: String, _ color: Color) -> some View {
    VStack(spacing: ExitSpacing.xs) {
        RoundedRectangle(cornerRadius: ExitRadius.sm)
            .fill(color)
            .frame(width: 60, height: 40)
            .overlay(
                RoundedRectangle(cornerRadius: ExitRadius.sm)
                    .stroke(Color.Exit.divider, lineWidth: 1)
            )
        
        Text(name)
            .font(.Exit.caption2)
            .foregroundStyle(Color.Exit.tertiaryText)
    }
}

#Preview("Buttons") {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        
        VStack(spacing: ExitSpacing.lg) {
            ExitButton(title: "Primary Button", style: .primary, action: {})
            ExitButton(title: "Secondary Button", style: .secondary, action: {})
            ExitButton(title: "Text Button", icon: "arrow.right", style: .text, isFullWidth: false, action: {})
            ExitButton(title: "Destructive", style: .destructive, action: {})
            ExitButton(title: "Disabled", isEnabled: false, action: {})
            ExitButton(title: "Loading...", isLoading: true, action: {})
        }
        .padding(ExitSpacing.lg)
    }
}

#Preview("Badges") {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        
        VStack(spacing: ExitSpacing.lg) {
            HStack(spacing: ExitSpacing.sm) {
                ExitBadge(text: "New", style: .filled)
                ExitBadge(text: "Beta", style: .outlined)
                ExitBadge(text: "Default", style: .subtle)
            }
            
            HStack(spacing: ExitSpacing.sm) {
                ExitBadge(text: "Success", icon: "checkmark", color: Color.Exit.positive, style: .subtle)
                ExitBadge(text: "Warning", icon: "exclamationmark.triangle", color: Color.Exit.caution, style: .subtle)
                ExitBadge(text: "Error", icon: "xmark", color: Color.Exit.warning, style: .subtle)
            }
        }
        .padding(ExitSpacing.lg)
    }
}

#Preview("Cards") {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        
        VStack(spacing: ExitSpacing.lg) {
            ExitCard(style: .filled) {
                VStack(alignment: .leading, spacing: ExitSpacing.md) {
                    ExitCardHeader(icon: "chart.pie.fill", title: "Filled Card")
                    Text("카드 컨텐츠 예시")
                        .font(.Exit.body)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
            }
            
            ExitCard(style: .outlined) {
                Text("Outlined Card")
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.primaryText)
            }
            
            ExitCard(style: .elevated) {
                Text("Elevated Card")
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.primaryText)
            }
        }
        .padding(ExitSpacing.lg)
    }
}

#Preview("Chips") {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        
        HStack(spacing: ExitSpacing.sm) {
            ExitChip(text: "전체", isSelected: true)
            ExitChip(text: "주식", isSelected: false)
            ExitChip(text: "ETF", isSelected: false)
            ExitChip(text: "채권", isSelected: false)
        }
        .padding(ExitSpacing.lg)
    }
}
