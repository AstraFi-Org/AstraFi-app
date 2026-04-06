import SwiftUI

struct AuthenticationFlowView: View {
    @State private var showSignUp: Bool = false

    var body: some View {
        if showSignUp {
            SignUpView(showSignUp: $showSignUp)
        } else {
            SignInView(showSignUp: $showSignUp)
        }
    }
}

struct SignInView: View {
    @Environment(AppStateManager.self) var appState
    @Binding var showSignUp: Bool

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                HStack {
                    Spacer()
                    Button("Skip") {
                        appState.isAuthenticated = true
                    }
                    .font(.system(size: 17))
                    .foregroundStyle(brandGradient)
                }
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Sign In")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Let's get started !")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
                .padding(.top, 24)
                .padding(.bottom, 36)

                AuthFieldLabel(text: "Email")
                AuthInputField(placeholder: "Email", text: $email,
                               icon: "envelope", keyboardType: .emailAddress)
                    .padding(.bottom, 20)

                AuthFieldLabel(text: "Password")
                AuthPasswordField(placeholder: "Password", text: $password,
                                  showPassword: $showPassword)

                HStack {
                    Spacer()
                    Button("Forgot Password?") {}
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                }
                .padding(.top, 10)
                .padding(.bottom, 32)

                AuthPrimaryButton(title: "Log In") {
                    appState.isAuthenticated = true
                }
                .padding(.bottom, 28)

                AuthOrDivider().padding(.bottom, 24)
                AuthAppleButton().padding(.bottom, 32)

                HStack(spacing: 4) {
                    Spacer()
                    Text("New to AstraFi?")
                        .font(.system(size: 15)).foregroundColor(.primary)
                    Button("Sign Up") { showSignUp = true }
                        .font(.system(size: 15))
                        .foregroundStyle(brandGradient)
                    Spacer()
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
        .navigationBarBackButtonHidden(true)
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
    }
}

struct SignUpView: View {
    @Environment(AppStateManager.self) var appState
    @Binding var showSignUp: Bool

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showConfirmPassword: Bool = false
    @State private var agreedToTerms: Bool = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                HStack {
                    Spacer()
                    Button("Skip") {
                        appState.isAuthenticated = true
                    }
                    .font(.system(size: 17))
                    .foregroundStyle(brandGradient)
                }
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Sign Up")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Let's get started !")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
                .padding(.top, 24)
                .padding(.bottom, 36)

                AuthFieldLabel(text: "Name")
                AuthInputField(placeholder: "Enter your Full Name",
                               text: $name, icon: "person.circle")
                    .padding(.bottom, 20)

                AuthFieldLabel(text: "Email")
                AuthInputField(placeholder: "Email", text: $email,
                               icon: "envelope", keyboardType: .emailAddress)
                    .padding(.bottom, 20)

                AuthFieldLabel(text: "Password")
                AuthInputField(placeholder: "Password", text: $password,
                               icon: "lock", isSecure: true)
                    .padding(.bottom, 20)

                AuthFieldLabel(text: "Confirm Password")
                AuthPasswordField(placeholder: "Confirm Password",
                                  text: $confirmPassword,
                                  showPassword: $showConfirmPassword)
                    .padding(.bottom, 8)

                HStack {
                    Spacer()
                    Button("Need Help?") {}
                        .font(.system(size: 14)).foregroundColor(.primary)
                }
                .padding(.bottom, 16)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 10) {
                        Button { agreedToTerms.toggle() } label: {
                            Image(systemName: agreedToTerms
                                  ? "checkmark.square.fill" : "square")
                                .font(.system(size: 22))
                                .foregroundStyle(
                                    agreedToTerms
                                        ? AnyShapeStyle(brandGradient)
                                        : AnyShapeStyle(Color(uiColor: .systemGray3))
                                )
                        }
                        HStack(spacing: 0) {
                            Text("I agree to all the ")
                                .font(.system(size: 14)).foregroundColor(.primary)
                            Button("Terms & Conditions") {}
                                .font(.system(size: 14))
                                .foregroundStyle(brandGradient)
                                .underline()
                            Text(". *")
                                .font(.system(size: 14)).foregroundColor(.primary)
                        }
                    }
                    Text("*You must agree to the Terms & Conditions and Privacy Policy to continue.")
                        .font(.system(size: 12)).foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 28)

                AuthPrimaryButton(title: "Create Account") {
                    appState.tempName = name
                    appState.tempEmail = email
                    appState.tempPassword = password
                    appState.isAuthenticated = true
                }
                .padding(.bottom, 20)

                HStack(spacing: 4) {
                    Spacer()
                    Button("Already have an account? Log in") { showSignUp = false }
                        .font(.system(size: 15))
                        .foregroundStyle(brandGradient)
                    Spacer()
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
        .navigationBarBackButtonHidden(true)
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
    }
}

struct AuthFieldLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.primary)
            .padding(.bottom, 8)
    }
}

struct AuthInputField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundColor(Color(uiColor: .systemGray2))
                .frame(width: 22)
            if isSecure {
                SecureField(placeholder, text: $text).font(.system(size: 16))
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 16)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(Color(uiColor: .systemGray4), lineWidth: 1))
    }
}

struct AuthPasswordField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock")
                .font(.system(size: 17))
                .foregroundColor(Color(uiColor: .systemGray2))
                .frame(width: 22)
            Group {
                if showPassword {
                    TextField(placeholder, text: $text)
                        .autocapitalization(.none).disableAutocorrection(true)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .font(.system(size: 16))
            Button { showPassword.toggle() } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .font(.system(size: 17))
                    .foregroundColor(Color(uiColor: .systemGray2))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 16)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(Color(uiColor: .systemGray4), lineWidth: 1))
    }
}

struct AuthPrimaryButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(brandGradient)
                .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AuthOrDivider: View {
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(.blue.opacity(0.4))
                .frame(height: 1)
            Text("or")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(brandGradient)
            Rectangle()
                .fill(.blue.opacity(0.4))
                .frame(height: 1)
        }
    }
}

struct AuthAppleButton: View {
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 10) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 18, weight: .medium)).foregroundColor(.primary)
                Text("Continue with Apple")
                    .font(.system(size: 17, weight: .medium)).foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 15)
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(uiColor: .systemGray4), lineWidth: 1.5))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        AuthenticationFlowView()
            .environment(AppStateManager())
    }
}
