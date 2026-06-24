import Foundation

actor AIIntelligenceCache {
    static let shared = AIIntelligenceCache()

    private let version = 2
    private let defaults: UserDefaults
    private let ttl: TimeInterval = 7 * 24 * 60 * 60

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func cachedIntelligence(for symbol: String) -> CompanyIntelligence? {
        let key = cacheKey(for: symbol)
        guard
            let data = defaults.data(forKey: key),
            let entry = try? JSONDecoder().decode(CacheEntry.self, from: data),
            Date().timeIntervalSince(entry.generatedAt) < ttl
        else {
            defaults.removeObject(forKey: key)
            return nil
        }
        return entry.response
    }

    func save(_ response: CompanyIntelligence, for symbol: String) {
        let entry = CacheEntry(symbol: symbol, generatedAt: Date(), response: response)
        guard let data = try? JSONEncoder().encode(entry) else { return }
        defaults.set(data, forKey: cacheKey(for: symbol))
    }

    private func cacheKey(for symbol: String) -> String {
        "ai-stock-intelligence-v\(version)-\(symbol.uppercased())"
    }

    private struct CacheEntry: Codable {
        let symbol: String
        let generatedAt: Date
        let response: CompanyIntelligence
    }
}
