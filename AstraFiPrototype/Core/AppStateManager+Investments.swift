import Foundation
import SwiftUI
import Supabase
import AuthenticationServices
import CryptoKit

extension AppStateManager {
        func addInvestment(_ investment: AstraInvestment) {
            if var profile = currentProfile {
                profile.investments.append(investment)
                currentProfile = profile
                recalculateFinancials()
                Task {
                    await syncMutualFundNAVs()
                    if let session = try? await supabase.auth.session {
                        try? await SupabaseRepository.shared.saveInvestment(investment, userId: session.user.id)
                    }
                }
            }
        }
        func updateInvestment(_ investment: AstraInvestment) {
            if var profile = currentProfile,
               let index = profile.investments.firstIndex(where: { $0.id == investment.id }) {
                profile.investments[index] = investment
                currentProfile = profile
                recalculateFinancials()
                Task {
                    await syncMutualFundNAVs(force: true)
                    if let session = try? await supabase.auth.session {
                        try? await SupabaseRepository.shared.saveInvestment(investment, userId: session.user.id)
                    }
                }
            }
        }
        func syncUpstoxHoldings(
            _ holdings: [UpstoxHolding],
            mutualFunds: [UpstoxMutualFundHolding] = [],
            mutualFundOrders: [UpstoxMutualFundOrder] = [],
            mutualFundSIPs: [UpstoxMutualFundSIP] = []
        ) {
            guard var profile = currentProfile else { return }
            
            let manualInvestments = profile.investments.filter { $0.brokerSource != "Upstox" }
            let existingUpstoxInvestments = Dictionary(
                profile.investments
                    .filter { $0.brokerSource == "Upstox" }
                    .compactMap { investment in
                        investment.brokerInstrumentID.map { ($0, investment) }
                    },
                uniquingKeysWith: { first, _ in first }
            )
            let connectedStockInvestments = holdings
                .filter { $0.quantity > 0 }
                .map { holding in
                    return AstraInvestment(
                        id: existingUpstoxInvestments[holding.id]?.id ?? UUID(),
                        investmentType: .stocks,
                        subtype: .largeCap,
                        investmentName: holding.displayName,
                        investmentAmount: holding.investedAmount.safeFinite,
                        startDate: existingUpstoxInvestments[holding.id]?.startDate ?? Date(),
                        mode: .lumpsum,
                        isin: holding.isin,
                        symbol: holding.tradingSymbol,
                        quantity: holding.quantity.safeFinite,
                        livePrice: holding.currentPrice.safeFinite,
                        priceChange: holding.dayChange.safeFinite,
                        priceChangePercentage: holding.dayChangePercentage.safeFinite,
                        brokerSource: "Upstox",
                        brokerInstrumentID: holding.id
                    )
                }
            let connectedMutualFundInvestments = mutualFunds
                .filter { $0.quantity > 0 }
                .map { holding in
                    let matchedOrders = mutualFundOrders
                        .filter { order in
                            order.isCompleted && mutualFundRecord(
                                instrumentKey: order.instrumentKey,
                                folio: order.folio,
                                matches: holding
                            )
                        }
                        .sorted { ($0.transactionDate ?? .distantPast) < ($1.transactionDate ?? .distantPast) }
                    let matchedSIP = mutualFundSIPs.first { sip in
                        normalizedUpstoxKey(sip.instrumentKey) == normalizedUpstoxKey(holding.instrumentKey)
                    }
                    let isSIP = matchedSIP != nil || matchedOrders.contains(where: \.isSIP)
                    let installments = matchedOrders.compactMap { order -> AstraInvestmentTransaction? in
                        guard let date = order.transactionDate else { return nil }
                        let nav = order.executedNAV.safeFinite
                        let amount = order.amount > 0 ? order.amount.safeFinite : (order.quantity * nav).safeFinite
                        return AstraInvestmentTransaction(
                            date: date,
                            type: order.transactionType?.uppercased() == "SELL" ? .sell : .buy,
                            amount: amount,
                            nav: nav,
                            units: order.quantity.safeFinite
                        )
                    }
                    let startDate = matchedSIP?.createdDate
                    ?? installments.first?.date
                    ?? existingUpstoxInvestments[holding.id]?.startDate
                    ?? Date()
                    let recurringAmount = matchedSIP?.instalmentAmount
                    ?? matchedOrders.last(where: { $0.isSIP && $0.transactionType?.uppercased() == "BUY" })?.amount
                    
                    return AstraInvestment(
                        id: existingUpstoxInvestments[holding.id]?.id ?? UUID(),
                        investmentType: .mutualFund,
                        subtype: .equityFund,
                        investmentName: holding.displayName,
                        investmentAmount: (isSIP ? (recurringAmount ?? holding.investedAmount) : holding.investedAmount).safeFinite,
                        startDate: startDate,
                        mode: isSIP ? .sip : .lumpsum,
                        isin: holding.instrumentKey,
                        lastNAV: holding.lastPrice.safeFinite,
                        lastUpdated: Date(),
                        units: holding.quantity.safeFinite,
                        purchaseNAV: holding.averagePrice.safeFinite,
                        livePrice: holding.lastPrice.safeFinite,
                        priceChange: holding.pnl.safeFinite,
                        brokerSource: "Upstox",
                        brokerInstrumentID: holding.id,
                        installments: installments
                    )
                }
            
            profile.investments = manualInvestments + connectedStockInvestments + connectedMutualFundInvestments
            currentProfile = profile
            recalculateFinancials()
        }
        private func normalizedUpstoxKey(_ value: String?) -> String {
            value?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased() ?? ""
        }
        private func mutualFundRecord(
            instrumentKey: String?,
            folio: String?,
            matches holding: UpstoxMutualFundHolding
        ) -> Bool {
            guard normalizedUpstoxKey(instrumentKey) == normalizedUpstoxKey(holding.instrumentKey) else {
                return false
            }
            
            let orderFolio = normalizedUpstoxKey(folio)
            let holdingFolio = normalizedUpstoxKey(holding.folio)
            return orderFolio.isEmpty || holdingFolio.isEmpty || orderFolio == holdingFolio
        }
        func removeUpstoxHoldings() {
            guard var profile = currentProfile else { return }
            profile.investments.removeAll { $0.brokerSource == "Upstox" }
            currentProfile = profile
            recalculateFinancials()
        }
        func deleteInvestment(at indexSet: IndexSet) {
            if var profile = currentProfile {
                let toDelete = indexSet.map { profile.investments[$0] }
                profile.investments.remove(atOffsets: indexSet)
                currentProfile = profile
                recalculateFinancials()
                Task {
                    for inv in toDelete {
                        try? await SupabaseRepository.shared.deleteInvestment(inv.id)
                    }
                }
            }
        }
        func deleteInvestment(_ investment: AstraInvestment) {
            if var profile = currentProfile,
               let index = profile.investments.firstIndex(where: { $0.id == investment.id }) {
                profile.investments.remove(at: index)
                currentProfile = profile
                recalculateFinancials()
                Task {
                    try? await SupabaseRepository.shared.deleteInvestment(investment.id)
                }
            }
        }
        func updateEmergencyFundAllocation(_ allocation: AstraEmergencyFundAllocation) {
            if var profile = currentProfile {
                profile.emergencyFundAllocation = allocation
                currentProfile = profile
                Task {
                    if let session = try? await supabase.auth.session {
                        try? await SupabaseRepository.shared.saveEmergencyFundAllocation(allocation, userId: session.user.id)
                    }
                }
            }
        }
        func syncMutualFundNAVs(force: Bool = false) async {
            guard !isSyncing else { return }
            isSyncing = true
            
            defer { isSyncing = false }
            
            await mfService.fetchMFData(force: force)
            
            guard var profile = currentProfile else { return }
            var updated = false
            
            // Update Stock Prices
            let marketTypes: Set<AstraInvestmentType> = [.stocks, .goldETF, .cryptocurrency]
            let stockSymbols = profile.investments.compactMap { marketTypes.contains($0.investmentType) ? $0.symbol : nil }
            if !stockSymbols.isEmpty {
                let stockPrices = await StockService.shared.fetchLivePrices(symbols: stockSymbols)
                for i in 0..<profile.investments.count {
                    if marketTypes.contains(profile.investments[i].investmentType),
                       let symbol = profile.investments[i].symbol,
                       let price = stockPrices[symbol] {
                        profile.investments[i].livePrice = price
                        profile.investments[i].lastNAV = price
                        profile.investments[i].lastUpdated = Date()
                        updated = true
                    }
                }
            }
            
            for i in 0..<profile.investments.count {
                let inv = profile.investments[i]
                
                // 1. Update Market Price/NAV
                if inv.investmentType == .mutualFund {
                    if inv.schemeCode == nil {
                        if let code = mfService.findSchemeCode(for: inv.investmentName) {
                            profile.investments[i].schemeCode = code
                        }
                    }
                    
                    guard let code = profile.investments[i].schemeCode else { continue }
                    
                    if let liveScheme = mfService.getScheme(by: code) {
                        profile.investments[i].lastNAV = liveScheme.nav
                        profile.investments[i].lastUpdated = Date()
                        updated = true
                    }
                    
                    let expectedCount: Int = {
                        let cal = Calendar.current
                        var count = 0
                        var d = inv.startDate
                        let today = Date()
                        while d <= today {
                            count += 1
                            guard let next = cal.date(byAdding: .month, value: 1, to: d) else { break }
                            d = next
                        }
                        return count
                    }()
                    let actualCount = profile.investments[i].installments.count
                    let needsRecalc = profile.investments[i].installments.isEmpty || (inv.mode == .sip && actualCount < expectedCount)
                    
                    if needsRecalc {
                        if inv.mode == .sip {
                            let (sipUnits, _, simulatedInstallments) = await mfService.calculateHistoricalSIPUnits(
                                schemeCode: code,
                                monthlyAmount: inv.investmentAmount,
                                startDate: inv.startDate
                            )
                            profile.investments[i].installments = simulatedInstallments
                            profile.investments[i].units = sipUnits
                            // Recalculate weighted-average purchase NAV
                            let totalPaid = simulatedInstallments.reduce(0.0) { $0 + $1.amount }
                            let totalUnits2 = simulatedInstallments.reduce(0.0) { $0 + $1.units }
                            if totalUnits2 > 0 {
                                profile.investments[i].purchaseNAV = totalPaid / totalUnits2
                            }
                            updated = true
                        } else {
                            // Lumpsum
                            if let histNAV = await mfService.fetchHistoricalNAV(schemeCode: code, date: inv.startDate) {
                                let units = inv.investmentAmount / histNAV
                                profile.investments[i].installments = [
                                    AstraInvestmentTransaction(date: inv.startDate, type: .buy, amount: inv.investmentAmount, nav: histNAV, units: units)
                                ]
                                profile.investments[i].units = units
                                profile.investments[i].purchaseNAV = histNAV
                                updated = true
                            }
                        }
                    }
                } else if marketTypes.contains(inv.investmentType) {
                    guard let symbol = inv.symbol else { continue }
                    
                    let expectedCount: Int = {
                        guard inv.mode == .sip else { return 1 }
                        let cal = Calendar.current
                        var count = 0
                        var d = inv.startDate
                        let today = Date()
                        while d <= today {
                            count += 1
                            guard let next = cal.date(byAdding: .month, value: 1, to: d) else { break }
                            d = next
                        }
                        return max(count, 1)
                    }()
                    let needsRecalc = profile.investments[i].installments.isEmpty || (inv.mode == .sip && profile.investments[i].installments.count < expectedCount)
                    
                    // Populate Missing Installments for Stocks, Gold ETFs, and Crypto
                    if needsRecalc {
                        if inv.mode == .sip {
                            let (sipUnits, _, simulatedInstallments) = await StockService.shared.calculateHistoricalSIPUnits(
                                symbol: symbol,
                                monthlyAmount: inv.investmentAmount,
                                startDate: inv.startDate
                            )
                            profile.investments[i].installments = simulatedInstallments
                            profile.investments[i].quantity = sipUnits
                            
                            let totalPaid = simulatedInstallments.reduce(0.0) { $0 + $1.amount }
                            let totalUnits = simulatedInstallments.reduce(0.0) { $0 + $1.units }
                            if totalUnits > 0 {
                                profile.investments[i].purchaseNAV = totalPaid / totalUnits
                            }
                            updated = true
                        } else {
                            // Lumpsum
                            let (units, _, simulatedInstallments) = await StockService.shared.calculateLumpsumUnits(
                                symbol: symbol,
                                amount: inv.investmentAmount,
                                startDate: inv.startDate
                            )
                            profile.investments[i].installments = simulatedInstallments
                            profile.investments[i].quantity = units
                            
                            if let tx = simulatedInstallments.first {
                                profile.investments[i].purchaseNAV = tx.nav
                            }
                            updated = true
                        }
                    }
                }
            }
            
            if updated {
                await MainActor.run {
                    self.currentProfile = profile
                    self.recalculateFinancials()
                }
            }
        }
}
