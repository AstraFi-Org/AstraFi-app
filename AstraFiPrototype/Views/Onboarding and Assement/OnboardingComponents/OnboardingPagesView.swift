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
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack {

                // Skip Button
                HStack {
                    Spacer()
                    Button("Skip") {
                        currentPage = onboardingPages.count - 1
                    }
                    .padding()
                }

                PageView(page: onboardingPages[currentPage])
                    .animation(.easeInOut, value: currentPage)

                // Indicators
                HStack(spacing: 8) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: index == currentPage ? 20 : 8, height: 8)
                    }
                }
                .padding(.bottom, 30)

                // Button
                Button(action: next) {
                    Text(currentPage == onboardingPages.count - 1 ? "Get Started" : "Next")
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

    func next() {
        if currentPage < onboardingPages.count - 1 {
            currentPage += 1
        }
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
}
