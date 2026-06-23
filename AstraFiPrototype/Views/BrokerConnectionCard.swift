import SwiftUI

struct BrokerConnectionCard: View {
    @ObservedObject var viewModel: UpstoxViewModel = .shared
    @State private var showError = false
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                UpstoxLogoView()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Upstox")
                        .font(.headline)
                    Label(viewModel.isConnected ? "Connected" : "Not Connected", systemImage: viewModel.isConnected ? "checkmark.circle.fill" : "link.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(viewModel.isConnected ? .green : .gray)
                }

                Spacer()
            }

            Button(action: {
                if !viewModel.isConnected {
                    viewModel.connect()
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: viewModel.isConnected ? "checkmark.circle.fill" : "externaldrive.connected.to.line.below")
                    }
                    Text(viewModel.isConnected ? "Connected ✓" : "Connect Upstox")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(viewModel.isConnected ? .green : AppTheme.auraIndigo)
            .disabled(viewModel.isConnected || viewModel.isLoading)
        }
        .padding(compact ? 12 : 16)
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

struct UpstoxLogoView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#41246D"), Color(hex: "#00B386")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)

            Text("UP")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
        .accessibilityLabel("Upstox logo")
    }
}

#Preview {
    BrokerConnectionCard()
        .padding()
}
