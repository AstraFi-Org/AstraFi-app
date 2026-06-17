import SwiftUI

struct ForgotPasswordView: View {
    @Environment(AppStateManager.self) var appState
    @Environment(\.dismiss) var dismiss
    @State private var email: String = ""
    @State private var navigateToOTP: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Forgot Password")
                        .font(.largeTitle.bold())
                    Text("Enter your email address to receive a verification code.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(.top, 24)
                .padding(.bottom, 36)
                
                AuthFieldLabel(text: "Email")
                AuthInputField(
                    placeholder: "Email",
                    text: $email,
                    icon: "envelope",
                    keyboardType: .emailAddress
                )
                .padding(.bottom, 32)
                
                AuthPrimaryButton(title: "Send OTP", isLoading: appState.isAuthLoading, isDisabled: email.isEmpty) {
                    Task {
                        let success = await appState.sendPasswordResetOTP(email: email)
                        if success {
                            navigateToOTP = true
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 28)
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationDestination(isPresented: $navigateToOTP) {
            VerifyOTPView()
        }
        .alert("Error", isPresented: Binding(
            get: { appState.authError != nil },
            set: { if !$0 { appState.authError = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(appState.authError ?? "An error occurred.")
        }
    }
}

struct VerifyOTPView: View {
    @Environment(AppStateManager.self) var appState
    @Environment(\.dismiss) var dismiss
    @State private var otp: String = ""
    @State private var navigateToReset: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Verify OTP")
                        .font(.largeTitle.bold())
                    Text("Enter the 6-digit code sent to \(appState.forgotPasswordEmail).")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(.top, 24)
                .padding(.bottom, 36)
                
                AuthFieldLabel(text: "Verification Code")
                AuthInputField(
                    placeholder: "123456",
                    text: $otp,
                    icon: "number",
                    keyboardType: .numberPad
                )
                .padding(.bottom, 32)
                
                AuthPrimaryButton(title: "Verify", isLoading: appState.isAuthLoading, isDisabled: otp.count < 6) {
                    Task {
                        let success = await appState.verifyPasswordResetOTP(otp: otp)
                        if success {
                            navigateToReset = true
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 28)
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationDestination(isPresented: $navigateToReset) {
            ResetPasswordView()
        }
        .alert("Error", isPresented: Binding(
            get: { appState.authError != nil },
            set: { if !$0 { appState.authError = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(appState.authError ?? "An error occurred.")
        }
    }
}

struct ResetPasswordView: View {
    @Environment(AppStateManager.self) var appState
    @Environment(\.dismiss) var dismiss
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reset Password")
                        .font(.largeTitle.bold())
                    Text("Create a new password for your account.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(.top, 24)
                .padding(.bottom, 36)
                
                AuthFieldLabel(text: "New Password")
                AuthPasswordField(
                    placeholder: "New Password",
                    text: $newPassword,
                    showPassword: $showPassword
                )
                .padding(.bottom, 20)
                
                AuthFieldLabel(text: "Confirm Password")
                AuthPasswordField(
                    placeholder: "Confirm Password",
                    text: $confirmPassword,
                    showPassword: $showConfirmPassword
                )
                .padding(.bottom, 32)
                
                AuthPrimaryButton(
                    title: "Update Password",
                    isLoading: appState.isAuthLoading,
                    isDisabled: newPassword.isEmpty || newPassword != confirmPassword
                ) {
                    Task {
                        // The updatePassword method handles state transition on success (logging the user in)
                        _ = await appState.updatePassword(newPassword: newPassword)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 28)
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .alert("Error", isPresented: Binding(
            get: { appState.authError != nil },
            set: { if !$0 { appState.authError = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(appState.authError ?? "An error occurred.")
        }
    }
}
