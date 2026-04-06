import SwiftUI
internal import UniformTypeIdentifiers

struct InvestmentDetailsScreen: View {
    @Bindable var data: CompleteAssessmentData
    @Environment(\.dismiss) private var dismiss
    @State private var goNext        = false
    @State private var selectedFile: String?
    @State private var showFilePicker = false
    @State private var importViewModel = ImportViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    StepBadge(current: 2, total: 4, title: "Investments", helpText: """
• Mutual Funds: Professionally managed pools of money investing in stocks/bonds.

• Stocks: Direct ownership in companies.

• Debt Funds/Bonds: Fixed-income investments that act as loans to entities.

• PPF: Long-term tax-free government savings scheme.

• NPS: Voluntary retirement savings scheme.


Modes:
• Lumpsum: One-time single payment.
• SIP: Regular monthly investments.
• SWP: Regular monthly withdrawals.
""")
                        .padding(.top, 16)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)

                    FormCard {
                        CardHeader(icon: "doc.badge.arrow.up.fill", title: "Import Investments")

                        Text("Upload your NSDL/CDSL CAS (PDF) or an Excel export (CSV) to automatically estimate your net worth.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Divider()

                        if importViewModel.isLoading {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .tint(.blue)
                                Text("Analyzing Document...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(Color.blue.opacity(0.06))
                                    .cornerRadius(14)
                        } else {
                            UploadDropZone(fileName: selectedFile) {
                                showFilePicker = true
                            }

                            if let error = importViewModel.errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .padding(.top, 4)
                            }
                        }
                    }

                    OrDivider()

                    FormCard {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(.blue.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "square.and.pencil")
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                            }
                            Text("Manual Entry")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Spacer()
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    data.investmentEntries.insert(AssessmentInvestmentEntry(), at: 0)
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.subheadline)
                                }

                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)

                            }
                        }
                    }

                    if data.investmentEntries.isEmpty {
                        FormCard {
                            EmptyRowHint()
                        }
                    } else {
                        ForEach(data.investmentEntries) { entry in
                            let safeBinding = Binding<AssessmentInvestmentEntry>(
                                get: { data.investmentEntries.first(where: { $0.id == entry.id }) ?? entry },
                                set: { newValue in
                                    if let idx = data.investmentEntries.firstIndex(where: { $0.id == entry.id }) {
                                        data.investmentEntries[idx] = newValue
                                    }
                                }
                            )

                            FormCard {
                                _InvestmentRow(
                                    entry: safeBinding,
                                    onRemove: {
                                        data.investmentEntries.removeAll(where: { $0.id == entry.id })
                                    }
                                )
                            }
                        }
                    }

                    Spacer().frame(height: 90)
                }
            }

            SingleNavFooter(isLast: false) {
                goNext = true
            }
        }
        .navigationTitle("Financial Assessment")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
        }
        .navigationDestination(isPresented: $goNext) {
            LoanDetailsScreen(data: data)
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.pdf, .commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                selectedFile = url.lastPathComponent
                Task {
                    await importViewModel.processPDF(at: url)
                }
            }
        }
        .sheet(isPresented: $importViewModel.showReviewList) {
            ParsedInvestmentListView(
                investments: $importViewModel.parsedInvestments,
                onConfirm: {
                    let newEntries = importViewModel.generateImportEntries()
                    withAnimation(.spring) {
                        data.investmentEntries.insert(contentsOf: newEntries, at: 0)
                    }
                },
                onCancel: {
                    importViewModel.reset()
                }
            )
        }
    }
}


private struct _InvestmentRow: View {
    @Binding var entry: AssessmentInvestmentEntry
    var onRemove: () -> Void

    @State private var searchResults: [MFScheme] = []
    @State private var showSearch = false

    private let green = Color.blue

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                Text("Investment Details")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(green)

                Spacer()

                Button(action: onRemove) {
                    Image(systemName: "trash.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red.opacity(0.75))
                        .padding(8)
                        .background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }

            VStack(spacing: 16) {

                VStack(alignment: .leading, spacing: 6) {
                    Text("Investment Type")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    ZStack {

                        HStack {
                            Text(entry.type.rawValue)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        Menu {
                            Picker("Type", selection: $entry.type) {
                                ForEach(AssessmentInvestmentEntry.InvestmentType.allCases, id: \.self) { t in
                                    Text(t.rawValue).tag(t)
                                }
                            }
                        } label: { Color.white.opacity(0.001) }
                    }
                    Hint("Helps us understand your asset allocation and risk profile.")
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Investment Mode")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Picker("Mode", selection: $entry.mode) {
                        ForEach(AssessmentInvestmentEntry.InvestmentMode.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                    Hint("SIP for regular growth, Lumpsum for one-time capital.")
                }

                VStack(alignment: .leading, spacing: 6) {
                    NativeField(
                        label: "Name / Fund",
                        placeholder: "e.g. Parag Parikh Flexi Cap",
                        text: $entry.fundName
                    )
                    .onChange(of: entry.fundName) { _, newValue in
                        if entry.type == .mutualFund && !newValue.isEmpty && entry.schemeCode == nil {
                            searchResults = MFService.shared.searchSchemes(query: newValue)
                            showSearch = !searchResults.isEmpty
                        } else {
                            showSearch = false
                        }
                    }
                    Hint("Specific fund names help in tracking performance accurately.")

                    if showSearch && entry.type == .mutualFund {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(searchResults) { scheme in
                                    Button {
                                        entry.fundName = scheme.name
                                        entry.schemeCode = scheme.schemeCode
                                        entry.isin = scheme.isin
                                        showSearch = false
                                    } label: {
                                        VStack(alignment: .leading) {
                                            Text(scheme.name)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                            Text("NAV: ₹\(String(format: "%.2f", scheme.nav)) | \(scheme.isin)")
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    Divider()
                                }
                            }
                            .padding(.horizontal, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .frame(maxHeight: 150)
                        .transition(.opacity)
                    }
                }

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        NativeField(
                            label: "Invested (₹)",
                            placeholder: "e.g. 50000",
                            text: $entry.amount,
                            keyboard: .numberPad
                        )
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 6) {
                        NativeField(
                            label: "Total Units",
                            placeholder: "e.g. 2.4110",
                            text: $entry.units,
                            keyboard: .decimalPad
                        )
                    }
                    .frame(maxWidth: .infinity)
                }

                if let code = entry.schemeCode, let scheme = MFService.shared.getScheme(by: code), let unitsNum = Double(entry.units) {
                    let cv = unitsNum * scheme.nav
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Real-time Valuation")
                                .font(.system(size: 10))
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                            Spacer()
                            Text("NAV: ₹\(String(format: "%.2f", scheme.nav))")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        
                        Text("₹\(String(format: "%.2f", cv))")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                    }
                    .padding(10)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(10)
                }

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Start Date")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        DatePicker(
                            "",
                            selection: $entry.startDate,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .tint(green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 6) {
                        NativeField(
                            label: "ISIN",
                            placeholder: "e.g. INF205K01MV6",
                            text: Binding(
                                get: { entry.isin ?? "" },
                                set: { entry.isin = $0 }
                            )
                        )
                    }
                    .frame(maxWidth: .infinity)
                }

                NativeField(
                    label: "Associated Goal (Optional)",
                    placeholder: "e.g. Retirement, Home Purchase",
                    text: $entry.associatedGoal
                )
            }
        }
    }
}
