import SwiftUI

struct InvestmentAccountsDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState

    @State private var showingAddAccount = false
    @State private var setuConnecting = false
    @ObservedObject private var upstoxViewModel = UpstoxViewModel.shared

    /// Every connected broker writes its holdings into the profile with a broker source.
    /// This keeps the snapshot independent of any one broker integration.
    private var connectedBrokerInvestments: [AstraInvestment] {
        appState.currentProfile?.investments.filter {
            !($0.brokerSource?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        } ?? []
    }

    private var connectedPortfolioValue: Double {
        connectedBrokerInvestments.reduce(0) { $0 + $1.currentValue.safeFinite }
    }

    private var connectedBrokerNames: [String] {
        var names = Set(
            connectedBrokerInvestments.compactMap { investment -> String? in
                guard let source = investment.brokerSource?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !source.isEmpty else { return nil }
                return source
            }
        )

        if upstoxViewModel.isConnected {
            names.insert("Upstox")
        }

        return names.sorted()
    }

    private var lastPortfolioSync: Date? {
        connectedBrokerInvestments
            .map { $0.lastUpdated ?? $0.createdAt }
            .max()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

//                VStack(alignment: .leading, spacing: 12) {
//                    HStack {
//                        Image(systemName: "link.circle.fill")
//                            .font(.title)
//                            .foregroundColor(.blue)
//                        Text("Connected Portfolios")
//                            .font(.headline)
//                    }
//                    Text("Securely connect broker and portfolio sources so AstraFi can keep your investment view fresh.")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//                .padding()
//                .background(AppTheme.cardBackground)
//                .cornerRadius(16)
//                .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Connected Accounts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    ConnectedAccountView(viewModel: upstoxViewModel)
                }

//                VStack(alignment: .leading, spacing: 16) {
//                    Text("Portfolio Sources")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                        .padding(.horizontal)
//
//                    VStack(spacing: 0) {
//                        ConnectionRow(name: "CAMS - CAS", status: "Connected", icon: "doc.text.fill", color: .blue)
//                        Divider().padding(.leading, 56)
//                        ConnectionRow(name: "NSDL Demat", status: "Connected", icon: "briefcase.fill", color: .indigo)
//                        Divider().padding(.leading, 56)
//                        ConnectionRow(name: "KFintech", status: "Not Linked", icon: "chart.pie.fill", color: .gray)
//                    }
//                    .background(AppTheme.cardBackground)
//                    .cornerRadius(16)
//                    .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
//                }

//                Button(action: {
//                    setuConnecting = true
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//                        setuConnecting = false
//                        if var profile = appState.currentProfile {
//                            profile.isSetuConnected = true
//                            appState.currentProfile = profile
//                        }
//                    }
//                }) {
//                    HStack {
//                        if setuConnecting {
//                            ProgressView()
//                                .tint(.white)
//                        } else {
//                            Image(systemName: appState.currentProfile?.isSetuConnected == true ? "checkmark.circle.fill" : "plus.circle.fill")
//                        }
//                        Text(setuConnecting ? "Connecting via Setu..." : (appState.currentProfile?.isSetuConnected == true ? "Portfolio Linked" : "Link New Account"))
//                            .fontWeight(.semibold)
//                    }
//                    .foregroundColor(.white)
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                    .background(appState.currentProfile?.isSetuConnected == true ? Color.blue : Color.blue)
//                    .cornerRadius(16)
//                    .shadow(color: (appState.currentProfile?.isSetuConnected == true ? Color.blue : Color.blue).opacity(0.3), radius: 8, x: 0, y: 4)
//                }
//                .disabled(appState.currentProfile?.isSetuConnected == true)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Portfolio Snapshot")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total Connected Assets")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(connectedPortfolioValue.toCurrency())
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                            Text(connectedBrokerNames.isEmpty
                                 ? "No accounts connected"
                                 : "\(connectedBrokerNames.count) account\(connectedBrokerNames.count == 1 ? "" : "s")")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }

                        Divider()

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Last portfolio sync")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(lastPortfolioSync?.formatted(date: .abbreviated, time: .shortened) ?? "Not synced yet")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            Spacer()
                            Button("Refresh") {
                                Task { await refreshConnectedAccounts() }
                            }
                                .font(.caption)
                                .foregroundColor(.blue)
                                .disabled(upstoxViewModel.isSyncingHoldings)
                        }
                    }
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(16)
                    .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
                }
            }
            .padding()
        }
        .navigationTitle("Investment Accounts")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.appBackground(for: colorScheme))
        .task {
            upstoxViewModel.loadStoredConnection()
            await refreshConnectedAccounts()
        }
        .onChange(of: upstoxViewModel.isConnected) { _, isConnected in
            if isConnected {
                Task { await refreshConnectedAccounts() }
            } else {
                appState.removeUpstoxHoldings()
            }
        }
    }

    private func refreshConnectedAccounts() async {
        guard upstoxViewModel.isConnected else { return }

        let snapshot = await upstoxViewModel.fetchConnectedInvestments()
        appState.syncUpstoxHoldings(
            snapshot.equity,
            mutualFunds: snapshot.mutualFunds,
            mutualFundOrders: snapshot.mutualFundOrders,
            mutualFundSIPs: snapshot.mutualFundSIPs
        )
    }
}

struct ConnectionRow: View {
    let name: String
    let status: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.headline)
                Text(status)
                    .font(.caption)
                    .foregroundColor(status == "Connected" ? .blue : .secondary)
            }
            Spacer()
            if status == "Connected" {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        InvestmentAccountsDetailView()
            .environment(AppStateManager.withSampleData())
    }
}
