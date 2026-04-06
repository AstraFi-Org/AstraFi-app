import SwiftUI


@Observable
final class AppStateManager {

    var isLoading: Bool = true
    var isAssessmentSkipped: Bool = false

    static func withSampleData() -> AppStateManager {
        let mgr = AppStateManager()
        let cal = Calendar.current
        func monthsAgo(_ n: Int) -> Date {
            cal.date(byAdding: .month, value: -n, to: Date()) ?? Date()
        }
        func yearsFromNow(_ n: Int) -> Date {
            cal.date(byAdding: .year, value: n, to: Date()) ?? Date()
        }

        let goalHome = AstraGoal(goalName: "Home Purchase", targetAmount: 7200000, currentAmount: 5500000, targetDate: yearsFromNow(3))
        let goalCar  = AstraGoal(goalName: "Car",       targetAmount: 2200000, currentAmount: 1800000, targetDate: yearsFromNow(1))
        let goalEdu  = AstraGoal(goalName: "Education", targetAmount: 1200000, currentAmount: 400000,  targetDate: yearsFromNow(6))

        mgr.currentProfile = AstraUserProfile(
            signUp: AstraSignUp(signUpName: "Akash Kashyap", email: "akash@example.com", password: ""),
            basicDetails: AstraBasicDetails(
                name: "Akash", age: 30, gender: .male, maritalStatus: .single,
                adultDependents: 1, childDependents: 1,
                incomeType: .fixed,
                monthlyIncome: 120000, monthlyIncomeAfterTax: 95000,
                monthlyExpenses: 55000, emergencyFundAmount: 300000,
                activeInvestment: true,
                riskTolerance: .high,
                investmentHorizon: .longTerm
            ),
            assets: AstraAssets(
                savingsAccountAmount: 250000,
                stocksHoldingAmount: 480000,
                mutualFundHoldingAmount: 800000,
                otherInvestmentAmount: 0,
                propertyAmount: 8500000,
                vehiclesAmount: 900000,
                depositsAmount: 200000,
                jewelleryAmount: 0
            ),
            liabilities: AstraLiabilities(
                homeLoanAmount: 7500000,
                vehicleLoanAmount: 900000,
                creditCardBills: 0,
                educationLoanAmount: 500000,
                otherLoanAmount: 0,
                otherDebtAmount: 0
            ),
            investments: [
                AstraInvestment(investmentType: .mutualFund, subtype: .equityFund,
                                investmentName: "Axis Bluechip MF", investmentAmount: 34000,
                                startDate: Date(), associatedGoalID: goalHome.id, mode: .sip,
                                schemeCode: "120465", units: 500.0, purchaseNAV: 60.0),
                AstraInvestment(investmentType: .stocks, subtype: .smallCap,
                                investmentName: "Parang TVF", investmentAmount: 24000,
                                startDate: Date(), associatedGoalID: goalHome.id, mode: .lumpsum),
                AstraInvestment(investmentType: .mutualFund, subtype: .debtFund,
                                investmentName: "ICICI Prudential MF", investmentAmount: 480000,
                                startDate: monthsAgo(12), associatedGoalID: goalCar.id, mode: .sip,
                                schemeCode: "105703", units: 4500.0, purchaseNAV: 100.0),
                AstraInvestment(investmentType: .stocks, subtype: .largeCap,
                                investmentName: "Reliance Industries", investmentAmount: 180000,
                                startDate: monthsAgo(24), mode: .lumpsum),
                AstraInvestment(investmentType: .goldETF,
                                investmentName: "SBI Gold ETF", investmentAmount: 75000,
                                startDate: monthsAgo(6), mode: .lumpsum),
                AstraInvestment(investmentType: .deposits,
                                investmentName: "HDFC Fixed Deposit", investmentAmount: 200000,
                                startDate: monthsAgo(8), mode: .lumpsum),
            ],
            loans: [
                AstraLoan(loanType: .homeLoan, lender: .hdfcBank,
                          loanAmount: 7500000, interestRate: 8.5,
                          loanStartDate: monthsAgo(5), loanTenureMonths: 180),
                AstraLoan(loanType: .carLoan, lender: .iciciBank,
                          loanAmount: 900000, interestRate: 9.2,
                          loanStartDate: monthsAgo(22), loanTenureMonths: 60),
                AstraLoan(loanType: .educationLoan, lender: .stateBankOfIndia,
                          loanAmount: 500000, interestRate: 7.0,
                          loanStartDate: monthsAgo(12), loanTenureMonths: 84)
            ],
            insurances: [
                AstraInsurance(insuranceType: .health, provider: "Star Health",
                               policyNumber: "SH-2024-00123", sumAssured: 500000,
                               annualPremium: 12000, startDate: monthsAgo(24),
                               expiryDate: yearsFromNow(1),
                               healthDetails: AstraHealthInsuranceDetails(planType: "Family Floater", roomRentLimit: 5000, daycareProcedures: true),
                               claims: [AstraClaim(date: monthsAgo(6), amount: 15000, status: .approved, description: "Fever hospitalization")]),
                AstraInsurance(insuranceType: .termLifeInsurance, provider: "HDFC Life",
                               policyNumber: "HDFC-TL-98765", sumAssured: 10000000,
                               annualPremium: 18500, startDate: monthsAgo(36),
                               expiryDate: yearsFromNow(15),
                               lifeDetails: AstraLifeInsuranceDetails(nomineeName: "Anjali Kashyap", maturityBenefit: 0, deathBenefit: 10000000, lifeInsuranceType: "Term")),
                AstraInsurance(insuranceType: .motor, provider: "Bajaj Allianz",
                               policyNumber: "BA-CAR-55432", sumAssured: 500000,
                               annualPremium: 9000, startDate: monthsAgo(12),
                               expiryDate: monthsAgo(-1),
                               motorDetails: AstraMotorInsuranceDetails(vehicleModel: "Honda City", idv: 450000, zeroDep: true, roadsideAssistance: true))
            ],
            goals: [goalHome, goalCar, goalEdu],
            financialHealthReport: AstraFinancialHealthReport(
                netWorth: 2030000, savingsRate: 42, debtToIncomeRatio: 0.35,
                investmentScore: 72, emergencyFundMonths: 5.5
            ),
            cashflowData: CashflowEntry(rent: 20000, groceries: 8000, utilities: 4000, dining: 6000, transport: 5000, shopping: 7000, entertainment: 3000, misc: 2000),
            monthlyHealthAssessments: [],
            isSetuConnected: false
        )
        return mgr
    }

    func setupEmptyProfile(name: String = "User") {
        let signUp = AstraSignUp(signUpName: name, email: "", password: "")

        let basic = AstraBasicDetails(
            name: name, age: 0, gender: .male, maritalStatus: .single,
            adultDependents: 0, childDependents: 0,
            incomeType: .fixed,
            monthlyIncome: 0, monthlyIncomeAfterTax: 0,
            monthlyExpenses: 0, emergencyFundAmount: 0,
            activeInvestment: false,
            riskTolerance: .low, investmentHorizon: .shortTerm
        )

        let assets = AstraAssets(
            savingsAccountAmount: 0, stocksHoldingAmount: 0,
            mutualFundHoldingAmount: 0, otherInvestmentAmount: 0,
            propertyAmount: 0, vehiclesAmount: 0,
            depositsAmount: 0, jewelleryAmount: 0
        )

        let liabilities = AstraLiabilities(
            homeLoanAmount: 0, vehicleLoanAmount: 0,
            creditCardBills: 0, educationLoanAmount: 0,
            otherLoanAmount: 0, otherDebtAmount: 0
        )

        let report = AstraFinancialHealthReport(
            netWorth: 0, savingsRate: 0, debtToIncomeRatio: 0,
            investmentScore: 0, emergencyFundMonths: 0
        )

        self.currentProfile = AstraUserProfile(
            signUp: signUp,
            basicDetails: basic,
            assets: assets,
            liabilities: liabilities,
            investments: [],
            loans: [],
            insurances: [],
            goals: [],
            financialHealthReport: report,
            cashflowData: nil,
            monthlyHealthAssessments: [],
            isSetuConnected: false
        )
    }

    var hasCompletedOnboarding: Bool = false

    var isAuthenticated: Bool = false

    var showDashboard: Bool = false

    var tempName: String = ""
    var tempEmail: String = ""
    var tempPassword: String = ""

    var currentProfile: AstraUserProfile?
    var savedPlans: [InvestmentPlanModel] = []

    func savePlan(_ plan: InvestmentPlanModel) {
        savedPlans.append(plan)

    }

    init() {
        Task {
            await syncMutualFundNAVs()
        }
    }

    var mfService = MFService.shared

    func updateProfile(from assessmentData: CompleteAssessmentData) {
        let signUp = AstraSignUp(
            signUpName: assessmentData.name,
            email: assessmentData.email.isEmpty ? "user@example.com" : assessmentData.email,
            password: assessmentData.password
        )

        let isVariable = assessmentData.incomeType == .variable
        let rawMin = Double(assessmentData.minMonthlyIncome) ?? 0
        let rawMax = Double(assessmentData.maxMonthlyIncome) ?? 0
        let calculatedIncome = isVariable ? (rawMin + rawMax) / 2 : (Double(assessmentData.income) ?? 0)
        let incomeValue = calculatedIncome.isFinite ? calculatedIncome : 0

        let rawTaxRate = Double(assessmentData.taxPercentage) ?? 0
        let taxRate = rawTaxRate.isFinite ? rawTaxRate : 0

        let calculatedIncomeAfterTax = isVariable ? (incomeValue * (1 - taxRate / 100)) : (Double(assessmentData.incomeAfterTax) ?? 0)
        let incomeAfterTaxValue = calculatedIncomeAfterTax.isFinite ? calculatedIncomeAfterTax : 0

        let rawExpenses = Double(assessmentData.expenditure) ?? 0
        let expensesValue = rawExpenses.isFinite ? rawExpenses : 0

        let rawEmergency = Double(assessmentData.emergencyFundAmount) ?? 0
        let emergencyValue = rawEmergency.isFinite ? rawEmergency : 0

        let basic = AstraBasicDetails(
            name: assessmentData.name,
            age: Int(assessmentData.age) ?? 0,
            gender: assessmentData.gender == .male ? .male : .female,
            maritalStatus: .single, 
            adultDependents: assessmentData.adultDependents,
            childDependents: assessmentData.childDependents,
            incomeType: assessmentData.incomeType == .fixed ? .fixed : .variable,
            monthlyIncome: incomeValue,
            monthlyIncomeAfterTax: incomeAfterTaxValue,
            monthlyExpenses: expensesValue,
            emergencyFundAmount: emergencyValue,
            activeInvestment: !assessmentData.investmentEntries.isEmpty,
            riskTolerance: .medium,
            investmentHorizon: .mediumTerm
        )

        let profileInvestments = assessmentData.investmentEntries.map { entry in
            let rawAmt = Double(entry.amount) ?? 0
            return AstraInvestment(
                investmentType: mapInvestmentType(entry.type),
                investmentName: entry.fundName,
                investmentAmount: rawAmt.isFinite ? rawAmt : 0,
                startDate: entry.startDate,
                mode: entry.mode == .sip ? .sip : .lumpsum,
                schemeCode: entry.schemeCode,
                isin: entry.isin
            )
        }

        let profileLoans = assessmentData.loanEntries.map { entry in
            let rawAmt = Double(entry.amount) ?? 0
            let rawRate = Double(entry.interestRate) ?? 0
            let rawEMI = Double(entry.emiAmount)

            var loan = AstraLoan(
                loanType: mapLoanType(entry.type),
                lender: mapLender(entry.bank),
                loanAmount: rawAmt.isFinite ? rawAmt : 0,
                interestRate: rawRate.isFinite ? rawRate : 0,
                interestType: entry.interestType,
                compoundingFrequency: entry.compoundingFrequency,
                emiAmount: (rawEMI?.isFinite ?? false) ? rawEMI : nil,
                emiFrequency: entry.emiFrequency,
                loanStartDate: entry.startDate,
                firstEMIDate: entry.firstEMIDate,
                loanTenureMonths: (Int(entry.timePeriod) ?? 0) * 12,
                installmentsPaid: Int(entry.installmentsPaid) ?? 0
            )

            loan.prepaymentPenaltyPercentage = Double(entry.prepaymentPenalty) ?? 0
            loan.isFloatingRate = entry.isFloatingRate
            loan.processingFee = Double(entry.processingFee) ?? 0
            loan.insurancePremium = Double(entry.insuranceCost) ?? 0
            loan.latePaymentPenalty = Double(entry.latePaymentPenalty) ?? 0
            loan.otherCharges = Double(entry.otherCharges) ?? 0
            loan.moratoriumMonths = Int(entry.moratoriumDuration) ?? 0
            loan.interestAccrualDuringMoratorium = entry.interestAccrualDuringMoratorium
            loan.trackTaxBenefits = entry.trackTaxBenefits

            return loan
        }

        let profileInsurances = assessmentData.insuranceEntries.map { entry in
            var ins = AstraInsurance(
                insuranceType: mapInsuranceType(entry.currentType),
                provider: entry.insurer,
                policyNumber: entry.policyNumber,
                sumAssured: Double(entry.coverAmount) ?? 0,
                annualPremium: Double(entry.annualPremium) ?? 0,
                startDate: entry.startDate,
                expiryDate: entry.expiryDate
            )

            ins.basePremium = Double(entry.basePremium) ?? (ins.annualPremium * 0.8)
            ins.taxesGST = Double(entry.taxesGST) ?? (ins.annualPremium * 0.18)
            ins.premiumFrequency = entry.premiumFrequency

            switch entry.details {
            case .life(let d):
                ins.lifeDetails = AstraLifeInsuranceDetails(
                    nomineeName: d.nomineeName,
                    maturityBenefit: Double(d.maturityBenefit),
                    deathBenefit: Double(d.deathBenefit),
                    lifeInsuranceType: d.lifeInsuranceType
                )
            case .term(let d):
                ins.lifeDetails = AstraLifeInsuranceDetails(
                    nomineeName: d.nomineeName,
                    maturityBenefit: 0,
                    deathBenefit: Double(d.deathBenefit),
                    lifeInsuranceType: "Term"
                )
            case .ulip(let d):
                ins.lifeDetails = AstraLifeInsuranceDetails(
                    nomineeName: d.nomineeName,
                    maturityBenefit: 0,
                    deathBenefit: 0,
                    lifeInsuranceType: "ULIP"
                )
                ins.surrenderValue = Double(d.surrenderValue)
                ins.expectedMaturityAmount = Double(d.expectedMaturityAmount)
            case .health(let d):
                ins.healthDetails = AstraHealthInsuranceDetails(
                    planType: d.planType,
                    roomRentLimit: Double(d.roomRentLimit),
                    daycareProcedures: d.daycareProcedures,
                    networkHospitalsCount: Int(d.networkHospitalsCount)
                )
            case .criticalIllness(_):
                ins.healthDetails = AstraHealthInsuranceDetails(
                    planType: "N/A",
                    roomRentLimit: 0,
                    daycareProcedures: true,
                    networkHospitalsCount: 0
                )

            case .motor(let d):
                ins.motorDetails = AstraMotorInsuranceDetails(
                    vehicleModel: d.vehicleModel,
                    idv: Double(d.idv),
                    zeroDep: d.zeroDep,
                    roadsideAssistance: d.roadsideAssistance
                )
            case .travel(_):

                break
            }

            return ins
        }

        let assets = AstraAssets(
            stocksHoldingAmount: profileInvestments.filter { $0.investmentType == .stocks }.map { $0.investmentAmount }.reduce(0, +),
            mutualFundHoldingAmount: profileInvestments.filter { $0.investmentType == .mutualFund }.map { $0.investmentAmount }.reduce(0, +),
            otherInvestmentAmount: profileInvestments.filter { [.cryptocurrency, .other, .nps, .ppf, .bonds].contains($0.investmentType) }.map { $0.investmentAmount }.reduce(0, +),
            propertyAmount: profileInvestments.filter { $0.investmentType == .realEstate }.map { $0.investmentAmount }.reduce(0, +),
            vehiclesAmount: 0, 
            depositsAmount: profileInvestments.filter { $0.investmentType == .deposits }.map { $0.investmentAmount }.reduce(0, +),
            jewelleryAmount: profileInvestments.filter { $0.investmentType == .physicalGold }.map { $0.investmentAmount }.reduce(0, +)
        )

        let liabilities = AstraLiabilities(
            homeLoanAmount: profileLoans.filter { $0.loanType == .homeLoan }.map { $0.loanAmount }.reduce(0, +),
            vehicleLoanAmount: profileLoans.filter { $0.loanType == .carLoan }.map { $0.loanAmount }.reduce(0, +),
            creditCardBills: profileLoans.filter { $0.loanType == .other && $0.lender == .other }.map { $0.loanAmount }.reduce(0, +), 
            educationLoanAmount: profileLoans.filter { $0.loanType == .educationLoan }.map { $0.loanAmount }.reduce(0, +),
            otherLoanAmount: profileLoans.filter { ![.homeLoan, .carLoan, .educationLoan].contains($0.loanType) }.map { $0.loanAmount }.reduce(0, +)
        )

        let totalAs = assets.totalAssets
        let totalLi = liabilities.totalLiabilities
        let netWorth = totalAs - totalLi

        let savingsRate = incomeAfterTaxValue > 0 ? ((incomeAfterTaxValue - expensesValue) / incomeAfterTaxValue) * 100 : 0

        let totalEMIs = profileLoans.reduce(0.0) { $0 + $1.calculatedEMI }
        let dti = incomeValue > 0 ? (totalEMIs / incomeValue) : 0

        let efMonths = expensesValue > 0 ? (emergencyValue / expensesValue) : 0

        let report = AstraFinancialHealthReport(
            netWorth: netWorth,
            savingsRate: savingsRate,
            debtToIncomeRatio: dti,
            investmentScore: Int(min(100, (savingsRate * 0.5) + (efMonths * 10))),
            emergencyFundMonths: efMonths
        )

        let initialScore = 400 + Int(report.investmentScore * 4) 
        let status = initialScore >= 750 ? "Excellent" : initialScore >= 650 ? "Good" : "Needs Work"
        let firstAssessment = AstraHealthAssessment(
            date: Date(),
            score: initialScore,
            status: status,
            keyInsights: ["First assessment generated from initial data", 
                          "Emergency fund covers \(String(format: "%.1f", efMonths)) months",
                          "Savings rate stands at \(Int(savingsRate))%"]
        )

        self.currentProfile = AstraUserProfile(
            signUp: signUp,
            basicDetails: basic,
            assets: assets,
            liabilities: liabilities,
            investments: profileInvestments,
            loans: profileLoans,
            insurances: profileInsurances,
            goals: [],
            financialHealthReport: report,
            monthlyHealthAssessments: [firstAssessment],
            isSetuConnected: assessmentData.isSetuSelected
        )

        Task {
            await syncMutualFundNAVs()
        }
    }

    private func mapInvestmentType(_ type: AssessmentInvestmentEntry.InvestmentType) -> AstraInvestmentType {
        switch type {
        case .mutualFund: return .mutualFund
        case .stocks: return .stocks
        case .bonds: return .bonds
        case .realEstate: return .realEstate
        case .gold: return .physicalGold
        case .crypto: return .cryptocurrency
        case .ppf: return .ppf
        case .nps: return .nps
        }
    }

    private func mapLoanType(_ type: AssessmentLoanEntry.LoanType) -> AstraLoanType {
        switch type {
        case .homeLoan: return .homeLoan
        case .carLoan: return .carLoan
        case .educationLoan: return .educationLoan
        case .businessLoan: return .businessLoan
        case .personalLoan: return .personalLoan
        case .creditCard: return .other
        }
    }

    private func mapLender(_ name: String) -> AstraLoanLender {
        switch name {
        case "SBI": return .stateBankOfIndia
        case "HDFC Bank": return .hdfcBank
        case "ICICI Bank": return .iciciBank
        case "Axis Bank": return .axisBank
        case "Kotak Mahindra": return .kotakMahindra
        case "Other": return .other
        default: return .other
        }
    }

    private func mapInsuranceType(_ type: AssessmentInsuranceEntry.InsuranceType) -> AstraInsuranceType {
        switch type {
        case .health: return .health
        case .life: return .life
        case .criticalIllness: return .criticalIllness
        case .term: return .termLifeInsurance
        case .motor: return .motor
        case .travel: return .travel
        case .ulip: return .ulip
        }
    }

    func recalculateFinancials() {
        guard var profile = currentProfile else { return }

        var newAssets = profile.assets
        newAssets.stocksHoldingAmount = profile.investments.filter { $0.investmentType == .stocks }.map { $0.currentValue }.reduce(0, +)
        newAssets.mutualFundHoldingAmount = profile.investments.filter { $0.investmentType == .mutualFund }.map { $0.currentValue }.reduce(0, +)
        newAssets.depositsAmount = profile.investments.filter { $0.investmentType == .deposits }.map { $0.currentValue }.reduce(0, +)
        newAssets.propertyAmount = profile.investments.filter { $0.investmentType == .realEstate }.map { $0.currentValue }.reduce(0, +)
        newAssets.jewelleryAmount = profile.investments.filter { $0.investmentType == .physicalGold }.map { $0.currentValue }.reduce(0, +)
        newAssets.otherInvestmentAmount = profile.investments.filter { [.cryptocurrency, .other, .nps, .ppf, .bonds].contains($0.investmentType) }.map { $0.currentValue }.reduce(0, +)
        profile.assets = newAssets

        var newLiabilities = profile.liabilities
        newLiabilities.homeLoanAmount = profile.loans.filter { $0.loanType == .homeLoan }.map { $0.loanAmount }.reduce(0, +)
        newLiabilities.vehicleLoanAmount = profile.loans.filter { $0.loanType == .carLoan }.map { $0.loanAmount }.reduce(0, +)
        newLiabilities.educationLoanAmount = profile.loans.filter { $0.loanType == .educationLoan }.map { $0.loanAmount }.reduce(0, +)
        newLiabilities.otherLoanAmount = profile.loans.filter { ![.homeLoan, .carLoan, .educationLoan].contains($0.loanType) }.map { $0.loanAmount }.reduce(0, +)
        profile.liabilities = newLiabilities

        let totalAs = profile.assets.totalAssets
        let totalLi = profile.liabilities.totalLiabilities
        let netWorth = totalAs - totalLi

        let incomeAfterTax = profile.basicDetails.monthlyIncomeAfterTax
        let expenses = profile.basicDetails.monthlyExpenses
        let savingsRate = incomeAfterTax > 0 ? ((incomeAfterTax - expenses) / incomeAfterTax) * 100 : 0

        let totalEMIs = profile.loans.reduce(0.0) { $0 + $1.calculatedEMI }
        let dti = profile.basicDetails.monthlyIncome > 0 ? (totalEMIs / profile.basicDetails.monthlyIncome) : 0
        let efMonths = expenses > 0 ? (profile.basicDetails.emergencyFundAmount / expenses) : 0

        profile.financialHealthReport = AstraFinancialHealthReport(
            netWorth: netWorth,
            savingsRate: savingsRate,
            debtToIncomeRatio: dti,
            investmentScore: Int(min(100, (savingsRate * 0.5) + (efMonths * 10))),
            emergencyFundMonths: efMonths
        )

        self.currentProfile = profile
    }

    func updateCashflow(_ cashflow: CashflowEntry) {
        if var profile = currentProfile {
            profile.cashflowData = cashflow
            profile.basicDetails.monthlyExpenses = cashflow.total
            currentProfile = profile
            recalculateFinancials()
        }
    }

    func addGoal(_ goal: AstraGoal) {
        if var profile = currentProfile {
            profile.goals.append(goal)
            currentProfile = profile
            recalculateFinancials()
        }
    }

    func updateGoal(_ goal: AstraGoal) {
        if var profile = currentProfile,
           let index = profile.goals.firstIndex(where: { $0.id == goal.id }) {
            profile.goals[index] = goal
            currentProfile = profile
            recalculateFinancials()
        }
    }

    func deleteGoal(at indexSet: IndexSet) {
        if var profile = currentProfile {
            profile.goals.remove(atOffsets: indexSet)
            currentProfile = profile
            recalculateFinancials()
        }
    }

    func deleteGoal(_ goal: AstraGoal) {
        if var profile = currentProfile,
           let index = profile.goals.firstIndex(where: { $0.id == goal.id }) {
            profile.goals.remove(at: index)
            currentProfile = profile
            recalculateFinancials()
        }
    }

    func addInvestment(_ investment: AstraInvestment) {
        if var profile = currentProfile {
            profile.investments.append(investment)
            currentProfile = profile
            recalculateFinancials()
            Task {
                await syncMutualFundNAVs()
            }
        }
    }

    func updateInvestment(_ investment: AstraInvestment) {
        if var profile = currentProfile,
           let index = profile.investments.firstIndex(where: { $0.id == investment.id }) {
            profile.investments[index] = investment
            currentProfile = profile
            recalculateFinancials()
            Task {
                await syncMutualFundNAVs(force: true)
            }
        }
    }

    func deleteInvestment(at indexSet: IndexSet) {
        if var profile = currentProfile {
            profile.investments.remove(atOffsets: indexSet)
            currentProfile = profile
            recalculateFinancials()
        }
    }

    func deleteInvestment(_ investment: AstraInvestment) {
        if var profile = currentProfile,
           let index = profile.investments.firstIndex(where: { $0.id == investment.id }) {
            profile.investments.remove(at: index)
            currentProfile = profile
            recalculateFinancials()
        }
    }

    func addLoan(_ loan: AstraLoan) {
        if var profile = currentProfile {
            profile.loans.append(loan)
            currentProfile = profile
            recalculateFinancials()
        }
    }

    func updateLoan(_ loan: AstraLoan) {
        if var profile = currentProfile,
           let index = profile.loans.firstIndex(where: { $0.id == loan.id }) {
            profile.loans[index] = loan
            currentProfile = profile
            recalculateFinancials()
        }
    }

    func deleteLoan(at indexSet: IndexSet) {
        if var profile = currentProfile {
            profile.loans.remove(atOffsets: indexSet)
            currentProfile = profile
            recalculateFinancials()
        }
    }

    func deleteLoan(_ loan: AstraLoan) {
        if var profile = currentProfile,
           let index = profile.loans.firstIndex(where: { $0.id == loan.id }) {
            profile.loans.remove(at: index)
            currentProfile = profile
            recalculateFinancials()
        }
    }

    func addInsurance(_ insurance: AstraInsurance) {
        if var profile = currentProfile {
            profile.insurances.append(insurance)
            currentProfile = profile
            recalculateFinancials()
        }
    }

    func updateInsurance(_ insurance: AstraInsurance) {
        if var profile = currentProfile,
           let index = profile.insurances.firstIndex(where: { $0.id == insurance.id }) {
            profile.insurances[index] = insurance
            currentProfile = profile
            recalculateFinancials()
        }
    }

    func deleteInsurance(at indexSet: IndexSet) {
        if var profile = currentProfile {
            profile.insurances.remove(atOffsets: indexSet)
            currentProfile = profile
            recalculateFinancials()
        }
    }

    func investments(for goalID: UUID) -> [AstraInvestment] {
        currentProfile?.investments.filter { $0.associatedGoalID == goalID } ?? []
    }

    func totalCollected(for goalID: UUID) -> Double {
        let linked = investments(for: goalID)
        return linked.reduce(0) { total, inv in
            if inv.mode == .sip {

                let calendar = Calendar.current
                let components = calendar.dateComponents([.month], from: inv.startDate, to: Date())
                let months = max(components.month ?? 0, 1)
                return total + (inv.investmentAmount * Double(months))
            } else {
                return total + inv.investmentAmount
            }
        }
    }

    func syncMutualFundNAVs(force: Bool = false) async {
        await mfService.fetchMFData(force: force)

        guard var profile = currentProfile else { return }
        var updated = false

        for i in 0..<profile.investments.count {
            if profile.investments[i].investmentType == .mutualFund {

                if profile.investments[i].schemeCode == nil {
                    if let code = mfService.findSchemeCode(for: profile.investments[i].investmentName) {
                        profile.investments[i].schemeCode = code
                        updated = true
                    }
                }

                guard let code = profile.investments[i].schemeCode else { continue }

                if let liveScheme = mfService.getScheme(by: code) {
                    profile.investments[i].lastNAV = liveScheme.nav
                    profile.investments[i].lastUpdated = Date()
                    updated = true
                }

                let history = await mfService.fetchHistoricalGraphData(schemeCode: code)
                if !history.isEmpty {

                    if profile.investments[i].lastNAV == nil || profile.investments[i].lastNAV == 0 {
                        if let latestNAVStr = history.last?.nav, let lNAV = Double(latestNAVStr) {
                            profile.investments[i].lastNAV = lNAV
                            profile.investments[i].lastUpdated = Date()
                            updated = true
                        }
                    }

                    if profile.investments[i].purchaseNAV == nil || profile.investments[i].purchaseNAV == 0 {

                        let df = DateFormatter(); df.dateFormat = "dd-MM-yyyy"
                        let targetDate = profile.investments[i].startDate

                        if let histNAV = await mfService.fetchHistoricalNAV(schemeCode: code, date: targetDate) {
                            profile.investments[i].purchaseNAV = histNAV
                            updated = true
                        }
                    }
                }

                if let pNAV = profile.investments[i].purchaseNAV, pNAV > 0 {
                    let units = profile.investments[i].investmentAmount / pNAV
                    if profile.investments[i].units != units {
                        profile.investments[i].units = units
                        updated = true
                    }
                }
            }
        }

        if updated {
            await MainActor.run {
                self.currentProfile = profile
                self.recalculateFinancials()
            }
        }
    }
}
