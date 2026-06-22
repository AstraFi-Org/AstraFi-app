import Foundation

final class FMPService {
    static let shared = FMPService()

    private let stableBaseURL = "https://financialmodelingprep.com/stable"
    private var apiKey: String { Secrets.fmpApiKey }

    func profile(symbol: String) async throws -> FMPProfile? {
        let rows: [FMPProfile] = try await requestArray(path: "profile", query: ["symbol": fmpSymbol(symbol)])
        return rows.first
    }

    func keyMetrics(symbol: String) async throws -> FMPKeyMetrics? {
        let rows: [FMPKeyMetrics] = try await requestArray(path: "key-metrics-ttm", query: ["symbol": fmpSymbol(symbol)])
        return rows.first
    }

    func ratios(symbol: String) async throws -> FMPRatios? {
        let rows: [FMPRatios] = try await requestArray(path: "ratios-ttm", query: ["symbol": fmpSymbol(symbol)])
        return rows.first
    }

    func incomeStatements(symbol: String) async throws -> [FMPIncomeStatement] {
        try await requestArray(path: "income-statement", query: ["symbol": fmpSymbol(symbol), "limit": "2"])
    }

    func peers(symbol: String) async throws -> [String] {
        let rows: [FMPPeersResponse] = try await requestArray(path: "stock-peers", query: ["symbol": fmpSymbol(symbol)])
        return rows.first?.peersList ?? []
    }

    private func requestArray<T: Decodable>(path: String, query: [String: String] = [:]) async throws -> [T] {
        guard !apiKey.isEmpty else {
            print("FMP request skipped for /\(path): FMP_API_KEY missing")
            throw URLError(.userAuthenticationRequired)
        }

        var components = URLComponents(string: "\(stableBaseURL)/\(path)")
        components?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) } + [
            URLQueryItem(name: "apikey", value: apiKey)
        ]
        guard let url = components?.url else { throw URLError(.badURL) }

        print("FMP URL:", sanitizedURL(url))
        let (data, response) = try await URLSession.shared.data(from: url)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200
        print("HTTP Status:", statusCode)
        guard statusCode < 400 else {
            if let body = String(data: data, encoding: .utf8) {
                print("FMP request failed for /\(path) with HTTP \(statusCode): \(body.prefix(500))")
            } else {
                print("FMP request failed for /\(path) with HTTP \(statusCode)")
            }
            throw URLError(.badServerResponse)
        }

        do {
            let decoded = try JSONDecoder().decode([T].self, from: data)
            print("FMP request OK for /\(path): \(decoded.count) row(s)")
            return decoded
        } catch {
            if let body = String(data: data, encoding: .utf8) {
                print("FMP decode failed for /\(path): \(body.prefix(500))")
            }
            throw error
        }
    }

    private func fmpSymbol(_ symbol: String) -> String {
        symbol.uppercased()
    }

    private func sanitizedURL(_ url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url.absoluteString
        }
        components.queryItems = components.queryItems?.map { item in
            item.name == "apikey" ? URLQueryItem(name: item.name, value: "<redacted>") : item
        }
        return components.url?.absoluteString ?? url.absoluteString
    }
}

struct FMPProfile: Decodable {
    let symbol: String?
    let companyName: String?
    let sector: String?
    let industry: String?
    let mktCap: Double?
    let fullTimeEmployees: String?
    let description: String?
}

struct FMPKeyMetrics: Decodable {
    let peRatioTTM: Double?
    let roeTTM: Double?
    let debtToEquityTTM: Double?
}

struct FMPRatios: Decodable {
    let priceEarningsRatioTTM: Double?
    let returnOnEquityTTM: Double?
    let debtEquityRatioTTM: Double?
    let netProfitMarginTTM: Double?
}

struct FMPIncomeStatement: Decodable {
    let revenue: Double?
    let netIncome: Double?
}

struct FMPPeersResponse: Decodable {
    let symbol: String?
    let peersList: [String]?
}
