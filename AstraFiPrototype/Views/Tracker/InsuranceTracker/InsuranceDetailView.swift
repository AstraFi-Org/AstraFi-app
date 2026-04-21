import SwiftUI

struct InsuranceDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppStateManager.self) var appState
    let insurance: AstraInsurance

    @State private var showingEdit = false
    @State private var showingDeleteConfirm = false

    private var activeInsurance: AstraInsurance {
        appState.currentProfile?.insurances.first(where: { $0.id == insurance.id }) ?? insurance
    }

    private var df: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }

    var body: some View {
        ScrollView {

                VStack(spacing: 24) {
                    headerCard
                    premiumSection

                    if let life = activeInsurance.lifeDetails {
                        lifeDetailsSection(life)
                    } else if let health = activeInsurance.healthDetails {
                        healthDetailsSection(health)
                    } else if let motor = activeInsurance.motorDetails {
                        motorDetailsSection(motor)
                    }

                    if !activeInsurance.riders.isEmpty {
                        ridersSection
                    }

                    if !activeInsurance.claims.isEmpty {
                        claimsSection
                    }

                    datesSection
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 30)
            .background(AppTheme.appBackground(for: colorScheme))
            .navigationTitle(activeInsurance.insuranceType.rawValue + " Insurance")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .sheet(isPresented: $showingEdit) {
                EditInsuranceView(insurance: activeInsurance)
            }
            .alert("Delete Policy", isPresented: $showingDeleteConfirm) {
                Button("Delete", role: .destructive, action: deletePolicy)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this policy? This action cannot be undone.")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                            .foregroundColor(.accentColor)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { showingEdit = true } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) { showingDeleteConfirm = true } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.accentColor)
                    }
                }
            }
    }

    private func deletePolicy() {
        if var userProfile = appState.currentProfile {
            userProfile.insurances.removeAll { $0.id == insurance.id }
            appState.currentProfile = userProfile
            appState.recalculateFinancials()
            dismiss()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(activeInsurance.provider)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(activeInsurance.insuranceType.rawValue + " Insurance")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Spacer()
                statusBadge(activeInsurance.status)
            }

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Sum Assured").font(.caption).foregroundColor(.secondary)
                    Text(activeInsurance.sumAssured.toCurrency()).font(.title3).fontWeight(.bold).foregroundColor(.primary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Annual Premium").font(.caption).foregroundColor(.secondary)
                    Text(activeInsurance.annualPremium.toCurrency()).font(.title3).fontWeight(.bold).foregroundColor(.accentColor)
                }
            }

            Divider()

            HStack {
                Label("Policy Number", systemImage: "doc.text.fill").font(.subheadline).foregroundColor(.secondary)
                Spacer()
                Text(activeInsurance.policyNumber).font(.subheadline).fontWeight(.semibold)
            }
        }
        .padding(24)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 5)
    }

    private var premiumSection: some View {
        _DetailSection(title: "Payment Information", icon: "creditcard.fill") {
            VStack(spacing: 16) {
                _DetailRow(icon: "clock.arrow.2.circlepath", label: "Frequency", value: activeInsurance.premiumFrequency.rawValue)
                _DetailRow(icon: "indianrupeesign", label: "Base Premium", value: activeInsurance.basePremium.toCurrency())
                _DetailRow(icon: "percent", label: "Taxes (GST)", value: activeInsurance.taxesGST.toCurrency())
                if activeInsurance.addOnCost > 0 {
                    _DetailRow(icon: "plus.circle", label: "Add-on Costs", value: activeInsurance.addOnCost.toCurrency())
                }
                Divider()
                _DetailRow(icon: "banknote.fill", label: "Total Yearly", value: activeInsurance.annualPremium.toCurrency(), isBold: true)
            }
        }
    }

    private func lifeDetailsSection(_ life: AstraLifeInsuranceDetails) -> some View {
        _DetailSection(title: "Life Coverage", icon: "heart.fill") {
            VStack(spacing: 16) {
                _DetailRow(icon: "person.2.fill", label: "Nominee", value: life.nomineeName ?? "Not Specified")
                _DetailRow(icon: "tag.fill", label: "Plan Type", value: life.lifeInsuranceType ?? "N/A")
                _DetailRow(icon: "checkmark.seal.fill", label: "Maturity Benefit", value: (life.maturityBenefit ?? 0).toCurrency())
                _DetailRow(icon: "cross.fill", label: "Death Benefit", value: (life.deathBenefit ?? 0).toCurrency())
                if let surrender = activeInsurance.surrenderValue, surrender > 0 {
                    _DetailRow(icon: "arrow.uturn.backward.circle.fill", label: "Surrender Value", value: surrender.toCurrency())
                }
                if let maturity = activeInsurance.expectedMaturityAmount, maturity > 0 {
                    _DetailRow(icon: "dollarsign.circle.fill", label: "Exp. Maturity", value: maturity.toCurrency())
                }
            }
        }
    }

    private func healthDetailsSection(_ health: AstraHealthInsuranceDetails) -> some View {
        _DetailSection(title: "Health Coverage", icon: "cross.case.fill") {
            VStack(spacing: 16) {
                _DetailRow(icon: "person.fill", label: "Plan Type", value: health.planType ?? "Individual")
                _DetailRow(icon: "bed.double.fill", label: "Room Rent Limit", value: (health.roomRentLimit ?? 0).toCurrency())
                _DetailRow(icon: "clock.fill", label: "Daycare", value: health.daycareProcedures ? "Included" : "Not Included")
                if let prePost = health.prePostHospitalization {
                    _DetailRow(icon: "calendar", label: "Pre/Post Hosp.", value: prePost)
                }
                if let count = health.networkHospitalsCount {
                    _DetailRow(icon: "building.2.fill", label: "Network Hospitals", value: "\(count)+")
                }

                if !health.coveredMembers.isEmpty {
                    Divider().padding(.vertical, 4)
                    HStack {
                        Image(systemName: "person.3.fill").foregroundColor(.secondary)
                        Text("Covered Members").font(.caption).fontWeight(.bold).foregroundColor(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(health.coveredMembers) { member in
                        HStack {
                            Text(member.name).font(.subheadline).fontWeight(.medium)
                            Spacer()
                            Text("\(member.age) yrs • \(member.relationship)").font(.caption).foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(6)
                    }
                }
            }
        }
    }

    private func motorDetailsSection(_ motor: AstraMotorInsuranceDetails) -> some View {
        _DetailSection(title: "Motor Coverage", icon: "car.fill") {
            VStack(spacing: 16) {
                _DetailRow(icon: "info.circle.fill", label: "Vehicle Model", value: motor.vehicleModel ?? "N/A")
                _DetailRow(icon: "shield.righthalf.filled", label: "IDV", value: (motor.idv ?? 0).toCurrency())
                _DetailRow(icon: "arrow.down.square.fill", label: "Zero Dep", value: motor.zeroDep ? "Enabled" : "Disabled")
                _DetailRow(icon: "help.circle.fill", label: "Roadside Asst.", value: motor.roadsideAssistance ? "Enabled" : "Disabled")
            }
        }
    }

    private var ridersSection: some View {
        _DetailSection(title: "Active Riders", icon: "plus.square.fill.on.square.fill") {
            VStack(spacing: 16) {
                ForEach(activeInsurance.riders) { rider in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(rider.name).font(.subheadline).fontWeight(.semibold)
                            Spacer()
                            Text(rider.premium.toCurrency()).font(.subheadline).foregroundColor(.accentColor).fontWeight(.bold)
                        }
                        Text(rider.benefit).font(.caption).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                    if rider.id != activeInsurance.riders.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private var claimsSection: some View {
        _DetailSection(title: "Claim History", icon: "list.clipboard.fill") {
            VStack(spacing: 16) {
                ForEach(activeInsurance.claims) { claim in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(claimStatusColor(claim.status).opacity(0.1)).frame(width: 40, height: 40)
                            Image(systemName: claimStatusIcon(claim.status)).foregroundColor(claimStatusColor(claim.status))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(df.string(from: claim.date)).font(.subheadline).fontWeight(.semibold)
                            if let desc = claim.description {
                                Text(desc).font(.caption).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(claim.amount.toCurrency()).font(.subheadline).fontWeight(.bold)
                            Text(claim.status.rawValue).font(.caption2).fontWeight(.bold).padding(.horizontal, 8).padding(.vertical, 2).background(claimStatusColor(claim.status).opacity(0.15)).foregroundColor(claimStatusColor(claim.status)).cornerRadius(6)
                        }
                    }
                    if claim.id != activeInsurance.claims.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private var datesSection: some View {
        _DetailSection(title: "Policy Timeline", icon: "calendar") {
            VStack(spacing: 16) {
                _DetailRow(icon: "calendar.badge.plus", label: "Start Date", value: df.string(from: activeInsurance.startDate))
                if let expiry = activeInsurance.expiryDate {
                    _DetailRow(icon: "calendar.badge.exclamationmark", label: "Expiry Date", value: df.string(from: expiry))
                }
            }
        }
    }

    private func statusBadge(_ status: AstraPolicyStatus) -> some View {
        Text(status.rawValue)
            .font(.caption).fontWeight(.bold)
            .foregroundColor(policyStatusColor(status))
            .padding(.horizontal, 14).padding(.vertical, 6)
            .background(policyStatusColor(status).opacity(0.15))
            .cornerRadius(20)
    }

    private func policyStatusColor(_ status: AstraPolicyStatus) -> Color {
        switch status {
        case .active: return .green
        case .lapsed: return .red
        case .gracePeriod: return .orange
        case .matured: return .blue
        }
    }

    private func claimStatusColor(_ status: AstraClaimStatus) -> Color {
        switch status {
        case .approved: return .green
        case .rejected: return .red
        case .pending: return .blue
        }
    }

    private func claimStatusIcon(_ status: AstraClaimStatus) -> String {
        switch status {
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .pending: return "clock.fill"
        }
    }
}

struct _DetailSection<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(.secondary).font(.caption)
                Text(title.uppercased()).font(.caption).fontWeight(.bold).foregroundColor(.secondary)
            }.padding(.leading, 4)

            VStack {
                content()
            }
            .padding(20)
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 4)
        }
    }
}

struct _DetailRow: View {
    let icon: String
    let label: String
    let value: String
    var isBold: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(.secondary).font(.subheadline).frame(width: 20)
            Text(label).font(.subheadline).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.subheadline).fontWeight(isBold ? .bold : .semibold).foregroundColor(.primary)
        }
    }
}

#Preview {
    NavigationStack {
        InsuranceDetailView(insurance: AstraInsurance(
            insuranceType: .health,
            provider: "Star Health",
            policyNumber: "POL-12345678",
            sumAssured: 500000,
            annualPremium: 15000,
            startDate: Date(),
            basePremium: 12000,
            taxesGST: 2160,
            premiumFrequency: .yearly,
            healthDetails: AstraHealthInsuranceDetails(
                planType: "Family Floater",
                coveredMembers: [
                    AstraCoveredMember(name: "John Doe", age: 35, relationship: "Self"),
                    AstraCoveredMember(name: "Jane Doe", age: 32, relationship: "Spouse")
                ],
                roomRentLimit: 5000,
                daycareProcedures: true,
                networkHospitalsCount: 500
            ),
            claims: [
                AstraClaim(date: Date(), amount: 15000, status: .approved, description: "Fever Treatment")
            ]
        ))
    }
    .environment(AppStateManager.withSampleData())
}
