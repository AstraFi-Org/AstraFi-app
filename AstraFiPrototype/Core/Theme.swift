import SwiftUI
import UIKit

// MARK: - Blur View
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: - App Theme
struct AppTheme {
    // ── Core Palette (iOS 17 Human Interface)
    static let auraBeige      = Color(hex: "#F2F2F7")   // iOS system grouped bg
    static let auraGold       = Color(hex: "#FFD60A")   // SF Yellow
    static let auraPurple     = Color(hex: "#BF5AF2")   // SF Purple
    static let auraIndigo     = Color(hex: "#007AFF")   // SF Blue (primary CTA)
    static let auraGreen      = Color(hex: "#30D158")   // SF Green
    static let auraMint       = Color(hex: "#00C7BE")   // SF Mint
    static let auraCream      = Color(hex: "#FAFAFA")
    static let auraGlass      = Color.white.opacity(0.72)

    // ── WWDC / System accents
    static let vibrantCyan    = Color(hex: "#32ADE6")
    static let vibrantOrange  = Color(hex: "#FF9F0A")
    static let vibrantGreen   = Color(hex: "#30D158")
    static let vibrantIndigo  = Color(hex: "#5E5CE6")
    static let vibrantRed     = Color(hex: "#FF453A")

    // ── Legacy aliases (no breaks)
    static let primaryTeal         = auraIndigo
    static let primaryGreen        = auraGreen
    static let darkTealBackground  = Color(hex: "#111114")

    // ── Backgrounds
    /// Page-level background: very dark in dark mode, iOS grouped gray in light mode
    static let darkBackground = Color(hex: "#111114")
    static let lightBackground = Color(hex: "#F2F2F7")

    static func appBackground(for colorScheme: ColorScheme) -> AnyView {
        if colorScheme == .dark {
            return AnyView(darkBackground.ignoresSafeArea())
        } else {
            return AnyView(lightBackground.ignoresSafeArea())
        }
    }

    // ── Adaptive card surface (matches screenshot: dark = #1C1C1E, light = white)
    static let cardBackground = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0x1C/255.0, green: 0x1C/255.0, blue: 0x1E/255.0, alpha: 1)  // #1C1C1E
            : UIColor.white
    })

    static let elevatedCardBackground = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0x2C/255.0, green: 0x2C/255.0, blue: 0x2E/255.0, alpha: 1)  // #2C2C2E
            : UIColor(white: 0.99, alpha: 1)
    })

    static let adaptiveShadow = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(white: 0, alpha: 0)
            : UIColor(white: 0, alpha: 0.07)
    })

    static let premiumShadow = Color.black.opacity(0.05)

    // ── Health card backgrounds
    static let healthCardBackgroundDark  = auraIndigo.opacity(0.12)
    static let healthCardBackgroundLight = auraIndigo.opacity(0.06)

    // ── Gradients
    static let accentGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#007AFF"), Color(hex: "#5E5CE6")]),
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let goldenGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#FFD60A"), Color(hex: "#FF9F0A")]),
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#111114"), Color(hex: "#1C1C1E")]),
        startPoint: .top, endPoint: .bottom
    )

    static let greenGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#30D158"), Color(hex: "#25A244")]),
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let purpleGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#BF5AF2"), Color(hex: "#5E5CE6")]),
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // ── Shadows
    static let accentShadow   = Color(hex: "#007AFF").opacity(0.30)
    static let shadowRadius: CGFloat   = 20
    static let shadowOffset   = CGPoint(x: 0, y: 10)

    // ── Layout constants
    static let auraPadding:           CGFloat = 20
    static let auraCardRadius:        CGFloat = 20
    static let auraInterCardSpacing:  CGFloat = 14

    static func applyAccentStyle<V: View>(_ content: V) -> some View {
        content
            .background(accentGradient)
            .shadow(color: accentShadow, radius: shadowRadius, x: shadowOffset.x, y: shadowOffset.y)
    }
}

// MARK: - Premium Typography
extension Font {
    static func auraTitle(size: CGFloat = 32, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight)
    }
    static func auraHeader(size: CGFloat = 20, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight)
    }
    static func auraBody(size: CGFloat = 16, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight)
    }
    static func auraCaption(size: CGFloat = 12, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
    static func auraDigital(size: CGFloat = 24, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight)
    }
}

// MARK: - Glass Card Modifier
struct GlassCardModifier: ViewModifier {
    var radius: CGFloat = 20
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(colorScheme == .dark
                          ? Color(red: 0x1C/255.0, green: 0x1C/255.0, blue: 0x1E/255.0) // #1C1C1E solid gray card
                          : Color.white.opacity(0.88))
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(
                        colorScheme == .dark
                            ? Color.white.opacity(0.06)
                            : Color.white.opacity(0.7),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.5 : 0.08),
                    radius: 14, x: 0, y: 6)
    }
}

// MARK: - Aura Card
struct AuraCardView<Content: View>: View {
    let content: Content
    let radius: CGFloat
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        content
            .padding(20)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: AppTheme.adaptiveShadow, radius: 14, x: 0, y: 5)
    }
}

// MARK: - View Extensions
extension View {
    func auraCardStyle(radius: CGFloat = 20) -> some View {
        AuraCardView(content: self, radius: radius)
    }

    func glassCard(radius: CGFloat = 20) -> some View {
        self.modifier(GlassCardModifier(radius: radius))
    }

    func auraGlassStyle(radius: CGFloat = 20) -> some View {
        self.modifier(GlassCardModifier(radius: radius))
    }

    func appAccentButtonStyle() -> some View {
        self
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.accentGradient)
            .clipShape(Capsule())
            .shadow(color: AppTheme.accentShadow, radius: 14, x: 0, y: 7)
    }
}

// MARK: - Color Extensions
extension Color {
    static let tableHeaderBackground   = Color(UIColor.secondarySystemGroupedBackground)
    static let subtleBackground        = AppTheme.auraBeige
    static let tableBorder             = Color(UIColor.separator).opacity(0.4)
    static let recommendationBackground = AppTheme.auraIndigo.opacity(0.06)
    static let connectorLine           = Color(UIColor.separator).opacity(0.3)
    static let stripeBackground        = Color.gray.opacity(0.03)
}
