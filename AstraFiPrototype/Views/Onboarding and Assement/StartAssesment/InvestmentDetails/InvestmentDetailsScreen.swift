import SwiftUI
internal import UniformTypeIdentifiers

struct InvestmentDetailsScreen: View {
    @Bindable var data: CompleteAssessmentData
    var onComplete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var goNext        = false
    @State private var selectedFile: String?
    @State private var showFilePicker = false
    @State private var importViewModel = ImportViewModel()
    
    @State private var mfSearchResults: [MFScheme] = []
    @State private var showSuggestions = false
    @State private var showingStockSearch = false
    @State private var activeEntryID: UUID?
    
    @State private var showingBreakdown = false
    @State private var breakdownEntry: AssessmentInvestmentEntry? = nil
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                AssessmentProgressHeader(progress: 0.6, title: "Your Investments", subtitle: "Tell us where you've invested to see your portfolio growth.")
                    .padding(.top, 16).padding(.horizontal, 20).padding(.bottom, 12)
                
                Form {
                    Section(header: Text("Import Investments"), footer: Text("Upload your NSDL/CDSL CAS (PDF) or an Excel export (CSV) to automatically estimate your net worth.")) {
                        if importViewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView("Analyzing Document...")
                                Spacer()
                            }
                        } else {
                            Button {
                                showFilePicker = true
                            } label: {
                                Label(selectedFile ?? "Tap to upload PDF/CSV", systemImage: "doc.badge.arrow.up.fill")
                            }
                            if let error = importViewModel.errorMessage {
                                Text(error).font(.caption).foregroundStyle(.red)
                            }
                        }
                    }
                    
                    Section {
                        Button {
                            withAnimation(.spring()) {
                                data.investmentEntries.insert(AssessmentInvestmentEntry(), at: 0)
                            }
                        } label: {
                            Label("Add Investment Manually", systemImage: "plus.circle.fill")
                        }
                    }
                    
                    if data.investmentEntries.isEmpty {
                        Section {
                            Text("No investments added yet.").foregroundStyle(.secondary)
                        }
                    } else {
                        ForEach($data.investmentEntries) { $entry in
                            Section(header: HStack {
                                Text("Investment Details")
                                Spacer()
                                Button(role: .destructive) {
                                    let idToDelete = entry.id
                                    data.investmentEntries.removeAll(where: { $0.id == idToDelete })
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }) {
                                Picker("Investment Type", selection: $entry.type) {
                                    ForEach(AssessmentInvestmentEntry.InvestmentType.allCases) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                                
                                Picker("Investment Mode", selection: $entry.mode) {
                                    ForEach(AssessmentInvestmentEntry.InvestmentMode.allCases, id: \.self) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }.pickerStyle(.segmented)
                                
                                if entry.type == .stocks {
                                    Button {
                                        activeEntryID = entry.id
                                        showingStockSearch = true
                                    } label: {
                                        HStack {
                                            if let symbol = entry.symbol {
                                                VStack(alignment: .leading) {
                                                    Text(symbol).font(.headline).foregroundColor(.primary)
                                                    Text(entry.fundName).font(.caption).foregroundColor(.secondary)
                                                }
                                            } else {
                                                Text("Search Stock / Company").font(.subheadline).foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            Image(systemName: "magnifyingglass").foregroundColor(.accentColor)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    
                                    HStack {
                                        Text("Qty").font(.subheadline).foregroundColor(.secondary)
                                        TextField("Calculated Shares", text: $entry.quantity)
                                            .keyboardType(.decimalPad)
                                            .disabled(true)
                                            .overlay(alignment: .trailing) {
                                                if !entry.quantity.isEmpty {
                                                    Text("Units")
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                        .padding(.trailing, 8)
                                                }
                                            }
                                    }
                                } else if entry.type == .ppf {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Public Provident Fund (PPF)").font(.headline)
                                        Text("Current Interest Rate: 7.1% (Govt. fixed)")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.vertical, 4)
                                    .onAppear {
                                        entry.fundName = "Public Provident Fund (PPF)"
                                    }
                                } else {
                                    VStack(alignment: .leading, spacing: 0) {
                                        HStack {
                                            Text("Fund Name ")
                                            Spacer()
                                            TextField("Name / Fund", text: $entry.fundName)
                                                .multilineTextAlignment(.trailing)
                                                .frame(width: 150)
                                                .onChange(of: entry.fundName) { _, newValue in
                                                    if entry.type == .mutualFund && !newValue.isEmpty {
                                                        activeEntryID = entry.id
                                                        mfSearchResults = MFService.shared.searchSchemes(query: newValue)
                                                        showSuggestions = !mfSearchResults.isEmpty
                                                    } else {
                                                        showSuggestions = false
                                                    }
                                                }
                                        }
                                        
                                        if showSuggestions && activeEntryID == entry.id && entry.type == .mutualFund {
                                            MFSearchSuggestionsView(results: mfSearchResults) { scheme in
                                                entry.fundName = scheme.name
                                                entry.isin = scheme.isin
                                                entry.schemeCode = scheme.schemeCode
                                                showSuggestions = false
                                                recalculateInvestment(entry: $entry)
                                            }
                                        }
                                    } // closes VStack (fund name)
                                } // closes else (not stocks, not ppf)
                                
                                HStack {
                                    Text("Invested Amount")
                                    Spacer()
                                    TextField("Amount", text: $entry.amount)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 150)
                                        .onChange(of: entry.amount) { _, _ in
                                            recalculateInvestment(entry: $entry)
                                        }
                                }
                                
                                DatePicker("Investment Date", selection: $entry.startDate, displayedComponents: .date)
                                    .onChange(of: entry.startDate) { _, _ in
                                        recalculateInvestment(entry: $entry)
                                    }
                                
                                if entry.mode == .sip {
                                    Picker("SIP Frequency", selection: $entry.frequency) {
                                        ForEach(AssessmentInvestmentEntry.AssessmentSIPFrequency.allCases) { freq in
                                            Text(freq.rawValue).tag(freq)
                                        }
                                    }
                                    .onChange(of: entry.frequency) { _, _ in
                                        recalculateInvestment(entry: $entry)
                                    }
                                }
                                
                                if !entry.amount.isEmpty {
                                    if entry.mode == .sip {
                                        let installmentCount = sipInstallmentCount(startDate: entry.startDate, frequency: entry.frequency)
                                        let sipAmt = Double(entry.amount) ?? 0
                                        let totalInvested = entry.totalInvested ?? (sipAmt * Double(installmentCount))
                                        let currentValue  = entry.currentValue ?? 0
                                        let diff = currentValue - totalInvested
                                        let growthRate = entry.growthRate ?? (totalInvested > 0 ? ((currentValue - totalInvested) / totalInvested) * 100 : 0)
                                        
                                        VStack(alignment: .leading, spacing: 10) {
                                            HStack {
                                                Image(systemName: "arrow.triangle.2.circlepath")
                                                    .foregroundColor(.blue)
                                                Text("SIP Calculation")
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.blue)
                                                Spacer()
                                                Text(entry.frequency.rawValue)
                                                    .font(.caption2)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 3)
                                                    .background(Color.blue.opacity(0.12))
                                                    .foregroundColor(.blue)
                                                    .cornerRadius(6)
                                            }
                                            Divider()
                                            HStack(spacing: 4) {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("SIP Amount").font(.caption).foregroundColor(.secondary)
                                                    Text("₹\(String(format: "%.0f", sipAmt))").fontWeight(.semibold)
                                                }
                                                Text("×").foregroundColor(.secondary).padding(.horizontal, 4)
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("Installments").font(.caption).foregroundColor(.secondary)
                                                    Text("\(installmentCount)").fontWeight(.semibold)
                                                }
                                                Spacer()
                                                VStack(alignment: .trailing, spacing: 2) {
                                                    Text("Total Invested").font(.caption).foregroundColor(.secondary)
                                                    Text("₹\(String(format: "%.0f", totalInvested))").fontWeight(.semibold)
                                                }
                                            }
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("Current Value").font(.caption).foregroundColor(.secondary)
                                                    Text("₹\(String(format: "%.0f", currentValue))").fontWeight(.semibold)
                                                }
                                                Spacer()
                                                VStack(alignment: .trailing, spacing: 2) {
                                                    Text("Gain / Loss").font(.caption).foregroundColor(.secondary)
                                                    Text("\(diff >= 0 ? "+" : "")₹\(String(format: "%.0f", diff)) (\(String(format: "%.2f", growthRate))%)")
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(growthRate >= 0 ? .green : .red)
                                                }
                                            }
                                        }
                                        .font(.subheadline)
                                        .padding(10)
                                        .background(Color.blue.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                        )
                                        .cornerRadius(10)
                                        
                                    } else {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("Total Invested").font(.caption).foregroundColor(.secondary)
                                                    Text("₹\(String(format: "%.0f", entry.totalInvested ?? 0))").fontWeight(.semibold)
                                                }
                                                Spacer()
                                                VStack(alignment: .trailing, spacing: 2) {
                                                    Text("Current Value").font(.caption).foregroundColor(.secondary)
                                                    Text("₹\(String(format: "%.0f", entry.currentValue ?? 0))").fontWeight(.semibold)
                                                }
                                            }
                                            HStack {
                                                Text("Gain/Loss:")
                                                Spacer()
                                                let diff = (entry.currentValue ?? 0) - (entry.totalInvested ?? 0)
                                                Text("\(diff >= 0 ? "+" : "")₹\(String(format: "%.0f", diff)) (\(String(format: "%.2f", entry.growthRate ?? 0))%)")
                                                    .foregroundColor((entry.growthRate ?? 0) >= 0 ? .green : .red)
                                            }
                                        }
                                        .font(.subheadline)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 4)
                                        .background(Color(.secondarySystemBackground).opacity(0.5))
                                        .cornerRadius(8)
                                    } // closes else (lumpsum)
                                } // closes if !entry.amount.isEmpty
                                
                            } // closes Section content
                        } // closes ForEach
                    } // closes else (entries not empty)
                    
                } // closes Form

                AssessmentFooterButton(label: "Continue", enabled: true, isLast: false) {
                    if let onComplete { onComplete() } else { goNext = true }
                }
            } // closes VStack
            
        } // closes ZStack
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
            allowedContentTypes: [UTType.pdf, UTType.commaSeparatedText],
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
                    withAnimation {
                        data.investmentEntries.append(contentsOf: newEntries)
                    }
                },
                onCancel: {
                    importViewModel.reset()
                }
            )
        }
        .sheet(isPresented: $showingStockSearch) {
            StockSearchView(selectedStock: .constant(nil)) { stock in
                if let idx = data.investmentEntries.firstIndex(where: { $0.id == activeEntryID }) {
                    data.investmentEntries[idx].fundName = stock.name
                    data.investmentEntries[idx].symbol = stock.symbol
                    data.investmentEntries[idx].livePrice = stock.currentPrice
                    recalculateInvestment(entry: $data.investmentEntries[idx])
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingBreakdown) {
            if let entry = breakdownEntry {
                InvestmentBreakdownSheet(entry: entry)
            }
        }
    }
    
    
    private func sipInstallmentCount(startDate: Date, frequency: AssessmentInvestmentEntry.AssessmentSIPFrequency) -> Int {
        let today = Date()
        guard startDate <= today else { return 0 }
        let cal = Calendar.current
        
        let component: Calendar.Component
        let divisor: Int
        
        switch frequency {
        case .weekly:
            component = .weekOfYear
            divisor = 1
        case .monthly:
            component = .month
            divisor = 1
        case .quarterly:
            component = .month
            divisor = 3
        case .yearly:
            component = .year
            divisor = 1
        }
        
        let diff = cal.dateComponents([component], from: startDate, to: today).value(for: component) ?? 0
        return max(0, (diff / divisor) + 1)
    }
    
    private func recalculateInvestment(entry: Binding<AssessmentInvestmentEntry>) {
        guard let investedAmount = Double(entry.wrappedValue.amount), investedAmount > 0 else { return }
        let type = entry.wrappedValue.type
        let isSIP = entry.wrappedValue.mode == .sip
        let startDate = entry.wrappedValue.startDate
        
        Task {
            var result: (totalUnits: Double, totalInvested: Double, installments: [AstraInvestmentTransaction]) = (0, 0, [])
            
            if type == .stocks, let symbol = entry.wrappedValue.symbol {
                if isSIP {
                    result = await StockService.shared.calculateHistoricalSIPUnits(symbol: symbol, monthlyAmount: investedAmount, startDate: startDate, frequency: entry.wrappedValue.frequency)
                } else {
                    result = await StockService.shared.calculateLumpsumUnits(symbol: symbol, amount: investedAmount, startDate: startDate)
                }
                let live = await StockService.shared.fetchPrice(symbol: symbol)
                await MainActor.run {
                    entry.wrappedValue.livePrice = live?.currentPrice
                    finalizeCalculation(entry: entry, result: result)
                }
            } else if type == .mutualFund, let isin = entry.wrappedValue.isin {
                if isSIP {
                    result = await MFService.shared.calculateHistoricalSIPUnits(schemeCode: entry.wrappedValue.schemeCode ?? "", monthlyAmount: investedAmount, startDate: startDate, frequency: entry.wrappedValue.frequency)
                } else {
                    if let nav = await MFService.shared.fetchHistoricalNAV(schemeCode: entry.wrappedValue.schemeCode ?? "", date: startDate) {
                        let units = investedAmount / nav
                        let tx = AstraInvestmentTransaction(date: startDate, type: .buy, amount: investedAmount, nav: nav, units: units)
                        result = (units, investedAmount, [tx])
                    } else {
                        result = (0, investedAmount, [])
                    }
                }
                let scheme = MFService.shared.getSchemeByISIN(isin)
                await MainActor.run {
                    entry.wrappedValue.livePrice = scheme?.nav
                    finalizeCalculation(entry: entry, result: result)
                }
            }
        }
    }
    
    private func finalizeCalculation(entry: Binding<AssessmentInvestmentEntry>, result: (totalUnits: Double, totalInvested: Double, installments: [AstraInvestmentTransaction])) {
        entry.wrappedValue.quantity = String(format: "%.4f", result.totalUnits)
        entry.wrappedValue.totalInvested = result.totalInvested
        entry.wrappedValue.transactions = result.installments.map { tx in
            AssessmentInvestmentEntry.AssessmentInvestmentTransaction(
                id: tx.id,
                date: tx.date,
                type: tx.type.rawValue,
                amount: tx.amount,
                nav: tx.nav,
                units: tx.units
            )
        }
        if let live = entry.wrappedValue.livePrice {
            let cv = result.totalUnits * live
            entry.wrappedValue.currentValue = cv
            if result.totalInvested > 0 {
                entry.wrappedValue.growthRate = ((cv - result.totalInvested) / result.totalInvested) * 100
            }
        }
    }
    
    
    //#Preview {
    //    @Previewable var data = CompleteAssessmentData()
    //    NavigationStack {
    //        InvestmentDetailsScreen(data: data)
    //    }
    //}
    
    // MARK: - Supporting Views
    struct MFSearchSuggestionsView: View {
        let results: [MFScheme]
        let onSelect: (MFScheme) -> Void
        
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(results) { scheme in
                        Button {
                            onSelect(scheme)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(scheme.name)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                Text(scheme.isin)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        Divider()
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: 200)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .shadow(radius: 2)
        }
    }
}
