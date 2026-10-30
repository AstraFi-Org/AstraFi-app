import Foundation

/// Mathematical and timeline simulation engine for fixed-income ladder strategies.
/// Deterministic, instrument-aware cash flow calculation adhering to AstraFi architecture.
enum FixedIncomeLadderEngine {

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
        var timelineEvents: [LadderCashFlowEvent] = []
        var totalAllocated = 0.0
        var totalGrossInterest = 0.0
        var totalNetInterest = 0.0
        var totalMaturityProceedsGross = 0.0
        var totalTaxesAndFees = 0.0
        var totalReinvested = 0.0
        var totalWithdrawalsPaid = 0.0

        var allocationByInstrument: [String: Double] = [:]
        var allocationByMaturityYear: [Int: Double] = [:]

        // Determine max horizon
        let maxMaturityYear = input.ladderEntries.map { $0.startYearOffset + $0.tenureYears }.max() ?? 5
        let simulationHorizonYears = max(5, maxMaturityYear)

        // Process each entry's cash flows
        for entry in input.ladderEntries {
            totalAllocated += entry.allocatedAmount
            allocationByInstrument[entry.instrumentType.rawValue, default: 0.0] += entry.allocatedAmount
            let matYear = entry.startYearOffset + entry.tenureYears
            allocationByMaturityYear[matYear, default: 0.0] += entry.allocatedAmount

            let (entryEvents, grossInt, netInt, matGross, taxFee, reinvested, withdrawn) = simulateEntry(
                entry: entry,
                stress: stress,
                inflationRate: input.inflationAssumptionPct / 100.0
            )

            timelineEvents.append(contentsOfKey: entryEvents)
            totalGrossInterest += grossInt
            totalNetInterest += netInt
            totalMaturityProceedsGross += matGross
            totalTaxesAndFees += taxFee
            totalReinvested += reinvested
            totalWithdrawalsPaid += withdrawn
        }

        // Sort timeline events chronologically
        timelineEvents.sort {
            if $0.yearOffset != $1.yearOffset {
                return $0.yearOffset < $1.yearOffset
            }
            return $0.isMaturityPrincipal && !$1.isMaturityPrincipal
        }

        // Generate yearly summary
        var yearlySummaries: [LadderYearlySummary] = []
        var runningCash = max(0, input.totalCapitalAvailable - totalAllocated)
        var runningInvested = totalAllocated

        var concentrationWarnings: [String] = []
        var liquidityGaps: [String] = []

        // Concentration check: Check if single non-sovereign instrument > 35% of total allocated
        for (instName, amount) in allocationByInstrument {
            let pct = (amount / max(1.0, totalAllocated)) * 100.0
            let isSovereign = instName.contains("G-Sec") || instName.contains("Treasury") || instName.contains("SGB")
            if !isSovereign && pct > 35.0 {
                concentrationWarnings.append(
                    "Concentration Risk: \(instName) represents \(String(format: "%.1f", pct))% of allocated ladder (recommended max 35% for non-sovereign credit)."
                )
            }
        }

        if totalAllocated > input.totalCapitalAvailable {
            concentrationWarnings.append(
                "Capital Shortfall: Allocated capital (\(formatCurrency(totalAllocated))) exceeds available capital (\(formatCurrency(input.totalCapitalAvailable)))."
            )
        }

        for year in 1...simulationHorizonYears {
            let yearEvents = timelineEvents.filter { $0.yearOffset == year }
            let yearInterest = yearEvents.filter { !$0.isMaturityPrincipal }.reduce(0.0) { $0 + $1.netCashInflow }
            let yearMatPrincipal = yearEvents.filter { $0.isMaturityPrincipal }.reduce(0.0) { $0 + $1.netCashInflow }
            let yearTaxFee = yearEvents.reduce(0.0) { $0 + $1.taxAndFeesDeducted }

            // Entries maturing in this year
            let maturingThisYear = input.ladderEntries.filter { ($0.startYearOffset + $0.tenureYears) == year }
            var yearReinvested = 0.0
            var yearWithdrawals = 0.0

            for m in maturingThisYear {
                let withdrawalNeed = m.plannedWithdrawalAtMaturity * pow(1.0 + (input.inflationAssumptionPct + stress.expenseInflationIncreasePct) / 100.0, Double(year))
                yearWithdrawals += withdrawalNeed

                if m.reinvestmentAction == .reinvestLadder {
                    let eligibleProceeds = max(0, m.allocatedAmount - withdrawalNeed)
                    yearReinvested += eligibleProceeds
                }
            }

            // Cash addition from interest and non-reinvested maturity principal
            let netCashAddition = yearInterest + max(0, yearMatPrincipal - yearReinvested - yearWithdrawals)
            runningCash += netCashAddition
            runningInvested = max(0, runningInvested - yearMatPrincipal + yearReinvested)

            if runningCash < input.desiredLiquidityReserve {
                liquidityGaps.append("Year \(year): Available cash (\(formatCurrency(runningCash))) falls below desired liquidity reserve (\(formatCurrency(input.desiredLiquidityReserve))).")
            }

            // Check if there are zero maturities and zero interest in this year
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
            stressTestResults: stressResults
        )
    }

    // MARK: - Internal Per-Entry Simulation

    private static func simulateEntry(
        entry: FixedIncomeEntry,
        stress: LadderStressScenario,
        inflationRate: Double
    ) -> (
        events: [LadderCashFlowEvent],
        grossInterest: Double,
        netInterest: Double,
        maturityProceedsGross: Double,
        taxesAndFees: Double,
        reinvested: Double,
        withdrawalsPaid: Double
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
                        isMaturityPrincipal: false
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
                            isMaturityPrincipal: false
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
                    isMaturityPrincipal: false
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
                        isMaturityPrincipal: false
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
                isMaturityPrincipal: true
            )
        )

        // Calculate reinvestment vs withdrawal
        let inflatedWithdrawal = entry.plannedWithdrawalAtMaturity * pow(1.0 + inflationRate, Double(maturityYear))
        let netAvailableFromPrincipal = max(0, principalRepaid - inflatedWithdrawal)
        let reinvested: Double
        if entry.reinvestmentAction == .reinvestLadder {
            reinvested = netAvailableFromPrincipal
        } else {
            reinvested = 0.0
        }

        return (
            events: events,
            grossInterest: grossInterestTotal,
            netInterest: netInterestTotal,
            maturityProceedsGross: p,
            taxesAndFees: totalTaxFee + principalTaxFee,
            reinvested: reinvested,
            withdrawalsPaid: min(principalRepaid, inflatedWithdrawal)
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
