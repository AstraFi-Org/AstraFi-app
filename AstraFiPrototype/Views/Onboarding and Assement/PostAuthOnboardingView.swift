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
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                TabView(selection: $currentPage) {
                    OnboardingCard(
                        title: "Start Your\nFinancial\nAssesment",
                        subtitle: "See how your financial choices impact your present and future, and how to improve them.",
                        footerText: "Your data stays private and secure.",
                        footerIcon: "lock.shield",
                        buttonTitle: "Start Assessment",
                        action: {
                            withAnimation {
                                appState.showPostAuthOnboarding = false
                                appState.showDashboard = false
                            }
                        }
                    )
                    .tag(0)

                    OnboardingCard(
                        title: "Take a quick tour\nto see how AstraFi\ncan help you.",
                        subtitle: "Explore how AstraFi helps you assess your finances, plan investments, and track assets—before getting started.",
                        footerText: nil,
                        footerIcon: nil,
                        buttonTitle: "Take a Look",
                        action: {
                            withAnimation {
                                appState.showPostAuthOnboarding = false
                                appState.showDashboard = true
                            }
                        }
                    )
                    .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 550)

                // Page Indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(currentPage == 0 ? Color.primary : Color.primary.opacity(0.2))
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(currentPage == 1 ? Color.primary : Color.primary.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
                .padding(.bottom, 20)

                Spacer()
            }
        }
    }
}

struct OnboardingCard: View {
    let title: String
    let subtitle: String
    let footerText: String?
    let footerIcon: String?
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                Text(title)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.primary)
                    .lineSpacing(4)

                Text(subtitle)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)

                Spacer()

                if let footerText = footerText {
                    HStack(spacing: 6) {
                        if let icon = footerIcon {
                            Image(systemName: icon)
                                .font(.system(size: 14))
                        }
                        Text(footerText)
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.secondary.opacity(0.8))
                }
            }
            .padding(40)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(35)
            .shadow(color: Color.primary.opacity(0.06), radius: 20, x: 0, y: 10) // ← adaptive shadow
            .padding(.horizontal, 25)

            Button(action: action) {
                Text(buttonTitle)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppTheme.auraIndigo)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 25)
            .padding(.top, 40)
        }
    }
}

#Preview {
    PostAuthOnboardingView()
        .environment(AppStateManager())
}
