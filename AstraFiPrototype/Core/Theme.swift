import SwiftUI
import UIKit

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct AppTheme {

    static let primaryTeal = Color.blue
    static let primaryGreen = Color.blue
    static let darkTealBackground = Color(UIColor.systemBackground)

    static func appBackground(for colorScheme: ColorScheme) -> AnyView {
        if colorScheme == .dark {
            return AnyView(
                Color.black
                    .ignoresSafeArea()
            )
        } else {
            return AnyView(
                Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            )
        }
    }

    static let cardBackground = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor.secondarySystemGroupedBackground
            : UIColor.white
    })

    static let adaptiveShadow = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(white: 0, alpha: 0)
            : UIColor(white: 0, alpha: 0.06)
    })

    static let healthCardBackgroundDark = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor.secondarySystemGroupedBackground
            : UIColor.systemBlue.withAlphaComponent(0.1)
    })

    static let healthCardBackgroundLight = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor.tertiarySystemGroupedBackground
            : UIColor.systemBlue.withAlphaComponent(0.05)
    })

    static let accentGradient = LinearGradient(
        gradient: Gradient(colors: [.blue, .blue]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentShadow = Color.blue.opacity(0.3)
    static let shadowRadius: CGFloat = 20
    static let shadowOffset = CGPoint(x: 0, y: 10)

    static func applyAccentStyle<V: View>(_ content: V) -> some View {
        content
            .background(Color.blue)
            .shadow(color: accentShadow, radius: shadowRadius, x: shadowOffset.x, y: shadowOffset.y)
    }
}

extension View {
    func appAccentButtonStyle() -> some View {
        self
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.accentGradient)
            .cornerRadius(14)
            .shadow(color: AppTheme.accentShadow, radius: 10, x: 0, y: 5)
    }
}

extension Color {
    static let tableHeaderBackground = Color(UIColor.secondarySystemBackground)
    static let subtleBackground      = Color(UIColor.tertiarySystemBackground)
    static let tableBorder           = Color.gray.opacity(0.2)
    static let recommendationBackground = Color.blue.opacity(0.05)
    static let connectorLine         = Color.gray.opacity(0.3)
    static let stripeBackground      = Color.gray.opacity(0.05)
}
