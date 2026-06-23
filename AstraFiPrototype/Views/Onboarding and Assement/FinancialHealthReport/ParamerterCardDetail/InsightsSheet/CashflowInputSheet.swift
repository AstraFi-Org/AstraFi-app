//
//  CashflowInputSheet.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI
import _PhotosUI_SwiftUI

struct CashflowInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var cashflow: CashflowEntry
    @State private var draft: CashflowEntry = CashflowEntry()
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var uploadedFileName: String? = nil

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "building.columns.fill").font(.subheadline).foregroundStyle(.blue)
                                .frame(width: 36, height: 36).background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Upload Bank Statement").font(.subheadline).bold()
                                Text("Auto-extract your monthly cashflow").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        PhotosPicker(selection: $photoItem, matching: .any(of: [.images])) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.blue.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6,4]))
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.04)))
                                    .frame(height: 72)
                                VStack(spacing: 5) {
                                    Image(systemName: uploadedFileName != nil ? "checkmark.circle.fill" : "arrow.up.doc.fill")
                                        .font(.title3).foregroundStyle(.blue)
                                    Text(uploadedFileName ?? "Tap to upload PDF or CSV")
                                        .font(.subheadline).foregroundStyle(.blue)
                                }
                            }
                        }
                        .onChange(of: photoItem) { _, newItem in
                            if newItem != nil { uploadedFileName = "statement_\(Int.random(in: 1000...9999)).pdf" }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("Monthly Cashflow — Manual Entry").font(.footnote).textCase(.uppercase)) {
                    ForEach(cashflowRows, id: \.1) { icon, label, kp, color in
                        HStack(spacing: 12) {
                            Image(systemName: icon).font(.subheadline).foregroundStyle(color)
                                .frame(width: 28, height: 28).background(color.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                            Text(label).font(.subheadline)
                            Spacer()
                            HStack(spacing: 3) {
                                Text("₹").font(.subheadline).foregroundStyle(.secondary)
                                TextField("0", value: Binding(
                                    get: { draft[keyPath: kp] },
                                    set: { draft[keyPath: kp] = $0 }
                                ), format: .number).keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing).frame(width: 90)
                                    .font(.subheadline).bold()
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                if draft.total > 0 {
                    Section {
                        HStack {
                            Text("Estimated Monthly Total").font(.subheadline).foregroundStyle(.secondary)
                            Spacer()
                            Text("₹\(draft.total.safeInt.formatted())").font(.headline).bold().foregroundStyle(.blue)
                        }
                    }
                }

                Section {
                    Button(action: { cashflow = draft; dismiss() }) {
                        HStack {
                            Spacer()
                            Text(draft.total > 0 ? "Calculate & Update Report" : "Save & Continue")
                                .font(.headline).bold().foregroundStyle(.white)
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
            .navigationTitle("Where You Spend the Most")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
            }
            .onAppear { draft = cashflow }
        }
    }

    private typealias CF = CashflowEntry
    private var cashflowRows: [(String, String, WritableKeyPath<CF, Double>, Color)] {[
        ("house.fill",           "House Rent / EMI",  \CF.rent,          .indigo),
        ("basket.fill",          "Groceries",          \CF.groceries,     .green),
        ("bolt.fill",            "Utilities & Bills",  \CF.utilities,     .yellow),
        ("fork.knife",           "Dining & Delivery",  \CF.dining,        .orange),
        ("car.fill",             "Transport",          \CF.transport,     .blue),
        ("cart.fill",            "Shopping",           \CF.shopping,      .cyan),
        ("popcorn.fill",         "Entertainment",      \CF.entertainment, .pink),
        ("ellipsis.circle.fill", "Other / Misc",       \CF.misc,          .gray),
    ]}
}
#Preview {
    CashflowInputSheet(cashflow: .constant(CashflowEntry()))
}
