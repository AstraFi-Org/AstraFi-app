import SwiftUI

struct SplashScreenView: View {
    @Environment(AppStateManager.self) var appState
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.4
    @State private var ringOpacity: Double = 0

    var body: some View {
        ZStack {
            // Deep dark background (premium dark mode feel)
            AppTheme.darkBackground
                .ignoresSafeArea()

            // Ambient glow behind logo
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#007AFF").opacity(0.35),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

            VStack(spacing: 20) {
                // Logo mark
                ZStack {
                    // Outer ring
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#007AFF"),
                                    Color(hex: "#5E5CE6"),
                                    Color(hex: "#BF5AF2")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 96, height: 96)

                    // Inner fill
                    //Circle()
                        

                    // Star icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#007AFF"), Color(hex: "#5E5CE6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 82, height: 82)
                        Image(.splash)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 82, height: 82)
                            .clipShape(Circle())
                    }
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                VStack(spacing: 6) {
                    Text("AstraFi")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(.white)

//                    Text("A Finance Guiding Star")
//                        .font(.system(size: 15, weight: .medium))
//                        .foregroundStyle(Color.white.opacity(0.5))
//                        .tracking(0.5)
                }
                .opacity(taglineOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
                ringScale = 1.0
                ringOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                taglineOpacity = 1.0
            }
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
//                appState.isLoading = false
//            }
        }
    }
}

#Preview {
    SplashScreenView()
        .environment(AppStateManager.withSampleData())
}
