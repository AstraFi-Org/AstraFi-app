import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppStateManager.self) var appState

    private var profile: AstraUserProfile? { appState.currentProfile }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                ProfileSection(title: "Identity & Security") {
                    NavigationLink(destination: BasicInformationDetailView()) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(symbols: [.blue, .cyan]))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Personal Bios")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("\(profile?.basicDetails.name ?? "Akash Kashyap") • \(profile?.basicDetails.age ?? 28) • \(profile?.basicDetails.gender.rawValue.capitalized ?? "Male")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }

                ProfileSection(title: "Intelligence Deck") {
                    NavigationLink(destination: MonthlyHealthReportsView()) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "doc.text.below.ecg.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blue)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Vital Health Reports")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                if let latest = profile?.monthlyHealthAssessments.sorted(by: { $0.date > $1.date }).first {
                                    Text("Latest Score: \(latest.score) • \(latest.date.formatted(.dateTime.month().year()))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("No reports available")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }

                Button(action: {
                    withAnimation {
                        appState.currentProfile = nil
                        appState.isAuthenticated = false
                        appState.showDashboard = false
                    }
                }) {
                    HStack {
                        Spacer()
                        Text("Sign Out Securely")
                            .font(.headline)
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(16)
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }
            .padding(.top, 10)
            .padding(.bottom, 50)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environment(AppStateManager())
    }
}
