//
//  SwiftUIView.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 20/04/26.
//

import SwiftUI

struct SignInView: View {
    @Environment(AppStateManager.self) var appState
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
                        .font(.system(size: 32, weight: .bold))
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
                    Button("Forgot Password?") {}
                        .font(.system(size: 14))
                }
                .padding(.top, 10)
                .padding(.bottom, 32)

                // Login
                AuthPrimaryButton(title: "Log In") {
                    Task {
                        await appState.signIn(email: email, password: password)
                    }
                }

                if let error = appState.authError {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .padding(.top, 8)
                }

                if appState.isAuthLoading {
                    ProgressView()
                        .padding(.top, 8)
                }

                AuthOrDivider().padding(.bottom, 24)
                AuthAppleButton().padding(.bottom, 32)

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
            ToolbarItem(placement: .topBarTrailing) {
                Button("Skip") {
                    appState.isAuthenticated = true
                    appState.showPostAuthOnboarding = true
                }
            }
        }
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
                            .font(.system(size: 32, weight: .bold))
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
                        Task {
                            await appState.signUp(name: name, email: email, password: password)
                        }
                    }

                    if let error = appState.authError {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }

                    if appState.isAuthLoading {
                        ProgressView()
                            .padding(.top, 8)
                    }

                    HStack(spacing: 4) {
                        Spacer()
                        Button("Already have an account? Sign in") { showSignUp = false }
                            .font(.system(size: 15))
                            .foregroundStyle(brandGradient)
                        Spacer()
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") {
                        appState.isAuthenticated = true
                        appState.showPostAuthOnboarding = true
                    }
                }
            }
        }
        
        .navigationBarBackButtonHidden(true)
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
    }
}
