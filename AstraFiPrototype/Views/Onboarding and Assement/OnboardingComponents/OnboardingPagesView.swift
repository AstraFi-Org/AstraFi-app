import SwiftUI

struct OnboardingPage {
    let imageName: String
    let title: String
    let subtitle: String
}

let onboardingPages: [OnboardingPage] = [
    .init(imageName: "onboarding_financial_health",
          title: "Check Your\nFinancial Health",
          subtitle: "Get a clear view of your Income, Expenses, Risk level."),

    .init(imageName: "onboarding_investment_plan",
          title: "Plan your Investment\nAround Goals",
          subtitle: "Goal based Planning to Achieve Faster"),

    .init(imageName: "onboarding_track_assets",
          title: "Track Investment\nAnd Assets",
          subtitle: "Track everything in one place"),

    .init(imageName: "onboarding_news_updates",
          title: "News And Updates",
          subtitle: "Stay updated with market trends"),
]

struct OnboardingPagesView: View {
    @Environment(AppStateManager.self) var appState
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack {

                // Skip Button — goes straight to Sign In/Sign Up
                HStack {
                    Spacer()
                    Button("Skip") {
                        navigateToAuth()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.blue)
                    .padding()
                }

                PageView(page: onboardingPages[currentPage])
                    .animation(.easeInOut, value: currentPage)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: index == currentPage ? 20 : 8, height: 8)
                    }
                }
                .animation(.easeInOut, value: currentPage)
                .padding(.bottom, 30)

                // Next / Get Started button
                Button(action: next) {
                    Text(currentPage == onboardingPages.count - 1 ? "Get Started" : "Next")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
                .padding(.horizontal)

                Spacer()
            }
        }
    }

    // Advance page; on last page navigate to Sign In / Sign Up
    func next() {
        if currentPage < onboardingPages.count - 1 {
            withAnimation { currentPage += 1 }
        } else {
            navigateToAuth()
        }
    }

    // Marks onboarding complete — AppRootView observes this flag
    // and automatically presents AuthenticationFlowView (Sign In / Sign Up)
    func navigateToAuth() {
        appState.hasCompletedOnboarding = true
    }
}

struct PageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack {
            Spacer()

            Image(page.imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 250)

            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.top, 20)

            Text(page.subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .padding(.top, 8)

            Spacer()
        }
    }
}

#Preview {
    OnboardingPagesView()
        .environment(AppStateManager())
}
