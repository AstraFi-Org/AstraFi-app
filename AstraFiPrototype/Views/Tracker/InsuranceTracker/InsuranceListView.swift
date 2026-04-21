import SwiftUI

struct InsuranceListView: View {
    @Environment(AppStateManager.self) var appState
    @Environment(\.dismiss) var dismiss
    @State private var showingAddPolicy = false

    private var insurances: [AstraInsurance] { appState.currentProfile?.insurances ?? [] }

    private var totalAnnualPremium: Double { insurances.reduce(0) { $0 + $1.annualPremium } }
    private var activePoliciesCount: Int   { insurances.count }

    private var healthPercent: CGFloat {
        let total = insurances.reduce(0) { $0 + $1.sumAssured }
        guard total > 0 else { return 0 }
        let health = insurances.filter {
            [.health, .termLifeInsurance, .criticalIllness, .life, .ulip].contains($0.insuranceType)
        }.reduce(0) { $0 + $1.sumAssured }
        return CGFloat(health / total)
    }
    private var otherPercent: CGFloat { max(0, 1 - healthPercent) }

    private var df: DateFormatter {
        let f = DateFormatter(); f.dateStyle = .medium; return f
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                summaryCard
                if insurances.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "shield.slash").font(.system(size: 36)).foregroundColor(.secondary)
                        Text("No insurance policies recorded yet")
                            .font(.subheadline).foregroundColor(.secondary)

                        Button(action: { showingAddPolicy = true }) {
                            Text("Add Policy")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity).padding(40)
                    .background(Color(uiColor: .systemBackground)).cornerRadius(16)
                } else {
                    ForEach(insurances) { ins in
                        NavigationLink(destination: InsuranceDetailView(insurance: ins)) {
                            PolicyCard(ins: ins)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding()
            .padding(.bottom, 30)
        }
        .navigationTitle("Insurance")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showingAddPolicy) {
            AddInsuranceView()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").fontWeight(.semibold)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingAddPolicy = true } label: {
                    Image(systemName: "plus").fontWeight(.semibold)
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Premium").font(.subheadline).foregroundColor(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(totalAnnualPremium.toCurrency())
                        .font(.system(size: 32, weight: .bold)).foregroundColor(.primary)
                    Text("/ Year").font(.subheadline).foregroundColor(.secondary)
                }
            }
            HStack(spacing: 20) {
                Text("Active Policies: \(activePoliciesCount)")
                    .font(.subheadline).foregroundColor(.secondary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total Sum Assured").font(.subheadline).foregroundColor(.secondary)
                    Text(insurances.reduce(0) { $0 + $1.sumAssured }.toCurrency())
                        .font(.subheadline).fontWeight(.semibold).foregroundColor(.primary)
                }
            }

            if !insurances.isEmpty {
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        ZStack {
                            Rectangle().fill(.blue)
                                .frame(width: geo.size.width * healthPercent)
                            if healthPercent > 0.1 {
                                Text("Health \( (healthPercent * 100).safeInt)%")
                                    .font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                            }
                        }
                        ZStack {
                            Rectangle().fill(.yellow)
                                .frame(width: geo.size.width * otherPercent)
                            if otherPercent > 0.1 {
                                Text("Other \( (otherPercent * 100).safeInt)%")
                                    .font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                            }
                        }
                    }
                    .frame(height: 48).clipShape(Capsule())
                }
                .frame(height: 48)
            }
        }
        .padding(20)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(uiColor: .label).opacity(0.06), radius: 8, x: 0, y: 2)
    }
}



#Preview {
    NavigationStack {
        InsuranceListView()
            .environment(AppStateManager())
    }
}
