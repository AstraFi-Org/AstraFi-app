import Foundation

/// Year-by-year retirement corpus simulation. Healthcare inflation is applied only to the healthcare slice.
enum RetirementCalculationEngine {

    static func yearsInRetirement(retirementAge: Int, lifeExpectancy: Int) -> Int {
        max(0, lifeExpectancy - retirementAge)
    }

    static func simulateDrawdown(
        startingCorpus: Double,
        retirementAge: Int,
        lifeExpectancy: Int,
        firstYearAnnualLifestyleExpense: Double,
        firstYearAnnualHealthcareExpense: Double,
        postRetirementReturn: Double,
        retirementInflation: Double,
        healthcareInflation: Double,
        otherAnnualRetirementIncome: Double
    ) -> (depleted: Bool, years: [RetirementYearSnapshot], terminalCorpus: Double) {
        let duration = yearsInRetirement(retirementAge: retirementAge, lifeExpectancy: lifeExpectancy)
        guard duration > 0 else {
            return (false, [], max(0, startingCorpus))
        }

        var corpus = startingCorpus
        var lifestyle = max(0, firstYearAnnualLifestyleExpense)
        var healthcare = max(0, firstYearAnnualHealthcareExpense)
        var snapshots: [RetirementYearSnapshot] = []
        snapshots.reserveCapacity(duration)
        var depleted = false

        for offset in 0..<duration {
            let beginning = corpus
            let growth = beginning * postRetirementReturn
            let ending = beginning + growth - lifestyle - healthcare + otherAnnualRetirementIncome
            snapshots.append(
                RetirementYearSnapshot(
                    age: retirementAge + offset,
                    beginningCorpus: beginning,
                    investmentReturnAmount: growth,
                    lifestyleExpense: lifestyle,
                    healthcareExpense: healthcare,
                    otherIncome: otherAnnualRetirementIncome,
                    endingCorpus: ending
                )
            )
            if ending < 0 {
                depleted = true
                corpus = ending
                break
            }
            corpus = ending
            lifestyle *= (1.0 + retirementInflation)
            healthcare *= (1.0 + healthcareInflation)
        }

        return (depleted, snapshots, corpus)
    }

    /// Minimum corpus at retirement such that the projected balance does not go negative before life expectancy.
    static func requiredStartingCorpus(
        retirementAge: Int,
        lifeExpectancy: Int,
        firstYearAnnualLifestyleExpense: Double,
        firstYearAnnualHealthcareExpense: Double,
        postRetirementReturn: Double,
        retirementInflation: Double,
        healthcareInflation: Double,
        otherAnnualRetirementIncome: Double,
        withdrawalRate: Double
    ) -> (corpus: Double, usedSimulation: Bool, withdrawalFallback: Double, drawdown: [RetirementYearSnapshot]) {
        let annualNeed = max(0, firstYearAnnualLifestyleExpense + firstYearAnnualHealthcareExpense - otherAnnualRetirementIncome)
        let safeRate = withdrawalRate > 0 ? withdrawalRate : 0.04
        let withdrawalFallback = annualNeed / safeRate
        let duration = yearsInRetirement(retirementAge: retirementAge, lifeExpectancy: lifeExpectancy)

        guard duration > 0, annualNeed > 0 else {
            return (max(0, withdrawalFallback), false, withdrawalFallback, [])
        }

        var low = 0.0
        var high = max(withdrawalFallback, annualNeed * Double(duration))
        for _ in 0..<12 {
            let probe = simulateDrawdown(
                startingCorpus: high,
                retirementAge: retirementAge,
                lifeExpectancy: lifeExpectancy,
                firstYearAnnualLifestyleExpense: firstYearAnnualLifestyleExpense,
                firstYearAnnualHealthcareExpense: firstYearAnnualHealthcareExpense,
                postRetirementReturn: postRetirementReturn,
                retirementInflation: retirementInflation,
                healthcareInflation: healthcareInflation,
                otherAnnualRetirementIncome: otherAnnualRetirementIncome
            )
            if !probe.depleted { break }
            high *= 2
            if high > 1e15 { break }
        }

        for _ in 0..<48 {
            let mid = (low + high) / 2.0
            let probe = simulateDrawdown(
                startingCorpus: mid,
                retirementAge: retirementAge,
                lifeExpectancy: lifeExpectancy,
                firstYearAnnualLifestyleExpense: firstYearAnnualLifestyleExpense,
                firstYearAnnualHealthcareExpense: firstYearAnnualHealthcareExpense,
                postRetirementReturn: postRetirementReturn,
                retirementInflation: retirementInflation,
                healthcareInflation: healthcareInflation,
                otherAnnualRetirementIncome: otherAnnualRetirementIncome
            )
            if probe.depleted {
                low = mid
            } else {
                high = mid
            }
        }

        let finalRun = simulateDrawdown(
            startingCorpus: high,
            retirementAge: retirementAge,
            lifeExpectancy: lifeExpectancy,
            firstYearAnnualLifestyleExpense: firstYearAnnualLifestyleExpense,
            firstYearAnnualHealthcareExpense: firstYearAnnualHealthcareExpense,
            postRetirementReturn: postRetirementReturn,
            retirementInflation: retirementInflation,
            healthcareInflation: healthcareInflation,
            otherAnnualRetirementIncome: otherAnnualRetirementIncome
        )
        return (high, true, withdrawalFallback, finalRun.years)
    }
}
