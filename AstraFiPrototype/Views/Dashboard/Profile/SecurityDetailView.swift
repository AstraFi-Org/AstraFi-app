import SwiftUI
import LocalAuthentication

struct SecurityDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("securityBiometricUnlockEnabled") private var biometricUnlockEnabled = false
    @AppStorage("securityRequireUnlockOnLaunch") private var requireUnlockOnLaunch = true
    @AppStorage("securityHideBalancesInSwitcher") private var hideBalancesInSwitcher = true
    @AppStorage("securityConfirmSensitiveActions") private var confirmSensitiveActions = true
    @AppStorage("securitySessionAlertsEnabled") private var sessionAlertsEnabled = true
    @AppStorage("securityDataExportApproval") private var dataExportApproval = true

    @State private var biometryName = "Face ID"
    @State private var biometryAvailable = false
    @State private var alertMessage: String?

    var body: some View {
        List {
            Section {
                securityHeader
            }

            Section {
                NativeSettingsToggleRow(
                    title: "\(biometryName) Unlock",
                    subtitle: biometryAvailable ? "Use device biometrics to open AstraFi." : "Set up Face ID in device settings to enable this.",
                    icon: "faceid",
                    color: Color(hex: "#007AFF"),
                    isOn: Binding(
                        get: { biometricUnlockEnabled },
                        set: { newValue in handleBiometricToggle(newValue) }
                    )
                )

                NativeSettingsToggleRow(
                    title: "Require Unlock on Launch",
                    subtitle: "Ask for device unlock when the app opens.",
                    icon: "lock.rotation",
                    color: Color(hex: "#007AFF"),
                    isOn: $requireUnlockOnLaunch
                )

                NativeSettingsToggleRow(
                    title: "Hide Balances in App Switcher",
                    subtitle: "Protect net worth and holdings when AstraFi is backgrounded.",
                    icon: "eye.slash.fill",
                    color: Color(hex: "#5856D6"),
                    isOn: $hideBalancesInSwitcher
                )
            } header: {
                Text("Device Protection")
            } footer: {
                Text("These controls protect financial information on this iPhone.")
            }

            Section {
                NativeSettingsActionRow(
                    title: "Trusted Devices",
                    subtitle: "This iPhone • Active now",
                    icon: "iphone",
                    color: Color(hex: "#34C759"),
                    value: "1"
                ) {
                    alertMessage = "Trusted device management will be connected to account session controls."
                }

                NativeSettingsActionRow(
                    title: "Active Sessions",
                    subtitle: "Review web and mobile sign-ins",
                    icon: "rectangle.connected.to.line.below",
                    color: Color(hex: "#007AFF"),
                    value: "Secure"
                ) {
                    alertMessage = "Active session review will be connected to Supabase session data."
                }

                NativeSettingsActionRow(
                    title: "Sign-in Activity",
                    subtitle: "Last sign-in today from this device",
                    icon: "clock.arrow.circlepath",
                    color: Color(hex: "#FF9F0A")
                ) {
                    alertMessage = "Sign-in activity will show recent authentication events."
                }
            } header: {
                Text("Account Safety")
            }

            Section {
                NativeSettingsToggleRow(
                    title: "Confirm Sensitive Actions",
                    subtitle: "Ask before changing goals, linked accounts, or exports.",
                    icon: "checkmark.shield.fill",
                    color: Color(hex: "#34C759"),
                    isOn: $confirmSensitiveActions
                )

                NativeSettingsToggleRow(
                    title: "New Session Alerts",
                    subtitle: "Notify when your account is used on a new device.",
                    icon: "bell.badge.fill",
                    color: Color(hex: "#FF2D55"),
                    isOn: $sessionAlertsEnabled
                )

                NativeSettingsToggleRow(
                    title: "Approve Data Export",
                    subtitle: "Require confirmation before downloading financial records.",
                    icon: "square.and.arrow.up.fill",
                    color: Color(hex: "#0A3558"),
                    isOn: $dataExportApproval
                )
            } header: {
                Text("Financial Data Controls")
            } footer: {
                Text("Account-wide device removal and audit history should be backed by server session controls before release.")
            }

            Section {
                Button(role: .destructive) {
                    alertMessage = "This will be connected to Supabase session revocation so users can sign out everywhere from one place."
                } label: {
                    HStack {
                        Spacer()
                        Text("Sign Out From All Devices")
                        Spacer()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(uiColor: .systemGroupedBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 72)
        }
        .task {
            refreshBiometryState()
        }
        .alert("Security", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var securityHeader: some View {
        HStack(spacing: 14) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(Color(hex: "#007AFF"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text("Account Protection")
                    .font(.headline)
                Text(biometricUnlockEnabled ? "\(biometryName) is enabled" : "Add device-level protection")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }

    private func refreshBiometryState() {
        let context = LAContext()
        var error: NSError?
        biometryAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        switch context.biometryType {
        case .faceID:
            biometryName = "Face ID"
        case .touchID:
            biometryName = "Touch ID"
        case .opticID:
            biometryName = "Optic ID"
        default:
            biometryName = "Face ID"
        }
    }

    private func handleBiometricToggle(_ newValue: Bool) {
        if newValue {
            authenticateForBiometricUnlock()
        } else {
            biometricUnlockEnabled = false
        }
    }

    private func authenticateForBiometricUnlock() {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricUnlockEnabled = false
            alertMessage = "Face ID is not available yet. Enable Face ID for this device in Settings, then try again."
            return
        }

        Task {
            do {
                let success = try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: "Unlock AstraFi and protect your financial profile."
                )
                biometricUnlockEnabled = success
            } catch {
                biometricUnlockEnabled = false
                alertMessage = "Face ID verification was cancelled or failed. Please try again."
            }
        }
    }
}

private struct NativeSettingsToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                NativeSettingsIcon(systemName: icon, color: color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(Color(hex: "#007AFF"))
        .padding(.vertical, 5)
    }
}

private struct NativeSettingsActionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var value: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                NativeSettingsIcon(systemName: icon, color: color)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                if let value {
                    Text(value)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
    }
}

private struct NativeSettingsIcon: View {
    let systemName: String
    let color: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(color, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        SecurityDetailView()
    }
}
