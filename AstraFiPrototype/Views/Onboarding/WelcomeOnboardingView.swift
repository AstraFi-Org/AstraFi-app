import SwiftUI

struct WelcomeOnboardingView: View {
    @Environment(AppStateManager.self) var appState
    @State private var data = CompleteAssessmentData()
    @State private var currentCard = 0
    @State private var goToAssessment = false
    @State private var showTour = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 0) {
                    if currentCard == 0 {
                        HStack {
                            Spacer()
                            Button("Skip") {
                                appState.setupEmptyProfile(name: "User")
                                appState.isAssessmentSkipped = true
                                appState.showDashboard = true
                            }
                            .font(.system(size: 17))
                            .foregroundColor(.blue)
                            .padding(.trailing, 24)
                            .padding(.top, 8)
                        }
                    }

                    Spacer()
                    TabView(selection: $currentCard) {
                        StartAssessmentCard().tag(0)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 420)
                    .padding(.horizontal, 20)
                    Spacer()

                    Button {
                        if currentCard == 0 { goToAssessment = true } else { showTour = true }
                    } label: {
                        Text(currentCard == 0 ? "Start Assessment" : "Take a Look")
                            .font(.headline).fontWeight(.semibold).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 17)
                            .background(LinearGradient(
                                colors: [.blue, .blue],
                                startPoint: .leading, endPoint: .trailing))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 28).padding(.bottom, 44)
                }
            }
            .navigationDestination(isPresented: $goToAssessment) { BasicDetailsScreen(data: data) }
        }
    }
}

private struct StartAssessmentCard: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text("Start Your\nFinancial\nAssessment")
                .font(.system(size: 34, weight: .bold)).lineSpacing(2).foregroundColor(.primary)
            Spacer().frame(height: 20)
            Text("See how your financial choices impact your present and future, and how to improve them.")
                .font(.subheadline).foregroundColor(.secondary).lineSpacing(4)
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill").font(.subheadline).foregroundColor(.secondary)
                Text("Your data stays private and secure.").font(.subheadline).foregroundColor(.secondary)
            }
            .padding(.bottom, 28)
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(uiColor: .systemBackground)).cornerRadius(24)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 16, x: 0, y: 4)
    }
}

#Preview {
    WelcomeOnboardingView()
        .environment(AppStateManager.withSampleData())
}
