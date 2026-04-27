//
//  InsuranceAdviceSheet.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

struct InsuranceAdviceSheet: View {
    @Environment(\.dismiss) private var dismiss
    let adultDependents: Int; let concerns: [AssessmentConcern]
    @State private var myAge = ""; @State private var myDisease = "None"
    @State private var depAges: [String] = []; @State private var depDiseases: [String] = []
    @State private var depRelations: [String] = []
    private let diseases = ["None","Diabetes","Hypertension","Heart Condition","Thyroid","Other"]

    private let insuranceTypes: [InsuranceTypeInfo] = [
        InsuranceTypeInfo(
            title: "Term Life Insurance",
            description: "Financial protection for your family in case of your untimely demise.",
            cost: "Low",
            coverage: "High sum assured (10-20x income)",
            whoShouldBuy: "Earning individuals with dependents",
            isEssential: true,
            icon: "shield.fill",
            color: Color(hex: "#30D158"),
            deepExplanation: DeepExplanation(
                whatItCovers: "Covers the risk of death. The sum assured is paid to the nominee.",
                useCase: "A breadwinner passes away, and the term plan provides a lump sum to pay off loans and sustain the family's lifestyle.",
                whyImportant: "It's the most cost-effective way to provide a large safety net.",
                pros: ["Very low premium for high coverage", "Tax benefits under 80C", "Pure protection"],
                limitations: ["No maturity benefit", "No survival benefit"]
            )
        ),
        InsuranceTypeInfo(
            title: "Health Insurance",
            description: "Covers medical expenses and hospitalization costs for you and your family.",
            cost: "Medium",
            coverage: "Hospitalization, Daycare, Pre/Post medical",
            whoShouldBuy: "Everyone (Individual or Family)",
            isEssential: true,
            icon: "cross.case.fill",
            color: Color(hex: "#30D158"),
            deepExplanation: DeepExplanation(
                whatItCovers: "Hospital bills, ICU charges, surgeries, and specialized treatments.",
                useCase: "Unexpected hospitalization for surgery costs ₹5 Lakhs; insurance covers the entire bill directly with the hospital.",
                whyImportant: "Medical inflation is rising; one illness can wipe out years of savings.",
                pros: ["Cashless treatment", "Covers ambulance & daycare", "Annual health checkups"],
                limitations: ["Waiting period for pre-existing diseases", "Co-payment in some cases"]
            )
        ),
        InsuranceTypeInfo(
            title: "Personal Accident Insurance",
            description: "Payout for accidental death, disability, or loss of income due to accidents.",
            cost: "Low",
            coverage: "Disability, Accidental death, Fractures",
            whoShouldBuy: "Earning individuals, frequent travelers",
            isEssential: false,
            icon: "bolt.shield.fill",
            color: Color(hex: "#007AFF"),
            deepExplanation: DeepExplanation(
                whatItCovers: "Accidental death, permanent total disability, and partial disability.",
                useCase: "An accident leads to permanent disability, making it impossible to work. The policy pays a lump sum to compensate for income loss.",
                whyImportant: "Accidents can happen anytime and often lead to long-term income loss which health insurance doesn't cover.",
                pros: ["Very affordable", "Global coverage", "Education benefit for children"],
                limitations: ["Only covers accidents, not illnesses", "No maturity benefit"]
            )
        ),
        InsuranceTypeInfo(
            title: "Critical Illness Insurance",
            description: "Lump-sum payout on diagnosis of severe illnesses like Cancer or Heart Attack.",
            cost: "Medium",
            coverage: "Lump-sum for 36+ major illnesses",
            whoShouldBuy: "Breadwinners, people with family history",
            isEssential: false,
            icon: "waveform.path.ecg",
            color: Color(hex: "#007AFF"),
            deepExplanation: DeepExplanation(
                whatItCovers: "Specific critical illnesses defined in the policy (Cancer, Heart Attack, Stroke, etc.).",
                useCase: "A person is diagnosed with cancer. The policy pays ₹20 Lakhs immediately, which can be used for experimental treatment or daily expenses.",
                whyImportant: "Major illnesses require prolonged care and often lead to job loss. A lump sum provides financial freedom during recovery.",
                pros: ["Lump-sum payout on first diagnosis", "Can be used for any purpose", "Tax benefits"],
                limitations: ["Survival period (usually 30 days)", "Waiting period for payout"]
            )
        ),
        InsuranceTypeInfo(
            title: "Motor Insurance",
            description: "Mandatory protection for your vehicle against accidents, theft, and third-party liability.",
            cost: "Medium",
            coverage: "Vehicle damage, Theft, Third-party liability",
            whoShouldBuy: "Vehicle owners",
            isEssential: false,
            icon: "car.fill",
            color: Color(hex: "#007AFF"),
            deepExplanation: DeepExplanation(
                whatItCovers: "Own damage to the vehicle and liability for damage caused to others.",
                useCase: "Your car meets with an accident. The insurance pays for repairs, minus the deductible.",
                whyImportant: "Third-party insurance is legally mandatory. Comprehensive cover protects your asset value.",
                pros: ["Legal compliance", "Protection against theft", "Roadside assistance"],
                limitations: ["Depreciation on parts", "Doesn't cover wear and tear"]
            )
        )
    ]

    private let ageStrategies: [AgeStrategy] = [
        AgeStrategy(range: "Age 20–30", recommendations: ["Term Insurance", "Health Insurance", "Personal Accident Cover"], insight: "Lock in low premiums early and build basic protection.", color: Color(hex: "#30D158"), icon: "person.badge.shield.checkmark"),
        AgeStrategy(range: "Age 30–45", recommendations: ["Increase Term Coverage", "Family Health Insurance", "Add Critical Illness Cover"], insight: "Protect your family and income during peak responsibility years.", color: Color(hex: "#FFCC00"), icon: "person.2.fill"),
        AgeStrategy(range: "Age 45+", recommendations: ["Maintain Health Insurance", "Focus on medical coverage", "Avoid new high-cost term plans"], insight: "Shift focus from growth to health and stability.", color: Color(hex: "#FF3B30"), icon: "person.crop.circle.badge.checkmark")
    ]

    @State private var selectedInsurance: InsuranceTypeInfo?

    var body: some View {
        NavigationStack {
            List {

                if !concerns.isEmpty {
                    Section(header: Text("Action Items").font(.footnote).textCase(.uppercase)) {
                        ForEach(concerns) { ConcernCard(concern: $0)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear).listRowSeparator(.hidden)
                        }
                    }
                }

                // Health credentials
                Section(header: Text("Health Profile").font(.footnote).textCase(.uppercase)) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Details").font(.caption).bold().foregroundStyle(.secondary)
                        HStack(spacing: 12) {
                            HStack {
                                Image(systemName: "person.fill").foregroundStyle(.secondary)
                                TextField("Your Age", text: $myAge).keyboardType(.numberPad).font(.subheadline)
                            }
                            .padding(10).background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            Picker("Condition", selection: $myDisease) {
                                ForEach(diseases, id: \.self) { Text($0) }
                            }.pickerStyle(.menu)
                        }
                    }
                    .padding(.vertical, 4)

                    if adultDependents > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Dependents").font(.caption).bold().foregroundStyle(.secondary)
                            ForEach(0..<adultDependents, id: \.self) { i in
                                HStack(spacing: 8) {
                                    Text("Dep \(i+1)").font(.caption2).foregroundStyle(.secondary).frame(width: 36)
                                    TextField("Age", text: Binding(
                                        get: { depAges.indices.contains(i) ? depAges[i] : "" },
                                        set: { if depAges.indices.contains(i) { depAges[i] = $0 } else { depAges.append($0) } }
                                    )).keyboardType(.numberPad).font(.subheadline)
                                        .padding(8).background(Color(.secondarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 8)).frame(width: 60)
                                    TextField("Relation", text: Binding(
                                        get: { depRelations.indices.contains(i) ? depRelations[i] : "" },
                                        set: { if depRelations.indices.contains(i) { depRelations[i] = $0 } else { depRelations.append($0) } }
                                    )).font(.subheadline)
                                        .padding(8).background(Color(.secondarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    Picker("", selection: Binding(
                                        get: { depDiseases.indices.contains(i) ? depDiseases[i] : "None" },
                                        set: { if depDiseases.indices.contains(i) { depDiseases[i] = $0 } else { depDiseases.append($0) } }
                                    )) { ForEach(diseases, id: \.self) { Text($0) } }.pickerStyle(.menu)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section(header: Text("Insurance Essentials").font(.footnote).textCase(.uppercase)) {
                    ForEach(insuranceTypes) { type in
                        InsuranceCardView(type: type) {
                            selectedInsurance = type
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear).listRowSeparator(.hidden)
                    }
                }

                Section(header: Text("What You Need at Each Stage").font(.footnote).textCase(.uppercase)) {
                    AgeStrategySection(strategies: ageStrategies)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear).listRowSeparator(.hidden)
                }

                Section {
                    Button(action: { dismiss() }) {
                        HStack {
                            Spacer()
                            Text("Explore Insurance Plans").font(.headline).fontWeight(.semibold).foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.vertical, 14).background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
                }
            }
            .listStyle(.plain)
            .background(Color(.systemGroupedBackground).opacity(0.5))
            .navigationTitle("Insurance Recommendations")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedInsurance) { type in
                InsuranceDetailModal(type: type)
            }
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.fontWeight(.semibold) } }
            .onAppear {
                if depAges.count < adultDependents {
                    depAges = Array(repeating: "", count: adultDependents)
                    depDiseases = Array(repeating: "None", count: adultDependents)
                    depRelations = Array(repeating: "", count: adultDependents)
                }
            }
        }
    }
}

// MARK: - Components

struct InsuranceCardView: View {
    let type: InsuranceTypeInfo
    let onInfoTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                HStack(spacing: 12) {
                    Image(systemName: type.icon)
                        .font(.title3)
                        .foregroundStyle(type.color)
                        .frame(width: 44, height: 44)
                        .background(type.color.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(type.title)
                            .font(.headline)
                        Text(type.isEssential ? "Essential" : "Recommended")
                            .font(.caption2).bold()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(type.isEssential ? Color(hex: "#30D158").opacity(0.1) : Color(hex: "#007AFF").opacity(0.1))
                            .foregroundStyle(type.isEssential ? Color(hex: "#30D158") : Color(hex: "#007AFF"))
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
                HighlightRow(title: "Cost", value: type.cost)
                HighlightRow(title: "Coverage", value: type.coverage)
                HighlightRow(title: "Who should buy", value: type.whoShouldBuy)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct HighlightRow: View {
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

struct InsuranceDetailModal: View {
    let type: InsuranceTypeInfo
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 16) {
                            Image(systemName: type.icon)
                                .font(.largeTitle)
                                .foregroundStyle(type.color)
                                .frame(width: 64, height: 64)
                                .background(type.color.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(type.title)
                                    .font(.title2).bold()
                                Text(type.isEssential ? "Essential Protection" : "Recommended Coverage")
                                    .font(.subheadline).foregroundStyle(type.color)
                            }
                        }
                    }
                    .padding(.top, 10)

                    Divider()

                    // Deep Explanation Sections
                    DetailSection(title: "What exactly it covers", content: type.deepExplanation.whatItCovers)
                    DetailSection(title: "Real-life use case", content: type.deepExplanation.useCase, isItalic: true)
                    DetailSection(title: "Why it is important", content: type.deepExplanation.whyImportant)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Pros").font(.headline)
                        ForEach(type.deepExplanation.pros, id: \.self) { pro in
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color(hex: "#30D158"))
                                Text(pro).font(.subheadline)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Limitations").font(.headline)
                        ForEach(type.deepExplanation.limitations, id: \.self) { limit in
                            HStack(spacing: 10) {
                                Image(systemName: "minus.circle.fill").foregroundStyle(.secondary)
                                Text(limit).font(.subheadline)
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(24)
            }
            .navigationTitle("Insurance Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct DetailSection: View {
    let title: String
    let content: String
    var isItalic: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .italic(isItalic)
                .lineSpacing(4)
        }
    }
}

struct AgeStrategySection: View {
    let strategies: [AgeStrategy]

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

// MARK: - Models

struct InsuranceTypeInfo: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let cost: String
    let coverage: String
    let whoShouldBuy: String
    let isEssential: Bool
    let icon: String
    let color: Color
    let deepExplanation: DeepExplanation
}

struct DeepExplanation {
    let whatItCovers: String
    let useCase: String
    let whyImportant: String
    let pros: [String]
    let limitations: [String]
}

struct AgeStrategy: Identifiable {
    let id = UUID()
    let range: String
    let recommendations: [String]
    let insight: String
    let color: Color
    let icon: String
}
