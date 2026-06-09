import SwiftUI
import Charts

// MARK: - Section Container
struct TrackerMoneyFlowSection: View {
    @Environment(AppStateManager.self) var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingDetailSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Header
            HStack(alignment:.firstTextBaseline) {
                Text("Cash Flow")
                    .font(.system(size: 22, weight: .bold))
                Spacer()
                Button {
                    showingDetailSheet = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 26))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AppTheme.auraIndigo)
                }
                                
            }


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
