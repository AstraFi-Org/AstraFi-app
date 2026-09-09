//
//  PostAuthOnboardingView.swift
//  AstraFiPrototype
//
//  Created by Ayush Ahuja on 27/04/26.
//

import SwiftUI

struct PostAuthOnboardingView: View {
    @Environment(AppStateManager.self) var appState
    @Environment(\.colorScheme) var colorScheme
    @State private var showingSignOutAlert = false

    private var userName: String {
        guard let rawName = appState.currentProfile?.signUp.signUpName.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawName.isEmpty,
              rawName != "User",
              !rawName.contains("@") else {
            return ""
        }
        return rawName.components(separatedBy: " ").first ?? ""
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        Spacer(minLength: 12)

                        // Hero 3D Illustration
                        Image("Signup")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 300, maxHeight: 270)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.05), radius: 20, x: 0, y: 10)
                            .padding(.horizontal, 24)

                        // Title & Subtitle
                        VStack(spacing: 10) {
                            Text(userName.isEmpty ? "Unlock your potential" : "Unlock your potential,\n\(userName)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)

                            Text("Gain access to personalized tools, benchmarks, and strategies to build a more secure financial future.")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 28)

                            // Trust & time expectation note
                            HStack(spacing: 6) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text("Takes ~2 mins • Private & encrypted")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.top, 4)

                        Spacer(minLength: 16)
                    }
                }

                // MARK: - Action Buttons
                VStack(spacing: 12) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            appState.showPostAuthOnboarding = false
                            appState.showDashboard = false
                        }
                    } label: {
                        Text("Start Financial Assessment")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            appState.showPostAuthOnboarding = false
                            appState.showDashboard = true
                        }
                    } label: {
                        Text("Explore Dashboard First")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .background(Color(UIColor.systemBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Centered App Logo + Name (Apple Native Principal Placement)
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)

                        Text("AstraFi")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }

                // Sign Out Action (Destructive Red)
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showingSignOutAlert = true
                    } label: {
                        Text("Sign Out")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await appState.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out? You can sign back in at any time.")
            }
        }
    }
}

#Preview {
    PostAuthOnboardingView()
        .environment(AppStateManager())
}


