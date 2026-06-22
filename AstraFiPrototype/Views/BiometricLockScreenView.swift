import SwiftUI
import LocalAuthentication

struct BiometricLockScreenView: View {
    @Environment(AppStateManager.self) var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var appeared = false
    @State private var authFailed = false
    @State private var iconBounce = false

    private var biometryName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID:  return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default:       return "Face ID"
        }
    }

    private var biometryIcon: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .touchID: return "touchid"
        default:       return "faceid"
        }
    }

    var body: some View {
        ZStack {
            // Native system background
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // App icon + lock badge
                VStack(spacing: 20) {
                    ZStack(alignment: .bottomTrailing) {
                        // App icon — rounded rect like iOS home screen icons
                        ZStack {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#007AFF"), Color(hex: "#5E5CE6")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)

                            Image(.splash)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        }

                        // Lock badge
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Color(uiColor: .systemGray), in: Circle())
                            .offset(x: 4, y: 4)
                    }
                    .scaleEffect(appeared ? 1.0 : 0.8)
                    .opacity(appeared ? 1.0 : 0)

                    // Title
                    VStack(spacing: 6) {
                        Text("AstraFi is Locked")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text("Unlock to access your financial data")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .opacity(appeared ? 1.0 : 0)
                }

                Spacer()

                // Face ID / Touch ID button
                VStack(spacing: 12) {
                    Button {
                        authenticate()
                    } label: {
                        Image(systemName: authFailed ? "lock.fill" : biometryIcon)
                            .font(.system(size: 44, weight: .thin))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 72, height: 72)
                            .contentShape(Rectangle())
                            .scaleEffect(iconBounce ? 0.85 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Unlock with \(biometryName)")

                    Text(authFailed ? "Tap to retry" : biometryName)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .opacity(appeared ? 1.0 : 0)
                .padding(.bottom, 80)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) {
                appeared = true
            }
            // Auto-trigger biometric auth after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                authenticate()
            }
        }
    }

    // MARK: - Authentication (unchanged logic)

    private func authenticate() {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var error: NSError?
        // Try biometrics first, fall back to device passcode
        let policy: LAPolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication

        guard context.canEvaluatePolicy(policy, error: &error) else {
            // If no auth method available at all, unlock to avoid locking user out
            appState.unlockApp()
            return
        }

        Task {
            do {
                let success = try await context.evaluatePolicy(
                    policy,
                    localizedReason: "Unlock AstraFi to access your financial data."
                )
                if success {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        appState.unlockApp()
                    }
                } else {
                    await MainActor.run {
                        authFailed = true
                        bounceIcon()
                    }
                }
            } catch {
                await MainActor.run {
                    authFailed = true
                    bounceIcon()
                }
            }
        }
    }

    private func bounceIcon() {
        withAnimation(.easeInOut(duration: 0.1)) {
            iconBounce = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                iconBounce = false
            }
        }
    }
}

#Preview {
    BiometricLockScreenView()
        .environment(AppStateManager())
}
