import SwiftUI
internal import UniformTypeIdentifiers

struct SpendingInsightsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppStateManager.self) var appState

    @State private var rent:          Double = 0
    @State private var groceries:     Double = 0
    @State private var utilities:     Double = 0
    @State private var dining:        Double = 0
    @State private var transport:     Double = 0
    @State private var shopping:      Double = 0
    @State private var entertainment: Double = 0
    @State private var misc:          Double = 0

    @State private var showSuccessAlert = false
    @State private var showingFileImporter = false
    @State private var showUploadOptions = false
    @State private var isProcessingFile = false
    @State private var uploadedFileName: String? = nil
    @State private var extractionSuccessMessage: String? = nil

    private var draftCashflow: CashflowEntry {
        var cf = appState.currentProfile?.cashflowData ?? CashflowEntry()
        cf.rent = rent
        cf.groceries = groceries
        cf.utilities = utilities
        cf.dining = dining
        cf.transport = transport
        cf.shopping = shopping
        cf.entertainment = entertainment
        cf.misc = misc
        
        var sources: [CashflowEntry.DetailedItem] = []
        if rent > 0 { sources.append(.init(name: "House Rent / EMI", amount: rent)) }
        if groceries > 0 { sources.append(.init(name: "Groceries", amount: groceries)) }
        if utilities > 0 { sources.append(.init(name: "Utilities & Bills", amount: utilities)) }
        if dining > 0 { sources.append(.init(name: "Dining & Delivery", amount: dining)) }
        if transport > 0 { sources.append(.init(name: "Transport", amount: transport)) }
        if shopping > 0 { sources.append(.init(name: "Shopping", amount: shopping)) }
        if entertainment > 0 { sources.append(.init(name: "Entertainment", amount: entertainment)) }
        if misc > 0 { sources.append(.init(name: "Other / Misc", amount: misc)) }
        
        if !sources.isEmpty {
            cf.expenseSources = sources
        }
        return cf
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                if draftCashflow.total > 0 {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text("Spending Analysis")
                                .font(.headline)
                        }

                        let topSpent = draftCashflow.breakdown.sorted(by: { $0.1 > $1.1 }).first
                        if let top = topSpent {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your highest expense is \(Text(top.0).fontWeight(.bold)) (\(top.1.toCurrency())).")

                                Text(getAdvice(for: top.0))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                            }
                            .padding()
                            .background(Color.accentColor.opacity(0.05))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(16)
                    .shadow(color: AppTheme.adaptiveShadow, radius: 8)
                }

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 40, height: 40)
                            Image(systemName: "building.columns.fill")
                                .foregroundColor(.blue)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upload Bank Statement")
                                .font(.headline)
                            Text("We'll auto-extract your monthly cashflow")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        if uploadedFileName != nil {
                            Button("Reset") {
                                withAnimation {
                                    uploadedFileName = nil
                                    extractionSuccessMessage = nil
                                    rent = 0; groceries = 0; utilities = 0; dining = 0
                                    transport = 0; shopping = 0; entertainment = 0; misc = 0
                                }
                            }
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        showUploadOptions = true
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                                .background(Color.blue.opacity(0.04))
                                .frame(height: 100)

                            if isProcessingFile {
                                HStack(spacing: 8) {
                                    ProgressView()
                                    Text("Extracting expenses...")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            } else {
                                VStack(spacing: 6) {
                                    Image(systemName: uploadedFileName != nil ? "checkmark.circle.fill" : "doc.badge.plus")
                                        .font(.title2)
                                        .foregroundColor(uploadedFileName != nil ? .green : .blue)
                                    Text(uploadedFileName ?? "Tap to upload PDF or CSV")
                                        .font(.subheadline.bold())
                                        .foregroundColor(uploadedFileName != nil ? .primary : .blue)
                                    if let msg = extractionSuccessMessage {
                                        Text(msg)
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    } else {
                                        Text("PDF or CSV statement supported")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 12)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog("Upload Statement", isPresented: $showUploadOptions, titleVisibility: .visible) {
                        Button("Upload PDF or CSV File") {
                            showingFileImporter = true
                        }
                        Button("Use Sample Statement (Instant Demo)") {
                            loadSampleStatement()
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                    .fileImporter(
                        isPresented: $showingFileImporter,
                        allowedContentTypes: [.pdf, .commaSeparatedText, .plainText],
                        allowsMultipleSelection: false
                    ) { result in
                        switch result {
                        case .success(let urls):
                            if let url = urls.first {
                                processStatement(url: url)
                            }
                        case .failure:
                            break
                        }
                    }
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(16)
                .shadow(color: AppTheme.adaptiveShadow, radius: 8)

                OrDividerLabel(text: "or enter manually")

                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 8) {
                        Image(systemName: "list.bullet.clipboard.fill")
                            .foregroundColor(.green)
                            .font(.subheadline)
                        Text("Monthly Cashflow Breakdown")
                            .font(.headline)
                    }

                    VStack(spacing: 0) {
                        ExpenseRow(icon: "house.fill", label: "House Rent / EMI", color: .purple, value: $rent)
                        Divider().padding(.leading, 50)
                        ExpenseRow(icon: "basket.fill", label: "Groceries", color: .orange, value: $groceries)
                        Divider().padding(.leading, 50)
                        ExpenseRow(icon: "bolt.fill", label: "Utilities & Bills", color: .yellow, value: $utilities)
                        Divider().padding(.leading, 50)
                        ExpenseRow(icon: "fork.knife", label: "Dining & Delivery", color: .red, value: $dining)
                        Divider().padding(.leading, 50)
                        ExpenseRow(icon: "car.fill", label: "Transport", color: .blue, value: $transport)
                        Divider().padding(.leading, 50)
                        ExpenseRow(icon: "cart.fill", label: "Shopping", color: .cyan, value: $shopping)
                        Divider().padding(.leading, 50)
                        ExpenseRow(icon: "popcorn.fill", label: "Entertainment", color: .pink, value: $entertainment)
                        Divider().padding(.leading, 50)
                        ExpenseRow(icon: "ellipsis.circle.fill", label: "Other / Misc", color: .gray, value: $misc)
                    }
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(16)
                .shadow(color: AppTheme.adaptiveShadow, radius: 8)

                Button(action: {
                    appState.updateCashflow(draftCashflow)
                    showSuccessAlert = true
                }) {
                    Text("Save Insights")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .cornerRadius(16)
                        .shadow(color: AppTheme.accentShadow, radius: 10, x: 0, y: 5)
                }
                .padding(.top, 10)
            }
            .padding()
        }
        .navigationTitle("Where You Spend the Most")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.appBackground(for: colorScheme))
        .onAppear {
            if let cf = appState.currentProfile?.cashflowData {
                rent = cf.rent
                groceries = cf.groceries
                utilities = cf.utilities
                dining = cf.dining
                transport = cf.transport
                shopping = cf.shopping
                entertainment = cf.entertainment
                misc = cf.misc
            }
        }
        .alert("Insights Saved", isPresented: $showSuccessAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your monthly spending insights have been updated successfully.")
        }
    }

    private func loadSampleStatement() {
        isProcessingFile = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let res = BankStatementCashflowParser.sampleDummyStatement()
            applyExtractedResult(res, fileName: "Sample_Bank_Statement.pdf")
            isProcessingFile = false
        }
    }

    private func processStatement(url: URL) {
        isProcessingFile = true
        DispatchQueue.global(qos: .userInitiated).async {
            let res = BankStatementCashflowParser.parse(url: url)
            DispatchQueue.main.async {
                applyExtractedResult(res, fileName: url.lastPathComponent)
                isProcessingFile = false
            }
        }
    }

    private func applyExtractedResult(_ res: ExtractedCashflowResult, fileName: String) {
        withAnimation {
            uploadedFileName = fileName
            rent = res.rent
            groceries = res.groceries
            utilities = res.utilities
            dining = res.dining
            transport = res.transport
            shopping = res.shopping
            entertainment = res.entertainment
            misc = res.misc
            extractionSuccessMessage = "Extracted \(res.transactionCount) transactions (\(res.detectedBank))"
        }
    }

    private func getAdvice(for category: String) -> String {
        switch category {
        case "EMIs and Rent":
            return "Housing and EMIs are fixed. If this exceeds 40% of income, consider refinancing your loans or exploring higher downpayments for future assets."
        case "Living Expenses":
            return "Groceries and entertainment are easier to optimize. Try the 50/30/20 rule: 50% Needs, 30% Wants, 20% Savings."
        case "Utilities & Other":
            return "Subscription services and utility bills often have hidden leaks. Review your active plans and cancel unused memberships."
        default:
            return "Regularly tracking your expenses is the first step to financial freedom. Keep categorized logs to find patterns."
        }
    }
}

struct ExpenseRow: View {
    let icon: String
    let label: String
    let color: Color
    @Binding var value: Double

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14))
            }

            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            HStack(spacing: 4) {
                Text("₹").foregroundColor(.secondary)
                TextField("0", value: $value, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .font(.body.monospacedDigit())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
        }
        .padding(.vertical, 12)
    }
}

private struct OrDividerLabel: View {
    let text: String
    var body: some View {
        HStack(spacing: 12) {
            Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1)
            Text(text)
                .font(.footnote).fontWeight(.medium).foregroundStyle(.secondary).fixedSize()
            Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1)
        }
    }
}

#Preview {
    NavigationStack {
        SpendingInsightsView()
            .environment(AppStateManager())
    }
}
