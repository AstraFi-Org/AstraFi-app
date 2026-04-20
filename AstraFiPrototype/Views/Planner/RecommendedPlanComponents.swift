import SwiftUI

struct RecommendedFund: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let returns: String
    let risk: String
    let icon: String
}

struct RecommendedFundsCard: View {
    let title: String
    let funds: [RecommendedFund]
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "hand.thumbsup.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
            }

            VStack(spacing: 12) {
                ForEach(funds) { fund in
                    FundRecommendationRow(fund: fund)
                }
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow, radius: 12, x: 0, y: 4)
    }
}

struct FundRecommendationRow: View {
    let fund: RecommendedFund
    @State private var showingBrowser = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: fund.icon)
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(fund.name)
                    .font(.system(size: 15, weight: .semibold))
                HStack(spacing: 6) {
                    Text(fund.category)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("•").foregroundColor(.secondary)
                    Text(fund.risk)
                        .font(.system(size: 11))
                        .foregroundColor(riskColor(fund.risk))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(fund.returns)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.green)

                Button(action: { showingBrowser = true }) {
                    Text("Start SIP")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .cornerRadius(6)
                }
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground).opacity(0.5))
        .cornerRadius(12)
        .sheet(isPresented: $showingBrowser) {
            SimpleWebView(title: fund.name, url: "https://www.google.com/search?q=\(fund.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        }
    }

    private func riskColor(_ risk: String) -> Color {
        if risk.contains("High") { return .red }
        if risk.contains("Mid") || risk.contains("Moderate") { return .orange }
        return .green
    }
}

struct SimpleWebView: View {
    let title: String
    let url: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "safari.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Navigating to external partner...")
                    .font(.headline)

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ProgressView()
                    .padding()

                Text("In a production app, this would open the official AMC website or a direct investment link via Setu / MF Central.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
#Preview {
    RecommendedFundsCard(
        title: "heke",
        funds:[RecommendedFund(
                name: "Axis",
                category: "",
                returns: "",
                risk: "",
                icon: "")]
    )
}
