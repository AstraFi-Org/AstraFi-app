import SwiftUI

private struct OnboardingPage {
    let imageName: String
    let title: String
    let subtitle: String
}

private let pages: [OnboardingPage] = [
    .init(imageName: "onboarding_financial_health",
          title: "Check Your\nFinancial Health",
          subtitle: "Get a clear view of your Income, Expenses, Risk level."),
    .init(imageName: "onboarding_investment_plan",
          title: "Plan your Investment\nAround Goals",
          subtitle: "Goal based Planning to Achieve Faster"),
    .init(imageName: "onboarding_track_assets",
          title: "Track Investment\nAnd Assets",
          subtitle: "Goal based Planning to Achieve Faster"),
    .init(imageName: "onboarding_news_updates",
          title: "News And Updates",
          subtitle: "Goal based Planning to Achieve Faster"),
]

struct OnboardingPagesView: View {
    @Environment(AppStateManager.self) var appState
    @State private var currentPage: Int = 0

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {

                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            appState.hasCompletedOnboarding = true  
                        }
                        .font(.system(size: 17))
                        .foregroundStyle(brandGradient)
                        .padding(.trailing, 24)
                        .padding(.top, 8)
                    } else {

                        Text("Skip").foregroundColor(.clear).padding(.trailing, 24).padding(.top, 8)
                    }
                }
                .frame(height: 44)

                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index]).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index
                                  ? .blue
                                  : Color(uiColor: .systemGray4))
                            .frame(width: currentPage == index ? 20 : 8, height: 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, 36)

                if currentPage == pages.count - 1 {
                    Button(action: advance) {
                        Text("Get Started")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .background(brandGradient)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 28)
                    .buttonStyle(PlainButtonStyle())
                } else {

                    Color.clear
                        .frame(height: 54) 
                }

                Spacer().frame(height: 52)
            }
        }
    }

    private func advance() {
        if currentPage < pages.count - 1 {
            withAnimation { currentPage += 1 }
        } else {
            appState.hasCompletedOnboarding = true
        }
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Image(page.imageName)
                .resizable()
                .scaledToFit()

                .padding(.bottom, 48)

            Text(page.title)
                .font(.system(size: 30, weight: .bold))
                .multilineTextAlignment(.center)
               .foregroundColor(.primary)

                .padding(.bottom, 10)

            Text(page.subtitle)
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)

            Spacer()
        }
    }
}

var brandGradient: LinearGradient {
    LinearGradient(
        colors: [
            .blue,
            .blue
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}

#Preview {
    OnboardingPagesView()
        .environment(AppStateManager())
}
