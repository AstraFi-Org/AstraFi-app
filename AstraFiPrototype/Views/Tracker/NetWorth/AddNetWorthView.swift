import SwiftUI

struct AddNetWorthView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppStateManager.self) var appState

    @State private var savingsAccount: String = "0"
    @State private var currentAccount: String = "0"
    @State private var stocks: String = "0"
    @State private var mutualFunds: String = "0"
    @State private var propertyRealEstate: String = "0"
    @State private var customAssets: [CustomEntry] = []
    @State private var showAddAssetSheet = false
    @State private var newAssetName = ""
    @State private var newAssetValue = ""

    @State private var homeLoan: String = "0"
    @State private var carLoan: String = "0"
    @State private var creditCardDues: String = "0"
    @State private var educationLoan: String = "0"
    @State private var customLiabilities: [CustomEntry] = []
    @State private var showAddLiabilitySheet = false
    @State private var newLiabilityName = ""
    @State private var newLiabilityValue = ""

    private var totalAssets: Int {
        let base = [savingsAccount, currentAccount, stocks, mutualFunds, propertyRealEstate]
        let baseTotal = base.compactMap { Int($0) }.reduce(0, +)
        let customTotal = customAssets.compactMap { Int($0.value) }.reduce(0, +)
        return baseTotal + customTotal
    }

    private var totalLiabilities: Int {
        let base = [homeLoan, carLoan, creditCardDues, educationLoan]
        let baseTotal = base.compactMap { Int($0) }.reduce(0, +)
        let customTotal = customLiabilities.compactMap { Int($0.value) }.reduce(0, +)
        return baseTotal + customTotal
    }

    private var netWorth: Int { totalAssets - totalLiabilities }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    summaryCard
                    assetsSection
                    liabilitiesSection
                    infoFooter
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Net Worth")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveAndDismiss() }
                        .fontWeight(.semibold)
                        .tint(.blue)
                }
            }
            .sheet(isPresented: $showAddAssetSheet) {
                AddCustomEntrySheet(
                    title: "Add Asset",
                    placeholder: "e.g. Gold, PPF, Fixed Deposit...",
                    accentColor: .blue,
                    name: $newAssetName,
                    value: $newAssetValue
                ) {
                    let trimmed = newAssetName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    customAssets.append(CustomEntry(name: trimmed, value: newAssetValue.isEmpty ? "0" : newAssetValue))
                    newAssetName = ""
                    newAssetValue = ""
                }
            }
            .sheet(isPresented: $showAddLiabilitySheet) {
                AddCustomEntrySheet(
                    title: "Add Liability",
                    placeholder: "e.g. Personal Loan, Other EMI...",
                    accentColor: .red,
                    name: $newLiabilityName,
                    value: $newLiabilityValue
                ) {
                    let trimmed = newLiabilityName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    customLiabilities.append(CustomEntry(name: trimmed, value: newLiabilityValue.isEmpty ? "0" : newLiabilityValue))
                    newLiabilityName = ""
                    newLiabilityValue = ""
                }
            }
            .onAppear { loadFromProfile() }
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Net Worth")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    Text("₹\(netWorth)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                Image(systemName: netWorth >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.7))
            }

            Rectangle()
                .fill(.white.opacity(0.25))
                .frame(height: 1)

            HStack {
                VStack(spacing: 4) {
                    Text("Assets")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.75))
                    Text("₹\(totalAssets)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(width: 1, height: 32)

                VStack(spacing: 4) {
                    Text("Liabilities")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.75))
                    Text("₹\(totalLiabilities)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: netWorth >= 0
                    ? [.green, .green]
                    : [Color.red.opacity(0.85), Color.red.opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
    }

    private var assetsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("Assets", systemImage: "arrow.up.circle.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.green)
                Spacer()
                Text("₹\(totalAssets)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 10)

            VStack(spacing: 0) {
                StyledAssetRow(icon: "building.columns.fill", iconColor: .blue,
                               label: "Savings Account", value: $savingsAccount)
                rowDivider
                StyledAssetRow(icon: "creditcard.fill", iconColor: .teal,
                               label: "Current Account", value: $currentAccount)
                rowDivider
                StyledAssetRow(icon: "chart.line.uptrend.xyaxis", iconColor: .purple,
                               label: "Stocks", value: $stocks)
                rowDivider
                StyledAssetRow(icon: "chart.pie.fill", iconColor: .orange,
                               label: "Mutual Funds", value: $mutualFunds)
                rowDivider
                StyledAssetRow(icon: "house.fill", iconColor: .indigo,
                               label: "Property / Real Estate", value: $propertyRealEstate)

                ForEach(Array(customAssets.enumerated()), id: \.element.id) { index, asset in
                    rowDivider
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.yellow.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "star.fill")
                                .font(.system(size: 15))
                                .foregroundColor(.yellow)
                        }
                        Text(asset.name)
                            .font(.system(size: 15))
                        Spacer()
                        HStack(spacing: 4) {
                            Text("₹").foregroundColor(.secondary).font(.subheadline)
                            TextField("0", text: Binding(
                                get: { index < customAssets.count ? customAssets[index].value : "0" },
                                set: { if index < customAssets.count { customAssets[index].value = $0 } }
                            ))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .font(.system(size: 15, weight: .medium))
                        }
                        Button {
                            if index < customAssets.count { customAssets.remove(at: index) }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red.opacity(0.7))
                                .font(.system(size: 20))
                        }
                        .padding(.leading, 2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                rowDivider
                Button { showAddAssetSheet = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 18))
                        Text("Add Asset")
                            .foregroundColor(.blue)
                            .font(.system(size: 15, weight: .medium))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.04), radius: 6, x: 0, y: 2)
        }
    }

    private var liabilitiesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("Liabilities", systemImage: "arrow.down.circle.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.red)
                Spacer()
                Text("₹\(totalLiabilities)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 10)

            VStack(spacing: 0) {
                StyledAssetRow(icon: "house.fill", iconColor: .red,
                               label: "Home Loan", value: $homeLoan)
                rowDivider
                StyledAssetRow(icon: "car.fill", iconColor: .orange,
                               label: "Car Loan", value: $carLoan)
                rowDivider
                StyledAssetRow(icon: "creditcard.fill", iconColor: .pink,
                               label: "Credit Card Dues", value: $creditCardDues)
                rowDivider
                StyledAssetRow(icon: "graduationcap.fill", iconColor: .purple,
                               label: "Education Loan", value: $educationLoan)

                ForEach(Array(customLiabilities.enumerated()), id: \.element.id) { index, item in
                    rowDivider
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundColor(.red.opacity(0.8))
                        }
                        Text(item.name)
                            .font(.system(size: 15))
                        Spacer()
                        HStack(spacing: 4) {
                            Text("₹").foregroundColor(.secondary).font(.subheadline)
                            TextField("0", text: Binding(
                                get: { index < customLiabilities.count ? customLiabilities[index].value : "0" },
                                set: { if index < customLiabilities.count { customLiabilities[index].value = $0 } }
                            ))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .font(.system(size: 15, weight: .medium))
                        }
                        Button {
                            if index < customLiabilities.count { customLiabilities.remove(at: index) }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red.opacity(0.7))
                                .font(.system(size: 20))
                        }
                        .padding(.leading, 2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                rowDivider
                Button { showAddLiabilitySheet = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 18))
                        Text("Add Liability")
                            .foregroundColor(.red)
                            .font(.system(size: 15, weight: .medium))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.04), radius: 6, x: 0, y: 2)
        }
    }

    private var infoFooter: some View {
        VStack(spacing: 10) {
            NWInfoBadge(icon: "clock.arrow.circlepath", text: "You can update this anytime")
            NWInfoBadge(icon: "lock.shield.fill", text: "Amounts are securely stored")
            NWInfoBadge(icon: "chart.line.uptrend.xyaxis", text: "Helps track your financial position")
        }
        .padding(.vertical, 4)
    }

    private var rowDivider: some View {
        Divider().padding(.leading, 64)
    }

    private func saveAndDismiss() {
        if var profile = appState.currentProfile {
            profile.assets.savingsAccountAmount = Double(savingsAccount) ?? 0
            profile.assets.currentAccountAmount = Double(currentAccount) ?? 0
            profile.assets.stocksHoldingAmount = Double(stocks) ?? 0
            profile.assets.mutualFundHoldingAmount = Double(mutualFunds) ?? 0
            profile.assets.propertyAmount = Double(propertyRealEstate) ?? 0
            profile.liabilities.homeLoanAmount = Double(homeLoan) ?? 0
            profile.liabilities.vehicleLoanAmount = Double(carLoan) ?? 0
            profile.liabilities.creditCardBills = Double(creditCardDues) ?? 0
            profile.liabilities.educationLoanAmount = Double(educationLoan) ?? 0
            appState.currentProfile = profile
        }
        dismiss()
    }

    private func loadFromProfile() {
        guard let profile = appState.currentProfile else { return }
        savingsAccount = String(profile.assets.savingsAccountAmount.safeInt)
        currentAccount = String(profile.assets.currentAccountAmount.safeInt)
        stocks = String(profile.assets.stocksHoldingAmount.safeInt)
        mutualFunds = String(profile.assets.mutualFundHoldingAmount.safeInt)
        propertyRealEstate = String(profile.assets.propertyAmount.safeInt)
        homeLoan = String(profile.liabilities.homeLoanAmount.safeInt)
        carLoan = String(profile.liabilities.vehicleLoanAmount.safeInt)
        creditCardDues = String(profile.liabilities.creditCardBills.safeInt)
        educationLoan = String(profile.liabilities.educationLoanAmount.safeInt)
    }
}

#Preview {
    AddNetWorthView()
        .environment(AppStateManager())
}
