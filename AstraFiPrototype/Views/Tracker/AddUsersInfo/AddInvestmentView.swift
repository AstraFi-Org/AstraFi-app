import SwiftUI

enum InvestmentType: String, CaseIterable, Identifiable, Hashable {
    case mutualFund = "Mutual Fund"
    case stock = "Stocks"
    case goldETF = "Gold ETF"
    case crypto = "Cryptocurrency"
    case fixedDeposit = "Fixed Deposits"
    case physicalGold = "Physical Gold"
    case ppf = "PPF"
    case nps = "NPS"
    case bond = "Bonds"
    case realEstate = "Real Estate"
    case cashSavings = "Cash Savings"
    case emergencyFund = "Emergency Fund"
    case other = "Other"

    var id: String { rawValue }

    var astraType: AstraInvestmentType {
        switch self {
        case .mutualFund: return .mutualFund
        case .stock: return .stocks
        case .goldETF: return .goldETF
        case .crypto: return .cryptocurrency
        case .fixedDeposit: return .deposits
        case .physicalGold: return .physicalGold
        case .ppf: return .ppf
        case .nps: return .nps
        case .bond: return .bonds
        case .realEstate: return .realEstate
        case .cashSavings: return .cashSavings
        case .emergencyFund: return .emergencyFund
        case .other: return .other
        }
    }

    init(_ astraType: AstraInvestmentType) {
        switch astraType {
        case .mutualFund: self = .mutualFund
        case .stocks: self = .stock
        case .goldETF: self = .goldETF
        case .cryptocurrency: self = .crypto
        case .deposits: self = .fixedDeposit
        case .physicalGold: self = .physicalGold
        case .ppf: self = .ppf
        case .nps: self = .nps
        case .bonds: self = .bond
        case .realEstate: self = .realEstate
        case .cashSavings: self = .cashSavings
        case .emergencyFund: self = .emergencyFund
        case .other: self = .other
        }
    }

    var supportsMode: Bool {
        [.mutualFund, .goldETF].contains(self)
    }

    var supportsQuantity: Bool {
        [.stock, .crypto].contains(self)
    }
}

protocol TrackerInvestmentFormModel {
    var name: String { get }
    var investedAmount: Double { get }
    var currentValue: Double { get }
    var startDate: Date { get }
}

struct MutualFundInvestment: TrackerInvestmentFormModel {
    var name: String
    var investedAmount: Double
    var currentValue: Double
    var startDate: Date
    var schemeCode: String?
    var isin: String?
    var units: Double
}

struct StockInvestment: TrackerInvestmentFormModel {
    var name: String
    var investedAmount: Double
    var currentValue: Double
    var startDate: Date
    var symbol: String
    var quantity: Double
}

struct GoldETFInvestment: TrackerInvestmentFormModel {
    var name: String
    var investedAmount: Double
    var currentValue: Double
    var startDate: Date
    var symbol: String
    var units: Double
}

struct CryptoInvestment: TrackerInvestmentFormModel {
    var name: String
    var investedAmount: Double
    var currentValue: Double
    var startDate: Date
    var symbol: String
    var quantity: Double
}

struct FDInvestment: TrackerInvestmentFormModel {
    var name: String
    var investedAmount: Double
    var currentValue: Double
    var startDate: Date
    var interestRate: Double
    var tenureYears: Double
}

struct PhysicalGoldInvestment: TrackerInvestmentFormModel {
    var name: String
    var investedAmount: Double
    var currentValue: Double
    var startDate: Date
    var goldType: String
    var weightGrams: Double
}

struct PPFInvestment: TrackerInvestmentFormModel {
    var name: String
    var investedAmount: Double
    var currentValue: Double
    var startDate: Date
    var monthlyContribution: Double
}

struct NPSInvestment: TrackerInvestmentFormModel {
    var name: String
    var investedAmount: Double
    var currentValue: Double
    var startDate: Date
    var category: String
}

struct BondInvestment: TrackerInvestmentFormModel {
    var name: String
    var investedAmount: Double
    var currentValue: Double
    var startDate: Date
    var couponRate: Double
    var maturityDate: Date
}

struct RealEstateInvestment: TrackerInvestmentFormModel {
    var name: String
    var investedAmount: Double
    var currentValue: Double
    var startDate: Date
}

struct CashSavingsInvestment: TrackerInvestmentFormModel {
    var name: String
    var investedAmount: Double
    var currentValue: Double
    var startDate: Date
    var bankName: String
}

struct EmergencyFundInvestment: TrackerInvestmentFormModel {
    var name: String
    var investedAmount: Double
    var currentValue: Double
    var startDate: Date
    var purpose: String
}

final class InvestmentFormViewModel {
    static let popularGoldETFs: [AstraStock] = [
        AstraStock(symbol: "GOLDBEES.NS", name: "Nippon India ETF Gold BeES", exchange: "NSE", currentPrice: 0, priceChange: 0, priceChangePercentage: 0),
        AstraStock(symbol: "HDFCGOLD.NS", name: "HDFC Gold ETF", exchange: "NSE", currentPrice: 0, priceChange: 0, priceChangePercentage: 0),
        AstraStock(symbol: "SETFGOLD.NS", name: "SBI Gold ETF", exchange: "NSE", currentPrice: 0, priceChange: 0, priceChangePercentage: 0),
        AstraStock(symbol: "IPGETF.NS", name: "ICICI Prudential Gold ETF", exchange: "NSE", currentPrice: 0, priceChange: 0, priceChangePercentage: 0),
        AstraStock(symbol: "KOTAKGOLD.NS", name: "Kotak Gold ETF", exchange: "NSE", currentPrice: 0, priceChange: 0, priceChangePercentage: 0),
        AstraStock(symbol: "AXISGOLD.NS", name: "Axis Gold ETF", exchange: "NSE", currentPrice: 0, priceChange: 0, priceChangePercentage: 0)
    ]

    static let popularCrypto: [AstraStock] = [
        AstraStock(symbol: "BINANCE:BTCUSDT", name: "Bitcoin", exchange: "Binance", currentPrice: 0, priceChange: 0, priceChangePercentage: 0),
        AstraStock(symbol: "BINANCE:ETHUSDT", name: "Ethereum", exchange: "Binance", currentPrice: 0, priceChange: 0, priceChangePercentage: 0),
        AstraStock(symbol: "BINANCE:SOLUSDT", name: "Solana", exchange: "Binance", currentPrice: 0, priceChange: 0, priceChangePercentage: 0),
        AstraStock(symbol: "BINANCE:XRPUSDT", name: "XRP", exchange: "Binance", currentPrice: 0, priceChange: 0, priceChangePercentage: 0)
    ]

    static let popularBanks = ["SBI", "HDFC", "ICICI", "Axis Bank", "Kotak"]
    static let goldTypes = ["24K", "22K", "18K"]
    static let npsCategories = ["Equity (E)", "Corporate Bond (C)", "Government Bond (G)"]
    static let bondTypes = ["Government Bond", "Corporate Bond", "Tax-Free Bond"]

    func maturityValue(principal: Double, annualRate: Double, years: Double) -> Double {
        guard principal > 0, years > 0 else { return principal }
        return principal * pow(1 + annualRate / 100, years)
    }

    func futureValueOfMonthlyContribution(monthly: Double, annualRate: Double, years: Double) -> Double {
        guard monthly > 0, years > 0 else { return 0 }
        let months = max(1, Int((years * 12).rounded()))
        let monthlyRate = annualRate / 100 / 12
        guard monthlyRate > 0 else { return monthly * Double(months) }
        return monthly * ((pow(1 + monthlyRate, Double(months)) - 1) / monthlyRate) * (1 + monthlyRate)
    }
}

struct AddInvestmentView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState

    private let formViewModel = InvestmentFormViewModel()

    @State private var selectedType: InvestmentType = .mutualFund
    @State private var name = ""
    @State private var amount = ""
    @State private var currentValue = ""
    @State private var units = ""
    @State private var mode: AstraInvestmentMode = .sip
    @State private var startDate = Date()
    @State private var selectedGoalID: UUID? = nil

    @State private var searchResults: [MFScheme] = []
    @State private var selectedSchemeCode: String?
    @State private var selectedISIN: String?
    @State private var showSearch = false
    @State private var isCalculatingUnits = false

    @State private var selectedMarketAsset: AstraStock?
    @State private var marketSearchQuery = ""
    @State private var marketSearchResults: [AstraStock] = []
    @State private var showingStockSearch = false
    @State private var isSearchingMarket = false
    @State private var marketSearchTask: Task<Void, Never>?
    @State private var quantity = ""
    @State private var historicalPriceOnDate: Double?
    @State private var isFetchingHistoricalQty = false

    @State private var bankName = "SBI"
    @State private var interestRate = ""
    @State private var tenureYears = ""
    @State private var goldType = "24K"
    @State private var goldWeight = ""
    @State private var npsCategory = "Equity (E)"
    @State private var bondType = "Government Bond"
    @State private var maturityDate = Calendar.current.date(byAdding: .year, value: 5, to: Date()) ?? Date()
    @State private var purpose = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Investment Details")) {
                    Picker("Investment Type", selection: $selectedType) {
                        ForEach(InvestmentType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .onChange(of: selectedType) { _, _ in
                        resetTypeSpecificFields()
                    }

                    dynamicFields
                }

                if let goals = appState.currentProfile?.goals, !goals.isEmpty {
                    Section(header: Text("Link to a Goal (Optional)")) {
                        Picker("Goal", selection: $selectedGoalID) {
                            Text("None").tag(Optional<UUID>(nil))
                            ForEach(goals) { goal in
                                Text(goal.goalName).tag(Optional(goal.id))
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
                    .disabled(!canSave)
                    .tint(canSave ? .blue : .gray)
                }
                .sharedBackgroundVisibility(.visible)
            }
        }
    }

    @ViewBuilder
    private var dynamicFields: some View {
        switch selectedType {
        case .mutualFund:
            mutualFundFields
        case .stock:
            stockFields
        case .goldETF:
            goldETFFields
        case .crypto:
            cryptoFields
        case .fixedDeposit:
            fixedDepositFields
        case .physicalGold:
            physicalGoldFields
        case .ppf:
            ppfFields
        case .nps:
            npsFields
        case .bond:
            bondFields
        case .realEstate:
            realEstateFields
        case .cashSavings:
            cashSavingsFields
        case .emergencyFund:
            emergencyFundFields
        case .other:
            otherFields
        }
    }

    private var mutualFundFields: some View {
        Group {
            searchableMutualFundField
            modePicker
            amountField(mode == .sip ? "Monthly SIP Amount" : "Lumpsum Amount")
                .onChange(of: amount) { _, _ in performMutualFundAutoCalculation() }
            unitsField
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                .onChange(of: startDate) { _, _ in performMutualFundAutoCalculation() }
        }
    }

    private var stockFields: some View {
        Group {
            Button {
                showingStockSearch = true
            } label: {
                selectedMarketAssetRow(placeholder: "Search Stock / Company")
            }
            .sheet(isPresented: $showingStockSearch) {
                StockSearchView(selectedStock: $selectedMarketAsset) { stock in
                    Task { await selectMarketAsset(stock) }
                }
                .presentationDetents([.medium, .large])
            }
            amountField("Total Investment Value")
                .onChange(of: amount) { _, _ in recalculateMarketQuantity() }
            quantityPreview(label: "Qty")
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                .onChange(of: startDate) { _, _ in recalculateMarketQuantity() }
        }
    }

    private var goldETFFields: some View {
        Group {
            marketSearchField(
                title: "Search Gold ETF",
                seeds: InvestmentFormViewModel.popularGoldETFs
            )
            modePicker
            amountField(mode == .sip ? "Monthly SIP Amount" : "Lumpsum Amount")
                .onChange(of: amount) { _, _ in recalculateMarketQuantity() }
            quantityPreview(label: "Units")
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                .onChange(of: startDate) { _, _ in recalculateMarketQuantity() }
        }
    }

    private var cryptoFields: some View {
        Group {
            marketSearchField(
                title: "Search Coin / Symbol",
                seeds: InvestmentFormViewModel.popularCrypto
            )
            amountField("Investment Amount")
                .onChange(of: amount) { _, _ in recalculateMarketQuantity() }
            quantityPreview(label: "Quantity")
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                .onChange(of: startDate) { _, _ in recalculateMarketQuantity() }
        }
    }

    private var fixedDepositFields: some View {
        Group {
            Picker("Bank Name", selection: $bankName) {
                ForEach(InvestmentFormViewModel.popularBanks, id: \.self) { Text($0) }
            }
            TextField("Custom Bank Name", text: $name)
            amountField("Deposit Amount")
            TextField("Interest Rate (%)", text: $interestRate).keyboardType(.decimalPad)
            TextField("Tenure (years)", text: $tenureYears).keyboardType(.decimalPad)
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
            projectionRow("Maturity Value", value: fdMaturityValue)
        }
    }

    private var physicalGoldFields: some View {
        Group {
            Picker("Gold Type", selection: $goldType) {
                ForEach(InvestmentFormViewModel.goldTypes, id: \.self) { Text($0) }
            }
            TextField("Weight (grams)", text: $goldWeight).keyboardType(.decimalPad)
            amountField("Purchase Price")
            TextField("Current Value", text: $currentValue).keyboardType(.decimalPad)
            DatePicker("Purchase Date", selection: $startDate, displayedComponents: .date)
            projectionRow("Total Value", value: physicalGoldCurrentValue)
        }
    }

    private var ppfFields: some View {
        Group {
            rateCard(title: "Current Interest Rate", value: "7.1%")
            amountField("Monthly Contribution")
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
            projectionRow("15Y Maturity Projection", value: ppfMaturityValue)
        }
    }

    private var npsFields: some View {
        Group {
            Picker("Category", selection: $npsCategory) {
                ForEach(InvestmentFormViewModel.npsCategories, id: \.self) { Text($0) }
            }
            amountField("Contribution Amount")
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
            projectionRow("Projected Corpus", value: npsProjectedCorpus)
        }
    }

    private var bondFields: some View {
        Group {
            Picker("Bond Type", selection: $bondType) {
                ForEach(InvestmentFormViewModel.bondTypes, id: \.self) { Text($0) }
            }
            TextField("Bond Name", text: $name)
            TextField("Coupon Rate (%)", text: $interestRate).keyboardType(.decimalPad)
            amountField("Amount")
            DatePicker("Purchase Date", selection: $startDate, displayedComponents: .date)
            DatePicker("Maturity Date", selection: $maturityDate, displayedComponents: .date)
            projectionRow("Maturity Value", value: bondMaturityValue)
        }
    }

    private var realEstateFields: some View {
        Group {
            TextField("Property Name", text: $name)
            amountField("Purchase Price")
            TextField("Current Value", text: $currentValue).keyboardType(.decimalPad)
            DatePicker("Purchase Date", selection: $startDate, displayedComponents: .date)
        }
    }

    private var cashSavingsFields: some View {
        Group {
            amountField("Amount")
            TextField("Bank Name", text: $bankName)
        }
    }

    private var emergencyFundFields: some View {
        Group {
            amountField("Amount")
            TextField("Purpose", text: $purpose)
        }
    }

    private var otherFields: some View {
        Group {
            TextField("Investment Name", text: $name)
            TextField("Current Value", text: $currentValue).keyboardType(.decimalPad)
            TextField("Notes", text: $notes)
        }
    }

    private var searchableMutualFundField: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Fund / Investment Name", text: $name)
                .onChange(of: name) { _, newValue in
                    guard selectedSchemeCode == nil, !newValue.isEmpty else {
                        showSearch = false
                        return
                    }
                    searchResults = MFService.shared.searchSchemes(query: newValue)
                    showSearch = !searchResults.isEmpty
                }

            if let code = selectedSchemeCode {
                HStack(spacing: 8) {
                    badge("Scheme Code: \(code)")
                    if let nav = selectedMutualFundNAV {
                        badge("NAV ₹\(String(format: "%.2f", nav))")
                    }
                }
            }

            if showSearch {
                suggestionsBox {
                    ForEach(searchResults) { scheme in
                        Button {
                            name = scheme.name
                            selectedSchemeCode = scheme.schemeCode
                            selectedISIN = scheme.isin
                            showSearch = false
                            performMutualFundAutoCalculation()
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(scheme.name).font(.subheadline).foregroundColor(.primary)
                                Text("NAV ₹\(String(format: "%.2f", scheme.nav)) • Code \(scheme.schemeCode)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                        }
                        Divider()
                    }
                }
            }
        }
    }

    private func marketSearchField(title: String, seeds: [AstraStock]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if selectedMarketAsset != nil {
                selectedMarketAssetRow(placeholder: title)
            }

            TextField(title, text: $marketSearchQuery)
                .onChange(of: marketSearchQuery) { _, newValue in
                    performMarketSearch(query: newValue, seeds: seeds)
                }
                .onAppear {
                    if marketSearchResults.isEmpty {
                        marketSearchResults = seeds
                    }
                }
                .onDisappear {
                    marketSearchTask?.cancel()
                }

            suggestionsBox {
                if isSearchingMarket {
                    HStack(spacing: 8) {
                        ProgressView().scaleEffect(0.7)
                        Text("Searching live symbols...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
                    Divider()
                }

                ForEach(displayedMarketSearchResults(seeds: seeds)) { asset in
                    Button {
                        Task { await selectMarketAsset(asset) }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(asset.name).font(.subheadline).foregroundColor(.primary)
                                Text(asset.symbol).font(.caption2).foregroundColor(.secondary)
                            }
                            Spacer()
                            let price = displayedMarketPrice(for: asset)
                            if price > 0 {
                                Text("₹\(String(format: "%.2f", price))")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    Divider()
                }

                if let customAsset = customMarketAssetCandidate(existing: displayedMarketSearchResults(seeds: seeds)) {
                    Button {
                        Task { await selectMarketAsset(customAsset) }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Use \(customAsset.symbol)")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Text("Typed symbol • price will be fetched after selection")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private func performMarketSearch(query: String, seeds: [AstraStock]) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        marketSearchTask?.cancel()

        guard !trimmedQuery.isEmpty else {
            isSearchingMarket = false
            marketSearchResults = seeds
            return
        }

        let localMatches = seeds.filter {
            $0.name.localizedCaseInsensitiveContains(trimmedQuery) ||
            $0.symbol.localizedCaseInsensitiveContains(trimmedQuery)
        }
        marketSearchResults = localMatches

        guard trimmedQuery.count >= 2 else { return }

        isSearchingMarket = true
        let type = selectedType
        marketSearchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            let remoteResults: [AstraStock]
            switch type {
            case .goldETF:
                remoteResults = await StockService.shared.searchGoldETFs(query: trimmedQuery)
            case .crypto:
                remoteResults = await StockService.shared.searchCryptoSymbols(query: trimmedQuery)
            default:
                remoteResults = []
            }

            guard !Task.isCancelled else { return }
            await MainActor.run {
                marketSearchResults = mergeMarketResults(localMatches + remoteResults)
                isSearchingMarket = false
            }
        }
    }

    private func displayedMarketSearchResults(seeds: [AstraStock]) -> [AstraStock] {
        let results = marketSearchResults.isEmpty ? seeds : marketSearchResults
        return mergeMarketResults(results)
    }

    private func mergeMarketResults(_ assets: [AstraStock]) -> [AstraStock] {
        var seen = Set<String>()
        var merged: [AstraStock] = []

        for asset in assets {
            let key = asset.symbol.uppercased()
            guard !key.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)
            merged.append(asset)
        }

        return merged
    }

    private func customMarketAssetCandidate(existing: [AstraStock]) -> AstraStock? {
        let raw = marketSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }

        let symbol: String
        let displayName: String
        let exchange: String

        switch selectedType {
        case .goldETF:
            let upper = raw.uppercased()
            symbol = upper.contains(".") ? upper : "\(upper).NS"
            displayName = raw.localizedCaseInsensitiveContains("gold") ? raw : "\(raw) Gold ETF"
            exchange = symbol.hasSuffix(".NS") ? "NSE" : "Market"
        case .crypto:
            let upper = raw.uppercased()
            if upper.hasPrefix("BINANCE:") {
                symbol = upper
            } else if upper.hasSuffix("USDT") {
                symbol = "BINANCE:\(upper)"
            } else {
                symbol = "BINANCE:\(upper)USDT"
            }
            displayName = raw.replacingOccurrences(of: "BINANCE:", with: "", options: .caseInsensitive)
            exchange = "Binance"
        default:
            return nil
        }

        guard !existing.contains(where: { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }) else {
            return nil
        }

        return AstraStock(
            symbol: symbol,
            name: displayName,
            exchange: exchange,
            currentPrice: 0,
            priceChange: 0,
            priceChangePercentage: 0
        )
    }

    private var modePicker: some View {
        Picker("Mode", selection: $mode) {
            Text("SIP (Monthly)").tag(AstraInvestmentMode.sip)
            Text("Lumpsum").tag(AstraInvestmentMode.lumpsum)
        }
        .pickerStyle(.segmented)
        .onChange(of: mode) { _, _ in
            performMutualFundAutoCalculation()
            recalculateMarketQuantity()
        }
    }

    private var unitsField: some View {
        HStack {
            TextField("Units", text: $units)
                .keyboardType(.decimalPad)
            if isCalculatingUnits {
                ProgressView().scaleEffect(0.6)
            }
        }
    }

    private func amountField(_ placeholder: String) -> some View {
        HStack {
            Text("₹")
            TextField(placeholder, text: $amount)
                .keyboardType(.decimalPad)
            if mode == .sip && selectedType.supportsMode {
                Text("/month").foregroundColor(.secondary).font(.caption)
            }
        }
    }

    private func quantityPreview(label: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            if isFetchingHistoricalQty {
                HStack(spacing: 6) {
                    ProgressView().scaleEffect(0.7)
                    Text("Calculating...").foregroundColor(.secondary).font(.caption)
                }
            } else if quantity.isEmpty {
                Text(selectedMarketAsset == nil ? "Select asset first" : "Enter an amount")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(quantity).fontWeight(.medium)
                    if let price = historicalPriceOnDate {
                        Text("@ ₹\(String(format: "%.2f", price))")
                            .foregroundColor(.secondary)
                            .font(.caption2)
                    }
                }
            }
        }
    }

    private func selectedMarketAssetRow(placeholder: String) -> some View {
        HStack {
            if let asset = selectedMarketAsset {
                VStack(alignment: .leading, spacing: 3) {
                    Text(asset.name).font(.headline).foregroundColor(.primary)
                    Text("\(asset.symbol) • \(asset.exchange)").font(.caption).foregroundColor(.secondary)
                }
            } else {
                Text(placeholder).foregroundColor(.secondary)
            }
            Spacer()
            if let asset = selectedMarketAsset, displayedMarketPrice(for: asset) > 0 {
                badge("₹\(String(format: "%.2f", displayedMarketPrice(for: asset)))")
            } else {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private func suggestionsBox<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(.horizontal, 8)
        }
        .frame(maxHeight: 220)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func badge(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.blue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.12), in: Capsule())
    }

    private func rateCard(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).fontWeight(.bold).foregroundColor(.green)
        }
        .padding(.vertical, 4)
    }

    private func projectionRow(_ title: String, value: Double) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value.toCurrency()).fontWeight(.semibold).foregroundColor(.green)
        }
    }

    private var selectedMutualFundNAV: Double? {
        guard let selectedSchemeCode else { return nil }
        return MFService.shared.getScheme(by: selectedSchemeCode)?.nav
    }

    private var fdMaturityValue: Double {
        formViewModel.maturityValue(
            principal: Double(amount) ?? 0,
            annualRate: Double(interestRate) ?? 0,
            years: Double(tenureYears) ?? 0
        )
    }

    private var physicalGoldCurrentValue: Double {
        Double(currentValue) ?? Double(amount) ?? 0
    }

    private var ppfMaturityValue: Double {
        formViewModel.futureValueOfMonthlyContribution(monthly: Double(amount) ?? 0, annualRate: 7.1, years: 15)
    }

    private var npsProjectedCorpus: Double {
        formViewModel.futureValueOfMonthlyContribution(monthly: Double(amount) ?? 0, annualRate: 10, years: 20)
    }

    private var bondMaturityValue: Double {
        let years = max(Calendar.current.dateComponents([.day], from: startDate, to: maturityDate).day.map { Double($0) / 365.0 } ?? 0, 0)
        return formViewModel.maturityValue(
            principal: Double(amount) ?? 0,
            annualRate: Double(interestRate) ?? 0,
            years: years
        )
    }

    private var canSave: Bool {
        switch selectedType {
        case .mutualFund:
            return selectedSchemeCode != nil && (Double(amount) ?? 0) > 0
        case .stock, .goldETF, .crypto:
            return selectedMarketAsset != nil && (Double(amount) ?? 0) > 0
        case .fixedDeposit:
            return (Double(amount) ?? 0) > 0 && !(name.isEmpty && bankName.isEmpty)
        case .physicalGold:
            return (Double(amount) ?? 0) > 0 && (Double(goldWeight) ?? 0) > 0
        case .ppf, .nps:
            return (Double(amount) ?? 0) > 0
        case .bond:
            return !name.isEmpty && (Double(amount) ?? 0) > 0
        case .realEstate:
            return !name.isEmpty && (Double(amount) ?? 0) > 0
        case .cashSavings:
            return (Double(amount) ?? 0) > 0 && !bankName.isEmpty
        case .emergencyFund:
            return (Double(amount) ?? 0) > 0
        case .other:
            return !name.isEmpty && (Double(currentValue) ?? 0) > 0
        }
    }

    private func displayedMarketPrice(for asset: AstraStock) -> Double {
        if selectedMarketAsset?.symbol == asset.symbol {
            return selectedMarketAsset?.currentPrice ?? asset.currentPrice
        }
        return asset.currentPrice
    }

    @MainActor
    private func selectMarketAsset(_ asset: AstraStock) async {
        let priced = await StockService.shared.fetchPrice(symbol: asset.symbol) ?? asset
        selectedMarketAsset = AstraStock(
            symbol: asset.symbol,
            name: selectedType == .crypto ? asset.name : (priced.name.isEmpty ? asset.name : priced.name),
            exchange: priced.exchange.isEmpty ? asset.exchange : priced.exchange,
            currentPrice: priced.currentPrice > 0 ? priced.currentPrice : asset.currentPrice,
            priceChange: priced.priceChange,
            priceChangePercentage: priced.priceChangePercentage
        )
        name = selectedMarketAsset?.name ?? asset.name
        marketSearchQuery = ""
        recalculateMarketQuantity()
    }

    private func resetTypeSpecificFields() {
        name = ""
        amount = ""
        currentValue = ""
        units = ""
        quantity = ""
        selectedSchemeCode = nil
        selectedISIN = nil
        selectedMarketAsset = nil
        searchResults = []
        marketSearchResults = []
        showSearch = false
        marketSearchQuery = ""
        historicalPriceOnDate = nil
        mode = selectedType.supportsMode ? .sip : .lumpsum
        if selectedType == .fixedDeposit { name = bankName }
        if selectedType == .cashSavings { bankName = "" }
    }

    private func saveInvestment() {
        let investedAmount = Double(amount) ?? Double(currentValue) ?? 0
        let staticCurrentValue = resolvedCurrentValue(investedAmount: investedAmount)
        let marketPrice = selectedMarketAsset?.currentPrice ?? historicalPriceOnDate
        let resolvedUnits = Double(units) ?? Double(quantity)

        let investmentName = resolvedInvestmentName
        let effectiveMode: AstraInvestmentMode = selectedType.supportsMode ? mode : (selectedType == .ppf ? .sip : .lumpsum)

        let newInvestment = AstraInvestment(
            id: UUID(),
            investmentType: selectedType.astraType,
            subtype: nil,
            investmentName: investmentName,
            investmentAmount: investedAmount,
            startDate: startDate,
            associatedGoalID: selectedGoalID,
            mode: effectiveMode,
            schemeCode: selectedSchemeCode,
            isin: selectedISIN,
            lastNAV: marketPrice ?? staticCurrentValue,
            lastUpdated: Date(),
            units: resolvedUnits ?? (effectiveMode == .sip && selectedType == .ppf ? elapsedContributionCount : 1),
            purchaseNAV: purchaseNAVForSavedInvestment(investedAmount: investedAmount, units: resolvedUnits),
            symbol: selectedMarketAsset?.symbol,
            quantity: resolvedUnits,
            livePrice: marketPrice ?? staticCurrentValue,
            priceChange: selectedMarketAsset?.priceChange,
            priceChangePercentage: selectedMarketAsset?.priceChangePercentage
        )

        appState.addInvestment(newInvestment)
        dismiss()
    }

    private var resolvedInvestmentName: String {
        switch selectedType {
        case .fixedDeposit:
            return name.isEmpty ? "\(bankName) Fixed Deposit" : name
        case .physicalGold:
            return "\(goldType) Physical Gold"
        case .ppf:
            return "PPF"
        case .nps:
            return "NPS - \(npsCategory)"
        case .bond:
            return name.isEmpty ? bondType : name
        case .cashSavings:
            return "\(bankName) Cash Savings"
        case .emergencyFund:
            return purpose.isEmpty ? "Emergency Fund" : "Emergency Fund - \(purpose)"
        case .other:
            return name
        default:
            return selectedMarketAsset?.name ?? name
        }
    }

    private func resolvedCurrentValue(investedAmount: Double) -> Double {
        switch selectedType {
        case .fixedDeposit:
            return fdMaturityValue > 0 ? min(fdMaturityValue, investedAmount * 10) : investedAmount
        case .physicalGold:
            return physicalGoldCurrentValue
        case .ppf:
            return investedAmount * elapsedContributionCount
        case .nps:
            return investedAmount
        case .bond:
            return investedAmount
        case .realEstate:
            return Double(currentValue) ?? investedAmount
        case .cashSavings, .emergencyFund:
            return investedAmount
        case .other:
            return Double(currentValue) ?? investedAmount
        default:
            return investedAmount
        }
    }

    private var elapsedContributionCount: Double {
        var count = 0
        var date = startDate
        while date <= Date() {
            count += 1
            guard let next = Calendar.current.date(byAdding: .month, value: 1, to: date) else { break }
            date = next
        }
        return Double(max(count, 1))
    }

    private func purchaseNAVForSavedInvestment(investedAmount: Double, units: Double?) -> Double? {
        if let historicalPriceOnDate { return historicalPriceOnDate }
        if let price = selectedMarketAsset?.currentPrice, price > 0 { return price }
        if let units, units > 0 { return investedAmount / units }
        return investedAmount
    }

    private func recalculateMarketQuantity() {
        guard let asset = selectedMarketAsset, let invested = Double(amount), invested > 0 else {
            quantity = ""
            return
        }

        isFetchingHistoricalQty = true
        Task {
            var price: Double?

            if selectedType == .crypto {
                price = await StockService.shared.fetchCryptoINRPrice(symbol: asset.symbol, date: startDate)
            } else if selectedType == .goldETF || selectedType == .stock {
                price = await StockService.shared.fetchHistoricalPrice(symbol: asset.symbol, date: startDate)
            }

            if price == nil || price == 0 {
                price = await StockService.shared.fetchPrice(symbol: asset.symbol)?.currentPrice
            }

            if price == nil || price == 0 {
                price = asset.currentPrice
            }

            await MainActor.run {
                if let price, price > 0 {
                    historicalPriceOnDate = price
                    quantity = selectedType == .crypto ? String(format: "%.6f", invested / price) : String(format: "%.3f", invested / price)
                    if selectedType == .crypto, var current = selectedMarketAsset {
                        current.currentPrice = price
                        selectedMarketAsset = current
                    }
                } else {
                    historicalPriceOnDate = nil
                    quantity = ""
                }
                isFetchingHistoricalQty = false
            }
        }
    }

    private func performMutualFundAutoCalculation() {
        guard selectedType == .mutualFund,
              let code = selectedSchemeCode,
              let invested = Double(amount),
              invested > 0 else { return }

        isCalculatingUnits = true
        Task {
            if mode == .sip {
                let result = await MFService.shared.calculateHistoricalSIPUnits(
                    schemeCode: code,
                    monthlyAmount: invested,
                    startDate: startDate
                )
                await MainActor.run {
                    units = String(format: "%.4f", result.totalUnits)
                    isCalculatingUnits = false
                }
            } else if let nav = await MFService.shared.fetchHistoricalNAV(schemeCode: code, date: startDate) {
                await MainActor.run {
                    units = String(format: "%.4f", invested / nav)
                    historicalPriceOnDate = nav
                    isCalculatingUnits = false
                }
            } else {
                await MainActor.run {
                    isCalculatingUnits = false
                }
            }
        }
    }
}

#Preview {
    AddInvestmentView()
        .environment(AppStateManager.withSampleData())
}
