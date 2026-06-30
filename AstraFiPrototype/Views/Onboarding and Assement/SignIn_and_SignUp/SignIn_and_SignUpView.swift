//
//  SwiftUIView.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 20/04/26.
//

import SwiftUI

struct SignInView: View {
    @Environment(AppStateManager.self) var appState
    @Environment(\.dismiss) private var dismiss
    @Binding var showSignUp: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Header
                VStack(alignment: .leading, spacing: 6) {

                    Text("Sign In")
                        .font(.largeTitle.bold())
                }
                .padding(.top, 24)
                .padding(.bottom, 36)

                // Email
                AuthFieldLabel(text: "Email")
                AuthInputField(
                    placeholder: "Email",
                    text: $email,
                    icon: "envelope",
                    keyboardType: .emailAddress
                )
                .padding(.bottom, 20)

                // Password
                AuthFieldLabel(text: "Password")
                AuthPasswordField(
                    placeholder: "Password",
                    text: $password,
                    showPassword: $showPassword
                )

                // Forgot
                HStack {
                    Spacer()
                    NavigationLink("Forgot Password?", destination: ForgotPasswordView())
                        .font(.system(size: 14))
                }
                .padding(.top, 10)
                .padding(.bottom, 32)

                // Login
                AuthPrimaryButton(title: "Sign In", isLoading: appState.isAuthLoading) {
                    Task {
                        await appState.signIn(email: email, password: password)
                    }
                }

                AuthOrDivider().padding(.vertical, 24)
                AuthAppleButton {
                    appState.signInWithApple()
                }.padding(.bottom, 32)

                // Sign up
                HStack {
                    Spacer()
                    Text("New to AstraFi?")
                    Button("Sign Up") { showSignUp = true }
                        .foregroundStyle(brandGradient)
                    Spacer()
                }
                .font(.system(size: 15))
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if appState.pendingGuestAssessment != nil {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        appState.pendingGuestAssessment = nil
                        dismiss()
                    }
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") {
                        appState.isGuest = true
                        appState.isAuthenticated = true
                        appState.showPostAuthOnboarding = true
                    }
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .alert("Authentication Error", isPresented: Binding(
            get: { appState.authError != nil },
            set: { if !$0 { appState.authError = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(appState.authError ?? "")
        }
    }
}

struct SignUpView: View {
    @Environment(AppStateManager.self) var appState
    @Environment(\.dismiss) private var dismiss
    @Binding var showSignUp: Bool

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showConfirmPassword: Bool = false
    @State private var agreedToTerms: Bool = true
    @State private var showSuccessPrompt: Bool = false
    @State private var showTermsSheet: Bool = false
    @State private var showPasswordRules: Bool = false

    var body: some View {
        NavigationStack{
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

    //                HStack {
    //                    Spacer()
    //                    Button("Skip") {
    //                        appState.isAuthenticated = true
    //                    }
    //                    .font(.system(size: 17))
    //                    .foregroundStyle(brandGradient)
    //                }
    //                .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 6) {

                        Text("Sign Up")
                            .font(.largeTitle.bold())
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
                        Button("Need Help?") { showPasswordRules = true }
                            .font(.system(size: 14)).foregroundColor(.blue)
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
                                Button("Terms & Conditions") {
                                    showTermsSheet = true
                                }
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

                    AuthPrimaryButton(title: "Create Account", isLoading: appState.isAuthLoading, isDisabled: !agreedToTerms) {
                        if let error = validateInput() {
                            appState.authError = error
                            return
                        }
                        Task {
                            let success = await appState.signUp(name: name, email: email, password: password)
                            if success {
                                showSuccessPrompt = true
                            }
                        }
                    }

                    HStack(spacing: 4) {
                        Spacer()
                        Text("Already have an account?")
                            .font(.system(size: 15))
                        Button("Sign in") { showSignUp = false }
                            .font(.system(size: 15))
                            .foregroundStyle(brandGradient)
                        Spacer()
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                if appState.pendingGuestAssessment != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            appState.pendingGuestAssessment = nil
                            dismiss()
                        }
                    }
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Skip") {
                            appState.isGuest = true
                            appState.isAuthenticated = true
                            appState.showPostAuthOnboarding = true
                        }
                    }
                }
            }
        }
        
        .navigationBarBackButtonHidden(true)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .alert("Account created successfully", isPresented: $showSuccessPrompt) {
            Button("OK", role: .cancel) {
                appState.completeSignUp()
            }
        } message: {
            Text("You are successfully signed up!")
        }
        .alert("Authentication Error", isPresented: Binding(
            get: { appState.authError != nil },
            set: { if !$0 { appState.authError = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(appState.authError ?? "")
        }
        .sheet(isPresented: $showTermsSheet) {
            TermsAndConditionsView(agreedToTerms: $agreedToTerms)
        }
        .alert("Password Requirements", isPresented: $showPasswordRules) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text("Your password must have:\n• At least 8 characters\n• One uppercase letter\n• One lowercase letter\n• One number\n• One special character")
        }
    }
    
    private func validateInput() -> String? {
        var errors: [String] = []

        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { 
            errors.append("• Please enter your name.") 
        }
        
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        if !emailPredicate.evaluate(with: email) { 
            errors.append("• Please enter a valid email address.") 
        }
        
        var passwordErrors: [String] = []
        if password.count < 8 { passwordErrors.append("at least 8 characters") }
        if password.rangeOfCharacter(from: .uppercaseLetters) == nil { passwordErrors.append("one uppercase letter") }
        if password.rangeOfCharacter(from: .lowercaseLetters) == nil { passwordErrors.append("one lowercase letter") }
        if password.rangeOfCharacter(from: .decimalDigits) == nil { passwordErrors.append("one number") }
        if password.range(of: ".*[^A-Za-z0-9].*", options: .regularExpression) == nil { passwordErrors.append("one special character") }
        
        if !passwordErrors.isEmpty {
            errors.append("• Password must contain " + passwordErrors.joined(separator: ", ") + ".")
        } else if password != confirmPassword { 
            errors.append("• Passwords do not match.") 
        }
        
        return errors.isEmpty ? nil : errors.joined(separator: "\n")
    }
}


