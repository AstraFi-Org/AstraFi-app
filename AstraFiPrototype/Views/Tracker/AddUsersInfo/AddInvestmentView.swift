import SwiftUI

struct AddInvestmentView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState

    @State private var name = ""
    @State private var type: AstraInvestmentType = .mutualFund
    @State private var amount = ""
    @State private var units = ""
    @State private var mode: AstraInvestmentMode = .sip
    @State private var startDate = Date()
    @State private var selectedGoalID: UUID? = nil

    @State private var searchResults: [MFScheme] = []
    @State private var selectedSchemeCode: String?
    @State private var selectedISIN: String?
    @State private var showSearch = false
    @State private var isCalculatingUnits = false
    
    // Stock specific states
    @State private var selectedStock: AstraStock?
    @State private var stockQuantity = ""
    @State private var showingStockSearch = false
    @State private var purchasePrice = ""
    @State private var isFetchingPrice = false
    @State private var isCalculating = false
    @State private var historicalPriceOnDate: Double? = nil
    @State private var isFetchingHistoricalQty = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Investment Details")) {
                    
                    Picker("Investment Type", selection: $type) {
                        ForEach(AstraInvestmentType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if type == .stocks {
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
                                .padding(.vertical, 8)
                            }
                            .sheet(isPresented: $showingStockSearch) {
                                StockSearchView(selectedStock: $selectedStock) { stock in
                                    Task {
                                        let priceData = await StockService.shared.fetchPrice(symbol: stock.symbol)
                                        await MainActor.run {
                                            let quote = priceData ?? stock
                                            selectedStock = quote
                                            name = quote.name
                                            // Reset qty display; will be recalculated from amount + startDate
                                            stockQuantity = ""
                                            historicalPriceOnDate = nil
                                            if amount.isEmpty {
                                                // Pre-fill a default amount so user sees an immediate qty preview
                                                amount = String(format: "%.0f", quote.currentPrice)
                                            }
                                            recalculateStockQty()
                                        }
                                    }
                                }
                                .presentationDetents([.medium, .large])
                            }
                        } else {
                            TextField("Fund / Investment Name", text: $name)
                                .onChange(of: name) { _, newValue in
                                    if type == .mutualFund && !newValue.isEmpty && selectedSchemeCode == nil {
                                        searchResults = MFService.shared.searchSchemes(query: newValue)
                                        showSearch = !searchResults.isEmpty
                                    } else {
                                        showSearch = false
                                    }
                                }

                            if showSearch && type == .mutualFund {
                                ScrollView {
                                    LazyVStack(alignment: .leading, spacing: 10) {
                                        ForEach(searchResults) { scheme in
                                            Button {
                                                name = scheme.name
                                                selectedSchemeCode = scheme.schemeCode
                                                selectedISIN = scheme.isin
                                                showSearch = false
                                            } label: {
                                                VStack(alignment: .leading) {
                                                    Text(scheme.name)
                                                        .font(.subheadline)
                                                        .foregroundColor(.primary)
                                                    Text("NAV: ₹\(String(format: "%.2f", scheme.nav)) | \(scheme.isin)")
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
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
                                .frame(maxHeight: 200)
                            }
                        }
                    }

                    

                    Picker("Mode", selection: $mode) {
                        Text("SIP (Monthly)").tag(AstraInvestmentMode.sip)
                        Text("Lumpsum").tag(AstraInvestmentMode.lumpsum)
                    }
                    .pickerStyle(.segmented)
                    
                    HStack {
                        Text("₹")
                        TextField(mode == .sip ? "Monthly SIP Amount" : (type == .stocks ? "Total Investment Value" : "Lumpsum Amount"), text: $amount)
                            .keyboardType(.decimalPad)
                            .onChange(of: amount) { _, _ in
                                if type == .stocks {
                                    recalculateStockQty()
                                } else if type == .mutualFund {
                                    performAutoCalculation()
                                }
                            }
                        if mode == .sip { Text("/month").foregroundColor(.secondary).font(.caption) }
                    }
                    
                    if type == .stocks {
                        // Read-only Qty: auto-calculated from Amount + Date using historical price
                        HStack {
                            Text("Qty")
                            Spacer()
                            if isFetchingHistoricalQty {
                                HStack(spacing: 6) {
                                    ProgressView().scaleEffect(0.7)
                                    Text("Calculating...")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            } else if stockQuantity.isEmpty {
                                Text(selectedStock == nil ? "Select a stock first" : "Enter an amount")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            } else {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(stockQuantity)
                                        .foregroundColor(.primary)
                                        .fontWeight(.medium)
                                    if let price = historicalPriceOnDate {
                                        Text("@ ₹\(String(format: "%.2f", price)) on date")
                                            .foregroundColor(.secondary)
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                    }

                    

                    if type == .mutualFund {
                        HStack {
                            TextField("Units", text: $units)
                                .keyboardType(.decimalPad)
                            if isCalculatingUnits {
                                ProgressView()
                                    .scaleEffect(0.6)
                            }
                        }
                    }

                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        .onChange(of: startDate) { _, _ in
                            if type == .stocks {
                                recalculateStockQty()
                            } else if type == .mutualFund {
                                performAutoCalculation()
                            }
                        }
                }

                if let goals = appState.currentProfile?.goals, !goals.isEmpty {
                    Section(header: Text("Link to a Goal (Optional)")) {
                        Picker("Goal", selection: $selectedGoalID) {
                            Text("None").tag(Optional<UUID>(nil))
                            ForEach(goals) { g in
                                Text(g.goalName).tag(Optional(g.id))
                            }
                        }
                    }
                }

            }
            .navigationTitle("New Investment")
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
                    Button(action: saveInvestment) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .disabled(name.isEmpty || amount.isEmpty)
                    .tint(
                        name.isEmpty || amount.isEmpty ? Color.gray : Color.blue
                    )
                }
                .sharedBackgroundVisibility(.visible)
            }
        }
    }

    private func saveInvestment() {
        let amt = Double(amount) ?? 0
        let qty = Double(stockQuantity)
        
        let newInv = AstraInvestment(
            id: UUID(),
            investmentType: type,
            subtype: nil,
            investmentName: type == .stocks ? (selectedStock?.name ?? name) : name,
            investmentAmount: amt,
            startDate: startDate,
            associatedGoalID: selectedGoalID,
            mode: mode,
            schemeCode: selectedSchemeCode,
            isin: selectedISIN,
            lastNAV: type == .stocks ? (historicalPriceOnDate ?? selectedStock?.currentPrice) : nil,
            lastUpdated: Date(),
            units: type == .mutualFund ? Double(units) : qty,
            // Bug 3 Fix: for SIP, purchaseNAV is computed after sync (weighted avg).
            // For lumpsum, use the historical price fetched on the start date.
            purchaseNAV: mode == .sip ? nil : (historicalPriceOnDate ?? (qty != nil && (qty ?? 0) > 0 ? (amt / (qty ?? 1)) : nil)),
            symbol: selectedStock?.symbol,
            quantity: qty,
            livePrice: selectedStock?.currentPrice,
            priceChange: selectedStock?.priceChange,
            priceChangePercentage: selectedStock?.priceChangePercentage
        )
        appState.addInvestment(newInv)
        dismiss()
    }

    // MARK: - Stock Qty Auto-Calculation
    // Called whenever amount or startDate changes for stocks.
    // Fetches the historical price on startDate and computes units = amount / price.
    private func recalculateStockQty() {
        guard type == .stocks, let symbol = selectedStock?.symbol, let amt = Double(amount), amt > 0 else {
            stockQuantity = ""
            historicalPriceOnDate = nil
            return
        }
        isFetchingHistoricalQty = true
        Task {
            if mode == .sip {
                // For SIP: sum up units bought each month at historical prices
                let result = await StockService.shared.calculateHistoricalSIPUnits(
                    symbol: symbol,
                    monthlyAmount: amt,
                    startDate: startDate
                )
                await MainActor.run {
                    self.stockQuantity = String(format: "%.2f", result.totalUnits)
                    self.historicalPriceOnDate = nil  // SIP has multiple prices
                    self.isFetchingHistoricalQty = false
                }
            } else {
                // For Lumpsum: fetch price on startDate → units = amount / price
                var price = await StockService.shared.fetchHistoricalPrice(symbol: symbol, date: startDate)
                if price == nil {
                    price = await StockService.shared.fetchPrice(symbol: symbol)?.currentPrice
                }
                await MainActor.run {
                    if let price = price, price > 0 {
                        self.historicalPriceOnDate = price
                        self.purchasePrice = String(format: "%.2f", price)
                        self.stockQuantity = String(format: "%.2f", amt / price)
                    } else {
                        self.stockQuantity = ""
                        self.historicalPriceOnDate = nil
                    }
                    self.isFetchingHistoricalQty = false
                }
            }
        }
    }

    // Kept for internal use (stock search callback still calls these temporarily)
    private func calculateAmountFromQty() {
        guard !isCalculating, type == .stocks, let qty = Double(stockQuantity), let price = Double(purchasePrice) else { return }
        isCalculating = true
        let newAmount = String(format: "%.0f", qty * price)
        if amount != newAmount { amount = newAmount }
        isCalculating = false
    }

    private func calculateQtyFromAmount() {
        guard !isCalculating, type == .stocks, let amt = Double(amount), let price = Double(purchasePrice), price > 0 else { return }
        isCalculating = true
        let newQty = String(format: "%.2f", amt / price)
        if stockQuantity != newQty { stockQuantity = newQty }
        isCalculating = false
    }

    private func performAutoCalculation() {
        guard let code = selectedSchemeCode, let amt = Double(amount), amt > 0 else { return }

        isCalculatingUnits = true
        Task {
            if mode == .sip {
                let (sipUnits, _, _) = await MFService.shared.calculateHistoricalSIPUnits(
                    schemeCode: code,
                    monthlyAmount: amt,
                    startDate: startDate
                )
                await MainActor.run {
                    self.units = String(format: "%.4f", sipUnits)
                    self.isCalculatingUnits = false
                }
            } else {
                if let nav = await MFService.shared.fetchHistoricalNAV(schemeCode: code, date: startDate) {
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
    AddInvestmentView()
        .environment(AppStateManager.withSampleData())
}
