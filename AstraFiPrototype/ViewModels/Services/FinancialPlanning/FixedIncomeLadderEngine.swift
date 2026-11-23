import Foundation

/// Mathematical and timeline simulation engine for fixed-income ladder strategies.
/// Deterministic, instrument-aware cash flow calculation adhering to AstraFi architecture.
enum FixedIncomeLadderEngine {

    private static func derivedID(from sourceID: UUID, year: Int, salt: UInt8) -> UUID {
        var bytes = sourceID.uuid
        withUnsafeMutableBytes(of: &bytes) { buffer in
            buffer[12] = UInt8(truncatingIfNeeded: year >> 24)
            buffer[13] = UInt8(truncatingIfNeeded: year >> 16)
            buffer[14] = UInt8(truncatingIfNeeded: year >> 8) ^ salt
            buffer[15] = UInt8(truncatingIfNeeded: year) ^ 0xA5
        }
        return UUID(uuid: bytes)
    }

    // MARK: - Primary Simulation Entry Point

    static func simulate(
        input: FixedIncomeLadderInput,
        appliedStress: LadderStressScenario? = nil,
        calculateStressScenarios: Bool = true
    ) -> FixedIncomeLadderResult {
        guard !input.ladderEntries.isEmpty else {
            return FixedIncomeLadderResult.empty()
        }

        let stress = appliedStress ?? LadderStressScenario.standardScenarios[0]
        let totalAllocated = input.ladderEntries.reduce(0) { $0 + $1.allocatedAmount }
        var allEntries = input.ladderEntries
        var timelineEvents: [LadderCashFlowEvent] = []
        var totalGrossInterest = 0.0
        var totalNetInterest = 0.0
        var totalMaturityProceedsGross = 0.0
        var totalTaxesAndFees = 0.0
        var totalReinvested = 0.0
        var totalWithdrawalsPaid = 0.0
        var reinvestmentRecords: [LadderReinvestmentRecord] = []
        var allocationByInstrument: [String: Double] = [:]
        var allocationByMaturityYear: [Int: Double] = [:]

        func addEntryEvents(_ entry: FixedIncomeEntry) {
            let simulated = simulateEntry(entry: entry, stress: stress)
            timelineEvents.append(contentsOf: simulated.events)
            totalGrossInterest += simulated.grossInterest
            totalNetInterest += simulated.netInterest
            totalMaturityProceedsGross += simulated.maturityProceedsGross
            totalTaxesAndFees += simulated.taxesAndFees
        }

        for entry in input.ladderEntries {
            allocationByInstrument[entry.instrumentType.rawValue, default: 0] += entry.allocatedAmount
            allocationByMaturityYear[entry.maturityYearOffset, default: 0] += entry.allocatedAmount
            addEntryEvents(entry)
        }

        let originalHorizon = input.ladderEntries.map(\.maturityYearOffset).max() ?? 5
        let maxNewTenure = input.ladderEntries
            .filter { $0.reinvestmentAction == .reinvestLadder }
            .map { ($0.reinvestmentConfiguration?.destinationTenureYears ?? 1) }
            .max() ?? 0
        // One real follow-on investment is simulated for each configured original tranche.
        // Follow-on legs mature to cash, preventing an unbounded automatic rollover loop.
        let simulationHorizonYears = max(5, originalHorizon + maxNewTenure)

        var yearlySummaries: [LadderYearlySummary] = []
        var runningCash = max(0, input.totalCapitalAvailable - totalAllocated)
        var runningInvested = totalAllocated
        var liquidityGaps: [String] = []

        if totalAllocated > input.totalCapitalAvailable {
            // Keep the original feasibility warning below; a negative unallocated amount
            // must not be silently added to cash.
            runningCash = 0
        }

        for year in 1...simulationHorizonYears {
            let yearEvents = timelineEvents.filter { $0.yearOffset == year }
            let interestEvents = yearEvents.filter { !$0.isMaturityPrincipal }
            let principalEvents = yearEvents.filter(\.isMaturityPrincipal)
            let yearInterest = interestEvents.reduce(0.0) { $0 + $1.netCashInflow }
            let yearMatPrincipal = principalEvents.reduce(0.0) { $0 + $1.netCashInflow }
            let yearTaxFee = yearEvents.reduce(0.0) { $0 + $1.taxAndFeesDeducted }
            let maturingEntries = allEntries.filter { $0.maturityYearOffset == year }
            var yearReinvested = 0.0
            var yearWithdrawals = 0.0
            var yearInvestedPrincipalMaturing = 0.0
            var children: [FixedIncomeEntry] = []

            for matured in maturingEntries {
                guard let principalEvent = principalEvents.first(where: { $0.entryID == matured.id }) else { continue }
                let withdrawal = matured.plannedWithdrawalAtMaturity * pow(
                    1.0 + (input.inflationAssumptionPct + stress.expenseInflationIncreasePct) / 100.0,
                    Double(year)
                )
                yearWithdrawals += withdrawal
                yearInvestedPrincipalMaturing += matured.allocatedAmount

                guard matured.reinvestmentAction == .reinvestLadder else { continue }

                let config = matured.reinvestmentConfiguration ?? LadderReinvestmentConfiguration(
                    mode: .principalOnly,
                    partialReinvestmentAmount: matured.allocatedAmount,
                    destinationInstrumentType: .bankFD,
                    destinationTenureYears: 1,
                    destinationRatePct: matured.reinvestmentRatePct,
                    destinationPayoutFrequency: .quarterlyCompounding,
                    destinationTaxRatePct: matured.taxRatePct,
                    destinationFeePct: matured.feePct
                )
                let maturityInterest = interestEvents
                    .filter { $0.entryID == matured.id }
                    .reduce(0.0) { $0 + $1.netCashInflow }
                let eligiblePrincipal = max(0, principalEvent.netCashInflow - withdrawal)
                let withdrawalBeyondPrincipal = max(0, withdrawal - principalEvent.netCashInflow)
                let eligibleInterest = max(0, maturityInterest - withdrawalBeyondPrincipal)
                let amountToReinvest: Double
                switch config.mode {
                case .principalOnly:
                    amountToReinvest = min(max(0, config.partialReinvestmentAmount), eligiblePrincipal)
                case .principalPlusInterest:
                    amountToReinvest = eligiblePrincipal + eligibleInterest
                case .partialAmount:
                    amountToReinvest = min(config.partialReinvestmentAmount, eligiblePrincipal + eligibleInterest)
                }
                guard amountToReinvest > 0 else { continue }

                let principalPart = min(amountToReinvest, eligiblePrincipal)
                let interestPart = min(eligibleInterest, max(0, amountToReinvest - principalPart))
                let destinationName = "Reinvested from \(matured.instrumentName) — \(config.destinationInstrumentType.shortName)"
                let modeledStartDate = input.simulationStartDate.flatMap {
                    Calendar.current.date(byAdding: .year, value: year, to: $0)
                }
                let modeledMaturityDate = modeledStartDate.flatMap {
                    Calendar.current.date(byAdding: .year, value: config.destinationTenureYears, to: $0)
                }
                let destination = FixedIncomeEntry(
                    id: derivedID(from: matured.id, year: year, salt: 0x31),
                    instrumentName: destinationName,
                    instrumentType: config.destinationInstrumentType,
                    allocatedAmount: amountToReinvest,
                    startYearOffset: year,
                    tenureYears: config.destinationTenureYears,
                    annualInterestRatePct: config.destinationRatePct,
                    payoutFrequency: config.destinationPayoutFrequency,
                    compounding: config.destinationInstrumentType.defaultFrequency.isCumulative ? .quarterly : matured.compounding,
                    taxRatePct: config.destinationTaxRatePct,
                    feePct: config.destinationFeePct,
                    reinvestmentAction: .cashBalance,
                    reinvestmentRatePct: config.destinationRatePct,
                    simulatedStartDate: modeledStartDate,
                    simulatedMaturityDate: modeledMaturityDate
                )
                children.append(destination)
                yearReinvested += amountToReinvest
                reinvestmentRecords.append(
                    LadderReinvestmentRecord(
                        id: derivedID(from: matured.id, year: year, salt: 0x72),
                        yearOffset: year,
                        sourceEntryID: matured.id,
                        sourceTrancheName: matured.instrumentName,
                        destinationTranche: destination,
                        principalReinvested: principalPart,
                        interestReinvested: interestPart
                    )
                )
            }

            for child in children {
                allEntries.append(child)
                addEntryEvents(child)
            }

            totalReinvested += yearReinvested
            totalWithdrawalsPaid += yearWithdrawals
            let cashAddition = yearInterest + yearMatPrincipal - yearReinvested - yearWithdrawals
            runningCash += cashAddition
            runningInvested = max(0, runningInvested - yearInvestedPrincipalMaturing + yearReinvested)

            if runningCash < input.desiredLiquidityReserve {
                liquidityGaps.append("Year \(year): Available cash (\(formatCurrency(runningCash))) falls below desired liquidity reserve (\(formatCurrency(input.desiredLiquidityReserve))).")
            }
            if yearMatPrincipal == 0 && yearInterest == 0 {
                liquidityGaps.append("Year \(year): Maturity gap — no ladder tranches mature or generate cash flow in this period.")
            }

            yearlySummaries.append(
                LadderYearlySummary(
                    yearOffset: year,
                    totalInterestReceived: yearInterest,
                    totalMaturityProceeds: yearMatPrincipal,
                    totalPrincipalReturned: yearMatPrincipal,
                    totalReinvested: yearReinvested,
                    totalTaxesAndFees: yearTaxFee,
                    plannedWithdrawalsPaid: yearWithdrawals,
                    availableCashBalance: runningCash,
                    endingLadderInvestedBalance: runningInvested
                )
            )
        }

        timelineEvents.sort {
            if $0.yearOffset != $1.yearOffset { return $0.yearOffset < $1.yearOffset }
            return $0.isMaturityPrincipal && !$1.isMaturityPrincipal
        }

        var concentrationWarnings: [String] = []
        let initialAllocationByInstrument = input.ladderEntries.reduce(into: [String: Double]()) { result, entry in
            result[entry.instrumentType.rawValue, default: 0] += entry.allocatedAmount
        }
        for (instrument, amount) in initialAllocationByInstrument {
            let pct = amount / max(1.0, totalAllocated) * 100.0
            let isSovereign = instrument.contains("G-Sec") || instrument.contains("Treasury") || instrument.contains("SGB")
            if !isSovereign && pct > 35.0 {
                concentrationWarnings.append("Concentration Risk: \(instrument) represents \(String(format: "%.1f", pct))% of allocated ladder (recommended max 35% for non-sovereign credit).")
            }
        }
        if totalAllocated > input.totalCapitalAvailable {
            concentrationWarnings.append("Capital Shortfall: Allocated capital (\(formatCurrency(totalAllocated))) exceeds available capital (\(formatCurrency(input.totalCapitalAvailable))).")
        }

        // Feasibility check
        let feasibility: PlanFeasibility
        let explanation: String
        if totalAllocated > input.totalCapitalAvailable {
            feasibility = .notCurrentlyFeasible
            explanation = "Allocations exceed total capital available. Reduce ladder tranche sizes to match available funds."
        } else if runningCash < 0 {
            feasibility = .aggressive
            explanation = "Planned withdrawals exceed available cash flow and maturity proceeds during the simulation."
        } else if !liquidityGaps.isEmpty && liquidityGaps.contains(where: { $0.contains("falls below desired liquidity") }) {
            feasibility = .manageable
            explanation = "Ladder is fully funded, but some years experience temporary cash dips below your liquidity reserve."
        } else {
            feasibility = .healthy
            explanation = "Well-balanced ladder. All planned cash flows, liquidity reserves, and maturities are solvent."
        }

        // Run standard stress scenarios for quick comparison
        var stressResults: [String: Double] = [:]
        if calculateStressScenarios {
            for sc in LadderStressScenario.standardScenarios {
                let res = simulateSingleStressEndingCash(input: input, stress: sc)
                stressResults[sc.id] = res
            }
        }

        return FixedIncomeLadderResult(
            totalCapitalAllocated: totalAllocated,
            unallocatedCapital: max(0, input.totalCapitalAvailable - totalAllocated),
            totalCumulativeInterestGross: totalGrossInterest,
            totalCumulativeInterestNet: totalNetInterest,
            totalMaturityProceedsGross: totalMaturityProceedsGross,
            totalTaxesAndFees: totalTaxesAndFees,
            totalReinvestedAmount: totalReinvested,
            totalWithdrawalsPaid: totalWithdrawalsPaid,
            endingPortfolioValue: runningInvested,
            endingAvailableCash: runningCash,
            timelineEvents: timelineEvents,
            yearlySummaries: yearlySummaries,
            allocationByInstrument: allocationByInstrument,
            allocationByMaturityYear: allocationByMaturityYear,
            liquidityGaps: liquidityGaps,
            concentrationWarnings: concentrationWarnings,
            feasibility: feasibility,
            feasibilityExplanation: explanation,
            stressTestResults: stressResults,
            simulatedLadderEntries: allEntries,
            reinvestmentRecords: reinvestmentRecords
        )
    }

    // MARK: - Internal Per-Entry Simulation

    private static func simulateEntry(
        entry: FixedIncomeEntry,
        stress: LadderStressScenario
    ) -> (
        events: [LadderCashFlowEvent],
        grossInterest: Double,
        netInterest: Double,
        maturityProceedsGross: Double,
        taxesAndFees: Double
    ) {
        var events: [LadderCashFlowEvent] = []
        let p = entry.allocatedAmount
        let r = max(0, (entry.annualInterestRatePct - (entry.startYearOffset > 0 ? stress.reinvestmentRateDropPct : 0.0)) / 100.0)
        let t = entry.tenureYears
        let taxRate = max(0, entry.taxRatePct / 100.0)
        let feeRate = max(0, entry.feePct / 100.0)

        var grossInterestTotal = 0.0
        var netInterestTotal = 0.0
        var totalTaxFee = 0.0

        let maturityYear = entry.startYearOffset + entry.tenureYears

        switch entry.instrumentType {
        case .bankFD:
            if entry.payoutFrequency.isCumulative {
                // Quarterly compounding convention: A = P * (1 + r/4)^(4*t)
                let compoundPeriodsPerYear = 4.0
                let totalPeriods = compoundPeriodsPerYear * Double(t)
                let finalMaturityValue = p * pow(1.0 + (r / compoundPeriodsPerYear), totalPeriods)
                let totalInterest = max(0, finalMaturityValue - p)
                let fee = finalMaturityValue * feeRate
                let tax = totalInterest * taxRate
                let netInterest = max(0, totalInterest - tax - fee)

                grossInterestTotal = totalInterest
                netInterestTotal = netInterest
                totalTaxFee = tax + fee

                // Emitted at maturity
                events.append(
                    LadderCashFlowEvent(
                        yearOffset: maturityYear,
                        instrumentName: entry.instrumentName,
                        instrumentType: entry.instrumentType,
                        eventDescription: "Cumulative Interest (Quarterly Compounded)",
                        grossCashInflow: totalInterest,
                        taxAndFeesDeducted: tax + fee,
                        netCashInflow: netInterest,
                        isMaturityPrincipal: false,
                        entryID: entry.id
                    )
                )
            } else {
                // Periodic interest payout (monthly, quarterly, or annual)
                let annualInterest = p * r
                let annualFee = annualInterest * feeRate
                let annualTax = annualInterest * taxRate
                let annualNet = max(0, annualInterest - annualTax - annualFee)

                for year in (entry.startYearOffset + 1)...maturityYear {
                    grossInterestTotal += annualInterest
                    netInterestTotal += annualNet
                    totalTaxFee += (annualTax + annualFee)

                    events.append(
                        LadderCashFlowEvent(
                            yearOffset: year,
                            instrumentName: entry.instrumentName,
                            instrumentType: entry.instrumentType,
                            eventDescription: "Periodic Interest Payout",
                            grossCashInflow: annualInterest,
                            taxAndFeesDeducted: annualTax + annualFee,
                            netCashInflow: annualNet,
                            isMaturityPrincipal: false,
                            entryID: entry.id
                        )
                    )
                }
            }

        case .treasuryBill:
            // T-Bills are pure discount instruments: Purchased at discount, redeemed at face value.
            // Face value = p. Earnings = p * r * t (or discount yield).
            let discountInterest = p * (r * Double(t))
            let tax = discountInterest * taxRate
            let fee = p * feeRate
            let netInterest = max(0, discountInterest - tax - fee)

            grossInterestTotal = discountInterest
            netInterestTotal = netInterest
            totalTaxFee = tax + fee

            events.append(
                LadderCashFlowEvent(
                    yearOffset: maturityYear,
                    instrumentName: entry.instrumentName,
                    instrumentType: entry.instrumentType,
                    eventDescription: "T-Bill Maturity Discount Gain",
                    grossCashInflow: discountInterest,
                    taxAndFeesDeducted: tax + fee,
                    netCashInflow: netInterest,
                    isMaturityPrincipal: false,
                    entryID: entry.id
                )
            )

        case .governmentSecurity, .corporateBond, .sgb, .customBond:
            // Coupon paying instruments
            let annualCoupon = p * r
            let annualFee = annualCoupon * feeRate
            let annualTax = annualCoupon * taxRate
            let annualNetCoupon = max(0, annualCoupon - annualTax - annualFee)

            for year in (entry.startYearOffset + 1)...maturityYear {
                grossInterestTotal += annualCoupon
                netInterestTotal += annualNetCoupon
                totalTaxFee += (annualTax + annualFee)

                events.append(
                    LadderCashFlowEvent(
                        yearOffset: year,
                        instrumentName: entry.instrumentName,
                        instrumentType: entry.instrumentType,
                        eventDescription: "\(entry.payoutFrequency.rawValue)",
                        grossCashInflow: annualCoupon,
                        taxAndFeesDeducted: annualTax + annualFee,
                        netCashInflow: annualNetCoupon,
                        isMaturityPrincipal: false,
                        entryID: entry.id
                    )
                )
            }
        }

        // Model Principal Repayment at Maturity (applying default/haircut stress if applicable)
        var principalRepaid = p
        var principalTaxFee = 0.0

        if entry.instrumentType == .corporateBond, let recoveryRate = stress.corporateDefaultRecoveryPct {
            // Corporate credit stress haircut
            principalRepaid = p * (recoveryRate / 100.0)
            principalTaxFee += (p - principalRepaid)
        }

        if stress.prematureBondSaleHaircutPct > 0 && (entry.instrumentType == .governmentSecurity || entry.instrumentType == .corporateBond) {
            let haircut = principalRepaid * (stress.prematureBondSaleHaircutPct / 100.0)
            principalRepaid -= haircut
            principalTaxFee += haircut
        }

        events.append(
            LadderCashFlowEvent(
                yearOffset: maturityYear,
                instrumentName: entry.instrumentName,
                instrumentType: entry.instrumentType,
                eventDescription: "Principal Maturity Repayment",
                grossCashInflow: p,
                taxAndFeesDeducted: principalTaxFee,
                netCashInflow: principalRepaid,
                isMaturityPrincipal: true,
                entryID: entry.id
            )
        )

        return (
            events: events,
            grossInterest: grossInterestTotal,
            netInterest: netInterestTotal,
            maturityProceedsGross: p,
            taxesAndFees: totalTaxFee + principalTaxFee
        )
    }

    private static func simulateSingleStressEndingCash(
        input: FixedIncomeLadderInput,
        stress: LadderStressScenario
    ) -> Double {
        let res = simulate(input: input, appliedStress: stress, calculateStressScenarios: false)
        return res.endingAvailableCash + res.endingPortfolioValue
    }

    private static func formatCurrency(_ value: Double) -> String {
        let absVal = abs(value)
        if absVal >= 10_000_000 {
            return String(format: "₹%.2fCr", value / 10_000_000.0)
        } else if absVal >= 100_000 {
            return String(format: "₹%.2fL", value / 100_000.0)
        } else {
            return String(format: "₹%.0f", value)
        }
    }
}

private extension Array {
    mutating func append(contentsOfKey elements: [Element]) {
        self.append(contentsOf: elements)
    }
}
