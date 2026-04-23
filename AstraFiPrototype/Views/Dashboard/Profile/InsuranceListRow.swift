import SwiftUI

struct InsuranceListRow: View {
    let insurance: AstraInsurance
    let editAction: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(insurance.insuranceType.rawValue.capitalized).font(.headline)
                    Spacer()
                    Text("Cover: \(insurance.sumAssured.toCurrency())")
                        .font(.subheadline).fontWeight(.bold)
                }
                HStack {
                    Label(insurance.provider, systemImage: "building.2.fill")
                        .font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text("₹\(Int(insurance.annualPremium))/yr")
                        .font(.caption).foregroundColor(.secondary)
                }
                Text("Policy: \(insurance.policyNumber)")
                    .font(.system(size: 10, design: .monospaced)).foregroundColor(.secondary)
                if let expiry = insurance.expiryDate {
                    Label("Expires: \(expiry.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                        .font(.caption2).foregroundColor(.secondary)
                }
            }
            Button(action: editAction) {
                Image(systemName: "pencil.circle.fill").font(.title3).foregroundColor(.blue)
            }
            .buttonStyle(.plain).padding(.leading, 8)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        InsuranceListRow(
            insurance: AstraInsurance(
                insuranceType: .life,
                provider: "HDFC Life",
                policyNumber: "POL123456789",
                sumAssured: 10000000,
                annualPremium: 15000,
                startDate: Date(),
                expiryDate: Date().addingTimeInterval(86400 * 365)
            ),
            editAction: {}
        )
    }
}
