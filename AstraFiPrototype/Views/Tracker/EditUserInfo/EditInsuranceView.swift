import SwiftUI

struct EditInsuranceView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState

    let insurance: AstraInsurance

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
                    _EditInsField(title: "Provider / Insurer", text: $provider)
                    _EditInsField(title: "Policy Number", text: $policyNumber)
                    _EditInsField(title: "Sum Assured (Cover)", text: $cover, isCurrency: true)
                    _EditInsField(title: "Annual Premium", text: $premium, isCurrency: true)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    Toggle("Has Expiry Date", isOn: $hasExpiry)
                    if hasExpiry {
                        DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                    }
                }

                Section(header: Text("Premium Breakdown")) {
                    _EditInsField(title: "Base Premium", text: $basePremium, isCurrency: true)
                    _EditInsField(title: "Taxes & GST", text: $taxesGST, isCurrency: true)
                    _EditInsField(title: "Add-On / Rider Cost", text: $addOnCost, isCurrency: true)
                    Picker("Payment Frequency", selection: $premiumFreq) {
                        ForEach(AstraPremiumFrequency.allCases, id: \.self) { f in Text(f.rawValue).tag(f) }
                    }
                }

                if type == .life || type == .termLifeInsurance || type == .ulip {
                    Section(header: Text("Life Insurance Details")) {
                        _EditInsField(title: "Nominee Name", text: $nomineeName)
                        _EditInsField(title: "Life Insurance Type", text: $lifeInsuranceTypeStr)
                        _EditInsField(title: "Death Benefit", text: $deathBenefit, isCurrency: true)
                        _EditInsField(title: "Maturity Benefit", text: $maturityBenefit, isCurrency: true)
                    }
                }

                if type == .health || type == .criticalIllness {
                    Section(header: Text("Health Insurance Details")) {
                        _EditInsField(title: "Plan Type", text: $planType)
                        _EditInsField(title: "Room Rent Limit", text: $roomRentLimit, isCurrency: true)
                        _EditInsField(title: "Pre/Post Hospitalization Terms", text: $prePostHosp)
                        _EditInsField(title: "Network Hospitals Count", text: $networkHosp, isNumber: true)
                        Toggle("Daycare Procedures Covered", isOn: $daycareProc)
                    }
                }

                if type == .motor {
                    Section(header: Text("Motor Insurance Details")) {
                        _EditInsField(title: "Vehicle Model", text: $vehicleModel)
                        _EditInsField(title: "Vehicle Number", text: $vehicleNumber)
                        _EditInsField(title: "IDV", text: $idv, isCurrency: true)
                        Toggle("Zero Depreciation", isOn: $zeroDep)
                        Toggle("Roadside Assistance", isOn: $rsa)
                    }
                }

                Section(header: Text("Advanced (Optional)")) {
                    _EditInsField(title: "Surrender Value", text: $surrenderValue, isCurrency: true)
                    _EditInsField(title: "Lock-in Period (Months)", text: $lockInPeriod, isNumber: true)
                    _EditInsField(title: "Expected Maturity Amount", text: $expectedMaturity, isCurrency: true)
                }

            }
            .navigationTitle("Edit Policy")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadPolicy)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveChanges) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(provider.isEmpty || cover.isEmpty || premium.isEmpty ? Color.gray : .blue)
                            .clipShape(Circle())
                    }
                    .disabled(provider.isEmpty || cover.isEmpty || premium.isEmpty)
                }
            }
        }
    }

    private func loadPolicy() {
        type = insurance.insuranceType
        provider = insurance.provider
        policyNumber = insurance.policyNumber
        cover = "\(Int(insurance.sumAssured))"
        premium = "\(Int(insurance.annualPremium))"
        startDate = insurance.startDate
        if let exp = insurance.expiryDate { hasExpiry = true; expiryDate = exp }

        basePremium = "\(Int(insurance.basePremium))"
        taxesGST = "\(Int(insurance.taxesGST))"
        addOnCost = "\(Int(insurance.addOnCost))"
        premiumFreq = insurance.premiumFrequency

        if let life = insurance.lifeDetails {
            nomineeName = life.nomineeName ?? ""
            lifeInsuranceTypeStr = life.lifeInsuranceType ?? ""
            if let db = life.deathBenefit { deathBenefit = "\(Int(db))" }
            if let mb = life.maturityBenefit { maturityBenefit = "\(Int(mb))" }
        }

        if let health = insurance.healthDetails {
            planType = health.planType ?? ""
            if let rrl = health.roomRentLimit { roomRentLimit = "\(Int(rrl))" }
            prePostHosp = health.prePostHospitalization ?? ""
            if let nc = health.networkHospitalsCount { networkHosp = "\(nc)" }
            daycareProc = health.daycareProcedures
        }

        if let motor = insurance.motorDetails {
            vehicleModel = motor.vehicleModel ?? ""
            vehicleNumber = motor.vehicleNumber ?? ""
            if let declared = motor.idv { idv = "\(Int(declared))" }
            zeroDep = motor.zeroDep
            rsa = motor.roadsideAssistance
        }

        if let sv = insurance.surrenderValue { surrenderValue = "\(Int(sv))" }
        if let lip = insurance.lockInPeriodMonths { lockInPeriod = "\(lip)" }
        if let em = insurance.expectedMaturityAmount { expectedMaturity = "\(Int(em))" }
    }

    private func saveChanges() {
        var updated = insurance
        updated.insuranceType = type
        updated.provider = provider
        updated.policyNumber = policyNumber
        updated.sumAssured = Double(cover) ?? insurance.sumAssured
        updated.annualPremium = Double(premium) ?? insurance.annualPremium
        updated.startDate = startDate
        updated.expiryDate = hasExpiry ? expiryDate : nil

        updated.basePremium = Double(basePremium) ?? 0
        updated.taxesGST = Double(taxesGST) ?? 0
        updated.addOnCost = Double(addOnCost) ?? 0
        updated.premiumFrequency = premiumFreq

        if type == .life || type == .termLifeInsurance || type == .ulip {
            updated.lifeDetails = AstraLifeInsuranceDetails(
                nomineeName: nomineeName.isEmpty ? nil : nomineeName,
                maturityBenefit: Double(maturityBenefit),
                deathBenefit: Double(deathBenefit),
                lifeInsuranceType: lifeInsuranceTypeStr.isEmpty ? nil : lifeInsuranceTypeStr
            )
            updated.healthDetails = nil
            updated.motorDetails = nil
        } else if type == .health || type == .criticalIllness {
            updated.healthDetails = AstraHealthInsuranceDetails(
                planType: planType.isEmpty ? nil : planType,
                roomRentLimit: Double(roomRentLimit),
                prePostHospitalization: prePostHosp.isEmpty ? nil : prePostHosp,
                daycareProcedures: daycareProc,
                networkHospitalsCount: Int(networkHosp)
            )
            updated.lifeDetails = nil
            updated.motorDetails = nil
        } else if type == .motor {
            updated.motorDetails = AstraMotorInsuranceDetails(
                vehicleModel: vehicleModel.isEmpty ? nil : vehicleModel,
                vehicleNumber: vehicleNumber.isEmpty ? nil : vehicleNumber,
                idv: Double(idv),
                zeroDep: zeroDep,
                roadsideAssistance: rsa
            )
            updated.lifeDetails = nil
            updated.healthDetails = nil
        }

        updated.surrenderValue = Double(surrenderValue)
        updated.lockInPeriodMonths = Int(lockInPeriod)
        updated.expectedMaturityAmount = Double(expectedMaturity)

        appState.updateInsurance(updated)
        dismiss()
    }
}

struct _EditInsField: View {
    let title: String
    @Binding var text: String
    var isCurrency: Bool = false
    var isNumber: Bool = false

    var body: some View {
        HStack {
            Text(title + (isCurrency ? " (₹)" : "")).foregroundColor(.primary)
            Spacer(minLength: 16)
            TextField(isCurrency ? "Amount" : (isNumber ? "Count" : "Details"), text: $text)
                .multilineTextAlignment(.trailing)
                .keyboardType(isCurrency || isNumber ? .decimalPad : .default)
        }
    }
}

#Preview {
    EditInsuranceView(insurance: AstraInsurance(
        insuranceType: .life,
        provider: "HDFC Life",
        policyNumber: "POL123456789",
        sumAssured: 10000000,
        annualPremium: 15000,
        startDate: Date(),
        expiryDate: Date().addingTimeInterval(86400 * 365)
    ))
    .environment(AppStateManager.withSampleData())
}
