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
        guard query.count >= 3 else { return [] }
        let lowerQuery = query.lowercased()
        return allSchemes.filter { $0.name.lowercased().contains(lowerQuery) }
            .prefix(20)
            .map { $0 }
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
}

struct MFHistoryResponse: Codable {
    let data: [MFHistoryPoint]
}

struct MFHistoryPoint: Codable {
    let date: String
    let nav: String
}
