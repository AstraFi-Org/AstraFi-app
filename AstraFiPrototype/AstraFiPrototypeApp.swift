import SwiftUI

@main
struct AstraFiPrototypeApp: App {
    @State private var appState = AppStateManager()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(appState)
                .preferredColorScheme(.dark)
        }
    }
}
