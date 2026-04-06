import SwiftUI

struct AddInsuranceView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState

    @State private var type: AstraInsuranceType = .health
    @State private var provider = ""
    @State private var policyNumber = ""
    @State private var cover = ""
    @State private var premium = ""
    @State private var startDate = Date()
    @State private var expiryDate = Date().addingTimeInterval(60 * 60 * 24 * 365)
    @State private var hasExpiry = false

    @State private var basePremium = ""
    @State private var taxesGST = ""
    @State private var addOnCost = ""
    @State private var premiumFreq: AstraPremiumFrequency = .yearly

    @State private var nomineeName = ""
    @State private var maturityBenefit = ""
    @State private var deathBenefit = ""
    @State private var lifeInsuranceTypeStr = "Term"

    @State private var planType = "Individual"
    @State private var roomRentLimit = ""
    @State private var prePostHosp = ""
    @State private var daycareProc = true
    @State private var networkHosp = ""

    @State private var vehicleModel = ""
    @State private var vehicleNumber = ""
    @State private var idv = ""
    @State private var zeroDep = false
    @State private var rsa = false

    @State private var surrenderValue = ""
    @State private var lockInPeriod = ""
    @State private var expectedMaturity = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Details")) {
                    Picker("Insurance Type", selection: $type) {
                        ForEach(AstraInsuranceType.allCases, id: \.self) { t in Text(t.rawValue).tag(t) }
                    }
                    _InsField(title: "Provider / Insurer", text: $provider)
                    _InsField(title: "Policy Number", text: $policyNumber)
                    _InsField(title: "Sum Assured (Cover)", text: $cover, isCurrency: true)
                    _InsField(title: "Annual Premium", text: $premium, isCurrency: true)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    Toggle("Has Expiry Date", isOn: $hasExpiry)
                    if hasExpiry {
                        DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                    }
                }

                Section(header: Text("Premium Breakdown")) {
                    _InsField(title: "Base Premium", text: $basePremium, isCurrency: true)
                    _InsField(title: "Taxes & GST", text: $taxesGST, isCurrency: true)
                    _InsField(title: "Add-On / Rider Cost", text: $addOnCost, isCurrency: true)
                    Picker("Payment Frequency", selection: $premiumFreq) {
                        ForEach(AstraPremiumFrequency.allCases, id: \.self) { f in Text(f.rawValue).tag(f) }
                    }
                }

                if type == .life || type == .termLifeInsurance || type == .ulip {
                    Section(header: Text("Life Insurance Details")) {
                        _InsField(title: "Nominee Name", text: $nomineeName)
                        _InsField(title: "Life Insurance Type", text: $lifeInsuranceTypeStr)
                        _InsField(title: "Death Benefit", text: $deathBenefit, isCurrency: true)
                        _InsField(title: "Maturity Benefit", text: $maturityBenefit, isCurrency: true)
                    }
                }

                if type == .health || type == .criticalIllness {
                    Section(header: Text("Health Insurance Details")) {
                        _InsField(title: "Plan Type", text: $planType)
                        _InsField(title: "Room Rent Limit", text: $roomRentLimit, isCurrency: true)
                        _InsField(title: "Pre/Post Hospitalization Terms", text: $prePostHosp)
                        _InsField(title: "Network Hospitals Count", text: $networkHosp, isNumber: true)
                        Toggle("Daycare Procedures Covered", isOn: $daycareProc)
                    }
                }

                if type == .motor {
                    Section(header: Text("Motor Insurance Details")) {
                        _InsField(title: "Vehicle Model", text: $vehicleModel)
                        _InsField(title: "Vehicle Number", text: $vehicleNumber)
                        _InsField(title: "IDV", text: $idv, isCurrency: true)
                        Toggle("Zero Depreciation", isOn: $zeroDep)
                        Toggle("Roadside Assistance", isOn: $rsa)
                    }
                }

                Section(header: Text("Advanced (Optional)")) {
                    _InsField(title: "Surrender Value", text: $surrenderValue, isCurrency: true)
                    _InsField(title: "Lock-in Period (Months)", text: $lockInPeriod, isNumber: true)
                    _InsField(title: "Expected Maturity Amount", text: $expectedMaturity, isCurrency: true)
                }

            }
            .navigationTitle("New Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: savePolicy) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .disabled(provider.isEmpty || cover.isEmpty || premium.isEmpty)
                    .tint((provider.isEmpty || cover.isEmpty || premium.isEmpty) ? .gray : .blue)
                }
                .sharedBackgroundVisibility(.visible)
            }
        }
    }

    private func savePolicy() {
        var newIns = AstraInsurance(
            insuranceType: type,
            provider: provider,
            policyNumber: policyNumber.isEmpty ? "N/A" : policyNumber,
            sumAssured: Double(cover) ?? 0,
            annualPremium: Double(premium) ?? 0,
            startDate: startDate,
            expiryDate: hasExpiry ? expiryDate : nil
        )

        newIns.basePremium = Double(basePremium) ?? 0
        newIns.taxesGST = Double(taxesGST) ?? 0
        newIns.addOnCost = Double(addOnCost) ?? 0
        newIns.premiumFrequency = premiumFreq

        if type == .life || type == .termLifeInsurance || type == .ulip {
            newIns.lifeDetails = AstraLifeInsuranceDetails(
                nomineeName: nomineeName.isEmpty ? nil : nomineeName,
                maturityBenefit: Double(maturityBenefit),
                deathBenefit: Double(deathBenefit),
                lifeInsuranceType: lifeInsuranceTypeStr.isEmpty ? nil : lifeInsuranceTypeStr
            )
        } else if type == .health || type == .criticalIllness {
            newIns.healthDetails = AstraHealthInsuranceDetails(
                planType: planType.isEmpty ? nil : planType,
                roomRentLimit: Double(roomRentLimit),
                prePostHospitalization: prePostHosp.isEmpty ? nil : prePostHosp,
                daycareProcedures: daycareProc,
                networkHospitalsCount: Int(networkHosp)
            )
        } else if type == .motor {
            newIns.motorDetails = AstraMotorInsuranceDetails(
                vehicleModel: vehicleModel.isEmpty ? nil : vehicleModel,
                vehicleNumber: vehicleNumber.isEmpty ? nil : vehicleNumber,
                idv: Double(idv),
                zeroDep: zeroDep,
                roadsideAssistance: rsa
            )
        }

        newIns.surrenderValue = Double(surrenderValue)
        newIns.lockInPeriodMonths = Int(lockInPeriod)
        newIns.expectedMaturityAmount = Double(expectedMaturity)

        appState.addInsurance(newIns)
        dismiss()
    }
}

struct _InsField: View {
    let title: String
    @Binding var text: String
    var isCurrency: Bool = false
    var isNumber: Bool = false

    var body: some View {
        HStack {
            Text(title).foregroundColor(.primary)
            Spacer(minLength: 16)
            if isCurrency { Text("₹").foregroundColor(.secondary) }
            TextField(title, text: $text)
                .multilineTextAlignment(.trailing)
                .keyboardType(isCurrency || isNumber ? .decimalPad : .default)
        }
    }
}

#Preview {
    AddInsuranceView()
        .environment(AppStateManager.withSampleData())
}

