import SwiftUI

struct FinalTab: View {
    @State private var trackerVM = TrackerViewModel()
    @Environment(AppStateManager.self) var appState

    var body: some View {
        @Bindable var appState = appState
        TabView(selection: $appState.selectedTab) {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Home", systemImage: appState.selectedTab == 0 ? "house.fill" : "house")
            }
            .tag(0)

            NavigationStack {
                PlannerView()
            }
            .tabItem {
                Label("Planner", systemImage: appState.selectedTab == 1
                      ? "chart.line.uptrend.xyaxis.circle.fill"
                      : "chart.line.uptrend.xyaxis.circle")
            }
            .tag(1)

            NavigationStack {
                TrackerView()
            }
            .tabItem {
                Label("Tracker", systemImage: appState.selectedTab == 2 ? "chart.pie.fill" : "chart.pie")
            }
            .tag(2)
        }
        .tint(Color(hex: "#007AFF"))
        .environment(trackerVM)
    }
}

#Preview {
    FinalTab()
        .environment(AppStateManager())
}
