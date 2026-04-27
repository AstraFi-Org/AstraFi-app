import Supabase
import Foundation

@Observable @MainActor
final class SupabaseRepository {
    static let shared = SupabaseRepository()
    private let fmt = ISO8601DateFormatter()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Codable Row Types for Upsert

    private struct UserProfileRow: Encodable {
        let user_id: String
        let signUpName: String
        let name: String
        let age: Int
        let gender: String
        let maritalStatus: String
        let adultDependents: Int
        let childDependents: Int
        let incomeType: String
        let monthlyIncome: Double
        let monthlyIncomeAfterTax: Double
        let monthlyExpenses: Double
        let emergencyFundAmount: Double
        let activeInvestment: Bool
        let riskTolerance: String
        let investmentHorizon: String
        let isSetuConnected: Bool

        enum CodingKeys: String, CodingKey {
            case user_id
            case signUpName = "signUpName"
            case name, age, gender
            case maritalStatus = "maritalStatus"
            case adultDependents = "adultDependents"
            case childDependents = "childDependents"
            case incomeType = "incomeType"
            case monthlyIncome = "monthlyIncome"
            case monthlyIncomeAfterTax = "monthlyIncomeAfterTax"
            case monthlyExpenses = "monthlyExpenses"
            case emergencyFundAmount = "emergencyFundAmount"
            case activeInvestment = "activeInvestment"
            case riskTolerance = "riskTolerance"
            case investmentHorizon = "investmentHorizon"
            case isSetuConnected = "isSetuConnected"
        }
    }

    private struct AssetsRow: Encodable {
        let user_id: String
        let savingsAccountAmount: Double
        let currentAccountAmount: Double
        let stocksHoldingAmount: Double
        let mutualFundHoldingAmount: Double
        let otherInvestmentAmount: Double
        let propertyAmount: Double
        let vehiclesAmount: Double
        let depositsAmount: Double
        let jewelleryAmount: Double
        let luxuryBelongingsAmount: Double
        let otherAssetsAmount: Double

        enum CodingKeys: String, CodingKey {
            case user_id
            case savingsAccountAmount = "savingsAccountAmount"
            case currentAccountAmount = "currentAccountAmount"
            case stocksHoldingAmount = "stocksHoldingAmount"
            case mutualFundHoldingAmount = "mutualFundHoldingAmount"
            case otherInvestmentAmount = "otherInvestmentAmount"
            case propertyAmount = "propertyAmount"
            case vehiclesAmount = "vehiclesAmount"
            case depositsAmount = "depositsAmount"
            case jewelleryAmount = "jewelleryAmount"
            case luxuryBelongingsAmount = "luxuryBelongingsAmount"
            case otherAssetsAmount = "otherAssetsAmount"
        }
    }

    private struct LiabilitiesRow: Encodable {
        let user_id: String
        let homeLoanAmount: Double
        let vehicleLoanAmount: Double
        let creditCardBills: Double
        let educationLoanAmount: Double
        let otherLoanAmount: Double
        let otherDebtAmount: Double

        enum CodingKeys: String, CodingKey {
            case user_id
            case homeLoanAmount = "homeLoanAmount"
            case vehicleLoanAmount = "vehicleLoanAmount"
            case creditCardBills = "creditCardBills"
            case educationLoanAmount = "educationLoanAmount"
            case otherLoanAmount = "otherLoanAmount"
            case otherDebtAmount = "otherDebtAmount"
        }
    }

    private struct GoalRow: Encodable {
        let id: String
        let user_id: String
        let goalName: String
        let targetAmount: Double
        let currentAmount: Double
        let manualSavingsContribution: Double
        let startDate: String
        let targetDate: String

        enum CodingKeys: String, CodingKey {
            case id, user_id
            case goalName = "goalName"
            case targetAmount = "targetAmount"
            case currentAmount = "currentAmount"
            case manualSavingsContribution = "manualSavingsContribution"
            case startDate = "startDate"
            case targetDate = "targetDate"
        }
    }

    private struct InvestmentRow: Encodable {
        let id: String
        let user_id: String
        let associatedGoalID: String?
        let investmentType: String
        let subtype: String?
        let investmentName: String
        let investmentAmount: Double
        let mode: String
        let startDate: String
        let schemeCode: String?
        let isin: String?
        let lastNAV: Double?
        let units: Double?
        let purchaseNAV: Double?
        let symbol: String?
        let quantity: Double?
        let priceChange: Double?
        let priceChangePercentage: Double?
        let createdAt: String

        enum CodingKeys: String, CodingKey {
            case id, user_id, subtype, symbol, quantity, isin, units
            case associatedGoalID = "associatedGoalID"
            case investmentType = "investmentType"
            case investmentName = "investmentName"
            case investmentAmount = "investmentAmount"
            case mode, startDate = "startDate"
            case schemeCode = "schemeCode"
            case lastNAV = "lastNAV"
            case purchaseNAV = "purchaseNAV"
            case priceChange = "priceChange"
            case priceChangePercentage = "priceChangePercentage"
            case createdAt = "createdAt"
        }
    }

    private struct InvestmentTransactionRow: Encodable {
        let id: String
        let investment_id: String
        let user_id: String
        let date: String
        let type: String
        let amount: Double
        let nav: Double
        let units: Double
    }

    private struct LoanRow: Encodable {
        let id: String
        let user_id: String
        let loanName: String
        let loanType: String
        let lender: String
        let loanAmount: Double
        let interestRate: Double
        let interestType: String
        let compoundingFrequency: String
        let emiAmount: Double?
        let emiFrequency: String
        let loanStartDate: String
        let firstEMIDate: String?
        let loanTenureMonths: Int
        let installmentsPaid: Int
        let prepaymentPenaltyPercentage: Double
        let isFloatingRate: Bool
        let processingFee: Double
        let insurancePremium: Double
        let latePaymentPenalty: Double
        let otherCharges: Double
        let moratoriumMonths: Int
        let interestAccrualDuringMoratorium: Bool
        let trackTaxBenefits: Bool
        let interestRateHistory: String

        enum CodingKeys: String, CodingKey {
            case id, user_id, lender
            case loanName = "loanName"
            case loanType = "loanType"
            case loanAmount = "loanAmount"
            case interestRate = "interestRate"
            case interestType = "interestType"
            case compoundingFrequency = "compoundingFrequency"
            case emiAmount = "emiAmount"
            case emiFrequency = "emiFrequency"
            case loanStartDate = "loanStartDate"
            case firstEMIDate = "firstEMIDate"
            case loanTenureMonths = "loanTenureMonths"
            case installmentsPaid = "installmentsPaid"
            case prepaymentPenaltyPercentage = "prepaymentPenaltyPercentage"
            case isFloatingRate = "isFloatingRate"
            case processingFee = "processingFee"
            case insurancePremium = "insurancePremium"
            case latePaymentPenalty = "latePaymentPenalty"
            case otherCharges = "otherCharges"
            case moratoriumMonths = "moratoriumMonths"
            case interestAccrualDuringMoratorium = "interestAccrualDuringMoratorium"
            case trackTaxBenefits = "trackTaxBenefits"
            case interestRateHistory = "interestRateHistory"
        }
    }

    private struct LoanPaymentRow: Encodable {
        let id: String
        let loan_id: String
        let user_id: String
        let emiNumber: Int
        let date: String
        let amountPaid: Double
        let interestComponent: Double
        let principalComponent: Double
        let remainingBalance: Double
        let status: String
        let penalty: Double

        enum CodingKeys: String, CodingKey {
            case id, loan_id, user_id, date, status, penalty
            case emiNumber = "emiNumber"
            case amountPaid = "amountPaid"
            case interestComponent = "interestComponent"
            case principalComponent = "principalComponent"
            case remainingBalance = "remainingBalance"
        }
    }

    private struct LoanPrepaymentRow: Encodable {
        let id: String
        let loan_id: String
        let user_id: String
        let amount: Double
        let date: String
    }

    private struct InsuranceRow: Encodable {
        let id: String
        let user_id: String
        let insuranceType: String
        let provider: String
        let policyNumber: String
        let sumAssured: Double
        let annualPremium: Double
        let basePremium: Double
        let taxesGST: Double
        let addOnCost: Double
        let premiumFrequency: String
        let startDate: String
        let expiryDate: String?
        let surrenderValue: Double?
        let lockInPeriodMonths: Int?
        let maturityDate: String?
        let expectedMaturityAmount: Double?
        let lifeDetails: String?
        let healthDetails: String?
        let motorDetails: String?
        let riders: String

        enum CodingKeys: String, CodingKey {
            case id, user_id, provider, riders
            case insuranceType = "insuranceType"
            case policyNumber = "policyNumber"
            case sumAssured = "sumAssured"
            case annualPremium = "annualPremium"
            case basePremium = "basePremium"
            case taxesGST = "taxesGST"
            case addOnCost = "addOnCost"
            case premiumFrequency = "premiumFrequency"
            case startDate = "startDate"
            case expiryDate = "expiryDate"
            case surrenderValue = "surrenderValue"
            case lockInPeriodMonths = "lockInPeriodMonths"
            case maturityDate = "maturityDate"
            case expectedMaturityAmount = "expectedMaturityAmount"
            case lifeDetails = "lifeDetails"
            case healthDetails = "healthDetails"
            case motorDetails = "motorDetails"
        }
    }

    private struct InsuranceClaimRow: Encodable {
        let id: String
        let insurance_id: String
        let user_id: String
        let date: String
        let amount: Double
        let status: String
        let description: String?
    }

    private struct InsurancePaymentRow: Encodable {
        let id: String
        let insurance_id: String
        let user_id: String
        let date: String
        let amount: Double
        let status: String
    }

    private struct CashflowSnapshotRow: Encodable {
        let user_id: String
        let monthKey: String
        let rent: Double
        let groceries: Double
        let utilities: Double
        let dining: Double
        let transport: Double
        let shopping: Double
        let entertainment: Double
        let misc: Double
        let incomeSources: String
        let expenseSources: String

        enum CodingKeys: String, CodingKey {
            case user_id, rent, groceries, utilities, dining, transport, shopping, entertainment, misc
            case monthKey = "monthKey"
            case incomeSources = "incomeSources"
            case expenseSources = "expenseSources"
        }
    }

    private struct HealthAssessmentRow: Encodable {
        let id: String
        let user_id: String
        let date: String
        let score: Int
        let status: String
        let keyInsights: String
        let insights: String?

        enum CodingKeys: String, CodingKey {
            case id, user_id, date, score, status, insights
            case keyInsights = "keyInsights"
        }
    }

    private struct EmergencyFundRow: Encodable {
        let user_id: String
        let treasuryBills: Double
        let commercialPapers: Double
        let savingsAccount: Double
        let sweepInFD: Double
        let isAllocatedByUser: Bool

        enum CodingKeys: String, CodingKey {
            case user_id
            case treasuryBills = "treasuryBills"
            case commercialPapers = "commercialPapers"
            case savingsAccount = "savingsAccount"
            case sweepInFD = "sweepInFD"
            case isAllocatedByUser = "isAllocatedByUser"
        }
    }

    private struct SavedPlanRow: Encodable {
        let id: String
        let user_id: String
        let name: String
        let dateSaved: String
        let targetGoal: String
        let input: String
        let isFollowed: Bool

        enum CodingKeys: String, CodingKey {
            case id, user_id, name, input
            case dateSaved = "dateSaved"
            case targetGoal = "targetGoal"
            case isFollowed = "isFollowed"
        }
    }

    // MARK: - User Profile

    func saveUserProfile(_ profile: AstraUserProfile, userId: UUID) async throws {
        let uid = userId.uuidString

        try await supabase.from("user_profiles").upsert(UserProfileRow(
            user_id: uid,
            signUpName: profile.signUp.signUpName,
            name: profile.basicDetails.name,
            age: profile.basicDetails.age,
            gender: profile.basicDetails.gender.rawValue,
            maritalStatus: profile.basicDetails.maritalStatus.rawValue,
            adultDependents: profile.basicDetails.adultDependents,
            childDependents: profile.basicDetails.childDependents,
            incomeType: profile.basicDetails.incomeType.rawValue,
            monthlyIncome: profile.basicDetails.monthlyIncome,
            monthlyIncomeAfterTax: profile.basicDetails.monthlyIncomeAfterTax,
            monthlyExpenses: profile.basicDetails.monthlyExpenses,
            emergencyFundAmount: profile.basicDetails.emergencyFundAmount,
            activeInvestment: profile.basicDetails.activeInvestment,
            riskTolerance: profile.basicDetails.riskTolerance.rawValue,
            investmentHorizon: profile.basicDetails.investmentHorizon.rawValue,
            isSetuConnected: profile.isSetuConnected
        )).execute()

        try await supabase.from("assets").upsert(AssetsRow(
            user_id: uid,
            savingsAccountAmount: profile.assets.savingsAccountAmount,
            currentAccountAmount: profile.assets.currentAccountAmount,
            stocksHoldingAmount: profile.assets.stocksHoldingAmount,
            mutualFundHoldingAmount: profile.assets.mutualFundHoldingAmount,
            otherInvestmentAmount: profile.assets.otherInvestmentAmount,
            propertyAmount: profile.assets.propertyAmount,
            vehiclesAmount: profile.assets.vehiclesAmount,
            depositsAmount: profile.assets.depositsAmount,
            jewelleryAmount: profile.assets.jewelleryAmount,
            luxuryBelongingsAmount: profile.assets.luxuryBelongingsAmount,
            otherAssetsAmount: profile.assets.otherAssetsAmount
        )).execute()

        try await supabase.from("liabilities").upsert(LiabilitiesRow(
            user_id: uid,
            homeLoanAmount: profile.liabilities.homeLoanAmount,
            vehicleLoanAmount: profile.liabilities.vehicleLoanAmount,
            creditCardBills: profile.liabilities.creditCardBills,
            educationLoanAmount: profile.liabilities.educationLoanAmount,
            otherLoanAmount: profile.liabilities.otherLoanAmount,
            otherDebtAmount: profile.liabilities.otherDebtAmount
        )).execute()
    }

    // MARK: - Goals

    func saveGoal(_ goal: AstraGoal, userId: UUID) async throws {
        try await supabase.from("goals").upsert(GoalRow(
            id: goal.id.uuidString,
            user_id: userId.uuidString,
            goalName: goal.goalName,
            targetAmount: goal.targetAmount,
            currentAmount: goal.currentAmount,
            manualSavingsContribution: goal.manualSavingsContribution,
            startDate: fmt.string(from: goal.startDate),
            targetDate: fmt.string(from: goal.targetDate)
        )).execute()
    }

    func fetchGoals(userId: UUID) async throws -> [AstraGoal] {
        struct FetchRow: Decodable {
            let id: UUID
            let goalName: String
            let targetAmount: Double
            let currentAmount: Double
            let manualSavingsContribution: Double
            let startDate: String
            let targetDate: String
        }
        let rows: [FetchRow] = try await supabase
            .from("goals").select()
            .eq("user_id", value: userId.uuidString)
            .execute().value

        return rows.map { row in
            AstraGoal(
                id: row.id,
                goalName: row.goalName,
                targetAmount: row.targetAmount,
                currentAmount: row.currentAmount,
                manualSavingsContribution: row.manualSavingsContribution,
                startDate: fmt.date(from: row.startDate) ?? Date(),
                targetDate: fmt.date(from: row.targetDate) ?? Date()
            )
        }
    }

    func deleteGoal(_ goalId: UUID) async throws {
        try await supabase.from("goals")
            .delete().eq("id", value: goalId.uuidString).execute()
    }

    // MARK: - Investments

    func saveInvestment(_ inv: AstraInvestment, userId: UUID) async throws {
        try await supabase.from("investments").upsert(InvestmentRow(
            id: inv.id.uuidString,
            user_id: userId.uuidString,
            associatedGoalID: inv.associatedGoalID?.uuidString,
            investmentType: inv.investmentType.rawValue,
            subtype: inv.subtype?.rawValue,
            investmentName: inv.investmentName,
            investmentAmount: inv.investmentAmount,
            mode: inv.mode.rawValue,
            startDate: fmt.string(from: inv.startDate),
            schemeCode: inv.schemeCode,
            isin: inv.isin,
            lastNAV: inv.lastNAV,
            units: inv.units,
            purchaseNAV: inv.purchaseNAV,
            symbol: inv.symbol,
            quantity: inv.quantity,
            priceChange: inv.priceChange,
            priceChangePercentage: inv.priceChangePercentage,
            createdAt: fmt.string(from: inv.createdAt)
        )).execute()

        for tx in inv.installments {
            try await supabase.from("investment_transactions").upsert(InvestmentTransactionRow(
                id: tx.id.uuidString,
                investment_id: inv.id.uuidString,
                user_id: userId.uuidString,
                date: fmt.string(from: tx.date),
                type: tx.type.rawValue,
                amount: tx.amount,
                nav: tx.nav,
                units: tx.units
            )).execute()
        }
    }

    func fetchInvestments(userId: UUID) async throws -> [AstraInvestment] {
        struct InvRow: Decodable {
            let id: UUID
            let associatedGoalID: UUID?
            let investmentType: String
            let subtype: String?
            let investmentName: String
            let investmentAmount: Double
            let mode: String
            let startDate: String
            let schemeCode: String?
            let isin: String?
            let lastNAV: Double?
            let units: Double?
            let purchaseNAV: Double?
            let symbol: String?
            let quantity: Double?
            let priceChange: Double?
            let priceChangePercentage: Double?
            let createdAt: String
        }
        struct TxRow: Decodable {
            let id: UUID
            let investment_id: UUID
            let date: String
            let type: String
            let amount: Double
            let nav: Double
            let units: Double
        }

        let invRows: [InvRow] = try await supabase
            .from("investments").select()
            .eq("user_id", value: userId.uuidString)
            .execute().value

        let txRows: [TxRow] = try await supabase
            .from("investment_transactions").select()
            .eq("user_id", value: userId.uuidString)
            .execute().value

        return invRows.map { row in
            let txs = txRows.filter { $0.investment_id == row.id }.map { tx in
                AstraInvestmentTransaction(
                    id: tx.id,
                    date: fmt.date(from: tx.date) ?? Date(),
                    type: tx.type == "Sell" ? .sell : .buy,
                    amount: tx.amount,
                    nav: tx.nav,
                    units: tx.units
                )
            }
            var inv = AstraInvestment(
                id: row.id,
                investmentType: AstraInvestmentType(rawValue: row.investmentType) ?? .other,
                subtype: row.subtype.flatMap { AstraInvestmentSubtype(rawValue: $0) },
                investmentName: row.investmentName,
                investmentAmount: row.investmentAmount,
                startDate: fmt.date(from: row.startDate) ?? Date(),
                associatedGoalID: row.associatedGoalID,
                mode: AstraInvestmentMode(rawValue: row.mode) ?? .lumpsum,
                schemeCode: row.schemeCode,
                isin: row.isin,
                units: row.units,
                purchaseNAV: row.purchaseNAV,
                symbol: row.symbol,
                quantity: row.quantity,
                priceChange: row.priceChange,
                priceChangePercentage: row.priceChangePercentage,
                createdAt: fmt.date(from: row.createdAt) ?? Date()
            )
            inv.lastNAV = row.lastNAV
            inv.installments = txs
            return inv
        }
    }

    func deleteInvestment(_ investmentId: UUID) async throws {
        try await supabase.from("investments")
            .delete().eq("id", value: investmentId.uuidString).execute()
    }

    // MARK: - Loans

    func saveLoan(_ loan: AstraLoan, userId: UUID) async throws {
        let rateHistoryJSON = (try? String(data: encoder.encode(loan.interestRateHistory), encoding: .utf8)) ?? "[]"

        try await supabase.from("loans").upsert(LoanRow(
            id: loan.id.uuidString,
            user_id: userId.uuidString,
            loanName: loan.loanName,
            loanType: loan.loanType.rawValue,
            lender: loan.lender.rawValue,
            loanAmount: loan.loanAmount,
            interestRate: loan.interestRate,
            interestType: loan.interestType.rawValue,
            compoundingFrequency: loan.compoundingFrequency.rawValue,
            emiAmount: loan.emiAmount,
            emiFrequency: loan.emiFrequency.rawValue,
            loanStartDate: fmt.string(from: loan.loanStartDate),
            firstEMIDate: loan.firstEMIDate.map { fmt.string(from: $0) },
            loanTenureMonths: loan.loanTenureMonths,
            installmentsPaid: loan.installmentsPaid,
            prepaymentPenaltyPercentage: loan.prepaymentPenaltyPercentage,
            isFloatingRate: loan.isFloatingRate,
            processingFee: loan.processingFee,
            insurancePremium: loan.insurancePremium,
            latePaymentPenalty: loan.latePaymentPenalty,
            otherCharges: loan.otherCharges,
            moratoriumMonths: loan.moratoriumMonths,
            interestAccrualDuringMoratorium: loan.interestAccrualDuringMoratorium,
            trackTaxBenefits: loan.trackTaxBenefits,
            interestRateHistory: rateHistoryJSON
        )).execute()

        for payment in loan.payments {
            try await supabase.from("loan_payments").upsert(LoanPaymentRow(
                id: payment.id.uuidString,
                loan_id: loan.id.uuidString,
                user_id: userId.uuidString,
                emiNumber: payment.emiNumber,
                date: fmt.string(from: payment.date),
                amountPaid: payment.amountPaid,
                interestComponent: payment.interestComponent,
                principalComponent: payment.principalComponent,
                remainingBalance: payment.remainingBalance,
                status: payment.status.rawValue,
                penalty: payment.penalty
            )).execute()
        }

        for prepayment in loan.prepayments {
            try await supabase.from("loan_prepayments").upsert(LoanPrepaymentRow(
                id: prepayment.id.uuidString,
                loan_id: loan.id.uuidString,
                user_id: userId.uuidString,
                amount: prepayment.amount,
                date: fmt.string(from: prepayment.date)
            )).execute()
        }
    }

    func fetchLoans(userId: UUID) async throws -> [AstraLoan] {
        struct LoanFetchRow: Decodable {
            let id: UUID
            let loanName: String
            let loanType: String
            let lender: String
            let loanAmount: Double
            let interestRate: Double
            let interestType: String
            let compoundingFrequency: String
            let emiAmount: Double?
            let emiFrequency: String
            let loanStartDate: String
            let firstEMIDate: String?
            let loanTenureMonths: Int
            let installmentsPaid: Int
            let prepaymentPenaltyPercentage: Double
            let isFloatingRate: Bool
            let processingFee: Double
            let insurancePremium: Double
            let latePaymentPenalty: Double
            let otherCharges: Double
            let moratoriumMonths: Int
            let interestAccrualDuringMoratorium: Bool
            let trackTaxBenefits: Bool
            let interestRateHistory: String?
        }
        struct PaymentFetchRow: Decodable {
            let id: UUID; let loan_id: UUID
            let emiNumber: Int; let date: String
            let amountPaid: Double; let interestComponent: Double
            let principalComponent: Double; let remainingBalance: Double
            let status: String; let penalty: Double
        }
        struct PrepayFetchRow: Decodable {
            let id: UUID; let loan_id: UUID
            let amount: Double; let date: String
        }

        let loanRows: [LoanFetchRow] = try await supabase
            .from("loans").select()
            .eq("user_id", value: userId.uuidString).execute().value
        let payRows: [PaymentFetchRow] = try await supabase
            .from("loan_payments").select()
            .eq("user_id", value: userId.uuidString).execute().value
        let prepRows: [PrepayFetchRow] = try await supabase
            .from("loan_prepayments").select()
            .eq("user_id", value: userId.uuidString).execute().value

        return loanRows.map { row in
            let payments = payRows.filter { $0.loan_id == row.id }.map { p in
                AstraLoanPayment(id: p.id, emiNumber: p.emiNumber,
                    date: fmt.date(from: p.date) ?? Date(),
                    amountPaid: p.amountPaid, interestComponent: p.interestComponent,
                    principalComponent: p.principalComponent, remainingBalance: p.remainingBalance,
                    status: AstraPaymentStatus(rawValue: p.status) ?? .pending, penalty: p.penalty)
            }
            let prepayments = prepRows.filter { $0.loan_id == row.id }.map { p in
                AstraPrepayment(id: p.id, amount: p.amount, date: fmt.date(from: p.date) ?? Date())
            }
            let rateHistory: [AstraRateChange] = row.interestRateHistory
                .flatMap { try? decoder.decode([AstraRateChange].self, from: Data($0.utf8)) } ?? []

            var loan = AstraLoan(
                id: row.id,
                loanType: AstraLoanType(rawValue: row.loanType) ?? .other,
                lender: AstraLoanLender(rawValue: row.lender) ?? .other,
                loanAmount: row.loanAmount, interestRate: row.interestRate,
                interestType: AstraInterestType(rawValue: row.interestType) ?? .compound,
                compoundingFrequency: AstraCompoundingFrequency(rawValue: row.compoundingFrequency) ?? .monthly,
                loanStartDate: fmt.date(from: row.loanStartDate) ?? Date(),
                loanTenureMonths: row.loanTenureMonths
            )
            loan.loanName = row.loanName
            loan.emiAmount = row.emiAmount
            loan.emiFrequency = AstraEMIFrequency(rawValue: row.emiFrequency) ?? .monthly
            loan.firstEMIDate = row.firstEMIDate.flatMap { fmt.date(from: $0) }
            loan.installmentsPaid = row.installmentsPaid
            loan.prepaymentPenaltyPercentage = row.prepaymentPenaltyPercentage
            loan.isFloatingRate = row.isFloatingRate
            loan.processingFee = row.processingFee
            loan.insurancePremium = row.insurancePremium
            loan.latePaymentPenalty = row.latePaymentPenalty
            loan.otherCharges = row.otherCharges
            loan.moratoriumMonths = row.moratoriumMonths
            loan.interestAccrualDuringMoratorium = row.interestAccrualDuringMoratorium
            loan.trackTaxBenefits = row.trackTaxBenefits
            loan.interestRateHistory = rateHistory
            loan.payments = payments
            loan.prepayments = prepayments
            return loan
        }
    }

    func deleteLoan(_ loanId: UUID) async throws {
        try await supabase.from("loans")
            .delete().eq("id", value: loanId.uuidString).execute()
    }
 

    // MARK: - Insurance

    func saveInsurance(_ ins: AstraInsurance, userId: UUID) async throws {
        let lifeJSON   = ins.lifeDetails.flatMap   { try? String(data: encoder.encode($0), encoding: .utf8) }
        let healthJSON = ins.healthDetails.flatMap  { try? String(data: encoder.encode($0), encoding: .utf8) }
        let motorJSON  = ins.motorDetails.flatMap   { try? String(data: encoder.encode($0), encoding: .utf8) }
        let ridersJSON = (try? String(data: encoder.encode(ins.riders), encoding: .utf8)) ?? "[]"

        try await supabase.from("insurances").upsert(InsuranceRow(
            id: ins.id.uuidString,
            user_id: userId.uuidString,
            insuranceType: ins.insuranceType.rawValue,
            provider: ins.provider,
            policyNumber: ins.policyNumber,
            sumAssured: ins.sumAssured,
            annualPremium: ins.annualPremium,
            basePremium: ins.basePremium,
            taxesGST: ins.taxesGST,
            addOnCost: ins.addOnCost,
            premiumFrequency: ins.premiumFrequency.rawValue,
            startDate: fmt.string(from: ins.startDate),
            expiryDate: ins.expiryDate.map { fmt.string(from: $0) },
            surrenderValue: ins.surrenderValue,
            lockInPeriodMonths: ins.lockInPeriodMonths,
            maturityDate: ins.maturityDate.map { fmt.string(from: $0) },
            expectedMaturityAmount: ins.expectedMaturityAmount,
            lifeDetails: lifeJSON,
            healthDetails: healthJSON,
            motorDetails: motorJSON,
            riders: ridersJSON
        )).execute()

        for claim in ins.claims {
            try await supabase.from("insurance_claims").upsert(InsuranceClaimRow(
                id: claim.id.uuidString,
                insurance_id: ins.id.uuidString,
                user_id: userId.uuidString,
                date: fmt.string(from: claim.date),
                amount: claim.amount,
                status: claim.status.rawValue,
                description: claim.description
            )).execute()
        }

        for payment in ins.payments {
            try await supabase.from("insurance_payments").upsert(InsurancePaymentRow(
                id: payment.id.uuidString,
                insurance_id: ins.id.uuidString,
                user_id: userId.uuidString,
                date: fmt.string(from: payment.date),
                amount: payment.amount,
                status: payment.status.rawValue
            )).execute()
        }
        
    }
    func deleteInsurance(_ insuranceId: UUID) async throws {
        try await supabase.from("insurances")
            .delete().eq("id", value: insuranceId.uuidString).execute()
    }

    func fetchInsurances(userId: UUID) async throws -> [AstraInsurance] {
        struct InsFetchRow: Decodable {
            let id: UUID; let insuranceType: String; let provider: String
            let policyNumber: String; let sumAssured: Double; let annualPremium: Double
            let basePremium: Double; let taxesGST: Double; let addOnCost: Double
            let premiumFrequency: String; let startDate: String; let expiryDate: String?
            let surrenderValue: Double?; let lockInPeriodMonths: Int?
            let maturityDate: String?; let expectedMaturityAmount: Double?
            let lifeDetails: String?; let healthDetails: String?
            let motorDetails: String?; let riders: String?
        }
        struct ClaimFetchRow: Decodable {
            let id: UUID; let insurance_id: UUID; let date: String
            let amount: Double; let status: String; let description: String?
        }
        struct PayFetchRow: Decodable {
            let id: UUID; let insurance_id: UUID
            let date: String; let amount: Double; let status: String
        }

        let insRows: [InsFetchRow] = try await supabase
            .from("insurances").select()
            .eq("user_id", value: userId.uuidString).execute().value
        let claimRows: [ClaimFetchRow] = try await supabase
            .from("insurance_claims").select()
            .eq("user_id", value: userId.uuidString).execute().value
        let payRows: [PayFetchRow] = try await supabase
            .from("insurance_payments").select()
            .eq("user_id", value: userId.uuidString).execute().value

        return insRows.map { row in
            let claims = claimRows.filter { $0.insurance_id == row.id }.map { c in
                AstraClaim(id: c.id, date: fmt.date(from: c.date) ?? Date(),
                    amount: c.amount, status: AstraClaimStatus(rawValue: c.status) ?? .pending,
                    description: c.description)
            }
            let payments = payRows.filter { $0.insurance_id == row.id }.map { p in
                AstraInsurancePayment(id: p.id, date: fmt.date(from: p.date) ?? Date(),
                    amount: p.amount, status: AstraPaymentStatus(rawValue: p.status) ?? .pending)
            }
            var ins = AstraInsurance(
                id: row.id,
                insuranceType: AstraInsuranceType(rawValue: row.insuranceType) ?? .other,
                provider: row.provider, policyNumber: row.policyNumber,
                sumAssured: row.sumAssured, annualPremium: row.annualPremium,
                startDate: fmt.date(from: row.startDate) ?? Date(),
                expiryDate: row.expiryDate.flatMap { fmt.date(from: $0) }
            )
            ins.basePremium = row.basePremium
            ins.taxesGST = row.taxesGST
            ins.addOnCost = row.addOnCost
            ins.premiumFrequency = AstraPremiumFrequency(rawValue: row.premiumFrequency) ?? .yearly
            ins.surrenderValue = row.surrenderValue
            ins.lockInPeriodMonths = row.lockInPeriodMonths
            ins.maturityDate = row.maturityDate.flatMap { fmt.date(from: $0) }
            ins.expectedMaturityAmount = row.expectedMaturityAmount
            ins.lifeDetails   = row.lifeDetails.flatMap   { try? decoder.decode(AstraLifeInsuranceDetails.self,   from: Data($0.utf8)) }
            ins.healthDetails = row.healthDetails.flatMap { try? decoder.decode(AstraHealthInsuranceDetails.self, from: Data($0.utf8)) }
            ins.motorDetails  = row.motorDetails.flatMap  { try? decoder.decode(AstraMotorInsuranceDetails.self,  from: Data($0.utf8)) }
            ins.riders   = row.riders.flatMap { try? decoder.decode([AstraRider].self, from: Data($0.utf8)) } ?? []
            ins.claims   = claims
            ins.payments = payments
            return ins
        }
    }

//    func deleteInsurance(_ insuranceId: UUID) async throws {
//        try await supabase.from("insurances")
//            .delete().eq("id", value: insuranceId.uuidString).execute()
//    }
    func updatePlanFollowStatus(planId: UUID, isFollowed: Bool) async throws {
        try await supabase.from("saved_plans")
            .update(["isFollowed": isFollowed])
            .eq("id", value: planId.uuidString)
            .execute()
    }
    
    func fetchSavedPlans(userId: UUID) async throws -> [InvestmentPlanModel] {
        struct PlanFetchRow: Decodable {
            let id: UUID
            let name: String?
            let dateSaved: String?
            let targetGoal: String?
            let input: String?
            let isFollowed: Bool?
        }

        let rows: [PlanFetchRow] = try await supabase
            .from("saved_plans").select()
            .eq("user_id", value: userId.uuidString)
            .execute().value

        return rows.compactMap { row in
            guard
                let inputJSON = row.input,
                let inputData = inputJSON.data(using: .utf8),
                let input = try? JSONDecoder().decode(InvestmentPlanInputModel.self, from: inputData)
            else { return nil }

            var plan = InvestmentPlanModel(
                name: row.name ?? "",
                dateSaved: row.dateSaved ?? "",
                targetGoal: row.targetGoal ?? "",
                input: input,
                isFollowed: row.isFollowed ?? false
            )
            plan.id = row.id
            return plan
        }
    }

    // MARK: - Cashflow Snapshots

    func saveCashflowSnapshot(_ entry: CashflowEntry, monthKey: String, userId: UUID) async throws {
        let incomeJSON  = (try? String(data: encoder.encode(entry.incomeSources),  encoding: .utf8)) ?? "[]"
        let expenseJSON = (try? String(data: encoder.encode(entry.expenseSources), encoding: .utf8)) ?? "[]"

        try await supabase.from("cashflow_snapshots").upsert(CashflowSnapshotRow(
            user_id: userId.uuidString, monthKey: monthKey,
            rent: entry.rent, groceries: entry.groceries, utilities: entry.utilities,
            dining: entry.dining, transport: entry.transport, shopping: entry.shopping,
            entertainment: entry.entertainment, misc: entry.misc,
            incomeSources: incomeJSON, expenseSources: expenseJSON
        )).execute()
    }

    func fetchCashflowSnapshots(userId: UUID) async throws -> [String: CashflowEntry] {
        struct SnapFetchRow: Decodable {
            let monthKey: String; let rent: Double; let groceries: Double
            let utilities: Double; let dining: Double; let transport: Double
            let shopping: Double; let entertainment: Double; let misc: Double
            let incomeSources: String?; let expenseSources: String?
        }
        let rows: [SnapFetchRow] = try await supabase
            .from("cashflow_snapshots").select()
            .eq("user_id", value: userId.uuidString).execute().value

        var result: [String: CashflowEntry] = [:]
        for row in rows {
            var entry = CashflowEntry(rent: row.rent, groceries: row.groceries,
                utilities: row.utilities, dining: row.dining, transport: row.transport,
                shopping: row.shopping, entertainment: row.entertainment, misc: row.misc)
            entry.incomeSources  = row.incomeSources.flatMap  { try? decoder.decode([CashflowEntry.DetailedItem].self, from: Data($0.utf8)) } ?? []
            entry.expenseSources = row.expenseSources.flatMap { try? decoder.decode([CashflowEntry.DetailedItem].self, from: Data($0.utf8)) } ?? []
            result[row.monthKey] = entry
        }
        return result
    }

    // MARK: - Health Assessments

    func saveHealthAssessment(_ assessment: AstraHealthAssessment, userId: UUID) async throws {
        let insightsJSON    = assessment.insights.flatMap { try? String(data: encoder.encode($0), encoding: .utf8) }
        let keyInsightsJSON = (try? String(data: encoder.encode(assessment.keyInsights), encoding: .utf8)) ?? "[]"

        try await supabase.from("health_assessments").upsert(HealthAssessmentRow(
            id: assessment.id.uuidString,
            user_id: userId.uuidString,
            date: fmt.string(from: assessment.date),
            score: assessment.score,
            status: assessment.status,
            keyInsights: keyInsightsJSON,
            insights: insightsJSON
        )).execute()
    }

    func fetchHealthAssessments(userId: UUID) async throws -> [AstraHealthAssessment] {
        struct AssessFetchRow: Decodable {
            let id: UUID; let date: String; let score: Int
            let status: String; let keyInsights: String?; let insights: String?
        }
        let rows: [AssessFetchRow] = try await supabase
            .from("health_assessments").select()
            .eq("user_id", value: userId.uuidString).execute().value

        return rows.map { row in
            AstraHealthAssessment(
                id: row.id, date: fmt.date(from: row.date) ?? Date(),
                score: row.score, status: row.status,
                keyInsights: row.keyInsights.flatMap { try? decoder.decode([String].self, from: Data($0.utf8)) } ?? [],
                insights: row.insights.flatMap { try? decoder.decode(FinancialAssessmentInsights.self, from: Data($0.utf8)) }
            )
        }
    }

    // MARK: - Emergency Fund Allocation

    func saveEmergencyFundAllocation(_ allocation: AstraEmergencyFundAllocation, userId: UUID) async throws {
        try await supabase.from("emergency_fund_allocations").upsert(EmergencyFundRow(
            user_id: userId.uuidString,
            treasuryBills: allocation.treasuryBills,
            commercialPapers: allocation.commercialPapers,
            savingsAccount: allocation.savingsAccount,
            sweepInFD: allocation.sweepInFD,
            isAllocatedByUser: allocation.isAllocatedByUser
        )).execute()
    }

    // MARK: - Saved Plans

    func savePlan(_ plan: InvestmentPlanModel, userId: UUID) async throws {
        let inputJSON = (try? String(data: encoder.encode(plan.input), encoding: .utf8)) ?? "{}"
        try await supabase.from("saved_plans").upsert(SavedPlanRow(
            id: plan.id.uuidString,
            user_id: userId.uuidString,
            name: plan.name,
            dateSaved: fmt.string(from: Date()),
            targetGoal: plan.targetGoal,
            input: inputJSON,
            isFollowed: false
        )).execute()
    }

    // MARK: - Full Sync

    func syncFullProfile(_ profile: AstraUserProfile, userId: UUID) async throws {
        try await saveUserProfile(profile, userId: userId)
        for goal in profile.goals { try await saveGoal(goal, userId: userId) }
        for inv  in profile.investments { try await saveInvestment(inv, userId: userId) }
        for loan in profile.loans { try await saveLoan(loan, userId: userId) }
        for ins  in profile.insurances { try await saveInsurance(ins, userId: userId) }
        for (key, entry) in profile.monthlyCashflowSnapshots {
            try await saveCashflowSnapshot(entry, monthKey: key, userId: userId)
        }
        for assessment in profile.monthlyHealthAssessments {
            try await saveHealthAssessment(assessment, userId: userId)
        }
        if let allocation = profile.emergencyFundAllocation {
            try await saveEmergencyFundAllocation(allocation, userId: userId)
        }
    }

    func fetchFullProfile(userId: UUID) async throws -> AstraUserProfile? {
        struct ProfileFetchRow: Decodable {
            let signUpName: String?; let name: String?; let age: Int?
            let gender: String?; let maritalStatus: String?
            let adultDependents: Int?; let childDependents: Int?
            let incomeType: String?; let monthlyIncome: Double?
            let monthlyIncomeAfterTax: Double?; let monthlyExpenses: Double?
            let emergencyFundAmount: Double?; let activeInvestment: Bool?
            let riskTolerance: String?; let investmentHorizon: String?
            let isSetuConnected: Bool?
        }
        struct AssetsFetchRow: Decodable {
            let savingsAccountAmount: Double?; let currentAccountAmount: Double?
            let stocksHoldingAmount: Double?; let mutualFundHoldingAmount: Double?
            let otherInvestmentAmount: Double?; let propertyAmount: Double?
            let vehiclesAmount: Double?; let depositsAmount: Double?
            let jewelleryAmount: Double?; let luxuryBelongingsAmount: Double?
            let otherAssetsAmount: Double?
        }
        struct LiabilitiesFetchRow: Decodable {
            let homeLoanAmount: Double?; let vehicleLoanAmount: Double?
            let creditCardBills: Double?; let educationLoanAmount: Double?
            let otherLoanAmount: Double?; let otherDebtAmount: Double?
        }

        guard let profileRow: ProfileFetchRow = try? await supabase
            .from("user_profiles").select()
            .eq("user_id", value: userId.uuidString)
            .single().execute().value
        else { return nil }

        let assetsRow: AssetsFetchRow?      = try? await supabase.from("assets").select().eq("user_id", value: userId.uuidString).single().execute().value
        let liabilitiesRow: LiabilitiesFetchRow? = try? await supabase.from("liabilities").select().eq("user_id", value: userId.uuidString).single().execute().value

        let goals       = try await fetchGoals(userId: userId)
        let investments = try await fetchInvestments(userId: userId)
        let loans       = try await fetchLoans(userId: userId)
        let insurances  = try await fetchInsurances(userId: userId)
        let snapshots   = try await fetchCashflowSnapshots(userId: userId)
        let assessments = try await fetchHealthAssessments(userId: userId)

        let signUp = AstraSignUp(signUpName: profileRow.signUpName ?? "", email: "", password: "")
        let basicDetails = AstraBasicDetails(
            name: profileRow.name ?? "",
            age: profileRow.age ?? 0,
            gender: AstraGender(rawValue: profileRow.gender ?? "male") ?? .male,
            maritalStatus: AstraMaritalStatus(rawValue: profileRow.maritalStatus ?? "single") ?? .single,
            adultDependents: profileRow.adultDependents ?? 0,
            childDependents: profileRow.childDependents ?? 0,
            incomeType: AstraIncomeType(rawValue: profileRow.incomeType ?? "fixed") ?? .fixed,
            monthlyIncome: profileRow.monthlyIncome ?? 0,
            monthlyIncomeAfterTax: profileRow.monthlyIncomeAfterTax ?? 0,
            monthlyExpenses: profileRow.monthlyExpenses ?? 0,
            emergencyFundAmount: profileRow.emergencyFundAmount ?? 0,
            activeInvestment: profileRow.activeInvestment ?? false,
            riskTolerance: AstraRiskTolerance(rawValue: profileRow.riskTolerance ?? "Medium") ?? .medium,
            investmentHorizon: AstraInvestmentHorizon(rawValue: profileRow.investmentHorizon ?? "Medium Term (3-7 yrs)") ?? .mediumTerm
        )
        let assets = AstraAssets(
            savingsAccountAmount: assetsRow?.savingsAccountAmount ?? 0,
            currentAccountAmount: assetsRow?.currentAccountAmount ?? 0,
            stocksHoldingAmount: assetsRow?.stocksHoldingAmount ?? 0,
            mutualFundHoldingAmount: assetsRow?.mutualFundHoldingAmount ?? 0,
            otherInvestmentAmount: assetsRow?.otherInvestmentAmount ?? 0,
            propertyAmount: assetsRow?.propertyAmount ?? 0,
            vehiclesAmount: assetsRow?.vehiclesAmount ?? 0,
            depositsAmount: assetsRow?.depositsAmount ?? 0,
            jewelleryAmount: assetsRow?.jewelleryAmount ?? 0,
            luxuryBelongingsAmount: assetsRow?.luxuryBelongingsAmount ?? 0,
            otherAssetsAmount: assetsRow?.otherAssetsAmount ?? 0
        )
        let liabilities = AstraLiabilities(
            homeLoanAmount: liabilitiesRow?.homeLoanAmount ?? 0,
            vehicleLoanAmount: liabilitiesRow?.vehicleLoanAmount ?? 0,
            creditCardBills: liabilitiesRow?.creditCardBills ?? 0,
            educationLoanAmount: liabilitiesRow?.educationLoanAmount ?? 0,
            otherLoanAmount: liabilitiesRow?.otherLoanAmount ?? 0,
            otherDebtAmount: liabilitiesRow?.otherDebtAmount ?? 0
        )

        var profile = AstraUserProfile(
            signUp: signUp, basicDetails: basicDetails,
            assets: assets, liabilities: liabilities,
            investments: investments, loans: loans,
            insurances: insurances, goals: goals,
            financialHealthReport: nil,
            cashflowData: snapshots.values.first,
            monthlyHealthAssessments: assessments,
            isSetuConnected: profileRow.isSetuConnected ?? false
        )
        profile.monthlyCashflowSnapshots = snapshots
        return profile
    }
    func deleteSavedPlan(_ planId: UUID) async throws {
        try await supabase.from("saved_plans")
            .delete().eq("id", value: planId.uuidString).execute()
    }
}
