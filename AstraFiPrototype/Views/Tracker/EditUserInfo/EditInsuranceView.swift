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
    @State private var planName = ""
    @State private var planNumber = ""
    @State private var policyTerm = ""
    @State private var premiumPayingTerm = ""
    @State private var installmentPremium = ""
    @State private var hasPolicyDocument = false

    @State private var nomineeName = ""
    @State private var maturityBenefit = ""
    @State private var deathBenefit = ""
    @State private var lifeInsuranceTypeStr = "Term"

    @State private var planType = "Individual"
    @State private var roomRentLimit = ""
    @State private var deductible = ""
    @State private var copayPercent = ""
    @State private var waitingPeriodMonths = ""
    @State private var coveredIllnesses = ""
    @State private var prePostHosp = ""
    @State private var daycareProc = true
    @State private var networkHosp = ""

    @State private var vehicleModel = ""
    @State private var vehicleNumber = ""
    @State private var idv = ""
    @State private var zeroDep = false
    @State private var rsa = false

    @State private var surrenderValue = ""
    @State private var paidUpValue = ""
    @State private var lockInPeriod = ""
    @State private var expectedMaturity = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Policy Identity")) {
                    Picker("Insurance Type", selection: $type) {
                        ForEach(AstraInsuranceType.allCases, id: \.self) { t in Text(t.rawValue).tag(t) }
                    }
                    _EditInsField(title: "Provider / Insurer", text: $provider)
                    _EditInsField(title: "Plan / Product Name", text: $planName)
                    _EditInsField(title: "Plan Number", text: $planNumber, isNumber: true)
                    _EditInsField(title: "Policy Number", text: $policyNumber)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    _EditInsField(title: "Policy Term (Years)", text: $policyTerm, isNumber: true)
                    _EditInsField(title: "Premium Paying Term (Years)", text: $premiumPayingTerm, isNumber: true)
                    Toggle("Has Expiry / Maturity Date", isOn: $hasExpiry)
                    if hasExpiry {
                        DatePicker("End Date", selection: $expiryDate, displayedComponents: .date)
                    }
                }

                Section(header: Text("Protection & Financial Data")) {
                    _EditInsField(title: "Sum Assured / Cover", text: $cover, isCurrency: true)
                    Picker("Payment Frequency", selection: $premiumFreq) {
                        ForEach(AstraPremiumFrequency.allCases, id: \.self) { f in Text(f.rawValue).tag(f) }
                    }
                    _EditInsField(title: "Installment Premium (Per Cycle)", text: $installmentPremium, isCurrency: true)
                    _EditInsField(title: "Annualized Premium", text: $premium, isCurrency: true)
                }

                Section(header: Text("Premium Breakdown (Optional)")) {
                    _EditInsField(title: "Base Premium", text: $basePremium, isCurrency: true)
                    _EditInsField(title: "Taxes & GST", text: $taxesGST, isCurrency: true)
                    _EditInsField(title: "Add-On / Rider Cost", text: $addOnCost, isCurrency: true)
                }

                if type == .life || type == .termLifeInsurance || type == .ulip || type == .personalAccident {
                    Section(header: Text("Life & Protection Details")) {
                        _EditInsField(title: "Nominee Name", text: $nomineeName)
                        _EditInsField(title: "Life Insurance Type", text: $lifeInsuranceTypeStr)
                        _EditInsField(title: "Death Benefit", text: $deathBenefit, isCurrency: true)
                        if type != .termLifeInsurance {
                            _EditInsField(title: "Maturity Benefit", text: $maturityBenefit, isCurrency: true)
                        }
                    }
                }

                if type == .health || type == .criticalIllness {
                    Section(header: Text("Health Insurance Details")) {
                        _EditInsField(title: "Plan Type", text: $planType)
                        _EditInsField(title: "Room Rent Limit", text: $roomRentLimit, isCurrency: true)
                        _EditInsField(title: "Deductible", text: $deductible, isCurrency: true)
                        _EditInsField(title: "Co-pay (%)", text: $copayPercent, isNumber: true)
                        _EditInsField(title: "Waiting Period (Months)", text: $waitingPeriodMonths, isNumber: true)
                        _EditInsField(title: "Covered Illnesses", text: $coveredIllnesses)
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

                Section(header: Text("Liquidity & Verification")) {
                    _EditInsField(title: "Surrender Value", text: $surrenderValue, isCurrency: true)
                    _EditInsField(title: "Paid-Up Value", text: $paidUpValue, isCurrency: true)
                    _EditInsField(title: "Lock-in Period (Months)", text: $lockInPeriod, isNumber: true)
                    _EditInsField(title: "Expected Maturity Amount", text: $expectedMaturity, isCurrency: true)
                    Toggle("Policy Document Available", isOn: $hasPolicyDocument)
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
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveChanges) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(provider.isEmpty || cover.isEmpty || (premium.isEmpty && installmentPremium.isEmpty) ? .gray : .blue)
                    }
                    .disabled(provider.isEmpty || cover.isEmpty || (premium.isEmpty && installmentPremium.isEmpty))
                }
            }
        }
    }

    private func loadPolicy() {
        type = insurance.insuranceType
        provider = insurance.provider
        planName = insurance.planName ?? ""
        planNumber = insurance.planNumber ?? ""
        policyNumber = insurance.policyNumber
        cover = "\(insurance.sumAssured.safeInt)"
        premium = "\(insurance.annualPremium.safeInt)"
        if let installment = insurance.installmentPremium { installmentPremium = "\(installment.safeInt)" }
        startDate = insurance.startDate
        if let exp = insurance.expiryDate ?? insurance.maturityDate { hasExpiry = true; expiryDate = exp }
        if let term = insurance.policyTermYears { policyTerm = "\(term)" }
        if let ppt = insurance.premiumPayingTermYears { premiumPayingTerm = "\(ppt)" }
        hasPolicyDocument = insurance.hasPolicyDocument ?? false

        basePremium = "\(insurance.basePremium.safeInt)"
        taxesGST = "\(insurance.taxesGST.safeInt)"
        addOnCost = "\(insurance.addOnCost.safeInt)"
        premiumFreq = insurance.premiumFrequency

        if let life = insurance.lifeDetails {
            nomineeName = life.nomineeName ?? ""
            lifeInsuranceTypeStr = life.lifeInsuranceType ?? ""
            if let db = life.deathBenefit { deathBenefit = "\(db.safeInt)" }
            if let mb = life.maturityBenefit { maturityBenefit = "\(mb.safeInt)" }
        }

        if let health = insurance.healthDetails {
            planType = health.planType ?? ""
            if let rrl = health.roomRentLimit { roomRentLimit = "\(rrl.safeInt)" }
            if let ded = health.deductible { deductible = "\(ded.safeInt)" }
            if let copay = health.copayPercent { copayPercent = "\(copay.safeInt)" }
            if let wait = health.waitingPeriodMonths { waitingPeriodMonths = "\(wait)" }
            coveredIllnesses = health.coveredIllnesses ?? ""
            prePostHosp = health.prePostHospitalization ?? ""
            if let nc = health.networkHospitalsCount { networkHosp = "\(nc)" }
            daycareProc = health.daycareProcedures
        }

        if let motor = insurance.motorDetails {
            vehicleModel = motor.vehicleModel ?? ""
            vehicleNumber = motor.vehicleNumber ?? ""
            if let declared = motor.idv { idv = "\(declared.safeInt)" }
            zeroDep = motor.zeroDep
            rsa = motor.roadsideAssistance
        }

        if let sv = insurance.surrenderValue { surrenderValue = "\(sv.safeInt)" }
        if let pv = insurance.paidUpValue { paidUpValue = "\(pv.safeInt)" }
        if let lip = insurance.lockInPeriodMonths { lockInPeriod = "\(lip)" }
        if let em = insurance.expectedMaturityAmount { expectedMaturity = "\(em.safeInt)" }
    }

    private func saveChanges() {
        let periods = InsuranceAnalysisEngine.periodsPerYear(premiumFreq)
        let annualVal: Double
        if let direct = Double(premium), direct > 0 {
            annualVal = direct
        } else if let inst = Double(installmentPremium), inst > 0 {
            annualVal = periods > 0 ? inst * periods : inst
        } else {
            annualVal = insurance.annualPremium
        }

        var updated = insurance
        updated.insuranceType = type
        updated.provider = provider
        updated.planName = planName.isEmpty ? nil : planName
        updated.planNumber = planNumber.isEmpty ? nil : planNumber
        updated.policyNumber = policyNumber
        updated.sumAssured = Double(cover) ?? insurance.sumAssured
        updated.annualPremium = annualVal
        updated.installmentPremium = Double(installmentPremium)
        updated.startDate = startDate
        updated.expiryDate = hasExpiry ? expiryDate : nil
        updated.policyTermYears = Int(policyTerm)
        updated.premiumPayingTermYears = Int(premiumPayingTerm)
        updated.hasPolicyDocument = hasPolicyDocument
        updated.lastUpdated = Date()

        updated.basePremium = Double(basePremium) ?? 0
        updated.taxesGST = Double(taxesGST) ?? 0
        updated.addOnCost = Double(addOnCost) ?? 0
        updated.premiumFrequency = premiumFreq

        if type == .life || type == .termLifeInsurance || type == .ulip || type == .personalAccident {
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
                networkHospitalsCount: Int(networkHosp),
                deductible: Double(deductible),
                copayPercent: Double(copayPercent),
                waitingPeriodMonths: Int(waitingPeriodMonths),
                coveredIllnesses: coveredIllnesses.isEmpty ? nil : coveredIllnesses
            )
            updated.lifeDetails = nil
            updated.motorDetails = nil
        } else if type == .motor {
            updated.motorDetails = AstraMotorInsuranceDetails(
                vehicleModel: vehicleModel.isEmpty ? nil : vehicleModel,
                vehicleNumber: vehicleNumber.isEmpty ? nil : vehicleNumber,
                idv: Double(idv),
                thirdPartyCoverage: true,
                ownDamageCoverage: true,
                zeroDep: zeroDep,
                roadsideAssistance: rsa
            )
            updated.lifeDetails = nil
            updated.healthDetails = nil
        }

        updated.surrenderValue = Double(surrenderValue)
        updated.paidUpValue = Double(paidUpValue)
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
