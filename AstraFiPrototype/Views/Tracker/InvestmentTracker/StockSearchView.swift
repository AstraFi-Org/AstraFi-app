import SwiftUI

struct StockSearchView: View {
    @Environment(\.dismiss) var dismiss
    @State private var stockService = StockService.shared
    
    @Binding var selectedStock: AstraStock?
    var onSelect: (AstraStock) -> Void
    
    @State private var searchText = ""
    @State private var results: [AstraStock] = []
    @State private var isLoading = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search Stocks (e.g. Reliance, TCS)", text: $searchText)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onChange(of: searchText) { _, newValue in
                        performSearch(query: newValue)
                    }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        results = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding()
            
            // Results List
            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if results.isEmpty && !searchText.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No stocks found for '\(searchText)'")
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List(results) { stock in
                    Button {
                        selectedStock = stock
                        onSelect(stock)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(stock.symbol)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(stock.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(stock.currentPrice.toCurrency())
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                
                                Text(String(format: "%@%.2f (%.2f%%)", stock.priceChange >= 0 ? "+" : "", stock.priceChange, stock.priceChangePercentage))
                                    .font(.caption2)
                                    .foregroundColor(stock.priceChange >= 0 ? .green : .red)
                            }
                            
                            Text(stock.exchange)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
            }
        }
        .onAppear {
            isFocused = true
        }
    }
    
    private func performSearch(query: String) {
        if query.count < 2 {
            results = []
            return
        }
        
        isLoading = true
        Task {
            let searchResults = await stockService.searchStocks(query: query)
            
            // Safety check: only proceed if the query matches the current search text
            guard query == searchText else { return }
            
            await MainActor.run {
                self.results = searchResults
                self.isLoading = false
            }
            
            // Fetch live prices for these symbols
            let symbols = searchResults.map { $0.symbol }
            let quotes = await stockService.fetchBatchQuotes(symbols: symbols)
            
            guard query == searchText else { return }
            
            await MainActor.run {
                for i in 0..<self.results.count {
                    let symbol = self.results[i].symbol
                    if let quote = quotes[symbol] {
                        self.results[i].currentPrice = quote.currentPrice
                        self.results[i].priceChange = quote.priceChange
                        self.results[i].priceChangePercentage = quote.priceChangePercentage
                    }
                }
            }
        }
    }
}

#Preview {
    StockSearchView(selectedStock: .constant(nil), onSelect: { _ in })
        .background(AppTheme.auraBeige)
}
