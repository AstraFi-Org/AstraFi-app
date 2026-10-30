import Foundation

/// Mathematical and temporal simulation engine for REITs and listed income assets.
/// Models distributions, price changes, reinvestment compounding, transaction fees, and stress tests.
enum REITSimulatorEngine {

    // MARK: - Primary Simulation Entry Point

    static func simulate(
        input: REITSimulatorInput,
        appliedStress: REITStressScenario? = nil,
        calculateStressScenarios: Bool = true
    ) -> REITSimulatorResult {
        guard input.investmentHorizonYears > 0 else {
            return REITSimulatorResult.empty()
        }

        let stress = appliedStress ?? REITStressScenario.standardScenarios[0]
        let horizon = input.investmentHorizonYears
        let txCostRate = max(0, input.transactionCostPct / 100.0)
        let distTaxRate = max(0, input.distributionTaxPct / 100.0)

        // Starting purchase
        let initialCapital = max(0, input.initialLumpSumInvestment)
        let initialNetCapital = initialCapital * (1.0 - txCostRate)
        let initialUnitPrice = max(1.0, input.purchasePricePerUnit)
        var currentUnitPrice = initialUnitPrice

        var totalUnitsHeld = initialNetCapital / initialUnitPrice
        var cumulativeCapitalInvested = initialCapital
        var cumulativeGrossDistributions = 0.0
        var cumulativeNetDistributions = 0.0
        var cumulativeCashDistributedToUser = 0.0
        var cumulativeReinvestedCapital = 0.0
        var cumulativeTaxesAndCosts = initialCapital * txCostRate

        // Initial distribution per unit based on starting yield
        let baseYield = max(0, (input.distributionYieldPct - stress.distributionCutPct) / 100.0)
        var annualDistributionPerUnit = currentUnitPrice * baseYield

        let distGrowthRate = stress.zeroDistributionGrowth ? 0.0 : (input.expectedAnnualDistributionGrowthPct / 100.0)
        let annualPriceAppreciationRate = (input.expectedAnnualPriceAppreciationPct - stress.unitPriceDropPct) / 100.0

        var yearlySnapshots: [REITYearlySnapshot] = []

        for year in 1...horizon {
            let beginningUnits = totalUnitsHeld

            // Monthly recurring contribution accumulation throughout the year
            let annualRecurringCapital = max(0, input.recurringMonthlyContribution * 12.0)
            cumulativeCapitalInvested += annualRecurringCapital

            let annualRecurringTxFee = annualRecurringCapital * txCostRate
            cumulativeTaxesAndCosts += annualRecurringTxFee
            let netRecurringCapital = annualRecurringCapital - annualRecurringTxFee

            // Average execution price for dollar-cost averaging during the year
            let midYearPrice = currentUnitPrice * (1.0 + annualPriceAppreciationRate * 0.5)
            let newUnitsFromSIP = midYearPrice > 0 ? (netRecurringCapital / midYearPrice) : 0

            // Eligible units for distribution this year (weighted: beginning units + 50% of SIP units)
            let eligibleUnitsForDist = beginningUnits + (newUnitsFromSIP * 0.5)

            // Gross distribution generated
            let grossDistribution = eligibleUnitsForDist * annualDistributionPerUnit
            let distTax = grossDistribution * distTaxRate
            let netDistribution = max(0, grossDistribution - distTax)

            cumulativeGrossDistributions += grossDistribution
            cumulativeNetDistributions += netDistribution
            cumulativeTaxesAndCosts += distTax

            var unitsBoughtFromReinvestment = 0.0
            if input.reinvestDistributions {
                // Distributions reinvested into units at year-end unit price
                let reinvestUnitPrice = max(0.01, currentUnitPrice * (1.0 + annualPriceAppreciationRate))
                unitsBoughtFromReinvestment = netDistribution / reinvestUnitPrice
                cumulativeReinvestedCapital += netDistribution
            } else {
                // Transferred out to cash
                cumulativeCashDistributedToUser += netDistribution
            }

            // Update unit price at year end
            currentUnitPrice = max(0.1, currentUnitPrice * (1.0 + annualPriceAppreciationRate))

            // Ending units
            let endingUnits = beginningUnits + newUnitsFromSIP + unitsBoughtFromReinvestment
            totalUnitsHeld = endingUnits

            // Market value at year end
            let endingMarketValue = endingUnits * currentUnitPrice
            let totalEconomicValue = endingMarketValue + cumulativeCashDistributedToUser
            let unrealizedGain = max(0, endingMarketValue - (cumulativeCapitalInvested + cumulativeReinvestedCapital))

            let prevEconomicValue = yearlySnapshots.last?.totalEconomicValue ?? initialCapital
            let annualTotalReturnPct = prevEconomicValue > 0 ? ((totalEconomicValue - prevEconomicValue - annualRecurringCapital) / prevEconomicValue) * 100.0 : 0.0

            yearlySnapshots.append(
                REITYearlySnapshot(
                    year: year,
                    beginningUnits: beginningUnits,
                    endingUnits: endingUnits,
                    unitPrice: currentUnitPrice,
                    distributionPerUnit: annualDistributionPerUnit,
                    cumulativeContributions: cumulativeCapitalInvested,
                    annualContributions: annualRecurringCapital,
                    grossDistributionsReceived: grossDistribution,
                    netDistributionsReceived: netDistribution,
                    unitsBoughtFromReinvestment: unitsBoughtFromReinvestment,
                    endingPortfolioMarketValue: endingMarketValue,
                    cumulativeCashReceived: cumulativeCashDistributedToUser,
                    totalEconomicValue: totalEconomicValue,
                    unrealizedCapitalGain: unrealizedGain,
                    annualTotalReturnPct: annualTotalReturnPct
                )
            )

            // Escalate distribution per unit for next year
            annualDistributionPerUnit *= (1.0 + distGrowthRate)
        }

        let finalMarketValue = totalUnitsHeld * currentUnitPrice
        let finalEconomicValue = finalMarketValue + cumulativeCashDistributedToUser
        let netProfit = finalEconomicValue - cumulativeCapitalInvested
        let absoluteReturnPct = cumulativeCapitalInvested > 0 ? (netProfit / cumulativeCapitalInvested) * 100.0 : 0.0

        // Approximate CAGR using simple annualized return formula
        let cagr: Double
        if cumulativeCapitalInvested > 0 && finalEconomicValue > 0 {
            cagr = (pow(finalEconomicValue / cumulativeCapitalInvested, 1.0 / Double(horizon)) - 1.0) * 100.0
        } else {
            cagr = 0.0
        }

        let finalRunrateDist = totalUnitsHeld * annualDistributionPerUnit

        // Evaluate feasibility and risk
        let feasibility: PlanFeasibility
        if netProfit < 0 {
            feasibility = .aggressive
        } else if input.reinvestDistributions {
            feasibility = .healthy
        } else {
            feasibility = .manageable
        }

        var notes: [String] = []
        notes.append("REIT distributions are not guaranteed; they depend on commercial property occupancy, tenant lease renewals, and operational net operating income (NOI).")
        if input.reinvestDistributions {
            notes.append("Distribution Reinvestment (DRIP) compounds your holdings: \(String(format: "%.1f", totalUnitsHeld - (initialCapital / initialUnitPrice))) additional units accumulated through compounding and SIP.")
        } else {
            notes.append("Cash distribution mode selected: Generated \(formatCurrency(cumulativeCashDistributedToUser)) in cumulative spendable liquidity over \(horizon) years.")
        }
        notes.append("Current indicative annual run-rate distribution at year \(horizon): \(formatCurrency(finalRunrateDist)) / year.")

        // Run stress comparisons
        var stressComparisons: [String: Double] = [:]
        if calculateStressScenarios {
            for sc in REITStressScenario.standardScenarios {
                let res = simulateSingleStressEconomicValue(input: input, stress: sc)
                stressComparisons[sc.id] = res
            }
        }

        return REITSimulatorResult(
            totalCapitalInvested: cumulativeCapitalInvested,
            totalUnitsAccumulated: totalUnitsHeld,
            finalUnitPrice: currentUnitPrice,
            finalPortfolioMarketValue: finalMarketValue,
            cumulativeGrossDistributions: cumulativeGrossDistributions,
            cumulativeNetDistributions: cumulativeNetDistributions,
            cumulativeReinvestedCapital: cumulativeReinvestedCapital,
            totalTaxesAndCosts: cumulativeTaxesAndCosts,
            totalNetEconomicValue: finalEconomicValue,
            netAbsoluteReturnPct: absoluteReturnPct,
            annualizedCAGR: cagr,
            finalAnnualRunrateDistribution: finalRunrateDist,
            yearlySnapshots: yearlySnapshots,
            stressTestComparisons: stressComparisons,
            feasibility: feasibility,
            summaryNotes: notes
        )
    }

    private static func simulateSingleStressEconomicValue(
        input: REITSimulatorInput,
        stress: REITStressScenario
    ) -> Double {
        let res = simulate(input: input, appliedStress: stress, calculateStressScenarios: false)
        return res.totalNetEconomicValue
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
