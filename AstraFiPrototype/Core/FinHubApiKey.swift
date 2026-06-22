import Foundation

struct Secrets {
    static let finnhubApiKey = value(for: "FINNHUB_API_KEY")

    static func value(for key: String) -> String {
        let environment = ProcessInfo.processInfo.environment
        if let exactValue = environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !exactValue.isEmpty {
            return exactValue
        }

        return environment.first { entry in
            entry.key.trimmingCharacters(in: .whitespacesAndNewlines) == key
        }?
        .value
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
