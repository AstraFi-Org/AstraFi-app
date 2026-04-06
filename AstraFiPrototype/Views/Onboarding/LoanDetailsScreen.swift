import SwiftUI
import Charts
internal import UniformTypeIdentifiers

struct LoanDetailsScreen: View {
    @Bindable var data: CompleteAssessmentData
    @State private var goNext      = false
    @State private var showRBIInfo  = false
    @State private var showFilePicker = false
    @State private var uploadedFileName: String? = nil
    @State private var importViewModel = LoanImportViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    StepBadge(current: 3, total: 4, title: "Loan Details", helpText: """
• Simple Interest: Calculated only on the principal amount.

• Compound Interest: Calculated on principal plus accumulated interest.

• Floating Rate: Interest rate that changes with market conditions.

• Moratorium: Period where loan repayments are temporarily paused (interest still accrues).

• Amortization: The process of gradually paying off a loan through scheduled installments that cover both principal and interest.
""")
                        .padding(.top, 16)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)

                    FormCard {
                        CardHeader(icon: "doc.badge.arrow.up.fill", title: "Upload Loan Document")
                        Text("Upload Loan Statement / Sanction Letter for best results. We'll use it to import all loan details securely and reduce manual work.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if importViewModel.isLoading {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .tint(.blue)
                                Text("Parsing Document...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(Color.blue.opacity(0.06))
                            .cornerRadius(14)
                        } else {
                            UploadDropZone(fileName: uploadedFileName) {
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
                                Image(systemName: "banknote.fill")
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
                                    data.loanEntries.insert(AssessmentLoanEntry(), at: 0)
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

                    if data.loanEntries.isEmpty {
                        FormCard {
                            LoanEmptyHint()
                        }
                    } else {
                        ForEach(data.loanEntries) { entry in
                            let safeBinding = Binding<AssessmentLoanEntry>(
                                get: { data.loanEntries.first(where: { $0.id == entry.id }) ?? entry },
                                set: { newValue in
                                    if let idx = data.loanEntries.firstIndex(where: { $0.id == entry.id }) {
                                        data.loanEntries[idx] = newValue
                                    }
                                }
                            )

                            _LoanRow(
                                entry: safeBinding,
                                onRemove: {
                                    data.loanEntries.removeAll(where: { $0.id == entry.id })
                                }
                            )
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
        .navigationDestination(isPresented: $goNext) {
            InsuranceDetailsScreen(data: data)
        }
        .sheet(isPresented: $showRBIInfo) {
            _RBISheet()
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.pdf, .commaSeparatedText, .spreadsheet],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                uploadedFileName = url.lastPathComponent
                Task {
                    await importViewModel.processLoanPDF(at: url)
                }
            }
        }
        .sheet(isPresented: $importViewModel.showReviewList) {
            ParsedLoanListView(
                loans: $importViewModel.parsedLoans,
                onConfirm: {
                    let newEntries = importViewModel.generateImportEntries()
                    withAnimation(.spring) {
                        data.loanEntries.insert(contentsOf: newEntries, at: 0)
                    }
                },
                onCancel: {
                    importViewModel.reset()
                }
            )
        }
    }
}


private struct _LoanRow: View {
    @Binding var entry: AssessmentLoanEntry
    var onRemove: () -> Void

    @State private var showStartDatePicker = false
    @State private var showEMIDatePicker   = false

    var body: some View {
        VStack(spacing: 0) {
            FormCard {
                VStack(alignment: .leading, spacing: 0) {

                    HStack {
                        Text("Loan Details")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)

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
                    .padding(.bottom, 16)

                    VStack(alignment: .leading, spacing: 14) {

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Loan Type")
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
                                    Picker("Loan Type", selection: $entry.type) {
                                        ForEach(AssessmentLoanEntry.LoanType.allCases, id: \.self) { t in
                                            Text(t.rawValue).tag(t)
                                        }
                                    }
                                } label: { Color.white.opacity(0.001) }
                            }
                        }
                        Hint("Knowing the type helps us identify tax-saving or repayment options.")

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Bank / Lender")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            ZStack {
                                HStack {
                                    Text(entry.bank.isEmpty ? "Select Bank" : entry.bank)
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
                                    Picker("Bank", selection: $entry.bank) {
                                        Text("Select Bank").tag("")
                                        Text("SBI").tag("SBI")
                                        Text("HDFC Bank").tag("HDFC Bank")
                                        Text("ICICI Bank").tag("ICICI Bank")
                                        Text("Axis Bank").tag("Axis Bank")
                                        Text("Kotak Mahindra").tag("Kotak Mahindra")
                                        Text("PNB").tag("PNB")
                                        Text("Bank of Baroda").tag("Bank of Baroda")
                                        Text("Yes Bank").tag("Yes Bank")
                                        Text("Other").tag("Other")
                                    }
                                } label: { Color.white.opacity(0.001) }
                            }
                        }
                        Hint("Select the financial institution that provided this loan.")

                        NativeField(
                            label: "Principal Amount (₹)",
                            placeholder: "e.g. 2500000",
                            text: $entry.amount,
                            keyboard: .numberPad
                        )
                        Hint("The original borrowed amount for amortization calculation.")
                    }

                    _LoanSectionDivider(title: "INTEREST & TENURE")

                    VStack(alignment: .leading, spacing: 14) {

                        HStack(spacing: 12) {
                            NativeField(
                                label: "Interest Rate (%)",
                                placeholder: "e.g. 8.5",
                                text: $entry.interestRate,
                                keyboard: .decimalPad
                            )
                            NativeField(
                                label: "Tenure (Years)",
                                placeholder: "e.g. 20",
                                text: $entry.timePeriod,
                                keyboard: .numberPad
                            )
                        }
                        HStack(spacing: 12) {
                            Hint("Helps identify if you can save money by refinancing.")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Hint("Remaining duration helps project your debt-free timeline.")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Interest Type")
                                    .font(.footnote)
                                    .foregroundStyle(.primary)
                                    .tracking(0.4)
                                ZStack {
                                    HStack {
                                        Text(entry.interestType.rawValue)
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
                                        Picker("Interest Type", selection: $entry.interestType) {
                                            ForEach(AstraInterestType.allCases, id: \.self) { t in
                                                Text(t.rawValue).tag(t)
                                            }
                                        }
                                    } label: { Color.white.opacity(0.001) }
                                }
                            }
                            

                            VStack(alignment: .leading, spacing: 5) {
                                Text("Frequency")
                                    .font(.footnote)
                                    .foregroundStyle(.primary)
                                    .tracking(0.4)
                                ZStack {
                                    HStack {
                                        Text(entry.compoundingFrequency.rawValue)
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
                                        Picker("Frequency", selection: $entry.compoundingFrequency) {
                                            ForEach(AstraCompoundingFrequency.allCases, id: \.self) { f in
                                                Text(f.rawValue).tag(f)
                                            }
                                        }
                                    } label: { Color.white.opacity(0.001) }
                                }
                            }
                        }

                        NativeField(
                            label: "Installments Already Paid (EMIs)",
                            placeholder: "e.g. 24",
                            text: $entry.installmentsPaid,
                            keyboard: .numberPad
                        )

                        Text("Remaining tenure will be automatically calculated.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                }
            }

            FormCard {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("EMI Details")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                        Spacer()
                    }
                    .padding(.bottom, 16)

                    VStack(alignment: .leading, spacing: 14) {

                        HStack(spacing: 12) {
                            NativeField(
                                label: "EMI Amount (₹)",
                                placeholder: "Optional",
                                text: $entry.emiAmount,
                                keyboard: .numberPad
                            )
                            VStack(alignment: .leading, spacing: 5) {
                                Text("EMI Frequency")
                                    .font(.footnote)
                                    .foregroundStyle(.primary)
                                    .tracking(0.4)
                                ZStack {
                                    HStack {
                                        Text(entry.emiFrequency.rawValue)
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
                                        Picker("EMI Frequency", selection: $entry.emiFrequency) {
                                            ForEach(AstraEMIFrequency.allCases, id: \.self) { f in
                                                Text(f.rawValue).tag(f)
                                            }
                                        }
                                    } label: { Color.white.opacity(0.001) }
                                }
                            }
                        }

                        HStack(spacing: 12) {
                            _DateButtonField(
                                label: "Loan Start Date",
                                date: $entry.startDate,
                                showPicker: $showStartDatePicker
                            )
                            _DateButtonField(
                                label: "First EMI Date",
                                date: $entry.firstEMIDate,
                                showPicker: $showEMIDatePicker
                            )
                        }
                    }

                    _LoanSectionDivider(title: "RATES & PREPAYMENT")

                    VStack(alignment: .leading, spacing: 14) {

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Floating Interest Rate")
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                            }
                            Spacer()
                            Toggle("", isOn: $entry.isFloatingRate)
                                .labelsHidden()
                                .tint(.blue)
                        }

                        NativeField(
                            label: "Prepayment Penalty (%)",
                            placeholder: "e.g. 2.0",
                            text: $entry.prepaymentPenalty,
                            keyboard: .decimalPad
                        )
                    }

                    _LoanSectionDivider(title: "CHARGES & HIDDEN COSTS")

                    VStack(alignment: .leading, spacing: 14) {

                        HStack(spacing: 12) {
                            NativeField(
                                label: "Processing Fee (₹)",
                                placeholder: "0",
                                text: $entry.processingFee,
                                keyboard: .numberPad
                            )
                            NativeField(
                                label: "Insurance Cost (₹)",
                                placeholder: "0",
                                text: $entry.insuranceCost,
                                keyboard: .numberPad
                            )
                        }

                        HStack(spacing: 12) {
                            NativeField(
                                label: "Late Penalty (₹)",
                                placeholder: "0",
                                text: $entry.latePaymentPenalty,
                                keyboard: .numberPad
                            )
                            NativeField(
                                label: "Other Charges (₹)",
                                placeholder: "0",
                                text: $entry.otherCharges,
                                keyboard: .numberPad
                            )
                        }
                    }

                    _LoanSectionDivider(title: "ADVANCED OPTIONS")

                    VStack(alignment: .leading, spacing: 14) {

                        NativeField(
                            label: "Moratorium Period (Months)",
                            placeholder: "e.g. 6",
                            text: $entry.moratoriumDuration,
                            keyboard: .numberPad
                        )

                        HStack {
                            Text("Track Tax Benefits (80C / Sec 24)")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Toggle("", isOn: $entry.trackTaxBenefits)
                                .labelsHidden()
                                .tint(.blue)
                        }
                    }
                }
            }

            .sheet(isPresented: $showStartDatePicker) {
                DatePickerSheet(title: "Loan Start Date", selection: $entry.startDate)
            }
            .sheet(isPresented: $showEMIDatePicker) {
                DatePickerSheet(title: "First EMI Date", selection: $entry.firstEMIDate)
            }
        }
    }
}

    private struct _LoanSectionDivider: View {
        let title: String
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Divider()
                    .padding(.vertical, 16)
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .tracking(1.0)
                    .padding(.bottom, 14)
            }
        }
    }

    private struct _PickerField<Content: View>: View {
        let label: String
        @ViewBuilder var content: Content

        var body: some View {
            VStack(alignment: .leading, spacing: 5) {
                Text(label)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .tracking(0.4)
                HStack {
                    content
                    Spacer()
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .frame(maxWidth: .infinity)
        }
    }

    private struct _DateButtonField: View {
        let label: String
        @Binding var date: Date
        @Binding var showPicker: Bool

        private static let dateFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .none
            return f
        }()

        var body: some View {
            VStack(alignment: .leading, spacing: 5) {
                Text(label)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .tracking(0.4)
                Button {
                    showPicker = true
                } label: {
                    Text(Self.dateFormatter.string(from: date))
                        .font(.body)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private struct _RBISheet: View {
        @Environment(\.dismiss) private var dismiss

        var body: some View {
            NavigationStack {
                VStack(spacing: 24) {

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .padding(.top, 40)

                    Text("Secure RBI Sync")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("AstraFi connects through Account Aggregator to fetch read-only bank data. No credentials stored.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 30)

                    Spacer()

                    Button("Proceed to Auth (Demo)") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding(20)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
