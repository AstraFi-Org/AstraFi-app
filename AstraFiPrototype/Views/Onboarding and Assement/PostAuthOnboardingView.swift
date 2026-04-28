//
//  PostAuthOnboardingView.swift
//  AstraFiPrototype
//
//  Created by Ayush Ahuja on 27/04/26.
//

import SwiftUI

struct PostAuthOnboardingView: View {
    @Environment(AppStateManager.self) var appState
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            AppTheme.lightBackground.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                TabView(selection: $currentPage) {
                    // Card 1: Financial Assessment
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
                    
                    // Card 2: Quick Tour / Dashboard
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
                        .fill(currentPage == 0 ? Color.black : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(currentPage == 1 ? Color.black : Color.gray.opacity(0.3))
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
                    .foregroundColor(.black)
                    .lineSpacing(4)
                
                Text(subtitle)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.gray)
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
                    .foregroundColor(.gray.opacity(0.8))
                }
            }
            .padding(40)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(35)
            .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
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
