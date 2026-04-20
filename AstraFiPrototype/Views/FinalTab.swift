import SwiftUI

struct FinalTab: View {
    @State private var trackerVM = TrackerViewModel()
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house")
            }
            .tag(0)

            NavigationStack {
                PlannerView()
            }
            .tabItem {
                Label("Planner", systemImage: selectedTab == 1
                      ? "chart.line.uptrend.xyaxis.circle.fill"
                      : "chart.line.uptrend.xyaxis.circle")
            }
            .tag(1)

            NavigationStack {
                TrackerView()
            }
            .tabItem {
                Label("Tracker", systemImage: selectedTab == 2 ? "chart.pie.fill" : "chart.pie")
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
