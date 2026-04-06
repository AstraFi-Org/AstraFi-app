import SwiftUI

struct SplashScreenView: View {
    @Environment(AppStateManager.self) var appState

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    .blue,
                    .green
                        .opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                Text("AstraFi")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("A finance Guiding Star")
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                appState.isLoading = false
            }
        }
    }
}

#Preview {
    SplashScreenView()
        .environment(AppStateManager.withSampleData())
}
