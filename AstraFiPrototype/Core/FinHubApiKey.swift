import Foundation

struct Secrets {
    static let finnhubApiKey = value(for: "FINNHUB_API_KEY")
    static let fmpApiKey = value(for: "FMP_API_KEY")
    static let openRouterAPIKey = value(for: "OPENROUTER_API_KEY")
    static let openRouterEndpoint = value(for: "OPENROUTER_ENDPOINT")

    static func value(for key: String) -> String {
        let knownConfigurationKeys: Set<String> = [
            "FINNHUB_API_KEY",
            "FMP_API_KEY",
            "OPENROUTER_API_KEY",
            "OPENROUTER_ENDPOINT"
        ]
        let isKnownConfigurationKey = knownConfigurationKeys.contains(key)
        let environment = ProcessInfo.processInfo.environment
        if let exactValue = environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !exactValue.isEmpty {
            return exactValue
        }

        if let looseEnvironmentValue = environment.first(where: { entry in
            entry.key.trimmingCharacters(in: .whitespacesAndNewlines) == key
        })?
            .value
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !looseEnvironmentValue.isEmpty {
            return looseEnvironmentValue
        }

        if let bundleValue = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            let trimmed = bundleValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }

        let fallback = localSwiftFallbackValue(for: key)
        if !fallback.isEmpty { return fallback }

        return isKnownConfigurationKey ? "" : key.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func printConfigurationStatus() {
        print("========== API KEY CONFIGURATION ==========")
        print("FINNHUB_API_KEY:", maskedStatus(finnhubApiKey))
        print("FMP_API_KEY:", maskedStatus(fmpApiKey))
        print("OPENROUTER_API_KEY:", maskedStatus(openRouterAPIKey))
        print("OPENROUTER_ENDPOINT:", openRouterEndpoint.isEmpty ? "default OpenRouter endpoint" : "configured")
    }

    private static func maskedStatus(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "missing" }
        return "configured (\(trimmed.count) chars)"
    }

    private static func localSwiftFallbackValue(for key: String) -> String {
        switch key {
        case "FINNHUB_API_KEY":
            return ""
        case "FMP_API_KEY":
            return ""
        case "OPENROUTER_API_KEY":
            return ""
        case "OPENROUTER_ENDPOINT":
            return "https://openrouter.ai/api/v1/chat/completions"
        default:
            return ""
        }
    }
}
