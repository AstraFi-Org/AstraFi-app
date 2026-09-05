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

    private let amfiURLs = [
        URL(string: "https://portal.amfiindia.com/spages/NAVAll.txt")!,
        URL(string: "https://www.amfiindia.com/spages/NAVAll.txt")!
    ]

    func fetchMFData(force: Bool = false) async {
        guard !isFetching else { return }

        if !force, let last = lastFetchDate, Date().timeIntervalSince(last) < 12 * 3600, !allSchemes.isEmpty {
            return
        }

        isFetching = true
        defer { isFetching = false }

        for url in amfiURLs {
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 20
                request.setValue("text/plain,*/*", forHTTPHeaderField: "Accept")
                request.setValue("AstraFi/1.0 iOS", forHTTPHeaderField: "User-Agent")

                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      200..<300 ~= httpResponse.statusCode else {
                    print("Error fetching AMFI data from \(url): invalid HTTP response")
                    continue
                }

                guard let content = String(data: data, encoding: .utf8) else { continue }

                let parsed = parseAMFIData(content)
                guard !parsed.isEmpty else {
                    print("Error fetching AMFI data: no schemes parsed from \(url)")
                    continue
                }

                await MainActor.run {
                    self.allSchemes = parsed
                    self.lastFetchDate = Date()
                }
                return
            } catch {
                print("Error fetching AMFI data from \(url): \(error)")
            }
        }
    }

    private func parseAMFIData(_ content: String) -> [MFScheme] {
        var schemes: [MFScheme] = []
        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            let lineStr = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !lineStr.isEmpty else { continue }

            let components = lineStr.components(separatedBy: ";")

            guard components.count >= 6 else { continue }

            let schemeCode = components[0].trimmingCharacters(in: .whitespaces)

            guard Int(schemeCode) != nil else { continue }

            let isin = components[1].trimmingCharacters(in: .whitespaces)
            let alternateISIN = components[2].trimmingCharacters(in: .whitespaces)

            let navString: String
            let date: String
            let name: String

            if components.count >= 8 {
                let baseName = components[3].trimmingCharacters(in: .whitespaces)
                let plan = components[4].trimmingCharacters(in: .whitespaces)
                let option = components[5].trimmingCharacters(in: .whitespaces)

                let nameParts = [baseName, plan, option].filter { !$0.isEmpty }
                name = nameParts.joined(separator: " - ")

                navString = components[6].trimmingCharacters(in: .whitespaces)
                date = components[7].trimmingCharacters(in: .whitespaces)
            } else {
                name = components[3].trimmingCharacters(in: .whitespaces)
                navString = components[4].trimmingCharacters(in: .whitespaces)
                date = components[5].trimmingCharacters(in: .whitespaces)
            }

            if let navValue = Double(navString) {
                let scheme = MFScheme(
                    schemeCode: schemeCode,
                    isin: isin,
                    alternateISIN: (alternateISIN.isEmpty || alternateISIN == "-") ? nil : alternateISIN,
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
        let search = Self.normalizedSearchTerms(query)
        guard !search.terms.isEmpty else { return [] }

        // AMFI scheme names vary by plan/option (for example, "Mid Cap" versus
        // "Midcap") and often omit generic words such as "Mutual". Rank every
        // available scheme against the meaningful terms instead of falling back
        // to a small, unrelated prefix of the AMFI catalogue.
        return allSchemes.compactMap { scheme in
            let name = Self.normalizedSearchTerms(scheme.name, removeGenericTerms: false)
            guard search.terms.allSatisfy({ name.compact.contains($0) }) else { return nil }

            var score = 0
            if name.compact.hasPrefix(search.compact) { score += 100 }
            else if name.compact.contains(search.compact) { score += 80 }
            score += search.terms.reduce(into: 0) { partial, term in
                if name.words.contains(where: { $0.hasPrefix(term) }) { partial += 10 }
            }
            return (scheme, score)
        }
        .sorted { lhs, rhs in
            lhs.1 == rhs.1 ? lhs.0.name.localizedCaseInsensitiveCompare(rhs.0.name) == .orderedAscending : lhs.1 > rhs.1
        }
        .prefix(15)
        .map(\.0)
    }

    private static func normalizedSearchTerms(_ value: String, removeGenericTerms: Bool = true) -> (terms: [String], words: [String], compact: String) {
        let folded = value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let words = folded.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        let genericTerms: Set<String> = ["mutual", "fund", "funds", "scheme"]
        let terms = removeGenericTerms ? words.filter { !genericTerms.contains($0) } : words
        return (terms, words, terms.joined())
    }

    func getScheme(by code: String) -> MFScheme? {
        allSchemes.first { $0.schemeCode == code }
    }

    func getSchemeByISIN(_ isin: String) -> MFScheme? {
        let normalizedISIN = isin.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return allSchemes.first {
            $0.isin.uppercased() == normalizedISIN ||
            $0.alternateISIN?.uppercased() == normalizedISIN
        }
    }

    func findSchemeCode(for name: String) -> String? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }

        // 1. Direct exact match
        if let exact = allSchemes.first(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            return exact.schemeCode
        }

        func normalize(_ str: String) -> String {
            str.lowercased()
                .replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "–", with: " ")
                .replacingOccurrences(of: "_", with: " ")
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }

        let normQuery = normalize(trimmedName)

        // 2. Exact normalized match
        if let normMatch = allSchemes.first(where: { normalize($0.name) == normQuery }) {
            return normMatch.schemeCode
        }

        // 3. Substring normalized match
        if let subMatch = allSchemes.first(where: {
            let normScheme = normalize($0.name)
            return normQuery.contains(normScheme) || normScheme.contains(normQuery)
        }) {
            return subMatch.schemeCode
        }

        // 4. Fallback search
        let results = searchSchemes(query: trimmedName)
        return results.first?.schemeCode
    }

    private func getFullHistory(for schemeCode: String) async throws -> [MFHistoryPoint] {
        if let cached = historyCache[schemeCode] {
            return cached
        }
        let urlString = "https://api.mfapi.in/mf/\(schemeCode)"
        guard let url = URL(string: urlString) else { return [] }

        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("AstraFi/1.0 iOS", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        let historyResponse = try JSONDecoder().decode(MFHistoryResponse.self, from: data)
        let points = historyResponse.data
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
    func calculateHistoricalSIPUnits(schemeCode: String, monthlyAmount: Double, startDate: Date, frequency: AssessmentInvestmentEntry.AssessmentSIPFrequency = .monthly) async -> (totalUnits: Double, totalInvested: Double, installments: [AstraInvestmentTransaction]) {
        var totalUnits: Double = 0
        var totalInvested: Double = 0
        var installments: [AstraInvestmentTransaction] = []
        
        let calendar = Calendar.current
        let today = Date()
        
        // Find all installment dates (same day of month)
        var currentDate = startDate
        var dates: [Date] = []
        
        
        let component: Calendar.Component
        let value: Int
        
        switch frequency {
        case .weekly:
            component = .weekOfYear
            value = 1
        case .monthly:
            component = .month
            value = 1
        case .quarterly:
            component = .month
            value = 3
        case .yearly:
            component = .year
            value = 1
        }
        
        while currentDate <= today {
            dates.append(currentDate)
            guard let next = calendar.date(byAdding: component, value: value, to: currentDate) else { break }
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
