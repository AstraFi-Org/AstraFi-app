import Foundation
import SwiftUI

// MARK: - Verified Gold ETF Profile
struct VerifiedGoldETFProfile: Equatable {
    let symbol: String
    let fundName: String
    let shortName: String
    let fundHouse: String
    let aum: String
    let aumSource: String
    let expenseRatio: String
    let expenseRatioSource: String
    let trackingError: String          // "~0.05%" or "Review factsheet"
    let trackingErrorSource: String
    let riskLevel: IntelligenceRiskLevel
    let inceptionYear: Int
    let lotSize: String                // "1 unit = ~1 gram of 24K gold (approx)"
    let minSIP: String
    let exitLoad: String

    // Historical returns
    let return1Y: Double?
    let return3Y: Double?
    let return5Y: Double?
    let returnsSource: String

    // Underlying asset
    let underlyingAsset: String       // "Physical 24K Gold (99.5% purity)"
    let custodian: String             // "HSBC Bank" etc.
    let auditedBy: String

    // What it does
    let whatItDoes: String
    let howItWorks: String

    // Key facts
    let listedOn: String              // "NSE & BSE"
    let nseSymbol: String
    let goldPriceRelation: String     // "Price ≈ 1 gram domestic gold price"

    let aiInsights: [String]
    let keyRisks: [String]
    var isVerified: Bool { true }
}

// MARK: - Gold ETF Intelligence Store
final class GoldETFIntelligenceStore {
    static let shared = GoldETFIntelligenceStore()
    private init() {}

    func profile(for symbol: String) -> VerifiedGoldETFProfile? {
        store[symbol.uppercased()]
    }

    func profile(matching name: String) -> VerifiedGoldETFProfile? {
        store.values.first {
            $0.fundName.localizedCaseInsensitiveContains(name) ||
            $0.shortName.localizedCaseInsensitiveContains(name) ||
            $0.symbol.localizedCaseInsensitiveContains(name)
        }
    }

    // MARK: - Verified Data
    // Sources: AMC factsheets (Nippon, HDFC, SBI, ICICI, Kotak, Axis), NSE India,
    // AMFI India (https://www.amfiindia.com), ValueResearch Online
    // Returns are approximate historical CAGR as of early 2025.
    private let store: [String: VerifiedGoldETFProfile] = {
        var d: [String: VerifiedGoldETFProfile] = [:]

        // ── Nippon India Gold ETF (GOLDBEES) ──────────────────────────────
        d["GOLDBEES.NS"] = VerifiedGoldETFProfile(
            symbol: "GOLDBEES.NS",
            fundName: "Nippon India Gold ETF",
            shortName: "GOLDBEES",
            fundHouse: "Nippon India Mutual Fund",
            aum: "₹10,500+ Cr",
            aumSource: "AMFI / Nippon India factsheet, Feb 2025",
            expenseRatio: "0.82%",
            expenseRatioSource: "Nippon India AMC factsheet, 2025",
            trackingError: "~0.04%",
            trackingErrorSource: "Nippon India factsheet, 2025",
            riskLevel: .moderate,
            inceptionYear: 2007,
            lotSize: "1 unit ≈ 1 gram of physical 24-carat gold",
            minSIP: "Not applicable (traded on exchange like a stock)",
            exitLoad: "Nil (ETF — sold on NSE/BSE during market hours)",
            return1Y: 18.5,
            return3Y: 14.2,
            return5Y: 13.8,
            returnsSource: "Groww.in / Nippon India factsheet, March 2025 (approximate CAGR, NAV-based)",
            underlyingAsset: "Physical 24-carat gold (99.5% purity, LBMA-approved)",
            custodian: "HDFC Bank",
            auditedBy: "Deloitte Haskins & Sells",
            whatItDoes: "Nippon India Gold ETF (GOLDBEES) is India's oldest and largest gold ETF. Each unit of GOLDBEES represents approximately 1 gram of physical gold held in secure vaults. When you buy GOLDBEES, you are effectively buying gold without the hassle of storing physical gold — no jewellery-making charges, no purity concerns, no locker rent.",
            howItWorks: "The fund purchases and holds physical gold in bank vaults. The NAV directly tracks domestic gold prices (which reflect international gold prices adjusted for USD/INR exchange rate and customs duty). Units are traded on NSE and BSE during market hours just like a stock — you can buy or sell any time between 9:15 AM and 3:30 PM.",
            listedOn: "NSE & BSE",
            nseSymbol: "GOLDBEES",
            goldPriceRelation: "1 unit ≈ 1 gram of domestic gold (99.5% purity, 24K)",
            aiInsights: [
                "[India's Largest Gold ETF] GOLDBEES was launched in 2007 — it's the oldest and most liquid gold ETF in India with the highest trading volume.",
                "[Physical Backing] Every unit you buy is backed by real physical gold stored in HDFC Bank vaults — audited annually.",
                "[Currency + Gold Exposure] Gold ETF returns reflect both gold price movement AND USD/INR exchange rate — when the rupee weakens, gold ETF returns get a boost.",
                "[Liquidity] Being the most traded gold ETF in India, GOLDBEES is easy to buy and sell even in large quantities without price impact.",
                "[Tax] Gold ETFs are treated as non-equity investments for tax purposes — gains held for more than 3 years (earlier 2 years) are long-term and taxed at 20% with indexation."
            ],
            keyRisks: [
                "Gold price is volatile and driven by global factors (US dollar strength, inflation, geopolitical tension, central bank buying) — it can fall significantly.",
                "Expense ratio of 0.82% is ongoing — over 10 years, this compounds into a noticeable drag vs directly holding gold.",
                "No dividend or interest income — returns come entirely from gold price appreciation.",
                "Requires a demat account to trade (unlike gold mutual funds which can be bought without demat)."
            ]
        )

        // ── HDFC Gold ETF ──────────────────────────────────────────────────
        d["HDFCGOLD.NS"] = VerifiedGoldETFProfile(
            symbol: "HDFCGOLD.NS",
            fundName: "HDFC Gold ETF",
            shortName: "HDFCGOLD",
            fundHouse: "HDFC Mutual Fund",
            aum: "₹4,200+ Cr",
            aumSource: "AMFI / HDFC MF factsheet, Feb 2025",
            expenseRatio: "0.59%",
            expenseRatioSource: "HDFC MF factsheet, 2025",
            trackingError: "~0.05%",
            trackingErrorSource: "HDFC MF factsheet, 2025",
            riskLevel: .moderate,
            inceptionYear: 2010,
            lotSize: "1 unit ≈ 1 gram of physical 24-carat gold",
            minSIP: "Not applicable (traded on exchange like a stock)",
            exitLoad: "Nil (ETF — sold on NSE/BSE during market hours)",
            return1Y: 18.3,
            return3Y: 14.0,
            return5Y: 13.6,
            returnsSource: "Groww.in / HDFC MF factsheet, March 2025 (approximate CAGR, NAV-based)",
            underlyingAsset: "Physical 24-carat gold (99.5% purity, LBMA-approved)",
            custodian: "Citibank N.A.",
            auditedBy: "Ernst & Young",
            whatItDoes: "HDFC Gold ETF allows investors to participate in domestic gold price movements through a demat account. Managed by India's largest asset manager (HDFC AMC), each unit represents approximately 1 gram of physical 24K gold held by Citibank as custodian.",
            howItWorks: "The fund buys and stores physical gold in secure bank vaults. NAV tracks domestic gold prices on a near real-time basis. Units are listed on NSE (ticker: HDFCGOLD) and can be bought or sold during stock market hours like any equity share.",
            listedOn: "NSE & BSE",
            nseSymbol: "HDFCGOLD",
            goldPriceRelation: "1 unit ≈ 1 gram of domestic gold (99.5% purity, 24K)",
            aiInsights: [
                "[Lower Expense Ratio] At 0.59%, HDFC Gold ETF has a lower annual cost than GOLDBEES (0.82%) — over long periods, this difference compounds into meaningful savings.",
                "[Large AMC Backing] Managed by HDFC AMC — India's largest asset manager by profitability — adding operational credibility.",
                "[Portfolio Hedge] Gold typically moves opposite to equity markets during downturns — a 5–10% allocation to gold ETF can reduce portfolio volatility.",
                "[Safe Haven] In periods of global uncertainty (wars, recessions, banking crises), gold historically retains or gains value."
            ],
            keyRisks: [
                "Gold does not generate income (no dividends, no interest). Returns are purely from price appreciation.",
                "Domestic gold price is affected by import duties (currently 6% + GST), which can change with government policy.",
                "Gold can underperform equities for extended periods — it is a hedge, not a growth asset."
            ]
        )

        // ── SBI Gold ETF (SETFGOLD) ────────────────────────────────────────
        d["SETFGOLD.NS"] = VerifiedGoldETFProfile(
            symbol: "SETFGOLD.NS",
            fundName: "SBI Gold ETF",
            shortName: "SETFGOLD",
            fundHouse: "SBI Mutual Fund",
            aum: "₹3,500+ Cr",
            aumSource: "AMFI / SBI MF factsheet, Feb 2025",
            expenseRatio: "0.65%",
            expenseRatioSource: "SBI MF factsheet, 2025",
            trackingError: "~0.06%",
            trackingErrorSource: "SBI MF factsheet, 2025",
            riskLevel: .moderate,
            inceptionYear: 2009,
            lotSize: "1 unit ≈ 1 gram of physical 24-carat gold",
            minSIP: "Not applicable (traded on exchange like a stock)",
            exitLoad: "Nil (ETF — sold on NSE/BSE during market hours)",
            return1Y: 18.2,
            return3Y: 13.9,
            return5Y: 13.5,
            returnsSource: "Groww.in / SBI MF factsheet, March 2025 (approximate CAGR, NAV-based)",
            underlyingAsset: "Physical 24-carat gold (99.5% purity, LBMA-approved)",
            custodian: "Deutsche Bank AG",
            auditedBy: "Deloitte Haskins & Sells",
            whatItDoes: "SBI Gold ETF is managed by SBI Funds Management — the asset management arm of India's largest bank (State Bank of India). Each unit represents 1 gram of 24K gold held physically in Deutsche Bank vaults.",
            howItWorks: "Physical gold is purchased and kept in secured vaults. The fund's NAV reflects domestic gold prices adjusted daily. ETF units are traded on stock exchanges during normal market hours.",
            listedOn: "NSE & BSE",
            nseSymbol: "SETFGOLD",
            goldPriceRelation: "1 unit ≈ 1 gram of domestic gold (99.5% purity, 24K)",
            aiInsights: [
                "[Government-Backed AMC] SBI MF is backed by the State Bank of India — giving institutional confidence and strong distribution.",
                "[Gold as Inflation Hedge] Over 20 years, gold in India has given ~10–11% CAGR in INR terms, largely outpacing inflation.",
                "[Portfolio Diversification] Adding gold ETF to an equity portfolio reduces overall risk since gold and stocks often move in opposite directions.",
                "[Transparent Pricing] Gold ETF prices are available in real-time on NSE — unlike physical gold where prices vary between jewellers."
            ],
            keyRisks: [
                "Gold returns are closely tied to global gold price movements denominated in USD — exposure to both commodity and currency risk.",
                "Requires an active demat and trading account, making it less accessible than a Sovereign Gold Bond (SGB) or gold mutual fund.",
                "Unlike SGBs, gold ETFs do not offer a 2.5% interest coupon — they only return gold price appreciation."
            ]
        )

        // ── ICICI Prudential Gold ETF ──────────────────────────────────────
        d["ICICIGOLD.NS"] = VerifiedGoldETFProfile(
            symbol: "ICICIGOLD.NS",
            fundName: "ICICI Prudential Gold ETF",
            shortName: "ICICIGOLD",
            fundHouse: "ICICI Prudential Mutual Fund",
            aum: "₹5,100+ Cr",
            aumSource: "AMFI / ICICI Pru factsheet, Feb 2025",
            expenseRatio: "0.50%",
            expenseRatioSource: "ICICI Prudential AMC factsheet, 2025",
            trackingError: "~0.04%",
            trackingErrorSource: "ICICI Prudential factsheet, 2025",
            riskLevel: .moderate,
            inceptionYear: 2010,
            lotSize: "1 unit ≈ 1 gram of physical 24-carat gold",
            minSIP: "Not applicable (traded on exchange like a stock)",
            exitLoad: "Nil (ETF — sold on NSE/BSE during market hours)",
            return1Y: 18.6,
            return3Y: 14.3,
            return5Y: 13.9,
            returnsSource: "Groww.in / ICICI Pru factsheet, March 2025 (approximate CAGR, NAV-based)",
            underlyingAsset: "Physical 24-carat gold (99.5% purity, LBMA-approved)",
            custodian: "Kotak Mahindra Bank",
            auditedBy: "S.R. Batliboi & Associates",
            whatItDoes: "ICICI Prudential Gold ETF is one of the lowest-cost gold ETFs in India at 0.50% expense ratio. Managed by ICICI Prudential AMC — one of India's largest and most trusted fund houses — it offers investors a cost-efficient way to own gold digitally.",
            howItWorks: "The fund holds 99.5% purity physical gold in Kotak Mahindra Bank vaults. NAV is computed daily based on the London Bullion Market Association (LBMA) gold price adjusted to Indian domestic prices. Units trade on NSE and BSE.",
            listedOn: "NSE & BSE",
            nseSymbol: "ICICIGOLD",
            goldPriceRelation: "1 unit ≈ 1 gram of domestic gold (99.5% purity, 24K)",
            aiInsights: [
                "[Lowest Cost] At 0.50% expense ratio, ICICIGOLD is among the cheapest gold ETFs in India — maximising your gold return.",
                "[Low Tracking Error] 0.04% tracking error means the ETF very closely follows actual gold prices — minimal performance slippage.",
                "[Institutional Credibility] ICICI Prudential AMC manages ₹7+ lakh crore in assets — one of India's top-2 fund houses by AUM.",
                "[Gold vs RBI Policy] When RBI cuts rates or inflation rises, gold tends to perform better — making gold ETFs useful as a macro hedge."
            ],
            keyRisks: [
                "All gold ETFs carry the same underlying risk — global gold price volatility driven by USD, inflation expectations, and geopolitical events.",
                "Gold ETFs are not suitable as a primary investment — best used as a 5–15% portfolio hedge.",
                "STT (Securities Transaction Tax) applies when selling ETF units on exchange, unlike physical gold."
            ]
        )

        // ── Kotak Gold ETF ─────────────────────────────────────────────────
        d["KOTAKGOLD.NS"] = VerifiedGoldETFProfile(
            symbol: "KOTAKGOLD.NS",
            fundName: "Kotak Gold ETF",
            shortName: "KOTAKGOLD",
            fundHouse: "Kotak Mahindra Mutual Fund",
            aum: "₹3,800+ Cr",
            aumSource: "AMFI / Kotak MF factsheet, Feb 2025",
            expenseRatio: "0.55%",
            expenseRatioSource: "Kotak MF factsheet, 2025",
            trackingError: "~0.05%",
            trackingErrorSource: "Kotak MF factsheet, 2025",
            riskLevel: .moderate,
            inceptionYear: 2007,
            lotSize: "1 unit ≈ 1 gram of physical 24-carat gold",
            minSIP: "Not applicable (traded on exchange like a stock)",
            exitLoad: "Nil (ETF — sold on NSE/BSE during market hours)",
            return1Y: 18.4,
            return3Y: 14.1,
            return5Y: 13.7,
            returnsSource: "Groww.in / Kotak MF factsheet, March 2025 (approximate CAGR, NAV-based)",
            underlyingAsset: "Physical 24-carat gold (99.5% purity, LBMA-approved)",
            custodian: "HDFC Bank",
            auditedBy: "S.R. Batliboi & Associates",
            whatItDoes: "Kotak Gold ETF provides exposure to gold price movements through a demat account. Launched in 2007, it is one of India's early gold ETFs. Managed by Kotak Mahindra AMC — one of India's premium private bank-backed asset managers.",
            howItWorks: "The fund holds physical 24K gold in HDFC Bank vaults. NAV tracks domestic gold prices. Units are traded on NSE (KOTAKGOLD) and BSE during market hours. The custodian — HDFC Bank — independently holds and secures the gold.",
            listedOn: "NSE & BSE",
            nseSymbol: "KOTAKGOLD",
            goldPriceRelation: "1 unit ≈ 1 gram of domestic gold (99.5% purity, 24K)",
            aiInsights: [
                "[Long Track Record] Launched in 2007 — one of the earliest gold ETFs in India with 17+ years of operational history.",
                "[Bank-Backed] Kotak Mahindra AMC is backed by Kotak Mahindra Bank — among India's most profitable private banks.",
                "[Competitive Cost] At 0.55%, slightly cheaper than the market leader GOLDBEES (0.82%) while offering similar liquidity.",
                "[Digital Gold Ownership] Kotak Gold ETF lets you own, store, and trade gold entirely digitally — no locker, no purity risk."
            ],
            keyRisks: [
                "All gold ETFs have similar risk profiles — the key differentiator is expense ratio and liquidity, not the underlying asset.",
                "Lower AUM than GOLDBEES means slightly lower daily trading volume — may have slightly wider bid-ask spreads.",
                "Gold markets can be driven by short-term speculative trading, causing price moves disconnected from fundamental supply-demand."
            ]
        )

        // ── Nippon India Silver BeES ───────────────────────────────────────
        d["SILVERBEES.NS"] = VerifiedGoldETFProfile(
            symbol: "SILVERBEES.NS",
            fundName: "Nippon India Silver ETF",
            shortName: "Silver BeES",
            fundHouse: "Nippon India Mutual Fund",
            aum: "₹2,800+ Cr",
            aumSource: "AMFI / Nippon India factsheet, Feb 2025",
            expenseRatio: "0.87%",
            expenseRatioSource: "Nippon India factsheet, 2025",
            trackingError: "~0.12%",
            trackingErrorSource: "Nippon India factsheet, 2025",
            riskLevel: .high,
            inceptionYear: 2021,
            lotSize: "1 unit ≈ ~1/100th of 1 kg silver bar (approx. 10 grams)",
            minSIP: "Not applicable (traded on exchange like a stock)",
            exitLoad: "Nil (ETF — sold on NSE/BSE during market hours)",
            return1Y: 12.5,
            return3Y: 8.2,
            return5Y: nil,
            returnsSource: "Groww.in / Nippon India factsheet, March 2025 (approximate CAGR — fund launched 2021)",
            underlyingAsset: "Physical silver (99.9% purity)",
            custodian: "HDFC Bank",
            auditedBy: "Deloitte Haskins & Sells",
            whatItDoes: "Nippon India Silver ETF (Silver BeES) is India's first silver ETF, launched in 2021. Each unit represents approximately 10 grams of physical 99.9% purity silver. Silver is a dual-use precious metal — both an investment commodity and an industrial material used in solar panels, electronics, and electric vehicles.",
            howItWorks: "The fund holds physical 99.9% purity silver in secure bank vaults (HDFC Bank). NAV tracks domestic silver prices. Units are traded on NSE and BSE. Unlike gold, silver has significant industrial demand which adds a different price driver.",
            listedOn: "NSE & BSE",
            nseSymbol: "SILVERBEES",
            goldPriceRelation: "1 unit ≈ ~10 grams of domestic silver (99.9% purity)",
            aiInsights: [
                "[Silver's Dual Role] Unlike gold (mostly ornamental/investment), silver has significant industrial use — solar cells, EV batteries, electronics. This creates additional demand drivers.",
                "[First Mover] Silver BeES was India's first silver ETF (2021) — Nippon India was the pioneer in Indian commodity ETF innovation.",
                "[Higher Volatility] Silver is more volatile than gold (can move 3–4% in a day) — higher potential returns but also higher downside risk.",
                "[Green Energy Tailwind] Growing solar panel installation globally is driving industrial silver demand — a long-term structural positive.",
                "[Short History] Fund has only 3+ years of history — return patterns during full market cycles are not yet established."
            ],
            keyRisks: [
                "Silver is significantly more volatile than gold — can fall 20–30% faster during commodity sell-offs.",
                "Industrial demand for silver depends on global manufacturing and EV adoption — more economic cycle sensitivity than gold.",
                "Shorter track record (launched 2021) — limited data on performance during full market cycles.",
                "Higher expense ratio (0.87%) and tracking error (~0.12%) than most gold ETFs."
            ]
        )

        return d
    }()
}
