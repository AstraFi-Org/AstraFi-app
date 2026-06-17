import SwiftUI
import _PhotosUI_SwiftUI
import Charts
internal import UniformTypeIdentifiers

struct LoanDetailsScreen: View {
    @Bindable var data: CompleteAssessmentData
    var onComplete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var goNext = false
    @State private var showRBIInfo = false
    @State private var showFilePicker = false
    @State private var showPhotoPicker = false
    @State private var uploadedFileName: String? = nil
    @State private var importViewModel = LoanImportViewModel()
    @State private var selectedItem: PhotosPickerItem? = nil

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                AssessmentProgressHeader(progress: 0.75, title: "Your Liabilities", subtitle: "Add any active loans or EMIs to understand your debt ratio.")
                    .padding(.top, 16).padding(.horizontal, 20).padding(.bottom, 12)

                Form {
                    Section(header: Text("Upload Loan Document"), footer: Text("Upload Loan Statement / Sanction Letter (PDF or Image) for auto-extraction.")) {
                        if importViewModel.isLoading {
                            HStack {
                                Spacer()
                                VStack {
                                    ProgressView()
                                    Text("Extracting Loan Details...")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        } else {
                            Menu {
                                Button {
                                    showFilePicker = true
                                } label: {
                                    Label("Upload PDF", systemImage: "doc.fill")
                                }

                                Button {
                                    showPhotoPicker = true
                                } label: {
                                    Label("Select from Gallery", systemImage: "photo.on.rectangle")
                                }

                            } label: {
                                Label(uploadedFileName ?? "Import from Document/Image", systemImage: "plus.viewfinder")
                                    .fontWeight(.medium)
                            }

                            if let error = importViewModel.errorMessage {
                                Text(error).font(.caption).foregroundStyle(.red)
                            }
                        }
                    }

                    Section {
                        Button {
                            withAnimation(.spring()) {
                                data.loanEntries.insert(AssessmentLoanEntry(), at: 0)
                            }
                        } label: {
                            Label("Add Loan Manually", systemImage: "plus.circle.fill")
                        }
                    }

                    if data.loanEntries.isEmpty {
                        Section {
                            Text("No loans added yet.").foregroundStyle(.secondary)
                        }
                    } else {
                        ForEach($data.loanEntries) { $entry in
                            Section(header: HStack {
                                Text(entry.loanName.isEmpty ? "Loan Details" : entry.loanName)
                                Spacer()
                                Button(role: .destructive) {
                                    let idToDelete = entry.id
                                    data.loanEntries.removeAll(where: { $0.id == idToDelete })
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }) {
                                Picker("Loan Type", selection: $entry.type) {
                                    ForEach(AssessmentLoanEntry.LoanType.allCases) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }

                                if !entry.loanName.isEmpty {
                                    TextField("Scheme Name", text: $entry.loanName)
                                }

                                DatePicker("Loan Sanction Date", selection: $entry.startDate, displayedComponents: .date)
//                                AssessmentField(
//                                    icon: "indianrupeesign",
//                                    label: "Loan Amount",
//                                    placeholder: "e.g. 352000",
//                                    text: $entry.amount,
//                                    keyboard: .numberPad
//                                )
                                HStack{
                                    Text("Loan Amount")
                                    Spacer()
                                    TextField("Loan Amount (₹)", text: $entry.amount)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 150)
                                }
//                                AssessmentField(
//                                    icon: "percent",
//                                    label: "Interest Rate (%)",
//                                    placeholder: "e.g. 7.5",
//                                    text: $entry.interestRate,
//                                    keyboard: .decimalPad
//                                )
                                HStack{
                                    Text("Interest Rate (%)")
                                    Spacer()
                                    TextField("Interest Rate (%)", text: $entry.interestRate)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 150)
                                    
                                }
//                                AssessmentField(
//                                    icon: "calendar",
//                                    label: "Tenure (Months)",
//                                    placeholder: "e.g. 20",
//                                    text: $entry.tenure,
//                                    keyboard: .numberPad
//                                )
                                HStack{
                                    Text("Tenure (Months)")
                                    Spacer()
                                    
                                    TextField("Tenure (Months)", text: $entry.tenure)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 150)
                                }
                                
                                
                                
                                if !entry.moratorium.isEmpty {
//                                    AssessmentField(
//                                        icon: "calendar",
//                                        label: "Moratorium (Months)",
//                                        placeholder: "e.g. 3",
//                                        text: $entry.moratorium,
//                                        keyboard: .numberPad
//                                    )
                                    HStack{
                                        Text("Moratorium (Months)")
                                        Spacer()
                                        TextField("e.g. 5", text: $entry.moratorium)
                                            .keyboardType(.numberPad)
                                            .multilineTextAlignment(.trailing)
                                            .frame(width: 150)
                                    }
                                }

                                if !entry.insurancePremium.isEmpty {
                                    HStack {
                                        Text("Insurance Premium")
                                        Spacer()
                                        TextField("e.g. 2540", text: $entry.insurancePremium)
                                            .keyboardType(.numberPad)
                                            .multilineTextAlignment(.trailing)
                                            .frame(width: 150)
                                    }
                                }

                                Picker("Interest Type", selection: $entry.interestType) {
                                    ForEach(AstraInterestType.allCases, id: \.self) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }

                                Picker("Compounding Frequency", selection: $entry.frequency) {
                                    ForEach(AstraCompoundingFrequency.allCases, id: \.self) { freq in
                                        Text(freq.rawValue).tag(freq)
                                    }
                                }
                            }
                        }
                    }
                    
                }

                AssessmentFooterButton(label: "Continue", enabled: true, isLast: false) {
                    if let onComplete { onComplete() } else { goNext = true }
                }
                .allowsHitTesting(true)
            }
        }
        .navigationTitle("Financial Assessment")
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
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { _, newItem in
            handleGallerySelection(newItem)
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

    // MARK: - Helper Methods

    private func handleGallerySelection(_ item: PhotosPickerItem?) {
        Task {
            if let data = try? await item?.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                uploadedFileName = "Gallery Image"
                await importViewModel.processLoanImage(image)
            }
        }
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
