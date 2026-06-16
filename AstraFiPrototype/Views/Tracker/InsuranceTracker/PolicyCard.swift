//
//  PolicyCard.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

struct PolicyCard: View {
    let ins: AstraInsurance

    private var df: DateFormatter {
        let f = DateFormatter(); f.dateStyle = .medium; return f
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ins.insuranceType.rawValue + " Insurance").font(.headline).fontWeight(.semibold)
                    Text(ins.provider).font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
                Text(ins.status.rawValue)
                    .font(.caption).fontWeight(.semibold)
                    .foregroundColor(statusColor(ins.status))
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(statusColor(ins.status).opacity(0.15)).cornerRadius(20)
            }

            Divider()

            VStack(spacing: 8) {
                policyRow(label: "Policy Number",  value: ins.policyNumber)
                policyRow(label: "Sum Assured",    value: ins.sumAssured.toCurrency())
                policyRow(label: "Annual Premium", value: ins.annualPremium.toCurrency())
                if let expiry = ins.expiryDate {
                    policyRow(label: "Expiry Date",     value: df.string(from: expiry))
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Coverage Details").font(.caption).fontWeight(.bold).foregroundColor(.secondary)

                if let life = ins.lifeDetails {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Nominee").font(.caption).foregroundColor(.secondary)
                            Text(life.nomineeName ?? "N/A").font(.subheadline).fontWeight(.medium)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Maturity Benefit").font(.caption).foregroundColor(.secondary)
                            Text((life.maturityBenefit ?? 0).toCurrency()).font(.subheadline).fontWeight(.medium)
                        }
                    }
                } else if let health = ins.healthDetails {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Plan Type").font(.caption).foregroundColor(.secondary)
                            Text(health.planType ?? "Individual").font(.subheadline).fontWeight(.medium)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Room Rent Limit").font(.caption).foregroundColor(.secondary)
                            Text((health.roomRentLimit ?? 0).toCurrency()).font(.subheadline).fontWeight(.medium)
                        }
                    }
                } else if let motor = ins.motorDetails {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Vehicle").font(.caption).foregroundColor(.secondary)
                            Text(motor.vehicleModel ?? "N/A").font(.subheadline).fontWeight(.medium)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("IDV").font(.caption).foregroundColor(.secondary)
                            Text((motor.idv ?? 0).toCurrency()).font(.subheadline).fontWeight(.medium)
                        }
                    }
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            if !ins.claims.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Last Claim").font(.caption).fontWeight(.bold).foregroundColor(.secondary)
                    HStack {
                        Text(df.string(from: ins.claims.first?.date ?? Date())).font(.caption)
                        Spacer()
                        Text((ins.claims.first?.amount ?? 0).toCurrency()).font(.caption).fontWeight(.semibold)
                        Text(ins.claims.first?.status.rawValue ?? "").font(.caption2).foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color(uiColor: .label).opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private func policyRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.subheadline).fontWeight(.medium).foregroundColor(.primary)
        }
    }

    private func statusColor(_ status: AstraPolicyStatus) -> Color {
        switch status {
        case .active: return .green
        case .lapsed: return .red
        case .gracePeriod: return .orange
        case .matured: return .blue
        }
    }
}


#Preview {
    let sampleState = AppStateManager.withSampleData()

    if let policy = sampleState.currentProfile?.insurances.first {
        PolicyCard(ins: policy)
            .padding()
            .background(Color(uiColor: .systemGroupedBackground))
    }
}
