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

    /// Reuses AstraFi's existing AI transport for explanation only. Financial
    /// calculations are completed locally in FinancialDecisionAnalysis.
    func generateFinancialDecisionInsight(from context: FinancialDecisionContext) async throws -> String {
        guard !Secrets.openRouterAPIKey.isEmpty else {
            return FinancialDecisionAIInsight.fallback(for: context)
        }
        let endpoint = Secrets.openRouterEndpoint.isEmpty
            ? "https://openrouter.ai/api/v1/chat/completions"
            : Secrets.openRouterEndpoint
        guard let url = URL(string: endpoint), let model = openRouterModels.first else {
            throw AIIntelligenceServiceError.missingConfiguration
        }

        let encodedContext = try JSONEncoder().encode(context)
        let contextJSON = String(data: encodedContext, encoding: .utf8) ?? "{}"
        let prompt = """
        Explain the following PRE-CALCULATED personal-finance readiness facts in 80 words or fewer.
        Use clear educational language. Do not calculate new metrics, alter numbers, recommend specific stocks, funds, banks, or products, predict returns, or give regulated financial advice.
        State the key priority and its factual reason. Do not use markdown.

        Facts JSON: \(contextJSON)
        """
        let payload = ChatCompletionRequest(
            model: model,
            messages: [
                ChatMessage(role: "system", content: "Explain only supplied facts. Never provide product recommendations or guarantees."),
                ChatMessage(role: "user", content: prompt)
            ],
            temperature: 0.2
        )
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Secrets.openRouterAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://astrafi.app", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("AstraFi", forHTTPHeaderField: "X-Title")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode ?? 200 < 400,
              let content = try JSONDecoder().decode(ChatCompletionResponse.self, from: data).choices.first?.message.content,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIIntelligenceServiceError.invalidResponse
        }
        return String(content.trimmingCharacters(in: .whitespacesAndNewlines).prefix(600))
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
        let sector = facts.sector.isEmpty ? "General Equities" : facts.sector
        let industry = facts.industry.isEmpty ? sector : facts.industry
        let marketContext = SecurityMarketContext.forSymbol(facts.symbol)
        let employees = facts.employees > 0 ? formattedInteger(facts.employees) : "Data unavailable"
        let marketCap = facts.marketCap > 0 ? marketContext.formatMarketCap(facts.marketCap) : "Data unavailable"
        let peRatio = facts.peRatio > 0 ? String(format: "%.1fx", facts.peRatio) : "Data unavailable"
        let revenueGrowth = formattedPercent(facts.revenueGrowth)
        let profitGrowth = formattedPercent(facts.profitGrowth)
        let debtToEquity = facts.debtToEquity > 0 ? String(format: "%.2f", facts.debtToEquity) : "Data unavailable"
        let priceTrend = priceTrendText(from: facts.priceHistory)

        print("===== DECODE SUCCESS =====")
        print("Using context-aware CompanyIntelligence fallback for \(facts.symbol)")

        // If verified store contains curated profile, produce high-quality, factual intelligence
        if let verified = CompanyIntelligenceStore.shared.profile(for: facts.symbol) {
            let whyGrowPoints: [String] = verified.secularGrowthDrivers.prefix(3).map { "- [Growth Catalyst] \($0)" } + [
                "- [Market Scale] Operating across \(verified.targetMarkets.prefix(2).joined(separator: "; ")).",
                "- [Historical Trend] Share price trend is \(priceTrend) over loaded period."
            ]

            let riskPoints: [String] = verified.keyBusinessRisks.prefix(3).map { "- [Operational Risk] \($0)" } + [
                "- [Financial Check] Revenue growth: \(revenueGrowth), Debt/Equity: \(debtToEquity)."
            ]

            let eli20Points: [String] = [
                "- [Core Business] \(verified.whatItDoes)",
                "- [Revenue Engine] \(verified.revenueModel.first ?? "Generates cash flow from core enterprise contracts.")",
                "- [What to Watch] Key investor metrics include \(verified.keyMetricsToMonitor.prefix(2).joined(separator: ", "))."
            ]

            let revenuePoints: [String] = verified.revenueModel.map { "- \($0)" }

            let bullishPoints: [String] = [
                "- [Analyst Stance] \(facts.analystBuy) Buy ratings, \(facts.analystHold) Hold, \(facts.analystSell) Sell from reporting brokers.",
                "- [Core Tailwinds] \(verified.secularGrowthDrivers.first ?? "Secular demand tailwinds in \(industry).")",
                "- [Valuation Multiple] Trading at a P/E multiple of \(peRatio)."
            ]

            let goWrongPoints: [String] = verified.keyBusinessRisks.suffix(3).map { "- \($0)" } + [
                "- [Macro Risk] Cyclical downturns or customer budget freezes in primary operating markets."
            ]

            let addressablePoints: [String] = [
                "- [Core Markets] Primary addressable customer base: \(verified.targetMarkets.joined(separator: ", ")).",
                "- [Enterprise Scale] Market capitalization stands at \(marketCap) on \(verified.exchange).",
                "- [Operating Footprint] Operating segments include \(verified.operatingSegments.map(\.name).prefix(3).joined(separator: ", "))."
            ]

            let employeePoints: [String] = [
                "- [Workforce Scale] \(company) employs approximately \(employees) professionals.",
                "- [Productivity] Talent efficiency directly dictates delivery margins and operating profit.",
                "- [Talent Quality] High-skilled workforce driving execution in \(industry)."
            ]

            let competitorsPoints: [String] = verified.operatingSegments.prefix(4).map { "- Operating Division: \($0.name) (\($0.sharePercentage ?? "Core"))" }

            let growthOppPoints: [String] = verified.secularGrowthDrivers.map { "- [Opportunity] \($0)" }

            return CompanyIntelligence(
                whyCanGrow: whyGrowPoints,
                biggestRisk: riskPoints,
                eli20: eli20Points,
                revenueModel: revenuePoints,
                analystBullishReason: bullishPoints,
                whatCanGoWrong: goWrongPoints,
                addressableMarket: addressablePoints,
                employees: employeePoints,
                competitors: competitorsPoints,
                growthOpportunities: growthOppPoints
            )
        }

        // Clean, truthful fallback for securities without curated repository
        let competitors = facts.competitors.isEmpty ? ["- Peer data not furnished by data provider."] : facts.competitors.prefix(4).map { "- \($0)" }
        let descriptionPoint = facts.description.isEmpty
            ? "- \(company) is listed on \(marketContext.exchange) under symbol \(facts.symbol)."
            : "- \(facts.description)"

        return CompanyIntelligence(
            whyCanGrow: [
                "- [Industry Catalyst] Operates in \(industry) within the \(sector) sector.",
                "- [Scale Metric] Current market capitalization is \(marketCap).",
                "- [Price Momentum] Price action is \(priceTrend) across recent chart history.",
                "- [Revenue Growth] Provider-reported revenue growth is \(revenueGrowth)."
            ],
            biggestRisk: [
                "- [Growth Risk] Slower economic demand can pressure top-line growth (current: \(revenueGrowth)).",
                "- [Balance Sheet] Debt-to-equity ratio is \(debtToEquity), which dictates financial solvency.",
                "- [Profit Stability] Trailing profit growth is \(profitGrowth); watch for margin contraction."
            ],
            eli20: [
                descriptionPoint,
                "- [Revenue Source] Generates income by selling products or services in the \(industry) space.",
                "- [Investor Caution] Compare valuation metrics and debt ratios against peer companies before investing."
            ],
            revenueModel: [
                "- Delivers products and solutions tailored to customers in \(industry).",
                "- Revenue growth reported by financial provider: \(revenueGrowth).",
                "- Operating results depend on volume demand and operational cost containment."
            ],
            analystBullishReason: [
                "- Analyst coverage: \(facts.analystBuy) Buy, \(facts.analystHold) Hold, \(facts.analystSell) Sell.",
                "- Current valuation multiple stands at P/E of \(peRatio).",
                "- Return on equity (ROE) is \(formattedPercent(facts.roe))."
            ],
            whatCanGoWrong: [
                "- Demand contraction in \(sector) can lead to earnings misses.",
                "- Rising operational costs or debt obligations could reduce net margins.",
                "- Increased industry competition may reduce product pricing power."
            ],
            addressableMarket: [
                "- Primary market demand is anchored in the \(industry) industry.",
                "- Company market capitalization is \(marketCap) on \(marketContext.exchange).",
                "- Long-term growth depends on expanding customer share within \(sector)."
            ],
            employees: [
                "- Full-time workforce: \(employees).",
                "- Labor productivity and headcount costs are critical to operating margins.",
                "- Employee figures reflect latest filings reported by market providers."
            ],
            competitors: competitors,
            growthOpportunities: [
                "- Expanding market share in \(industry) through organic customer acquisition.",
                "- Operating margin expansion if cost efficiencies outpace inflation.",
                "- Strengthening balance sheet resilience and improving return on capital."
            ]
        )
    }

    private func formattedInteger(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func formattedPercent(_ value: Double) -> String {
        guard value != 0 else { return "Data unavailable" }
        let normalized = abs(value) > 1 ? value : value * 100
        let sign = value > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f%%", normalized))"
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
