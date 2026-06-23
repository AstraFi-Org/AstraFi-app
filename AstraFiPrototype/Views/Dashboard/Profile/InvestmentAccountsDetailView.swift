import SwiftUI

struct InvestmentAccountsDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState

    @State private var showingAddAccount = false
    @State private var setuConnecting = false
    @ObservedObject private var upstoxViewModel = UpstoxViewModel.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "link.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                        Text("Connected Portfolios")
                            .font(.headline)
                    }
                    Text("Securely connect broker and portfolio sources so AstraFi can keep your investment view fresh.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(16)
                .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Connected Accounts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    ConnectedAccountView(viewModel: upstoxViewModel)
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Portfolio Sources")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        ConnectionRow(name: "CAMS - CAS", status: "Connected", icon: "doc.text.fill", color: .blue)
                        Divider().padding(.leading, 56)
                        ConnectionRow(name: "NSDL Demat", status: "Connected", icon: "briefcase.fill", color: .indigo)
                        Divider().padding(.leading, 56)
                        ConnectionRow(name: "KFintech", status: "Not Linked", icon: "chart.pie.fill", color: .gray)
                    }
                    .background(AppTheme.cardBackground)
                    .cornerRadius(16)
                    .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
                }

                Button(action: {
                    setuConnecting = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        setuConnecting = false
                        if var profile = appState.currentProfile {
                            profile.isSetuConnected = true
                            appState.currentProfile = profile
                        }
                    }
                }) {
                    HStack {
                        if setuConnecting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: appState.currentProfile?.isSetuConnected == true ? "checkmark.circle.fill" : "plus.circle.fill")
                        }
                        Text(setuConnecting ? "Connecting via Setu..." : (appState.currentProfile?.isSetuConnected == true ? "Portfolio Linked" : "Link New Account"))
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(appState.currentProfile?.isSetuConnected == true ? Color.blue : Color.blue)
                    .cornerRadius(16)
                    .shadow(color: (appState.currentProfile?.isSetuConnected == true ? Color.blue : Color.blue).opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(appState.currentProfile?.isSetuConnected == true)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Portfolio Snapshot")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total Assets Fetch")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("₹12,80,000")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                            Text("Updated 2h ago")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }

                        Divider()

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Last CAS Generation")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("15 Mar 2024")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            Spacer()
                            Button("Refresh") { }
                                .font(.caption)
                                .foregroundColor(.blue)
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
        }
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
