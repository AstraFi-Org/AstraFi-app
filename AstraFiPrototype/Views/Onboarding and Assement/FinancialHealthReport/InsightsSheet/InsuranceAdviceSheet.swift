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

    private var coverTypes: [(String, String, String, Color)] {
        var base: [(String, String, String, Color)] = [
            ("shield.fill","Term Life Insurance","Cover dependents with 10–15× annual income. Ideal for breadwinners.",.blue)
        ]
        let hasDiabetes = myDisease == "Diabetes" || depDiseases.contains("Diabetes")
        let elderDep = depAges.contains { (Int($0) ?? 0) > 60 }
        let parentDep = depRelations.contains { $0.lowercased().contains("father") || $0.lowercased().contains("mother") }
        if elderDep || (parentDep && hasDiabetes) {
            base.append(("heart.text.square.fill","Senior Health Insurance","Strongly recommended given advanced age or pre-existing conditions.",.red))
        } else {
            base.append(("cross.case.fill","Family Health Insurance","A family floater of ₹10–20L covers hospitalisation for the whole family.",.blue))
        }
        base.append(("waveform.path.ecg","Critical Illness Rider","Covers 36+ critical illnesses with a lump-sum payout on diagnosis.",.orange))
        base.append(("person.badge.shield.checkmark.fill","Child Plan","Secures your child's education milestones in your absence.",.purple))
        return base
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "shield.fill")
                            .font(.title2).foregroundStyle(Color(hex: "#30D158"))
                            .frame(width: 52, height: 52).background(Color(hex: "#30D158").opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Insurance Recommendations").font(.title3).bold()
                            Text("Based on \(adultDependents) adult dependent\(adultDependents == 1 ? "" : "s") in your profile")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
                .listRowBackground(Color.clear).listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 16, leading: 20, bottom: 12, trailing: 20))

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

                Section(header: Text("Recommended Plans").font(.footnote).textCase(.uppercase)) {
                    ForEach(coverTypes, id: \.0) { icon, title, desc, color in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: icon).font(.title3).foregroundStyle(color)
                                .frame(width: 44, height: 44).background(color.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(title).font(.headline)
                                Text(desc).font(.subheadline).foregroundStyle(.secondary).lineSpacing(3)
                            }
                        }
                        .padding(.vertical, 6)
                    }
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
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Insurance Recommendations")
            .navigationBarTitleDisplayMode(.inline)
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
