import SwiftUI
import PhotosUI
import UIKit

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppStateManager.self) var appState
    @AppStorage("profileImageData") private var profileImageData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem?

    private var profile: AstraUserProfile? { appState.currentProfile }
    private var basic: AstraBasicDetails? { profile?.basicDetails }
    private var report: AstraFinancialHealthReport? { profile?.financialHealthReport }

    private var displayName: String {
        basic?.name.isEmpty == false ? basic?.name ?? "AstraFi User" : profile?.signUp.signUpName ?? "AstraFi User"
    }

    private var email: String {
        profile?.signUp.email.isEmpty == false ? profile?.signUp.email ?? "Email not added" : "Email not added"
    }

    private var completion: Double {
        guard let profile else { return 0.12 }
        var score = 0.0
        if !profile.basicDetails.name.isEmpty { score += 0.14 }
        if !profile.signUp.email.isEmpty { score += 0.10 }
        if profile.basicDetails.age > 0 { score += 0.10 }
        if profile.basicDetails.monthlyIncome > 0 { score += 0.14 }
        if profile.basicDetails.monthlyExpenses > 0 { score += 0.12 }
        if profile.basicDetails.emergencyFundAmount > 0 { score += 0.10 }
        if !profile.investments.isEmpty { score += 0.10 }
        if !profile.loans.isEmpty { score += 0.08 }
        if !profile.insurances.isEmpty { score += 0.07 }
        if !profile.goals.isEmpty { score += 0.05 }
        return min(score, 1.0)
    }

    private var latestReportSubtitle: String {
        if let latest = profile?.monthlyHealthAssessments.sorted(by: { $0.date > $1.date }).first {
            return "Latest score \(latest.score) • \(latest.date.formatted(.dateTime.month().year()))"
        }
        if let score = report?.investmentScore {
            return "Current score \(score) • Assessment ready"
        }
        return "No report generated yet"
    }

    var body: some View {
        List {
            Section {
                profileHeader
                    .listRowInsets(EdgeInsets(top: 18, leading: 16, bottom: 18, trailing: 16))
            }

            Section {
                ProfileSettingsNavigationRow(
                        title: "Profile Information",
                        subtitle: "\(basic?.age ?? 0 > 0 ? "\(basic?.age ?? 0) yrs" : "Age not added") • \(basic?.gender.rawValue.capitalized ?? "Gender not added")",
                        icon: "person.crop.circle",
                        color: Color(hex: "#007AFF"),
                        destination: BasicInformationDetailView()
                    )

                ProfileSettingsNavigationRow(
                        title: "Financial Profile",
                        subtitle: "\(basic?.riskTolerance.rawValue ?? "Risk not set") risk • \(basic?.investmentHorizon.rawValue ?? "Horizon not set")",
                        icon: "chart.line.uptrend.xyaxis",
                        color: Color(hex: "#34C759"),
                        destination: FinancialProfileDetailView()
                    )

                ProfileSettingsNavigationRow(
                        title: "Connected Accounts",
                        subtitle: profile?.isSetuConnected == true ? "Account Aggregator linked" : "Link portfolio and bank data",
                        icon: "building.columns",
                        color: Color(hex: "#5856D6"),
                        destination: InvestmentAccountsDetailView()
                    )
            } header: {
                Text("Account Details")
            }

            Section {
                ProfileSettingsNavigationRow(
                        title: "Investments",
                        subtitle: "\(profile?.investments.count ?? 0) holdings • \(totalPortfolioValue.toCurrency(compact: true))",
                        icon: "chart.pie",
                        color: Color(hex: "#34C759"),
                        destination: FullInvestmentListView()
                    )

                ProfileSettingsNavigationRow(
                        title: "Loans & EMIs",
                        subtitle: "\(profile?.loans.count ?? 0) loans • \(monthlyEMILoad.toCurrency(compact: true))/mo",
                        icon: "creditcard",
                        color: Color(hex: "#FF9F0A"),
                        destination: LoanTrackerView()
                    )

                ProfileSettingsNavigationRow(
                        title: "Insurance Coverage",
                        subtitle: "\(profile?.insurances.count ?? 0) policies • Protection tracker",
                        icon: "shield.fill",
                        color: Color(hex: "#5856D6"),
                        destination: InsuranceListView()
                    )

                ProfileSettingsNavigationRow(
                        title: "Goals",
                        subtitle: "\(profile?.goals.count ?? 0) active goals • Milestone tracking",
                        icon: "flag.fill",
                        color: Color(hex: "#FF2D55"),
                        destination: GoalListView()
                    )
            } header: {
                Text("Financial Records")
            }

            Section {
                ProfileSettingsNavigationRow(
                        title: "Vital Health Reports",
                        subtitle: latestReportSubtitle,
                        icon: "doc.text.below.ecg",
                        color: Color(hex: "#007AFF"),
                        destination: MonthlyHealthReportsView()
                    )

                ProfileSettingsNavigationRow(
                        title: "Spending Insights",
                        subtitle: "Cash flow, expenses, and savings behaviour",
                        icon: "arrow.left.arrow.right",
                        color: Color(hex: "#AF52DE"),
                        destination: SpendingInsightsView()
                    )
            } header: {
                Text("Insights & Reports")
            }

            Section {
                ProfileSettingsNavigationRow(
                        title: "Security",
                        subtitle: "Device lock, sessions, and sign-in activity",
                        icon: "lock.shield.fill",
                        color: Color(hex: "#007AFF"),
                        destination: SecurityDetailView()
                    )

                ProfileSettingsNavigationRow(
                        title: "Change Password",
                        subtitle: "Update account credentials",
                        icon: "key.fill",
                        color: Color(hex: "#8E8E93"),
                        destination: ProfilePlaceholderView(title: "Change Password", icon: "key", message: "Connect this screen to Supabase password reset or secure password update.")
                    )

                ProfileSettingsNavigationRow(
                        title: "Privacy Controls",
                        subtitle: "Data sharing, consent, and app permissions",
                        icon: "hand.raised.fill",
                        color: Color(hex: "#34C759"),
                        destination: ProfilePlaceholderView(title: "Privacy Controls", icon: "hand.raised", message: "Show data consent, third-party sharing, and account deletion controls here.")
                    )

                ProfileSettingsNavigationRow(
                        title: "Notifications",
                        subtitle: "Alerts for goals, EMIs, and reports",
                        icon: "bell.badge.fill",
                        color: Color(hex: "#FF2D55"),
                        destination: NotificationsView()
                    )
            } header: {
                Text("Security & Privacy")
            }

            Section {
                ProfileSettingsNavigationRow(
                        title: "Help & Support",
                        subtitle: "Contact, FAQs, and issue reporting",
                        icon: "questionmark.circle",
                        color: Color(hex: "#007AFF"),
                        destination: ProfilePlaceholderView(title: "Help & Support", icon: "questionmark.circle", message: "Add support email, FAQs, and escalation details before App Store submission.")
                    )

                ProfileSettingsNavigationRow(
                        title: "Terms & Privacy Policy",
                        subtitle: "Legal documents and financial disclaimers",
                        icon: "doc.plaintext",
                        color: Color(hex: "#8E8E93"),
                        destination: ProfilePlaceholderView(title: "Terms & Privacy Policy", icon: "doc.plaintext", message: "Add Terms, Privacy Policy, data disclosure, and educational-only disclaimer here.")
                    )
            } header: {
                Text("Support & Legal")
            }

            Section {
                signOutButton
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(uiColor: .systemGroupedBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 72)
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self),
                      UIImage(data: data) != nil else { return }
                profileImageData = data
            }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                avatarView

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color(hex: "#0A3558"), in: Circle())
                        .overlay(Circle().stroke(Color(uiColor: .systemGroupedBackground), lineWidth: 3))
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 6) {
                Text(displayName)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                Text(email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            VStack(spacing: 8) {
                ProgressView(value: completion)
                    .tint(Color(hex: "#007AFF"))
                    .frame(width: 210)
                Text("\(Int((completion * 100).rounded()))% Profile Setup")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                ProfileMetricPill(title: "Health", value: report.map { "\($0.investmentScore)" } ?? "--", icon: "heart.text.square.fill", color: Color(hex: "#007AFF"))
                ProfileMetricPill(title: "Net Worth", value: (report?.netWorth ?? calculatedNetWorth).toCurrency(compact: true), icon: "indianrupeesign.circle.fill", color: Color(hex: "#34C759"))
                ProfileMetricPill(title: "DTI", value: String(format: "%.0f%%", (report?.debtToIncomeRatio ?? debtToIncomeRatio) * 100), icon: "percent", color: debtToIncomeRatio > 0.4 ? Color(hex: "#FF453A") : Color(hex: "#FF9F0A"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var avatarView: some View {
        if let profileImageData, let image = UIImage(data: profileImageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 108, height: 108)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(uiColor: .secondarySystemGroupedBackground), lineWidth: 3))
                .shadow(color: Color.black.opacity(0.12), radius: 14, x: 0, y: 8)
        } else {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#007AFF"), Color(hex: "#34C759")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 108, height: 108)
                .overlay(
                    Text(initials)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                )
                .shadow(color: Color(hex: "#007AFF").opacity(0.22), radius: 16, x: 0, y: 8)
        }
    }

    private var signOutButton: some View {
        Button {
            Task { await appState.signOut() }
        } label: {
            HStack {
                Spacer()
                Text("Sign Out Securely")
                    .font(.body)
                Spacer()
            }
            .foregroundStyle(Color(hex: "#FF453A"))
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private var initials: String {
        let parts = displayName.split(separator: " ")
        let first = parts.first?.prefix(1) ?? "A"
        let second = parts.dropFirst().first?.prefix(1) ?? ""
        return "\(first)\(second)".uppercased()
    }

    private var totalPortfolioValue: Double {
        profile?.investments.reduce(0) { $0 + $1.currentValue } ?? 0
    }

    private var monthlyEMILoad: Double {
        profile?.loans.reduce(0) { $0 + $1.calculatedEMI } ?? 0
    }

    private var calculatedNetWorth: Double {
        let assets = totalPortfolioValue
            + (profile?.assets.savingsAccountAmount ?? 0)
            + (profile?.assets.propertyAmount ?? 0)
            + (profile?.assets.vehiclesAmount ?? 0)
            + (profile?.assets.depositsAmount ?? 0)
        let liabilities = (profile?.liabilities.homeLoanAmount ?? 0)
            + (profile?.liabilities.vehicleLoanAmount ?? 0)
            + (profile?.liabilities.educationLoanAmount ?? 0)
            + (profile?.liabilities.otherLoanAmount ?? 0)
            + (profile?.liabilities.creditCardBills ?? 0)
        return assets - liabilities
    }

    private var debtToIncomeRatio: Double {
        let income = basic?.monthlyIncomeAfterTax ?? 0
        guard income > 0 else { return 0 }
        return monthlyEMILoad / income
    }
}

private struct ProfileHubSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                content
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }
}

private struct ProfileHubNavigationRow<Destination: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(color)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.secondary.opacity(0.55))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct ProfileSettingsNavigationRow<Destination: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(color, in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 5)
        }
    }
}

private struct ProfileHubDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 76)
            .padding(.trailing, 20)
    }
}

private struct ProfileMetricPill: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ProfilePlaceholderView: View {
    let title: String
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(Color(hex: "#007AFF"))
                .frame(width: 86, height: 86)
                .background(Color(hex: "#007AFF").opacity(0.10), in: Circle())

            Text(title)
                .font(.title2.bold())

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environment(AppStateManager.withSampleData())
    }
}
