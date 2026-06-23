import SwiftUI

struct ConnectedAccountView: View {
    @ObservedObject var viewModel: UpstoxViewModel = .shared
    @Environment(AppStateManager.self) private var appState
    @State private var showError = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                UpstoxLogoView()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Broker: Upstox")
                        .font(.headline)
                    Label(viewModel.isConnected ? "Status: Connected" : "Status: Not Connected", systemImage: viewModel.isConnected ? "checkmark.circle.fill" : "link.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(viewModel.isConnected ? .green : .gray)
                }

                Spacer()
            }

            if let profile = viewModel.profile, viewModel.isConnected {
                VStack(spacing: 10) {
                    AccountDetailRow(title: "User Name", value: profile.userName, icon: "person.crop.circle")
                    AccountDetailRow(title: "Email", value: profile.email, icon: "envelope")
                    AccountDetailRow(title: "User ID", value: profile.userID, icon: "number")
                    AccountDetailRow(title: "Exchange Support", value: profile.exchanges.joined(separator: ", "), icon: "building.columns")
                    AccountDetailRow(title: "Products Available", value: profile.products.joined(separator: ", "), icon: "square.grid.2x2")
                    AccountDetailRow(title: "Connection Status", value: "Connected", icon: "checkmark.circle.fill", valueColor: .green)
                    AccountDetailRow(title: "Connected Date", value: profile.connectedDate.formatted(date: .abbreviated, time: .shortened), icon: "calendar")
                }
            }

            if viewModel.isConnected {
                Button(role: .destructive) {
                    viewModel.disconnect()
                    appState.removeUpstoxHoldings()
                } label: {
                    Label("Disconnect Account", systemImage: "xmark.circle")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            } else {
                Button {
                    viewModel.connect()
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "externaldrive.connected.to.line.below")
                        }
                        Text(viewModel.isLoading ? "Connecting..." : "Connect")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.auraIndigo)
                .disabled(viewModel.isLoading)
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
        .onChange(of: viewModel.errorMessage) { _, newValue in
            showError = newValue != nil
        }
        .alert("Upstox Connection Error", isPresented: $showError) {
            Button("Retry") {
                if viewModel.isConnected {
                    Task { await viewModel.fetchProfile() }
                } else {
                    viewModel.connect()
                }
            }
            Button("Cancel", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong.")
        }
    }
}

private struct AccountDetailRow: View {
    let title: String
    let value: String
    let icon: String
    var valueColor: Color = .primary

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 18, height: 18)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer(minLength: 12)

            Text(value.isEmpty ? "Not available" : value)
                .font(.caption.weight(.semibold))
                .foregroundColor(valueColor)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    ConnectedAccountView()
        .padding()
}
