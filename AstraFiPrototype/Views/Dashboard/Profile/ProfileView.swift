import SwiftUI
import PhotosUI
import UIKit

struct ProfileView: View {
    @Environment(AppStateManager.self) private var appState
    @AppStorage("profileImageData") private var profileImageData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem?

    private var profile: AstraUserProfile? { appState.currentProfile }
    private var basic: AstraBasicDetails? { profile?.basicDetails }
    private var report: AstraFinancialHealthReport? { profile?.financialHealthReport }

    private var displayName: String {
        if let name = basic?.name, !name.isEmpty { return name }
        if let signUpName = profile?.signUp.signUpName, !signUpName.isEmpty { return signUpName }
        return "AstraFi User"
    }

    private var email: String {
        guard let email = profile?.signUp.email, !email.isEmpty else { return "Email not added" }
        return email
    }

    private var latestHealthScore: String {
        let savedReports = (profile?.monthlyHealthAssessments ?? [])
            .filter { (0...100).contains($0.score) }
            .sorted { $0.date > $1.date }
        if let latest = savedReports.first {
            return "\(latest.score)"
        }
        return "--"
    }

    var body: some View {
        Form {
            Section {
                ProfileHeader(
                    name: displayName,
                    email: email,
                    initials: initials,
                    imageData: profileImageData,
                    selectedPhotoItem: $selectedPhotoItem
                )
            }

            Section {
                HStack {
                    ProfileMetric(title: "Health", value: latestHealthScore)
                    Divider().frame(height: 40)
                    ProfileMetric(title: "Net Worth", value: (report?.netWorth ?? calculatedNetWorth).toCurrency(compact: true))
                    Divider().frame(height: 40)
                    ProfileMetric(title: "DTI", value: String(format: "%.0f%%", (report?.debtToIncomeRatio ?? debtToIncomeRatio) * 100))
                }
                .padding(.vertical, 8)
            }

            Section("Account Details") {
                NavigationLink(destination: BasicInformationDetailView()) {
                    Label("Profile Information", systemImage: "person.circle")
                }

                NavigationLink(destination: FinancialProfileDetailView()) {
                    Label("Financial Profile", systemImage: "chart.line.uptrend.xyaxis")
                }

                NavigationLink(destination: InvestmentAccountsDetailView()) {
                    Label("Connected Accounts", systemImage: "building.columns")
                }
            }

            Section("Financial Records") {
                NavigationLink(destination: FullInvestmentListView()) {
                    Label("Investments", systemImage: "chart.pie")
                }

                NavigationLink(destination: LoanTrackerView()) {
                    Label("Loans & EMIs", systemImage: "creditcard")
                }

                NavigationLink(destination: InsuranceListView()) {
                    Label("Insurance Coverage", systemImage: "shield")
                }

                NavigationLink(destination: GoalListView()) {
                    Label("Goals", systemImage: "flag")
                }
            }

            Section("Insights & Reports") {
                NavigationLink(destination: MonthlyHealthReportsView()) {
                    Label("Vital Health Reports", systemImage: "doc.text.below.ecg")
                }

                NavigationLink(destination: SpendingInsightsView()) {
                    Label("Spending Insights", systemImage: "arrow.left.arrow.right")
                }
            }

            Section("Security & Privacy") {
                NavigationLink(destination: SecurityDetailView()) {
                    Label("Security", systemImage: "lock.shield")
                }

                NavigationLink(destination: ChangePasswordView()) {
                    Label("Change Password", systemImage: "key")
                }

                NavigationLink(destination: PrivacyControlsView()) {
                    Label("Privacy Controls", systemImage: "hand.raised")
                }
            }

            Section("General") {
                NavigationLink(destination: ProfilePlaceholderView(title: "Help & Support", icon: "questionmark.circle", message: "Add support email, FAQs, and escalation details before App Store submission.")) {
                    Label("Help & Support", systemImage: "questionmark.circle")
                }

                NavigationLink(destination: ProfilePlaceholderView(title: "Terms & Privacy Policy", icon: "doc.plaintext", message: "Add Terms, Privacy Policy, data disclosure, and educational-only disclaimer here.")) {
                    Label("Terms & Privacy Policy", systemImage: "doc.plaintext")
                }
            }

            Section {
                Button(role: .destructive) {
                    Task { await appState.signOut() }
                } label: {
                    HStack {
                        Spacer()
                        Text("Sign Out").fontWeight(.semibold)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemGroupedBackground))
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self),
                      UIImage(data: data) != nil else { return }
                profileImageData = data
            }
        }
    }

    private var initials: String {
        let parts = displayName.split(separator: " ")
        let first = parts.first?.prefix(1) ?? "A"
        let second = parts.dropFirst().first?.prefix(1) ?? ""
        return "\(first)\(second)".uppercased()
    }

    private var completion: Double {
        guard let profile else { return 0 }

        let completed = [
            !profile.basicDetails.name.isEmpty,
            !profile.signUp.email.isEmpty,
            profile.basicDetails.age > 0,
            profile.basicDetails.monthlyIncome > 0,
            profile.basicDetails.monthlyExpenses > 0,
            profile.basicDetails.emergencyFundAmount > 0,
            !profile.investments.isEmpty,
            !profile.loans.isEmpty,
            !profile.insurances.isEmpty,
            !profile.goals.isEmpty
        ].filter { $0 }.count

        return Double(completed) / 10.0
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

private struct ProfileHeader: View {
    let name: String
    let email: String
    let initials: String
    let imageData: Data?
    @Binding var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                avatar
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Color(hex: "#0A3558"), in: Circle())
                        .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2))
                }
                .buttonStyle(.plain)
                .offset(x: 2, y: 2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)

                Text(email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var avatar: some View {
        if let imageData, let image = UIImage(data: imageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Circle()
                .fill(LinearGradient(colors: [Color(hex: "#007AFF"), Color(hex: "#34C759")], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay {
                    Text(initials)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                }
        }
    }
}

private struct ProfileMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ProfilePlaceholderView: View {
    let title: String
    let icon: String
    let message: String

    var body: some View {
        ContentUnavailableView(title, systemImage: icon, description: Text(message))
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
