import Foundation

enum AIIntelligenceServiceError: LocalizedError {
    case missingConfiguration
    case invalidResponse
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "OpenRouter key is not configured. Add OPENROUTER_API_KEY to the Xcode scheme environment."
        case .invalidResponse:
            return "AI response could not be decoded into stock intelligence."
        case .emptyResponse:
            return "AI provider returned an empty response."
        }
    }
}

final class AIIntelligenceService {
    private let session: URLSession
    private let openRouterModels = [
        "qwen/qwen3-next-80b-a3b-instruct:free",
        "nvidia/nemotron-3-super-120b-a12b:free",
        "google/gemma-4-31b-it:free",
        "google/gemma-4-26b-a4b-it:free",
        "openai/gpt-oss-20b:free",
        "nex-agi/nex-n2-pro:free",
        "nousresearch/hermes-3-llama-3.1-405b:free",
        "meta-llama/llama-3.3-70b-instruct:free"
    ]

    init(session: URLSession = .shared) {
        self.session = session
    }

    func generateIntelligence(from facts: StockFacts, diagnosticLogging: Bool = false) async throws -> CompanyIntelligence {
        print("🚀 STARTING AI GENERATION")
        let prompt = try prompt(for: facts)

        if !Secrets.openRouterAPIKey.isEmpty {
            return try await generateWithOpenRouter(prompt: prompt, facts: facts, diagnosticLogging: diagnosticLogging)
        }

        print("OPENROUTER ERROR")
        print("OPENROUTER_API_KEY missing. Using facts-based intelligence fallback.")
        return fallbackIntelligence(from: facts)
    }

    private func prompt(for facts: StockFacts) throws -> String {
        let factsData = try JSONEncoder().encode(facts)
        let factsJSON = String(data: factsData, encoding: .utf8) ?? "{}"

        return """
        Act as a professional equity research analyst.

        Analyze the following company facts.

        Use these inputs:
        - StockProfile
        - Financials
        - Price history
        - Company description
        - Employees
        - Sector
        - Industry
        - Competitors

        Rules:
        - Return STRICT JSON ONLY.
        - Every value must be an array of markdown bullet strings.
        - Each section must contain 3 to 6 bullet points.
        - Start every bullet string with "- ".
        - Maximum 30 words per bullet.
        - Use numbers whenever possible.
        - Explain in simple language.
        - Avoid generic statements.
        - Mention market sizes if available.
        - Mention employees and competitors.
        - Do not provide buy, sell, or hold advice.

        Expected JSON:
        {
          "whyCanGrow":[],
          "biggestRisk":[],
          "eli20":[],
          "revenueModel":[],
          "analystBullishReason":[],
          "whatCanGoWrong":[],
          "addressableMarket":[],
          "employees":[],
          "competitors":[],
          "growthOpportunities":[]
        }

        Company facts JSON:
        \(factsJSON)
        """
    }

    private func generateWithOpenRouter(prompt: String, facts: StockFacts, diagnosticLogging: Bool) async throws -> CompanyIntelligence {
        let endpoint = Secrets.openRouterEndpoint.isEmpty
            ? "https://openrouter.ai/api/v1/chat/completions"
            : Secrets.openRouterEndpoint
        guard let url = URL(string: endpoint) else {
            throw AIIntelligenceServiceError.missingConfiguration
        }

        print("===== OPENROUTER REQUEST =====")
        print(prompt)

        var lastError: Error = AIIntelligenceServiceError.invalidResponse
        for model in openRouterModels {
            print("Using model:", model)
            let payload = ChatCompletionRequest(
                model: model,
                messages: [
                    ChatMessage(role: "system", content: "Return strict JSON only. Do not include markdown."),
                    ChatMessage(role: "user", content: prompt)
                ],
                temperature: 0.2
            )

            let payloadData = try JSONEncoder().encode(payload)
            if diagnosticLogging {
                print("========== OPENROUTER INPUT ==========")
                print(Self.prettyJSON(from: payloadData))
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(Secrets.openRouterAPIKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("https://astrafi.app", forHTTPHeaderField: "HTTP-Referer")
            request.setValue("AstraFi", forHTTPHeaderField: "X-Title")
            request.httpBody = payloadData

            let data: Data
            let response: URLResponse
            do {
                (data, response) = try await session.data(for: request)
            } catch {
                print("OPENROUTER ERROR")
                print(error)
                lastError = error
                continue
            }
            let rawResponse = String(data: data, encoding: .utf8) ?? "<non-utf8 response>"

            print("===== RAW RESPONSE =====")
            print(rawResponse)
            if diagnosticLogging {
                print("========== OPENROUTER RAW RESPONSE ==========")
                print(rawResponse)
            }

            if Self.containsOpenRouterError(rawResponse) {
                print("OPENROUTER ERROR")
                lastError = AIIntelligenceServiceError.invalidResponse
                continue
            }

            guard (response as? HTTPURLResponse)?.statusCode ?? 200 < 400 else {
                print("OPENROUTER ERROR")
                lastError = AIIntelligenceServiceError.invalidResponse
                continue
            }

            let decoded: ChatCompletionResponse
            do {
                decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
            } catch {
                if diagnosticLogging {
                    print("JSON DECODING FAILED")
                    print(rawResponse)
                    print("OpenRouter envelope decoding error:", error)
                }
                print("❌ DECODING FAILED")
                print(error)
                print("RAW RESPONSE:")
                print(rawResponse)
                lastError = AIIntelligenceServiceError.invalidResponse
                continue
            }

            guard let text = decoded.choices.first?.message.content,
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                lastError = AIIntelligenceServiceError.emptyResponse
                continue
            }

            do {
                return try decodeCompanyIntelligence(from: text, rawResponse: rawResponse, diagnosticLogging: diagnosticLogging)
            } catch {
                lastError = error
                continue
            }
        }

        print("OPENROUTER ERROR")
        print("All free OpenRouter models failed. Using facts-based intelligence fallback.")
        print(lastError)
        return fallbackIntelligence(from: facts)
    }

    private static func containsOpenRouterError(_ rawResponse: String) -> Bool {
        guard let data = rawResponse.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return rawResponse.contains("\"error\"")
        }
        return object["error"] != nil
    }

    private func decodeCompanyIntelligence(from text: String, rawResponse: String, diagnosticLogging: Bool = false) throws -> CompanyIntelligence {
        let cleanedText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonString = Self.extractJSONObject(from: cleanedText)

        print("===== JSON STRING =====")
        print(jsonString)

        guard let data = jsonString.data(using: .utf8) else {
            throw AIIntelligenceServiceError.invalidResponse
        }

        do {
            let companyIntelligence = try JSONDecoder().decode(CompanyIntelligence.self, from: data)
            print("===== DECODE SUCCESS =====")
            print(companyIntelligence)
            return companyIntelligence
        } catch {
            if diagnosticLogging {
                print("JSON DECODING FAILED")
                print(jsonString)
                print("CompanyIntelligence decoding error:", error)
            }
            print("❌ DECODING FAILED")
            print(error)
            print("RAW RESPONSE:")
            print(rawResponse)
            throw AIIntelligenceServiceError.invalidResponse
        }
    }

    private static func extractJSONObject(from text: String) -> String {
        guard
            let start = text.firstIndex(of: "{"),
            let end = text.lastIndex(of: "}"),
            start <= end
        else {
            return text
        }
        return String(text[start...end]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func fallbackIntelligence(from facts: StockFacts) -> CompanyIntelligence {
        let company = facts.companyName.isEmpty ? facts.symbol : facts.companyName
        let sector = facts.sector.isEmpty ? "its sector" : facts.sector
        let industry = facts.industry.isEmpty ? "its industry" : facts.industry
        let employees = facts.employees > 0 ? formattedInteger(facts.employees) : "Data unavailable"
        let competitors = facts.competitors.isEmpty ? ["Data unavailable"] : facts.competitors.prefix(6).map { "- \($0)" }
        let marketCap = facts.marketCap > 0 ? formattedCurrency(facts.marketCap) : "Data unavailable"
        let peRatio = facts.peRatio > 0 ? String(format: "%.1fx", facts.peRatio) : "Data unavailable"
        let revenueGrowth = formattedPercent(facts.revenueGrowth)
        let profitGrowth = formattedPercent(facts.profitGrowth)
        let debtToEquity = facts.debtToEquity > 0 ? String(format: "%.2f", facts.debtToEquity) : "Data unavailable"
        let priceTrend = priceTrendText(from: facts.priceHistory)

        let descriptionPoint: String
        if facts.description.isEmpty {
            descriptionPoint = "- Business description is unavailable from provider data."
        } else {
            descriptionPoint = "- \(company) operates in \(industry), within the \(sector) sector."
        }

        print("===== DECODE SUCCESS =====")
        print("Using facts-based CompanyIntelligence fallback")

        return CompanyIntelligence(
            whyCanGrow: [
                "- \(company) has exposure to \(sector), giving it a clear operating market.",
                "- Provider profile lists \(industry), which defines its core growth area.",
                "- Current price history indicates \(priceTrend), useful for trend context.",
                "- Market cap is \(marketCap), showing the company scale available from provider data."
            ],
            biggestRisk: [
                "- Revenue growth is \(revenueGrowth), so weak growth can limit upside.",
                "- Profit growth is \(profitGrowth), making margin pressure important to watch.",
                "- Debt-to-equity is \(debtToEquity), which affects financial flexibility.",
                "- Competitor coverage is \(facts.competitors.isEmpty ? "unavailable" : "available"), so peer comparison may be incomplete."
            ],
            eli20: [
                descriptionPoint,
                "- Think of revenue as customer money coming in from products and services.",
                "- Profit growth shows whether the company keeps more money after costs.",
                "- Price trend is \(priceTrend), but it is not a buy or sell signal."
            ],
            revenueModel: [
                "- \(company) makes money through operations in \(industry).",
                "- Its sector is \(sector), so revenue depends on demand in that market.",
                "- Company description and financial metrics are provider-backed when available.",
                "- Revenue growth from provider data is \(revenueGrowth)."
            ],
            analystBullishReason: [
                "- Analyst buy count is \(facts.analystBuy), based on available provider data.",
                "- Analyst hold count is \(facts.analystHold), showing neutral coverage if present.",
                "- Analyst sell count is \(facts.analystSell), useful for risk balance.",
                "- Valuation context uses PE ratio of \(peRatio)."
            ],
            whatCanGoWrong: [
                "- Growth can slow if demand weakens in \(sector).",
                "- Margins can compress if costs rise faster than revenue.",
                "- High competition can reduce pricing power in \(industry).",
                "- Missing provider metrics should be treated as uncertainty, not strength."
            ],
            addressableMarket: [
                "- Addressable market data is not directly available from providers.",
                "- The practical market is linked to \(sector) demand.",
                "- Industry exposure is \(industry), which defines the nearest business market.",
                "- Market cap is \(marketCap), but it is not total market size."
            ],
            employees: [
                "- Employee count is \(employees).",
                "- A larger workforce can support scale, delivery, and operations.",
                "- Employee productivity should be compared with revenue and profit growth.",
                "- Workforce data comes from provider profile when available."
            ],
            competitors: competitors,
            growthOpportunities: [
                "- Grow within \(industry) by expanding customers, products, or services.",
                "- Improve profitability if profit growth rises above \(profitGrowth).",
                "- Strengthen returns if ROE improves from \(formattedPercent(facts.roe)).",
                "- Better provider coverage can improve future peer and analyst comparisons."
            ]
        )
    }

    private func formattedInteger(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func formattedCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "₹\(Int(value))"
    }

    private func formattedPercent(_ value: Double) -> String {
        guard value != 0 else { return "Data unavailable" }
        let normalized = abs(value) > 1 ? value : value * 100
        return String(format: "%.1f%%", normalized)
    }

    private func priceTrendText(from history: [Double]) -> String {
        guard let first = history.first, let last = history.last, first > 0 else {
            return "Data unavailable"
        }
        let change = ((last - first) / first) * 100
        if abs(change) < 0.1 { return "mostly flat" }
        return change > 0
            ? String(format: "up %.1f%% over loaded history", change)
            : String(format: "down %.1f%% over loaded history", abs(change))
    }

    private static func prettyJSON(from data: Data) -> String {
        guard
            let object = try? JSONSerialization.jsonObject(with: data),
            let prettyData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
            let prettyString = String(data: prettyData, encoding: .utf8)
        else {
            return String(data: data, encoding: .utf8) ?? "<non-utf8 json>"
        }
        return prettyString
    }
}

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
}

private struct ChatMessage: Codable {
    let role: String
    let content: String
}

private struct ChatCompletionResponse: Decodable {
    let choices: [ChatChoice]
}

private struct ChatChoice: Decodable {
    let message: ChatMessage
}
