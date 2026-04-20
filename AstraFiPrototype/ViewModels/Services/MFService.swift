import Foundation
import SwiftUI
import Observation

@Observable
class MFService {
    static let shared = MFService()

    var allSchemes: [MFScheme] = []
    var isFetching: Bool = false
    var lastFetchDate: Date?

    @ObservationIgnored private var historyCache: [String: [MFHistoryPoint]] = [:]

    private let amfiURL = URL(string: "https://www.amfiindia.com/spages/NAVAll.txt")!

    func fetchMFData(force: Bool = false) async {
        guard !isFetching else { return }

        if !force, let last = lastFetchDate, Date().timeIntervalSince(last) < 12 * 3600, !allSchemes.isEmpty {
            return
        }

        isFetching = true
        defer { isFetching = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: amfiURL)
            guard let content = String(data: data, encoding: .utf8) else { return }

            let parsed = parseAMFIData(content)

            await MainActor.run {
                self.allSchemes = parsed
                self.lastFetchDate = Date()
            }
        } catch {
            print("Error fetching AMFI data: \(error)")
        }
    }

    private func parseAMFIData(_ content: String) -> [MFScheme] {
        var schemes: [MFScheme] = []
        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            let components = line.components(separatedBy: ";")

            guard components.count >= 6 else { continue }

            let schemeCode = components[0].trimmingCharacters(in: .whitespaces)

            guard Int(schemeCode) != nil else { continue }

            let isin = components[1].trimmingCharacters(in: .whitespaces)
            let name = components[3].trimmingCharacters(in: .whitespaces)
            let navString = components[4].trimmingCharacters(in: .whitespaces)
            let date = components[5].trimmingCharacters(in: .whitespaces)

            if let navValue = Double(navString) {
                let scheme = MFScheme(
                    schemeCode: schemeCode,
                    isin: isin,
                    name: name,
                    nav: navValue,
                    date: date
                )
                schemes.append(scheme)
            }
        }

        return schemes
    }

    func searchSchemes(query: String) -> [MFScheme] {
        guard query.count >= 2 else { return [] }
        let lowerQuery = query.lowercased()
        
        // 1. Exact Match Check (Requirement: if name exact matches then show the same fund in list only)
        if let exact = allSchemes.first(where: { $0.name.lowercased() == lowerQuery }) {
            return [exact]
        }
        
        // 2. High Priority: Contains query
        let containsResults = allSchemes.filter { $0.name.lowercased().contains(lowerQuery) }
        
        // 3. Score and Sort
        let scoredItems = containsResults.map { scheme -> (scheme: MFScheme, score: Double) in
            var score = SearchUtility.fuzzyMatchScore(query: lowerQuery, target: scheme.name)
            
            // AMC priority: If query matches the first word (AMC name)
            let firstWord = scheme.name.components(separatedBy: " ").first?.lowercased() ?? ""
            if firstWord == lowerQuery || firstWord.hasPrefix(lowerQuery) {
                score += 0.2 // Boost AMC matches
            }
            
            return (scheme, score)
        }
        
        // 4. Fallback to Fuzzy Search if few results
        if scoredItems.count < 5 && query.count >= 3 {
            let allScored = allSchemes.prefix(2000).map { scheme -> (scheme: MFScheme, score: Double) in // Limit full fuzzy to first 2000 for performance
                (scheme, SearchUtility.fuzzyMatchScore(query: lowerQuery, target: scheme.name))
            }.filter { $0.score > 0.6 }
            
            return (scoredItems + allScored)
                .sorted { $0.score > $1.score }
                .map { $0.scheme }
                .removeDuplicates()
                .prefix(15)
                .map { $0 }
        }
        
        return scoredItems
            .sorted { $0.score > $1.score }
            .prefix(15)
            .map { $0.scheme }
    }

    func getScheme(by code: String) -> MFScheme? {
        allSchemes.first { $0.schemeCode == code }
    }

    func getSchemeByISIN(_ isin: String) -> MFScheme? {
        allSchemes.first { $0.isin == isin }
    }

    func findSchemeCode(for name: String) -> String? {

        if let exact = allSchemes.first(where: { $0.name.lowercased() == name.lowercased() }) {
            return exact.schemeCode
        }

        return allSchemes.first(where: { name.lowercased().contains($0.name.lowercased()) || $0.name.lowercased().contains(name.lowercased()) })?.schemeCode
    }

    private func getFullHistory(for schemeCode: String) async throws -> [MFHistoryPoint] {
        if let cached = historyCache[schemeCode] {
            return cached
        }
        let urlString = "https://api.mfapi.in/mf/\(schemeCode)"
        guard let url = URL(string: urlString) else { return [] }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(MFHistoryResponse.self, from: data)
        let points = response.data
        historyCache[schemeCode] = points
        return points
    }

    func fetchHistoricalNAV(schemeCode: String, date: Date) async -> Double? {
        do {
            let allPoints = try await getFullHistory(for: schemeCode)

            let df = DateFormatter()
            df.dateFormat = "dd-MM-yyyy"
            let targetDateString = df.string(from: date)

            if let point = allPoints.first(where: { $0.date == targetDateString }) {
                return Double(point.nav)
            }

            let sortedPoints = allPoints.compactMap { p -> (Date, Double)? in
                guard let d = df.date(from: p.date), let v = Double(p.nav) else { return nil }
                return (d, v)
            }.sorted(by: { $0.0 > $1.0 })

            return sortedPoints.first(where: { $0.0 <= date })?.1
        } catch {
            print("Error fetching historical NAV: \(error)")
            return nil
        }
    }

    func fetchHistoricalGraphData(schemeCode: String, startDate: Date? = nil) async -> [MFHistoryPoint] {
        do {
            let allPoints = try await getFullHistory(for: schemeCode)

            if let start = startDate {
                let df = DateFormatter()
                df.dateFormat = "dd-MM-yyyy"

                let filtered = allPoints.filter { point in
                    if let pointDate = df.date(from: point.date) {

                        return pointDate >= start.addingTimeInterval(-86400)
                    }
                    return false
                }
                return filtered.reversed()
            } else {

                return Array(allPoints.prefix(100)).reversed()
            }
        } catch {
            print("Error fetching graph data: \(error)")
            return []
        }
    }

    /// Simulates SIP installments from startDate to now.
    /// Returns total units accumulated, total amount invested, and the list of installments.
    func calculateHistoricalSIPUnits(schemeCode: String, monthlyAmount: Double, startDate: Date) async -> (totalUnits: Double, totalInvested: Double, installments: [AstraInvestmentTransaction]) {
        var totalUnits: Double = 0
        var totalInvested: Double = 0
        var installments: [AstraInvestmentTransaction] = []
        
        let calendar = Calendar.current
        let today = Date()
        
        // Find all installment dates (same day of month)
        var currentDate = startDate
        var dates: [Date] = []
        
        while currentDate <= today {
            dates.append(currentDate)
            guard let next = calendar.date(byAdding: .month, value: 1, to: currentDate) else { break }
            currentDate = next
        }
        
        // For each date, fetch NAV and calculate units
        for date in dates {
            if let nav = await fetchHistoricalNAV(schemeCode: schemeCode, date: date), nav > 0 {
                let units = monthlyAmount / nav
                totalUnits += units
                totalInvested += monthlyAmount
                
                installments.append(AstraInvestmentTransaction(
                    date: date,
                    type: .buy,
                    amount: monthlyAmount,
                    nav: nav,
                    units: units
                ))
            }
        }
        
        return (totalUnits, totalInvested, installments)
    }
}

struct MFHistoryResponse: Codable {
    let data: [MFHistoryPoint]
}

struct MFHistoryPoint: Codable {
    let date: String
    let nav: String
}
