//
//  LiabilityDetailSheet.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

struct LiabilityDetailSheet: View {
    let insights: FinancialAssessmentInsights
    let concerns: [AssessmentConcern]

    private let loanTypes: [LoanTypeInfo] = [
        LoanTypeInfo(
            title: "Home Loan",
            description: "Used to buy property. Lower interest (~8–10%). Long tenure (15–30 years).",
            interestRate: "Low (8-10%)",
            tenure: "Long (15-30 years)",
            riskLevel: "Low",
            purpose: "Asset building",
            visualTag: "Good Debt",
            tagColor: Color(hex: "#30D158"),
            icon: "house.fill",
            deepExplanation: LoanDeepExplanation(
                whatItIsUsedFor: "Purchasing residential or commercial property.",
                typicalInterestRates: "8% to 10% annually depending on credit score and bank.",
                realLifeExample: "Buying a ₹50L apartment with a 20-year loan allows you to own an asset while paying monthly installments instead of rent.",
                pros: ["Asset creation over time", "Tax benefits on principal and interest", "Lowest interest rates among all loans"],
                risks: ["Long-term financial commitment", "Property value fluctuations"],
                whenToTakeVsAvoid: "Take when you have a stable income and a 10-20% down payment ready. Avoid if your job is unstable or the EMI exceeds 40% of your take-home pay."
            )
        ),
        LoanTypeInfo(
            title: "Education Loan",
            description: "Finances higher education. Builds your human capital and future earning potential.",
            interestRate: "Low/Medium (9-12%)",
            tenure: "Long (7-15 years)",
            riskLevel: "Low",
            purpose: "Asset building (Human Capital)",
            visualTag: "Good Debt",
            tagColor: Color(hex: "#30D158"),
            icon: "graduationcap.fill",
            deepExplanation: LoanDeepExplanation(
                whatItIsUsedFor: "Tuition fees, books, and living expenses for higher studies.",
                typicalInterestRates: "9% to 12% annually. Often has a moratorium period (no EMI during studies).",
                realLifeExample: "Taking a ₹20L loan for an MBA that doubles your salary allows you to pay off the debt quickly while significantly increasing your wealth.",
                pros: ["Invests in future earning capacity", "Tax benefits under Section 80E", "Moratorium period provides breathing room"],
                risks: ["Pressure to get a high-paying job immediately", "Burden if the degree doesn't lead to better income"],
                whenToTakeVsAvoid: "Take for reputable courses/institutions with clear career paths. Avoid for generic degrees from low-ranked colleges with poor placement records."
            )
        ),
        LoanTypeInfo(
            title: "Car Loan",
            description: "Finances a vehicle. Manageable if income is stable but the asset depreciates.",
            interestRate: "Medium (7-11%)",
            tenure: "Medium (3-7 years)",
            riskLevel: "Medium",
            purpose: "Consumption / Utility",
            visualTag: "Neutral",
            tagColor: Color(hex: "#FFCC00"),
            icon: "car.fill",
            deepExplanation: LoanDeepExplanation(
                whatItIsUsedFor: "Buying a new or used four-wheeler.",
                typicalInterestRates: "7% to 11% depending on the car model and borrower profile.",
                realLifeExample: "Taking a ₹10L car loan for a vehicle that saves 2 hours of daily commute, improving productivity and quality of life.",
                pros: ["Increases mobility and convenience", "Fixed interest rates", "Easily accessible"],
                risks: ["Asset value drops 10-20% as soon as it leaves the showroom", "High insurance and maintenance costs"],
                whenToTakeVsAvoid: "Take when a car is a necessity for work or family. Avoid if you're buying a luxury car just for status that stretches your budget."
            )
        ),
        LoanTypeInfo(
            title: "Personal Loan",
            description: "No collateral required. High interest (~12–20%). Quick access to money.",
            interestRate: "High (12-20%)",
            tenure: "Short/Medium (1-5 years)",
            riskLevel: "High",
            purpose: "Consumption / Emergency",
            visualTag: "Risky",
            tagColor: Color(hex: "#FF3B30"),
            icon: "person.fill",
            deepExplanation: LoanDeepExplanation(
                whatItIsUsedFor: "Unspecified personal needs like weddings, travel, or medical emergencies.",
                typicalInterestRates: "12% to 20% annually. Among the most expensive bank loans.",
                realLifeExample: "Taking a ₹5L personal loan for a vacation. You enjoy for a week but pay interest for the next 3 years.",
                pros: ["Quick disbursal", "No collateral or security needed", "Flexible usage"],
                risks: ["Very high interest cost", "Can lead to a debt trap if used for lifestyle expenses"],
                whenToTakeVsAvoid: "Take only for unavoidable emergencies (medical) if you have no other funds. Avoid for weddings, vacations, or gadget upgrades."
            )
        ),
        LoanTypeInfo(
            title: "Credit Card Debt",
            description: "Very high interest (~30–40% annually). Most expensive form of borrowing.",
            interestRate: "Very High (30-40%)",
            tenure: "Short (Monthly)",
            riskLevel: "Very High",
            purpose: "Consumption",
            visualTag: "Risky",
            tagColor: Color(hex: "#FF3B30"),
            icon: "creditcard.fill",
            deepExplanation: LoanDeepExplanation(
                whatItIsUsedFor: "Revolving credit on daily purchases when the full balance isn't paid.",
                typicalInterestRates: "2.5% to 3.5% per month, which is ~30% to 42% annually.",
                realLifeExample: "Buying a ₹1L iPhone on credit card and paying only the 'Minimum Due'. It could take 10+ years to clear the debt and cost 3x the phone's price.",
                pros: ["Interest-free period (up to 45 days)", "Reward points and cashback", "Builds credit score if paid in full"],
                risks: ["Exorbitant interest rates", "Negative impact on credit score", "Encourages impulsive spending"],
                whenToTakeVsAvoid: "Use as a payment tool and pay 100% of the bill every month. Avoid carrying a balance at all costs—it is a financial emergency."
            )
        )
    ]

    private let loanAgeStrategies: [LoanAgeStrategy] = [
        LoanAgeStrategy(range: "Age 20–30", recommendations: ["Avoid personal loans", "Use education loan if needed", "Build credit score"], insight: "Focus on growth, avoid unnecessary debt.", color: Color(hex: "#30D158"), icon: "leaf.fill"),
        LoanAgeStrategy(range: "Age 30–45", recommendations: ["Home loan is acceptable", "Car loan manageable if income stable", "Avoid high-interest loans"], insight: "Use debt to build assets, not liabilities.", color: Color(hex: "#FFCC00"), icon: "house.fill"),
        LoanAgeStrategy(range: "Age 45+", recommendations: ["Reduce outstanding loans", "Avoid new long-term loans", "Focus on becoming debt-free"], insight: "Shift from borrowing to financial stability.", color: Color(hex: "#FF3B30"), icon: "lock.shield.fill")
    ]

    @State private var selectedLoan: LoanTypeInfo?

    private var dtiColor: Color {
        insights.debtToIncomeRatio >= 0.45 ? Color(hex: "#FF453A")
            : insights.debtToIncomeRatio >= 0.30 ? Color(hex: "#FF9F0A")
            : Color(hex: "#30D158")
    }
    private var dtiLabel: String {
        insights.debtToIncomeRatio >= 0.45 ? "Stressed" : insights.debtToIncomeRatio >= 0.30 ? "Moderate" : "Healthy"
    }

    var body: some View {
        List {

                Section(header: Text("Key Metrics").font(.footnote).textCase(.uppercase)) {
                    // Active loans
                    HStack {
                        Label("Active Loans", systemImage: "list.bullet.rectangle").font(.subheadline)
                        Spacer()
                        Text("\(insights.loanCount)").font(.title3).bold()
                            .foregroundStyle(insights.loanCount > 0 ? Color(hex: "#BF5AF2") : Color(hex: "#30D158"))
                    }
                    .padding(.vertical, 4)

                    // Debt-to-income gauge
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Debt-to-Income Ratio").font(.subheadline)
                            Spacer()
                            Text("\(Int(insights.debtToIncomeRatio * 100))%").font(.subheadline).bold().foregroundStyle(dtiColor)
                            Text(dtiLabel).font(.caption).bold().foregroundStyle(dtiColor)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(dtiColor.opacity(0.1)).clipShape(Capsule())
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color(UIColor.tertiarySystemFill)).frame(height: 8)
                                // Zones
                                Capsule().fill(Color(hex: "#30D158").opacity(0.3)).frame(width: geo.size.width * 0.3, height: 8)
                                Capsule()
                                    .fill(LinearGradient(colors: [Color(hex: "#30D158"), Color(hex: "#FF9F0A"), Color(hex: "#FF453A")],
                                                         startPoint: .leading, endPoint: .trailing))
                                    .opacity(0.2).frame(height: 8)
                                // Indicator
                                Capsule().fill(dtiColor)
                                    .frame(width: max(8, geo.size.width * min(1, insights.debtToIncomeRatio)), height: 8)
                                // Benchmark marker
                                Rectangle().fill(Color.secondary.opacity(0.5))
                                    .frame(width: 2, height: 14)
                                    .offset(x: geo.size.width * 0.3 - 1, y: -3)
                            }
                        }
                        .frame(height: 8)
                        HStack {
                            Text("Safe zone").font(.caption2).foregroundStyle(.secondary)
                            Spacer()
                            Text("30% benchmark").font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 2)
                    }
                    .padding(.vertical, 6)
                }

                Section(header: Text("Loan Essentials").font(.footnote).textCase(.uppercase)) {
                    ForEach(loanTypes) { type in
                        LoanCardView(type: type) {
                            selectedLoan = type
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear).listRowSeparator(.hidden)
                    }
                }

                Section(header: Text("Smart Borrowing by Life Stage").font(.footnote).textCase(.uppercase)) {
                    LoanAgeStrategySection(strategies: loanAgeStrategies)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear).listRowSeparator(.hidden)
                }

                Section(header: Text("Before You Take a Loan").font(.footnote).textCase(.uppercase)) {
                    SmartLoanInsightsCard()
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
                        .listRowBackground(Color.clear).listRowSeparator(.hidden)
                }

                if !concerns.isEmpty {
                    Section(header: Text("Action Items").font(.footnote).textCase(.uppercase)) {
                        ForEach(concerns) { concern in
                            ConcernCard(concern: concern)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear).listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .background(Color(.systemGroupedBackground).opacity(0.5))
            .navigationTitle("Liability & Debt Health")
            .navigationBarTitleDisplayMode(.inline)
            .alert(selectedLoan?.title ?? "", isPresented: Binding(
                get: { selectedLoan != nil },
                set: { if !$0 { selectedLoan = nil } }
            )) {
                Button("OK", role: .cancel) { selectedLoan = nil }
            } message: {
                if let loan = selectedLoan {
                    Text(loanAlertMessage(for: loan))
                }
            }
    }
    private func loanAlertMessage(for loan: LoanTypeInfo) -> String {
        """
        \(loan.description)

        Interest: \(loan.interestRate)
        Tenure: \(loan.tenure)
        Risk: \(loan.riskLevel)
        Purpose: \(loan.purpose)

        \(loan.deepExplanation.whenToTakeVsAvoid)
        """
    }
}

// MARK: - Components

struct LoanCardView: View {
    let type: LoanTypeInfo
    let onInfoTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                HStack(spacing: 12) {
                    Image(systemName: type.icon)
                        .font(.title3)
                        .foregroundStyle(type.tagColor)
                        .frame(width: 44, height: 44)
                        .background(type.tagColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(type.title)
                            .font(.headline)
                        Text(type.visualTag)
                            .font(.caption2).bold()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(type.tagColor.opacity(0.1))
                            .foregroundStyle(type.tagColor)
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                Button(action: onInfoTap) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            Text(type.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            VStack(alignment: .leading, spacing: 8) {
                LoanHighlightRow(title: "Interest", value: type.interestRate)
                LoanHighlightRow(title: "Tenure", value: type.tenure)
                LoanHighlightRow(title: "Risk", value: type.riskLevel)
                LoanHighlightRow(title: "Purpose", value: type.purpose)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct LoanHighlightRow: View {
    let title: String
    let value: String
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Circle().fill(.secondary.opacity(0.5)).frame(width: 4, height: 4).padding(.top, 7)
            Text("\(title):").font(.caption).bold().foregroundStyle(.secondary)
            Text(value).font(.caption).foregroundStyle(.primary)
        }
    }
}

struct LoanAgeStrategySection: View {
    let strategies: [LoanAgeStrategy]

    var body: some View {
        VStack(spacing: 16) {
            ForEach(strategies) { strategy in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: strategy.icon)
                            .foregroundStyle(strategy.color)
                        Text(strategy.range)
                            .font(.headline)
                        Spacer()
                        Circle()
                            .fill(strategy.color)
                            .frame(width: 8, height: 8)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(strategy.recommendations, id: \.self) { rec in
                            HStack(spacing: 8) {
                                Image(systemName: "dot.circle.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.secondary)
                                Text(rec)
                                    .font(.subheadline)
                            }
                        }
                    }

                    Text(strategy.insight)
                        .font(.caption)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(strategy.color.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.primary)
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}

struct SmartLoanInsightsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(Color(hex: "#FFCC00"))
                Text("Before You Take a Loan")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 10) {
                SmartInsightRow(text: "EMI should not exceed 30–40% of income")
                SmartInsightRow(text: "Prefer lower interest + shorter tenure")
                SmartInsightRow(text: "Always compare loan vs investment opportunity")
                SmartInsightRow(text: "Avoid borrowing for lifestyle upgrades")
            }
        }
        .padding(20)
        .background(Color(hex: "#FFCC00").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: "#FFCC00").opacity(0.2), lineWidth: 1)
        )
    }
}

struct SmartInsightRow: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.caption)
                .foregroundStyle(Color(hex: "#FFCC00"))
                .padding(.top, 2)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Models

struct LoanTypeInfo: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let interestRate: String
    let tenure: String
    let riskLevel: String
    let purpose: String
    let visualTag: String
    let tagColor: Color
    let icon: String
    let deepExplanation: LoanDeepExplanation
}

struct LoanDeepExplanation {
    let whatItIsUsedFor: String
    let typicalInterestRates: String
    let realLifeExample: String
    let pros: [String]
    let risks: [String]
    let whenToTakeVsAvoid: String
}

struct LoanAgeStrategy: Identifiable {
    let id = UUID()
    let range: String
    let recommendations: [String]
    let insight: String
    let color: Color
    let icon: String
}
