import SwiftUI
import Charts

// MARK: - Section Container
struct TrackerMoneyFlowSection: View {
    @Environment(AppStateManager.self) var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingDetailSheet = false

    private var growthInfo: (pct: Double, up: Bool)? {
        guard let profile = appState.currentProfile else { return nil }
        return AuraMoneyFlowChart.calculateGrowth(profile: profile)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Header
            HStack(alignment: .center) {
                Text("Cash Flow")
                    .font(.system(size: 22, weight: .bold))
                Spacer()
                if let g = growthInfo {
                    HStack(spacing: 4) {
                        Image(systemName: g.up ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                        Text(String(format: "%.0f%% vs last month", g.pct))
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                    }
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundStyle(g.up ? Color(hex: "#30D158") : Color(hex: "#FF453A"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background((g.up ? Color(hex: "#30D158") : Color(hex: "#FF453A")).opacity(0.12))
                    .clipShape(Capsule())
                }
                Button {
                    showingDetailSheet = true
                } label: {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 24))
                        .foregroundStyle(AppTheme.auraIndigo)
                }
            }
            .padding(.horizontal, 8)


            // Card
            if let profile = appState.currentProfile {
                AuraMoneyFlowChart(profile: profile)
                    .auraCardStyle(radius: 24)
                    .onTapGesture { showingDetailSheet = true }

                
            } else {
                TrackerEmptyState(icon: "chart.bar.fill", message: "No data available yet.")
                    .auraCardStyle(radius: 24)
            }
        }
        .sheet(isPresented: $showingDetailSheet) {
            MoneyFlowSourceSheet()
        }
    }
}

#Preview {
    let sampleState = AppStateManager.withSampleData()

    NavigationStack {
        TrackerMoneyFlowSection()
            .environment(sampleState)
            .padding()
    }
    .background(Color(uiColor: .systemGroupedBackground))
}
