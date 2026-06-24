import SwiftUI

struct AddGoalView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState

    @State private var goalName = ""
    @State private var targetAmount = ""
    @State private var targetDate = Date().addingTimeInterval(60 * 60 * 24 * 365)

    @State private var linkInvestment = false

    @State private var invName = ""
    @State private var invType: AstraInvestmentType = .mutualFund
    @State private var invMode: AstraInvestmentMode = .sip
    @State private var invAmount = ""
    @State private var invStartDate = Date()
    @State private var manualSavings = ""
    @State private var units = ""
    
    @State private var selectedStock: AstraStock?
    @State private var stockQuantity = ""
    @State private var showingStockSearch = false
    @State private var purchasePrice = ""
    @State private var isFetchingPrice = false
    @State private var isCalculating = false
    @State private var isCalculatingUnits = false
    
    @State private var searchResults: [MFScheme] = []
    @State private var selectedSchemeCode: String?
    @State private var selectedISIN: String?
    @State private var showSearch = false
    
    @State private var linkExisting = false
    @State private var selectedExistingInvestmentIDs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            Form {
                goalSection
                existingInvestmentsSection
                investmentToggleSection
                if linkInvestment { investmentSection }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveGoal) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(goalName.isEmpty || targetAmount.isEmpty || (linkInvestment && (invName.isEmpty || invAmount.isEmpty)) ? .gray : .blue)
                    }
                    .disabled(goalName.isEmpty || targetAmount.isEmpty || (linkInvestment && (invName.isEmpty || invAmount.isEmpty)))
                }
            }
        }
    }

    private func saveGoal() {
        let amount = Double(targetAmount) ?? 0
        let savings = Double(manualSavings) ?? 0
        let newGoal = AstraGoal(id: UUID(), goalName: goalName, targetAmount: amount, currentAmount: 0, manualSavingsContribution: savings, startDate: Date(), targetDate: targetDate)
        appState.addGoal(newGoal)

        // Link existing investments
        if linkExisting {
            for id in selectedExistingInvestmentIDs {
                if var inv = appState.currentProfile?.investments.first(where: { $0.id == id }) {
                    inv.associatedGoalID = newGoal.id
                    appState.updateInvestment(inv)
                }
            }
        }

        if linkInvestment, (!invName.isEmpty || selectedStock != nil), let invAmt = Double(invAmount) {
            let qty = Double(stockQuantity)
            let mfUnits = Double(units)
            let newInv = AstraInvestment(
                id: UUID(),
                investmentType: invType,
                subtype: nil,
                investmentName: invType == .stocks ? (selectedStock?.name ?? invName) : invName,
                investmentAmount: invAmt,
                startDate: invStartDate,
                associatedGoalID: newGoal.id,
                mode: invMode,
                schemeCode: selectedSchemeCode,
                isin: selectedISIN,
                lastNAV: invType == .stocks ? (Double(purchasePrice) ?? selectedStock?.currentPrice) : nil,
                lastUpdated: Date(),
                units: invType == .mutualFund ? mfUnits : qty,
                purchaseNAV: Double(purchasePrice) ?? (invType == .stocks ? ((qty ?? 0) > 0 ? (invAmt / (qty ?? 1)) : 0) : ((mfUnits ?? 0) > 0 ? (invAmt / (mfUnits ?? 1)) : 0)),
                symbol: selectedStock?.symbol,
                quantity: qty,
                livePrice: selectedStock?.currentPrice,
                priceChange: selectedStock?.priceChange,
                priceChangePercentage: selectedStock?.priceChangePercentage
            )
            appState.addInvestment(newInv)
        }
        dismiss()
    }

    private var goalSection: some View {
        Section(header: Text("Goal Details")) {
            TextField("Goal Name (e.g. Dream Car)", text: $goalName)
            HStack {
                Text("₹")
                TextField("Target Amount", text: $targetAmount).keyboardType(.decimalPad)
            }
            DatePicker("Target Date", selection: $targetDate, displayedComponents: .date)
            
            HStack {
                Text("₹")
                TextField("Initial Savings Contribution", text: $manualSavings).keyboardType(.decimalPad)
            }
        }
    }

    private var existingInvestmentsSection: some View {
        Section(header: Text("Link Existing Investments")) {
            Toggle("Link from already added investments", isOn: $linkExisting)
            
            if linkExisting {
                let investments = appState.currentProfile?.investments ?? []
                if investments.isEmpty {
                    Text("No existing investments found.").font(.caption).foregroundColor(.secondary)
                } else {
                    ForEach(investments) { inv in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(inv.investmentName).font(.subheadline).fontWeight(.medium)
                                Text(inv.investmentType.rawValue).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedExistingInvestmentIDs.contains(inv.id) {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.blue)
                            } else {
                                Image(systemName: "circle").foregroundColor(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedExistingInvestmentIDs.contains(inv.id) {
                                selectedExistingInvestmentIDs.remove(inv.id)
                            } else {
                                selectedExistingInvestmentIDs.insert(inv.id)
                            }
                        }
                    }
                }
            }
        }
    }

    private var investmentToggleSection: some View {
        Section(header: Text("Linked Investment")) {
            Toggle("Start an Investment for this Goal", isOn: $linkInvestment)
            if !linkInvestment {
                Text("Link a SIP or Lumpsum investment directly to this goal so your savings are tracked automatically.")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
    }

    private var investmentSection: some View {
        Section(header: Text("Investment Details")) {
            if invType == .stocks {
                Button {
                    showingStockSearch = true
                } label: {
                    HStack {
                        if let stock = selectedStock {
                            VStack(alignment: .leading) {
                                Text(stock.symbol).font(.headline)
                                Text(stock.name).font(.caption).foregroundColor(.secondary)
                            }
                        } else {
                            Text("Search Stock / Company").foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "magnifyingglass")
                    }
                }
                .sheet(isPresented: $showingStockSearch) {
                    StockSearchView(selectedStock: $selectedStock) { stock in
                        Task {
                            let priceData = await StockService.shared.fetchPrice(symbol: stock.symbol)
                            await MainActor.run {
                                let quote = priceData ?? stock
                                selectedStock = quote
                                invName = quote.name
                                let price = quote.currentPrice
                                purchasePrice = String(format: "%.2f", price)
                                if !invAmount.isEmpty {
                                    calculateQtyFromAmount()
                                } else if !stockQuantity.isEmpty {
                                    calculateAmountFromQty()
                                } else {
                                    // Defaults
                                    stockQuantity = "1"
                                    invAmount = String(format: "%.0f", price)
                                }
                            }
                        }
                    }
                    .presentationDetents([.medium, .large])
                }
            } else {
                TextField("Investment / Fund Name", text: $invName)
                    .onChange(of: invName) { _, newValue in
                        if invType == .mutualFund && !newValue.isEmpty && selectedSchemeCode == nil {
                            searchResults = MFService.shared.searchSchemes(query: newValue)
                            showSearch = !searchResults.isEmpty
                        } else {
                            showSearch = false
                        }
                    }
                
                if showSearch && invType == .mutualFund {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(searchResults) { scheme in
                                Button {
                                    invName = scheme.name
                                    selectedSchemeCode = scheme.schemeCode
                                    selectedISIN = scheme.isin
                                    showSearch = false
                                    performAutoCalculation()
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(scheme.name).font(.subheadline).foregroundColor(.primary)
                                        Text("NAV: ₹\(String(format: "%.2f", scheme.nav))")
                                            .font(.caption2).foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                                Divider()
                            }
                        }
                        .padding(.horizontal, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .frame(maxHeight: 150)
                }
            }

            Picker("Investment Type", selection: $invType) {
                ForEach(AstraInvestmentType.allCases, id: \.self) { t in
                    Text(t.rawValue).tag(t)
                }
            }

            if invType == .stocks {
                HStack {
                    Text("Qty")
                    TextField("Number of Shares", text: $stockQuantity)
                        .keyboardType(.decimalPad)
                        .onChange(of: stockQuantity) { _, _ in
                            calculateAmountFromQty()
                        }
                }
            }

            Picker("Mode", selection: $invMode) {
                Text("SIP (Monthly)").tag(AstraInvestmentMode.sip)
                Text("Lumpsum").tag(AstraInvestmentMode.lumpsum)
            }
            .pickerStyle(.segmented)

            HStack {
                Text("₹")
                TextField(invMode == .sip ? "Monthly SIP Amount" : (invType == .stocks ? "Total Investment Value" : "Lumpsum Amount"), text: $invAmount)
                    .keyboardType(.decimalPad)
                    .onChange(of: invAmount) { _, _ in
                        if invType == .stocks {
                            calculateQtyFromAmount()
                        } else if invType == .mutualFund {
                            performAutoCalculation()
                        }
                    }
                if invMode == .sip { Text("/month").foregroundColor(.secondary).font(.caption) }
                if isCalculating || isCalculatingUnits || isFetchingPrice {
                    ProgressView().scaleEffect(0.6)
                }
            }

            DatePicker("Investment Start Date", selection: $invStartDate, displayedComponents: .date)
                .onChange(of: invStartDate) { _, _ in
                    if invType == .stocks {
                        updateHistoricalPrice()
                    } else if invType == .mutualFund {
                        performAutoCalculation()
                    }
                }
        }
    }

    private func calculateAmountFromQty() {
        guard !isCalculating, invType == .stocks, let qty = Double(stockQuantity), let price = Double(purchasePrice) else { return }
        isCalculating = true
        let newAmount = String(format: "%.0f", qty * price)
        if invAmount != newAmount {
            invAmount = newAmount
        }
        isCalculating = false
    }

    private func calculateQtyFromAmount() {
        guard !isCalculating, invType == .stocks, let amt = Double(invAmount), let price = Double(purchasePrice), price > 0 else { return }
        isCalculating = true
        let newQty = String(format: "%.2f", amt / price)
        if stockQuantity != newQty {
            stockQuantity = newQty
        }
        isCalculating = false
    }

    private func updateHistoricalPrice() {
        guard invType == .stocks, let symbol = selectedStock?.symbol else { return }
        isFetchingPrice = true
        Task {
            if invMode == .sip {
                let amt = Double(invAmount) ?? 0
                if amt > 0 {
                    let result = await StockService.shared.calculateHistoricalSIPUnits(symbol: symbol, monthlyAmount: amt, startDate: invStartDate)
                    await MainActor.run {
                        self.stockQuantity = String(format: "%.2f", result.totalUnits)
                        self.isFetchingPrice = false
                    }
                } else {
                    await MainActor.run { self.isFetchingPrice = false }
                }
            } else {
                var price = await StockService.shared.fetchHistoricalPrice(symbol: symbol, date: invStartDate)
                if price == nil {
                    price = await StockService.shared.fetchPrice(symbol: symbol)?.currentPrice
                }
                
                let finalPrice = price
                await MainActor.run {
                    if let price = finalPrice, price > 0 {
                        self.purchasePrice = String(format: "%.2f", price)
                        if !invAmount.isEmpty {
                            calculateQtyFromAmount()
                        }
                    }
                    self.isFetchingPrice = false
                }
            }
        }
    }

    private func performAutoCalculation() {
        guard invType == .mutualFund, let code = selectedSchemeCode, let amt = Double(invAmount), amt > 0 else { return }

        isCalculatingUnits = true
        Task {
            if invMode == .sip {
                let (sipUnits, _, _) = await MFService.shared.calculateHistoricalSIPUnits(
                    schemeCode: code,
                    monthlyAmount: amt,
                    startDate: invStartDate
                )
                await MainActor.run {
                    self.units = String(format: "%.4f", sipUnits)
                    self.isCalculatingUnits = false
                }
            } else {
                if let nav = await MFService.shared.fetchHistoricalNAV(schemeCode: code, date: invStartDate) {
                    await MainActor.run {
                        self.units = String(format: "%.4f", amt / nav)
                        self.isCalculatingUnits = false
                    }
                } else {
                    await MainActor.run {
                        self.isCalculatingUnits = false
                    }
                }
            }
        }
    }
}

#Preview {
    AddGoalView()
        .environment(AppStateManager.withSampleData())
}
