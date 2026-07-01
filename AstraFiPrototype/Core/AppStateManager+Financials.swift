import Foundation
import SwiftUI
import Supabase
import AuthenticationServices
import CryptoKit

extension AppStateManager {
    func updateProfile(from assessmentData: CompleteAssessmentData) {
        let signUp = AstraSignUp(
            signUpName: assessmentData.name,
            email: assessmentData.email.isEmpty ? "user@example.com" : assessmentData.email,
            password: assessmentData.password
        )
        
        let rawIncome = Double(assessmentData.income) ?? 0
        let incomeValue = rawIncome.isFinite ? rawIncome : 0
        let incomeAfterTaxValue = incomeValue // Removed 20% default tax estimate
        
        let rawExpenses = Double(assessmentData.expenditure) ?? 0
        let expensesValue = rawExpenses.isFinite ? rawExpenses : 0
        
        let rawEmergency = Double(assessmentData.emergencyFundAmount) ?? 0
        let emergencyValue = rawEmergency.isFinite ? rawEmergency : 0
        
        let basic = AstraBasicDetails(
            name: assessmentData.name,
            age: Int(assessmentData.age.trimmingCharacters(in: .whitespaces)) ?? 0,
            gender: assessmentData.gender == .male ? .male : .female,
            maritalStatus: .single,
            adultDependents: self.currentProfile?.basicDetails.adultDependents ?? Int(assessmentData.numberOfDependents) ?? 1,
            childDependents: 0,
            incomeType: assessmentData.incomeType == .fixed ? .fixed : .variable,
            monthlyIncome: incomeValue,
            monthlyIncomeAfterTax: incomeValue, // Removed 20% default tax estimate
            monthlyExpenses: expensesValue,
            emergencyFundAmount: emergencyValue,
            activeInvestment: !assessmentData.investmentEntries.isEmpty,
            riskTolerance: Self.deriveRiskTolerance(
                savingsRate: incomeAfterTaxValue > 0 ? (incomeAfterTaxValue - expensesValue) / incomeAfterTaxValue : 0,
                investmentCount: assessmentData.investmentEntries.count
            ),
            investmentHorizon: Self.deriveInvestmentHorizon(
                age: Int(assessmentData.age.trimmingCharacters(in: .whitespaces)) ?? 30,
                dependents: Int(assessmentData.numberOfDependents) ?? 0
            )
        )
        
        let profileInvestments = assessmentData.investmentEntries.map { entry in
            let rawAmt = Double(entry.amount) ?? 0
            var inv = AstraInvestment(
                investmentType: mapInvestmentType(entry.type),
                investmentName: entry.fundName,
                investmentAmount: rawAmt.isFinite ? rawAmt : 0,
                startDate: entry.startDate,
                mode: entry.mode == .sip ? .sip : .lumpsum,
                schemeCode: entry.schemeCode,
                isin: entry.isin,
                symbol: entry.symbol,
                quantity: Double(entry.quantity),
                livePrice: entry.livePrice
            )
            
            // Map transaction history
            inv.installments = entry.transactions.map { tx in
                AstraInvestmentTransaction(
                    id: tx.id,
                    date: tx.date,
                    type: tx.type.lowercased() == "sell" ? .sell : .buy,
                    amount: tx.amount,
                    nav: tx.nav,
                    units: tx.units
                )
            }
            return inv
        }
        
        let profileLoans = assessmentData.loanEntries.map { entry in
            let rawAmt  = Double(entry.amount)       ?? 0
            let rawRate = Double(entry.interestRate) ?? 0
            // The assessment field is labelled "Tenure (Months)" — store as-is.
            // Do NOT multiply by 12; that would turn 15 months into 180 months.
            let tenureMonths = Int(entry.tenure) ?? 0
            
            var loan = AstraLoan(
                loanType: mapLoanType(entry.type),
                lender: .other,
                loanAmount: rawAmt.isFinite  ? rawAmt  : 0,
                interestRate: rawRate.isFinite ? rawRate : 0,
                interestType: entry.interestType,
                compoundingFrequency: entry.frequency,
                loanStartDate: entry.startDate,
                loanTenureMonths: tenureMonths
            )
            // Preserve the custom name the user typed (e.g. "My Car Loan").
            // Falls back to loanType.rawValue in the UI via displayName.
            loan.loanName = entry.loanName.trimmingCharacters(in: .whitespacesAndNewlines)
            loan.insurancePremium = Double(entry.insurancePremium) ?? 0
            loan.moratoriumMonths = Int(entry.moratorium) ?? 0
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
            otherInvestmentAmount: profileInvestments.filter { [.cryptocurrency, .other, .nps, .ppf, .bonds, .cashSavings, .emergencyFund].contains($0.investmentType) }.map { $0.investmentAmount }.reduce(0, +),
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
        
        let savingsRate = incomeAfterTaxValue > 0 ? (((incomeAfterTaxValue - expensesValue) / incomeAfterTaxValue) * 100).safeFinite : 0
        
        let totalEMIs = profileLoans.reduce(0.0) { $0 + $1.calculatedEMI }
        let dti = incomeValue > 0 ? (totalEMIs / incomeValue).safeFinite : 0
        
        let efMonths = expensesValue > 0 ? (emergencyValue / expensesValue).safeFinite : 0
        let investmentScore = min(100, max(0, (savingsRate * 0.5) + (efMonths * 10))).safeInt
        
        let report = AstraFinancialHealthReport(
            netWorth: netWorth,
            savingsRate: savingsRate,
            debtToIncomeRatio: dti,
            investmentScore: investmentScore,
            emergencyFundMonths: efMonths
        )
        
        let initialScore = report.investmentScore
        let status = initialScore >= 80 ? "Excellent" : initialScore >= 70 ? "Good" : "Needs Work"
        let firstAssessment = AstraHealthAssessment(
            date: Date(),
            score: initialScore,
            status: status,
            keyInsights: ["First assessment generated from initial data",
                          "Emergency fund covers \(String(format: "%.1f", efMonths)) months",
                          "Savings rate stands at \(savingsRate.safeInt)%"]
        )
        
        let newInvestments = profileInvestments
        let newLoans = profileLoans
        let newInsurances = profileInsurances
        
        if var existingProfile = self.currentProfile {
            // MERGE LOGIC
            existingProfile.signUp.email = assessmentData.email.isEmpty
            ? existingProfile.signUp.email : assessmentData.email
            
            // Merge Investments
            for newInv in newInvestments {
                if !existingProfile.investments.contains(where: {
                    $0.investmentName.lowercased() == newInv.investmentName.lowercased() &&
                    abs($0.investmentAmount - newInv.investmentAmount) < 1.0
                }) {
                    existingProfile.investments.append(newInv)
                }
            }
            
            // Merge Loans
            for newLoan in newLoans {
                if !existingProfile.loans.contains(where: {
                    abs($0.loanAmount - newLoan.loanAmount) < 1.0 &&
                    $0.loanType == newLoan.loanType
                }) {
                    existingProfile.loans.append(newLoan)
                }
            }
            
            // Merge Insurances
            for newIns in newInsurances {
                if !existingProfile.insurances.contains(where: {
                    $0.policyNumber == newIns.policyNumber ||
                    ($0.insuranceType == newIns.insuranceType && abs($0.sumAssured - newIns.sumAssured) < 1.0)
                }) {
                    existingProfile.insurances.append(newIns)
                }
            }
            
            if !assessmentData.income.isEmpty {
                existingProfile.basicDetails.monthlyIncome = incomeValue
                existingProfile.basicDetails.monthlyIncomeAfterTax = incomeValue
            }
            if !assessmentData.expenditure.isEmpty {
                existingProfile.basicDetails.monthlyExpenses = expensesValue
            }
            if !assessmentData.emergencyFundAmount.isEmpty {
                existingProfile.basicDetails.emergencyFundAmount = emergencyValue
            }
            if !assessmentData.name.trimmingCharacters(in: .whitespaces).isEmpty {
                existingProfile.basicDetails.name = assessmentData.name
            }
            let parsedAge = Int(assessmentData.age.trimmingCharacters(in: .whitespaces)) ?? 0
            if parsedAge > 0 {
                existingProfile.basicDetails.age = parsedAge
            }
            existingProfile.basicDetails.gender = assessmentData.gender == .male ? .male : .female
            existingProfile.basicDetails.incomeType = assessmentData.incomeType == .fixed ? .fixed : .variable
            
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM"
            let monthKey = df.string(from: Date())
            
            var cf = existingProfile.cashflowData ?? CashflowEntry()
            if cf.incomeSources.isEmpty && incomeValue > 0 {
                cf.incomeSources = [.init(name: "Salary/Income", amount: incomeValue)]
            }
            if cf.expenseSources.isEmpty && expensesValue > 0 {
                cf.expenseSources = [.init(name: "Total Expenses", amount: expensesValue)]
            }
            existingProfile.cashflowData = cf
            existingProfile.monthlyCashflowSnapshots[monthKey] = cf
            
            self.currentProfile = existingProfile
        } else {
            // NEW PROFILE
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM"
            let monthKey = df.string(from: Date())
            
            var cf = CashflowEntry()
            if incomeValue > 0 {
                cf.incomeSources = [.init(name: "Salary/Income", amount: incomeValue)]
            }
            if expensesValue > 0 {
                cf.expenseSources = [.init(name: "Total Expenses", amount: expensesValue)]
            }
            
            var newProfile = AstraUserProfile(
                signUp: signUp,
                basicDetails: basic,
                assets: assets,
                liabilities: liabilities,
                investments: profileInvestments,
                loans: profileLoans,
                insurances: profileInsurances,
                goals: [],
                financialHealthReport: report,
                cashflowData: cf,
                monthlyHealthAssessments: [firstAssessment],
                isSetuConnected: false
            )
            newProfile.monthlyCashflowSnapshots[monthKey] = cf
            self.currentProfile = newProfile
        }
        
        recalculateFinancials() // Ensure all scores are updated with merged data
        
        Task {
            await syncMutualFundNAVs()
        }
        Task {
            if let session = try? await supabase.auth.session,
               let profile = currentProfile {
                do {
                    try await SupabaseRepository.shared.syncFullProfile(profile, userId: session.user.id)
                    print("Supabase sync successful for user: \(session.user.id)")
                } catch {
                    print("Supabase sync failed: \(error)")
                }
            }
        }
    }
    func syncProfile() {
            guard let profile = currentProfile else { return }
            Task {
                if let session = try? await supabase.auth.session {
                    do {
                        try await SupabaseRepository.shared.syncFullProfile(profile, userId: session.user.id)
                        print("Supabase sync successful for user: \(session.user.id)")
                    } catch {
                        print("Supabase sync failed: \(error)")
                    }
                }
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
        private static func deriveRiskTolerance(savingsRate: Double, investmentCount: Int) -> AstraRiskTolerance {
            switch (savingsRate, investmentCount) {
            case (let s, let c) where s >= 0.35 && c >= 3: return .high
            case (let s, _)     where s >= 0.20:            return .medium
            default:                                         return .low
            }
        }
        private static func deriveInvestmentHorizon(age: Int, dependents: Int) -> AstraInvestmentHorizon {
            switch (age, dependents) {
            case (let a, _) where a < 35: return .longTerm
            case (let a, let d) where a < 50 && d <= 2: return .mediumTerm
            default: return .shortTerm
            }
        }
        func recalculateFinancials() {
            guard var profile = currentProfile else { return }
            
            var newAssets = profile.assets
            newAssets.stocksHoldingAmount = profile.investments.filter { $0.investmentType == .stocks }.map { $0.currentValue.safeFinite }.reduce(0, +)
            newAssets.mutualFundHoldingAmount = profile.investments.filter { $0.investmentType == .mutualFund }.map { $0.currentValue.safeFinite }.reduce(0, +)
            newAssets.depositsAmount = profile.investments.filter { $0.investmentType == .deposits }.map { $0.currentValue.safeFinite }.reduce(0, +)
            newAssets.propertyAmount = profile.investments.filter { $0.investmentType == .realEstate }.map { $0.currentValue.safeFinite }.reduce(0, +)
            newAssets.jewelleryAmount = profile.investments.filter { $0.investmentType == .physicalGold }.map { $0.currentValue.safeFinite }.reduce(0, +)
            newAssets.otherInvestmentAmount = profile.investments.filter { [.cryptocurrency, .other, .nps, .ppf, .bonds, .cashSavings, .emergencyFund].contains($0.investmentType) }.map { $0.currentValue.safeFinite }.reduce(0, +)
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
            let savingsRate = incomeAfterTax > 0 ? (((incomeAfterTax - expenses) / incomeAfterTax) * 100).safeFinite : 0
            
            let totalEMIs = profile.loans.reduce(0.0) { $0 + $1.calculatedEMI }
            let dti = profile.basicDetails.monthlyIncome > 0 ? (totalEMIs / profile.basicDetails.monthlyIncome).safeFinite : 0
            
            let efTarget = profile.basicDetails.monthlyIncome * 6.0
            let efMonths = efTarget > 0 ? ((profile.basicDetails.emergencyFundAmount / efTarget) * 6.0).safeFinite : 0
            let investmentScore = min(100, max(0, (savingsRate * 0.5) + (efMonths * 10))).safeInt
            
            profile.financialHealthReport = AstraFinancialHealthReport(
                netWorth: netWorth,
                savingsRate: savingsRate,
                debtToIncomeRatio: dti,
                investmentScore: investmentScore,
                emergencyFundMonths: efMonths
            )
            
            // Sync goal currentAmount with dynamic total
            for i in 0..<profile.goals.count {
                let gid = profile.goals[i].id
                let linked = profile.investments.filter { $0.associatedGoalID == gid }
                let linkedTotal = linked.reduce(0.0) { $0 + $1.currentValue }
                profile.goals[i].currentAmount = linkedTotal + profile.goals[i].manualSavingsContribution
            }
            
            self.currentProfile = profile
        }
}
