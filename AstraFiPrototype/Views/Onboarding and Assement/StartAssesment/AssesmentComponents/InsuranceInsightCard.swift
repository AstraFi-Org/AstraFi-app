//
//  InsuranceInsightCard.swift
//  AstraFiPrototype
//
//  Created by Ayush Ahuja on 26/04/26.
//

import SwiftUI

// MARK: - Insurance Insight Card
/// Shows live, personalised insurance insights below the form fields —
/// mirrors the CoreVitalsCard pattern from BasicDetailView.
struct InsuranceInsightCard: View {

    let isInsured: Bool
    let coverAmountStr: String
    let income: Double           // monthly disposable income
    let numDependentsStr: String
    let areDependentsInsured: Bool
    let dependentEntries: [AssessmentInsuranceEntry]
    let policyDetails: AssessmentInsuranceEntry.InsuranceDetails?
    let expiryDate: Date?

    @State private var showKnowledge = false

    // MARK: - Derived values

    private var numDependents: Int  { Int(numDependentsStr) ?? 0 }
    private var coverAmount: Double { Double(coverAmountStr) ?? 0 }
    private var annualIncome: Double { income * 12 }

    // Recommended term cover = 10–15× annual income
    private var minRecommendedCover: Double { annualIncome * 10 }
    private var maxRecommendedCover: Double { annualIncome * 15 }

    // Is the user's cover amount adequate?
    private var isCoverAdequate: Bool { coverAmount >= minRecommendedCover }
    private var coverShortfall: Double { max(0, minRecommendedCover - coverAmount) }
    private var coverSurplus: Double  { max(0, coverAmount - minRecommendedCover) }

    // Is the policy expiring soon (within 60 days)?
    private var isExpiringSoon: Bool {
        guard let exp = expiryDate else { return false }
        return exp.timeIntervalSinceNow < 60 * 86_400
    }
    private var isExpired: Bool {
        guard let exp = expiryDate else { return false }
        return exp < Date()
    }

    // Uninsured dependents scenario
    private var hasUninsuredDependents: Bool {
        numDependents > 0 && !areDependentsInsured
    }
    private var partiallyInsuredDependents: Bool {
        numDependents > 0 && areDependentsInsured &&
        !dependentEntries.isEmpty &&
        dependentEntries.count < numDependents
    }

    // Overall card accent colour
    private var accentColor: Color {
        if !isInsured { return AppTheme.vibrantRed }
        if isExpired  { return AppTheme.vibrantRed }
        if isExpiringSoon || !isCoverAdequate || hasUninsuredDependents { return AppTheme.vibrantOrange }
        return AppTheme.auraGreen
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header
            HStack(spacing: 8) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.vibrantCyan)
                Text("Insurance Snapshot")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Spacer()
                Button { showKnowledge = true } label: {
                    ZStack {
                        Circle()
                            .fill(AppTheme.auraIndigo.opacity(0.12))
                            .frame(width: 28, height: 28)
                        Image(systemName: "info")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.auraIndigo)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Insurance insights and tips")
            }
            .padding(.bottom, 16)

            // ── Content switches on whether the user is insured
            if isInsured {
                insuredContent
            } else {
                uninsuredContent
            }

            // ── Footer caption
            Text("Based on standard Indian financial planning benchmarks.")
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(Color.secondary.opacity(0.6))
                .padding(.top, 14)
        }
        .padding(18)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentColor.opacity(0.18), lineWidth: 1)
        )
        .sheet(isPresented: $showKnowledge) {
            InsuranceKnowledgeSheet(
                isInsured: isInsured,
                isCoverAdequate: isCoverAdequate,
                hasUninsuredDependents: hasUninsuredDependents,
                income: income,
                numDependents: numDependents
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
    }

    // MARK: - Insured View

    @ViewBuilder
    private var insuredContent: some View {
        VStack(alignment: .leading, spacing: 0) {

            // 1. Cover Adequacy Row
            if income > 0 && coverAmount > 0 {
                coverAdequacyRow
                divider
            }

            // 2. Expiry Row
            if let exp = expiryDate {
                expiryRow(exp)
                divider
            }

            // 3. Dependent Coverage Row
            if numDependents > 0 {
                dependentCoverageRow
                divider
            }

            // 4. Overall status banner
            statusBanner
        }
    }

    // ── Cover Adequacy
    private var coverAdequacyRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    iconCircle("indianrupeesign.circle.fill",
                               color: isCoverAdequate ? AppTheme.auraGreen : AppTheme.vibrantOrange)
                    Text("Cover Adequacy")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(isCoverAdequate ? "Adequate" : "Under-insured")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(isCoverAdequate ? AppTheme.auraGreen : AppTheme.vibrantOrange)
                    .contentTransition(.identity)
            }

            // Progress bar: cover vs recommended minimum
            if annualIncome > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 6)
                        Capsule()
                            .fill(isCoverAdequate ? AppTheme.auraGreen : AppTheme.vibrantOrange)
                            .frame(
                                width: geo.size.width * min(CGFloat(coverAmount / maxRecommendedCover), 1),
                                height: 6
                            )
                        // 10× marker (minimum)
                        Rectangle()
                            .fill(Color.primary.opacity(0.4))
                            .frame(width: 2, height: 10)
                            .position(x: geo.size.width * CGFloat(minRecommendedCover / maxRecommendedCover), y: 3)
                    }
                }
                .frame(height: 6)
            }

            if isCoverAdequate {
                Text("✓  Cover ≥ 10× annual income — well-protected")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
            } else if income > 0 {
                Text("Shortfall: \(coverShortfall.toCurrency(compact: true)) · Target ≥ \(minRecommendedCover.toCurrency(compact: true)) (10× annual income)")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.bottom, 4)
    }

    // ── Expiry
    private func expiryRow(_ exp: Date) -> some View {
        let daysLeft = Int(exp.timeIntervalSinceNow / 86_400)
        let color: Color = isExpired ? AppTheme.vibrantRed :
                           isExpiringSoon ? AppTheme.vibrantOrange : AppTheme.auraGreen
        let label = isExpired ? "Expired" :
                    isExpiringSoon ? "\(daysLeft)d left" : "Active"

        return HStack(spacing: 8) {
            iconCircle("calendar.badge.clock", color: color)
            Text("Policy Validity")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
            Text(label)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.identity)
        }
        .padding(.vertical, 2)
    }

    // ── Dependent Coverage
    private var dependentCoverageRow: some View {
        let color: Color = hasUninsuredDependents ? AppTheme.vibrantRed :
                           partiallyInsuredDependents ? AppTheme.vibrantOrange : AppTheme.auraGreen
        let status = hasUninsuredDependents ? "Not Covered" :
                     partiallyInsuredDependents ? "Partial" : "Covered"

        return HStack(spacing: 8) {
            iconCircle("person.2.fill", color: color)
            Text("Dependents (\(numDependents))")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
            Text(status)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.identity)
        }
        .padding(.vertical, 2)
    }

    // ── Status Banner (overall recommendation)
    private var statusBanner: some View {
        let (icon, color, message) = overallStatusMessage
        return HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
                .padding(.top, 1)
            Text(message)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var overallStatusMessage: (String, Color, String) {
        if isExpired {
            return ("exclamationmark.triangle.fill", AppTheme.vibrantRed,
                    "Your policy has expired. Renew immediately — any claim during this gap will be rejected.")
        }
        if isExpiringSoon {
            return ("exclamationmark.circle.fill", AppTheme.vibrantOrange,
                    "Policy expiring soon. Renew before it lapses to avoid a coverage break and possible re-assessment by the insurer.")
        }
        if !isCoverAdequate && income > 0 && coverAmount > 0 {
            return ("arrow.up.circle.fill", AppTheme.vibrantOrange,
                    "Your cover is below 10× annual income. Top it up with a term plan — premiums are lowest when you're young and healthy.")
        }
        if hasUninsuredDependents {
            return ("person.crop.circle.badge.exclamationmark.fill", AppTheme.vibrantOrange,
                    "\(numDependents) dependent\(numDependents > 1 ? "s" : "") ha\(numDependents > 1 ? "ve" : "s") no insurance. A single hospitalisation can wipe out months of savings — add a family floater or individual health plan.")
        }
        if partiallyInsuredDependents {
            return ("exclamationmark.circle.fill", AppTheme.vibrantOrange,
                    "Some dependents still lack coverage. Complete their policies to ensure the whole family is protected.")
        }
        return ("checkmark.seal.fill", AppTheme.auraGreen,
                "You and your family appear well-covered. Review your cover every 2–3 years as income and responsibilities grow.")
    }

    // MARK: - Not insured View

    private var uninsuredContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Risk pills
            HStack(spacing: 8) {
                riskPill(icon: "cross.fill",         color: AppTheme.vibrantRed,    text: "Medical risk")
                riskPill(icon: "house.fill",         color: AppTheme.vibrantOrange, text: "Income gap")
                riskPill(icon: "person.2.fill",      color: AppTheme.auraIndigo,    text: "Family exposed")
            }

            // Key demerits
            VStack(alignment: .leading, spacing: 10) {
                demeritRow(
                    icon: "cross.case.fill",
                    color: AppTheme.vibrantRed,
                    title: "Medical Costs Hit Your Savings",
                    detail: "A single hospitalisation in India can cost ₹2–10 lakh. Without health insurance, you drain your emergency fund or take on high-interest debt."
                )
                Divider().opacity(0.4)
                demeritRow(
                    icon: "shield.slash.fill",
                    color: AppTheme.vibrantOrange,
                    title: "No Income Protection",
                    detail: "If you're the primary earner, an accidental death or disability without a term plan leaves dependents financially exposed."
                )
                if numDependents > 0 {
                    Divider().opacity(0.4)
                    demeritRow(
                        icon: "person.2.fill",
                        color: AppTheme.auraIndigo,
                        title: "\(numDependents) Dependent\(numDependents > 1 ? "s" : "") at Risk",
                        detail: "With \(numDependents) dependent\(numDependents > 1 ? "s" : ""), the financial impact of an unforeseen event is magnified. A family floater health plan is the first step."
                    )
                }
                Divider().opacity(0.4)
                demeritRow(
                    icon: "chart.line.downtrend.xyaxis",
                    color: AppTheme.vibrantRed,
                    title: "Tax Benefits Missed",
                    detail: "Health insurance premiums qualify for ₹25,000–₹50,000 deduction under Sec 80D. You're leaving this tax saving on the table."
                )
            }

            // What to do hint
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.auraGold)
                    .padding(.top, 1)
                Text("Start with a ₹5–10 lakh health plan and a term life cover of 10–15× your annual income — both combined cost less than ₹1,500/month for most people under 30.")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .background(AppTheme.auraGold.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    // MARK: - Helpers

    private func iconCircle(_ icon: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.12))
                .frame(width: 30, height: 30)
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
        }
    }

    private func riskPill(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.primary.opacity(0.75))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(color.opacity(0.08))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.18), lineWidth: 1))
    }

    private func demeritRow(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
            }
            .padding(.top, 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text(detail)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var divider: some View {
        Divider().opacity(0.5).padding(.vertical, 8)
    }
}

// MARK: - Insurance Knowledge Sheet

struct InsuranceKnowledgeSheet: View {
    let isInsured: Bool
    let isCoverAdequate: Bool
    let hasUninsuredDependents: Bool
    let income: Double
    let numDependents: Int

    @Environment(\.dismiss) private var dismiss

    private var annualIncome: Double { income * 12 }
    private var minCover: Double { annualIncome * 10 }
    private var maxCover: Double { annualIncome * 15 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // ── Headline message
                    let (icon, color, title, body) = headlineMessage
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(color)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(color)
                            Text(body)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(14)
                    .background(color.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(color.opacity(0.25), lineWidth: 1)
                    )

                    // ── Cover Rule
                    infoBlock(
                        icon: "shield.fill",
                        color: AppTheme.auraIndigo,
                        title: "The 10–15× Rule for Life / Term Cover",
                        rows: [
                            ("Minimum Cover", income > 0 ? "≥ \(minCover.toCurrency(compact: true))" : "10× Annual Income"),
                            ("Ideal Cover",   income > 0 ? "\(maxCover.toCurrency(compact: true))" : "15× Annual Income"),
                            ("Why?", "Replaces income so dependents can sustain their lifestyle for 10–15 years if you're no longer around.")
                        ]
                    )

                    // ── Health Insurance Rule
                    infoBlock(
                        icon: "cross.case.fill",
                        color: AppTheme.vibrantRed,
                        title: "Health Insurance Benchmarks",
                        rows: [
                            ("Minimum Sum Insured", "₹5 lakh (individual) / ₹10 lakh (family floater)"),
                            ("Ideal Sum Insured", "₹10–25 lakh for metros; medical inflation ~14%/yr"),
                            ("Key Features", "Zero co-pay · No room-rent cap · Daycare procedures · Pre-existing disease cover after waiting period")
                        ]
                    )

                    // ── Dependent Risk (if applicable)
                    if numDependents > 0 {
                        infoBlock(
                            icon: "person.2.fill",
                            color: AppTheme.auraIndigo,
                            title: "Protecting Your \(numDependents) Dependent\(numDependents > 1 ? "s" : "")",
                            rows: [
                                ("Family Floater", "One policy covers the whole family; premium is lower than individual plans"),
                                ("Critical Illness", "Lumpsum payout on diagnosis — covers income loss during treatment"),
                                ("Super Top-Up", "Boosts existing cover cheaply once base policy's sum insured is exhausted")
                            ]
                        )
                    }

                    // ── Tax Benefit
                    infoBlock(
                        icon: "percent",
                        color: AppTheme.auraGreen,
                        title: "Tax Savings Under Sec 80D",
                        rows: [
                            ("Self & Family (< 60 yrs)", "Deduction up to ₹25,000"),
                            ("Parents (< 60 yrs)", "Additional ₹25,000"),
                            ("Senior Citizen Parents", "Up to ₹50,000 — total deduction ₹75,000"),
                            ("Preventive Health Check-up", "₹5,000 within the above limits")
                        ]
                    )

                    Text("Insurance benchmarks vary by age, health, and goals. Consult a SEBI-registered financial planner for personalised advice.")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(Color.secondary.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 8)
                }
                .padding(16)
            }
            .navigationTitle("Insurance Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
            }
        }
    }

    private var headlineMessage: (String, Color, String, String) {
        if !isInsured {
            return ("exclamationmark.triangle.fill", AppTheme.vibrantRed,
                    "You're currently uninsured",
                    "Insurance is the foundation of a financial plan — not an optional add-on. Even a ₹5 lakh health plan dramatically reduces your financial risk.")
        }
        if !isCoverAdequate && income > 0 {
            return ("arrow.up.circle.fill", AppTheme.vibrantOrange,
                    "Your cover needs a top-up",
                    "You're insured, but the sum assured is below the 10× annual income benchmark. Adding a term plan or increasing coverage closes this gap affordably.")
        }
        if hasUninsuredDependents {
            return ("person.crop.circle.badge.exclamationmark.fill", AppTheme.vibrantOrange,
                    "Dependents need coverage",
                    "Your own insurance is in place, but uninsured dependents remain a financial vulnerability. A family floater health plan is the fastest fix.")
        }
        return ("checkmark.seal.fill", AppTheme.auraGreen,
                "You're well-covered!",
                "Your insurance setup looks solid. The details below help you stay informed and adjust as your life circumstances evolve.")
    }

    private func infoBlock(icon: String, color: Color, title: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            VStack(alignment: .leading, spacing: 8) {
                ForEach(rows, id: \.0) { row in
                    HStack(alignment: .top, spacing: 8) {
                        Text(row.0)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .frame(width: 120, alignment: .leading)
                        Text(row.1)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(14)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 6, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(color.opacity(0.10), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Insured – Good") {
    InsuranceInsightCard(
        isInsured: true,
        coverAmountStr: "15000000",
        income: 120000,
        numDependentsStr: "2",
        areDependentsInsured: true,
        dependentEntries: [AssessmentInsuranceEntry(), AssessmentInsuranceEntry()],
        policyDetails: .life(AssessmentInsuranceEntry.LifeDetails()),
        expiryDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Insured – Under-covered") {
    InsuranceInsightCard(
        isInsured: true,
        coverAmountStr: "500000",
        income: 120000,
        numDependentsStr: "2",
        areDependentsInsured: false,
        dependentEntries: [],
        policyDetails: .health(AssessmentInsuranceEntry.HealthDetails()),
        expiryDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Not Insured") {
    InsuranceInsightCard(
        isInsured: false,
        coverAmountStr: "",
        income: 120000,
        numDependentsStr: "3",
        areDependentsInsured: false,
        dependentEntries: [],
        policyDetails: nil,
        expiryDate: nil
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
