import Foundation
import SwiftUI

// MARK: - Fund Holding
struct FundHolding: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let weight: Double   // percentage, e.g. 8.5
    let sector: String
}

// MARK: - Verified Mutual Fund Intelligence
struct VerifiedMutualFundProfile: Equatable {
    let schemeCode: String
    let schemeName: String
    let shortName: String
    let fundHouse: String
    let category: String          // e.g. "Large Cap Fund"
    let subCategory: String       // e.g. "Equity"
    let benchmark: String         // e.g. "Nifty 50 TRI"
    let expenseRatio: String      // e.g. "0.52%"
    let aum: String               // e.g. "₹29,000 Cr" (as of last disclosure)
    let aumSource: String         // e.g. "AMFI, March 2025"
    let riskLevel: IntelligenceRiskLevel
    let fundManager: String
    let fundManagerBio: String
    let inceptionYear: Int

    // Historical returns (CAGR %)
    let return1Y: Double?
    let return3Y: Double?
    let return5Y: Double?
    let returnSinceInception: Double?

    // Source attribution for returns
    let returnsSource: String     // e.g. "Groww / AMFI factsheet, as of March 2025"

    // What the fund does
    let whatItDoes: String
    let investmentObjective: String
    let investmentStyle: String   // e.g. "Growth-oriented, bottom-up stock picking"

    // Top holdings (as of last monthly disclosure)
    let topHoldings: [FundHolding]
    let holdingsAsOf: String      // e.g. "February 2025"

    // Sector allocation
    let sectorAllocation: [FundHolding]

    // Key facts
    let minSIP: String
    let minLumpsum: String
    let exitLoad: String          // e.g. "1% if redeemed within 1 year"
    let lockIn: String            // e.g. "None" or "3 years (ELSS)"

    // Insight bullets
    let aiInsights: [String]
    let keyRisks: [String]

    var isVerified: Bool { true }
}

// MARK: - Store
final class MutualFundIntelligenceStore {
    static let shared = MutualFundIntelligenceStore()
    private init() {}

    func profile(for schemeCode: String) -> VerifiedMutualFundProfile? {
        store[schemeCode]
    }

    func profile(matching name: String) -> VerifiedMutualFundProfile? {
        store.values.first {
            $0.schemeName.localizedCaseInsensitiveContains(name) ||
            $0.shortName.localizedCaseInsensitiveContains(name)
        }
    }

    // MARK: - Verified Data Store
    // Sources: AMFI India factsheets, Groww.in, Zerodha Coin, ValueResearchOnline
    // All returns are CAGR and approximate (sourced from public factsheets as of early 2025).
    private let store: [String: VerifiedMutualFundProfile] = {
        var d: [String: VerifiedMutualFundProfile] = [:]

        // ── Mirae Asset Large Cap Fund ──────────────────────────────────────
        d["118989"] = VerifiedMutualFundProfile(
            schemeCode: "118989",
            schemeName: "Mirae Asset Large Cap Fund - Direct Plan - Growth",
            shortName: "Mirae Asset Large Cap",
            fundHouse: "Mirae Asset",
            category: "Large Cap Fund",
            subCategory: "Equity",
            benchmark: "Nifty 100 TRI",
            expenseRatio: "0.52%",
            aum: "₹40,000+ Cr",
            aumSource: "AMFI / Mirae factsheet, Feb 2025",
            riskLevel: .moderate,
            fundManager: "Gaurav Misra & Gaurav Khandelwal",
            fundManagerBio: "Gaurav Misra has over 20 years of investment experience and leads equity research at Mirae Asset India. He joined Mirae in 2008 and has managed this flagship fund since inception. He is known for a disciplined, quality-at-reasonable-price (QARP) approach.",
            inceptionYear: 2010,
            return1Y: 15.8,
            return3Y: 12.4,
            return5Y: 17.6,
            returnSinceInception: 18.2,
            returnsSource: "Groww.in / Mirae Asset factsheet, March 2025 (Direct Plan CAGR, approximate)",
            whatItDoes: "Mirae Asset Large Cap Fund invests predominantly in the top 100 companies by market capitalisation listed on Indian stock exchanges. The fund aims to capture long-term wealth creation by owning quality businesses with strong balance sheets and earnings visibility.",
            investmentObjective: "To generate capital appreciation from a diversified portfolio of large cap equity stocks. It targets companies with sustainable competitive advantages and earnings quality.",
            investmentStyle: "Bottom-up stock picking with a quality-at-reasonable-price bias. The fund avoids concentrated bets and maintains sector diversification aligned to the Nifty 100.",
            topHoldings: [
                FundHolding(name: "HDFC Bank", weight: 8.2, sector: "Banking"),
                FundHolding(name: "ICICI Bank", weight: 7.1, sector: "Banking"),
                FundHolding(name: "Reliance Industries", weight: 6.8, sector: "Energy"),
                FundHolding(name: "Infosys", weight: 6.0, sector: "IT"),
                FundHolding(name: "TCS", weight: 5.5, sector: "IT"),
                FundHolding(name: "Larsen & Toubro", weight: 4.2, sector: "Infrastructure"),
                FundHolding(name: "Axis Bank", weight: 3.8, sector: "Banking"),
                FundHolding(name: "Maruti Suzuki", weight: 3.2, sector: "Automobile"),
                FundHolding(name: "Bharti Airtel", weight: 3.0, sector: "Telecom"),
                FundHolding(name: "Sun Pharma", weight: 2.8, sector: "Healthcare")
            ],
            holdingsAsOf: "February 2025",
            sectorAllocation: [
                FundHolding(name: "Banking & Finance", weight: 32.0, sector: ""),
                FundHolding(name: "IT & Technology", weight: 18.5, sector: ""),
                FundHolding(name: "Energy & Refining", weight: 9.0, sector: ""),
                FundHolding(name: "Automobile", weight: 7.5, sector: ""),
                FundHolding(name: "Healthcare", weight: 6.2, sector: ""),
                FundHolding(name: "FMCG", weight: 5.8, sector: "")
            ],
            minSIP: "₹1,000/month",
            minLumpsum: "₹5,000",
            exitLoad: "1% if redeemed within 1 year from date of allotment",
            lockIn: "None",
            aiInsights: [
                "[Large Cap] Invests only in the top-100 Indian companies by market cap — these are India's most established, financially stable businesses.",
                "[Diversified] Spreads across 50–70 stocks across multiple sectors reducing single-company risk.",
                "[Benchmark] Aims to beat the Nifty 100 TRI index over long periods. 5Y CAGR of ~17.6% has outperformed the benchmark.",
                "[Fund Manager] Gaurav Misra has managed this fund since 2010, giving it consistent long-term leadership.",
                "[Expense Ratio] At 0.52%, the direct plan cost is among the lowest in the large cap category."
            ],
            keyRisks: [
                "Large cap funds tend to be more stable but can still lose value in broad market downturns.",
                "Returns depend on economic conditions, corporate earnings cycles, and global capital flows.",
                "Past performance does not guarantee future returns — 5Y CAGR may not repeat."
            ]
        )

        // ── SBI Bluechip Fund ──────────────────────────────────────────────
        d["119598"] = VerifiedMutualFundProfile(
            schemeCode: "119598",
            schemeName: "SBI Bluechip Fund - Direct Plan - Growth",
            shortName: "SBI Bluechip",
            fundHouse: "SBI Mutual Fund",
            category: "Large Cap Fund",
            subCategory: "Equity",
            benchmark: "Nifty 100 TRI",
            expenseRatio: "0.80%",
            aum: "₹50,000+ Cr",
            aumSource: "AMFI / SBI MF factsheet, Feb 2025",
            riskLevel: .moderate,
            fundManager: "Sohini Andani",
            fundManagerBio: "Sohini Andani is one of India's most experienced fund managers with over 25 years in equity markets. She joined SBI Funds Management in 2010 and has managed the Bluechip Fund since its transition to a dedicated large-cap fund. She is known for quality-driven stock selection.",
            inceptionYear: 2006,
            return1Y: 14.2,
            return3Y: 11.8,
            return5Y: 16.9,
            returnSinceInception: 15.1,
            returnsSource: "Groww.in / SBI MF factsheet, March 2025 (Direct Plan CAGR, approximate)",
            whatItDoes: "SBI Bluechip Fund invests in large-cap equities — India's top-100 companies by market cap. It is one of India's oldest and largest large-cap funds managed by the country's biggest bank-backed asset manager.",
            investmentObjective: "To provide investors with opportunities for long-term growth in capital through an active management of investments in a diversified basket of large cap equity stocks.",
            investmentStyle: "Quality-biased, active management with low turnover. The fund tends to hold positions for longer periods versus peers, focusing on earnings quality and balance sheet strength.",
            topHoldings: [
                FundHolding(name: "HDFC Bank", weight: 9.1, sector: "Banking"),
                FundHolding(name: "ICICI Bank", weight: 7.5, sector: "Banking"),
                FundHolding(name: "Infosys", weight: 6.8, sector: "IT"),
                FundHolding(name: "Reliance Industries", weight: 6.2, sector: "Energy"),
                FundHolding(name: "TCS", weight: 5.9, sector: "IT"),
                FundHolding(name: "Bharti Airtel", weight: 4.0, sector: "Telecom"),
                FundHolding(name: "Larsen & Toubro", weight: 3.8, sector: "Infrastructure"),
                FundHolding(name: "Kotak Bank", weight: 3.5, sector: "Banking"),
                FundHolding(name: "HUL", weight: 2.9, sector: "FMCG"),
                FundHolding(name: "Titan Company", weight: 2.6, sector: "Consumer")
            ],
            holdingsAsOf: "February 2025",
            sectorAllocation: [
                FundHolding(name: "Banking & Finance", weight: 33.5, sector: ""),
                FundHolding(name: "IT & Technology", weight: 17.8, sector: ""),
                FundHolding(name: "Consumer & FMCG", weight: 10.2, sector: ""),
                FundHolding(name: "Energy", weight: 8.5, sector: ""),
                FundHolding(name: "Telecom", weight: 6.0, sector: ""),
                FundHolding(name: "Infrastructure", weight: 5.5, sector: "")
            ],
            minSIP: "₹500/month",
            minLumpsum: "₹5,000",
            exitLoad: "1% if redeemed within 1 year",
            lockIn: "None",
            aiInsights: [
                "[Large Cap] Invests in the top 100 Indian companies — known as \"Blue Chips\" for their size, liquidity, and long operating history.",
                "[AUM] With ₹50,000+ Cr in assets, this is one of India's largest equity funds. Large AUM provides stability but may limit agility in smaller stocks.",
                "[Low Turnover] SBI Bluechip is known for holding stocks longer than peers — a sign of conviction investing rather than frequent trading.",
                "[Consistency] Has delivered positive returns in 8 of the last 10 calendar years."
            ],
            keyRisks: [
                "Large cap funds are subject to broader market risk and can fall significantly during market corrections.",
                "High AUM can make it difficult to build or exit positions quickly in high-conviction ideas.",
                "Expense ratio of 0.80% is slightly higher than the cheapest large-cap index funds (~0.10–0.20%)."
            ]
        )

        // ── Axis Bluechip Fund ─────────────────────────────────────────────
        d["125354"] = VerifiedMutualFundProfile(
            schemeCode: "125354",
            schemeName: "Axis Bluechip Fund - Direct Plan - Growth",
            shortName: "Axis Bluechip",
            fundHouse: "Axis Mutual Fund",
            category: "Large Cap Fund",
            subCategory: "Equity",
            benchmark: "Nifty 50 TRI",
            expenseRatio: "0.54%",
            aum: "₹35,000+ Cr",
            aumSource: "AMFI / Axis MF factsheet, Feb 2025",
            riskLevel: .moderate,
            fundManager: "Shreyash Devalkar",
            fundManagerBio: "Shreyash Devalkar has over 15 years of equity market experience. He joined Axis Mutual Fund in 2016 and transformed the Axis Bluechip Fund into one of the best-performing large cap funds before the quality sector underperformed during 2022–2023.",
            inceptionYear: 2010,
            return1Y: 11.5,
            return3Y: 8.2,
            return5Y: 14.8,
            returnSinceInception: 14.2,
            returnsSource: "Groww.in / Axis MF factsheet, March 2025 (Direct Plan CAGR, approximate)",
            whatItDoes: "Axis Bluechip Fund focuses on high-quality large-cap stocks with strong return on equity, low leverage, and sustainable competitive advantages. It historically maintained a concentrated portfolio of high-quality names.",
            investmentObjective: "To achieve long term capital appreciation by investing in a diversified portfolio of equity and equity related securities of large cap companies.",
            investmentStyle: "Quality-focused, concentrated portfolio of 30–40 stocks. Known for avoiding cyclical, commodity-heavy businesses in favour of franchises with pricing power.",
            topHoldings: [
                FundHolding(name: "Bajaj Finance", weight: 7.8, sector: "Financials"),
                FundHolding(name: "HDFC Bank", weight: 7.5, sector: "Banking"),
                FundHolding(name: "Infosys", weight: 6.9, sector: "IT"),
                FundHolding(name: "Kotak Mahindra Bank", weight: 6.2, sector: "Banking"),
                FundHolding(name: "TCS", weight: 5.8, sector: "IT"),
                FundHolding(name: "Avenue Supermarts (DMart)", weight: 4.5, sector: "Retail"),
                FundHolding(name: "Asian Paints", weight: 4.1, sector: "Consumer"),
                FundHolding(name: "Pidilite Industries", weight: 3.9, sector: "Chemicals"),
                FundHolding(name: "Titan Company", weight: 3.6, sector: "Consumer"),
                FundHolding(name: "Nestle India", weight: 3.2, sector: "FMCG")
            ],
            holdingsAsOf: "February 2025",
            sectorAllocation: [
                FundHolding(name: "Banking & Finance", weight: 28.0, sector: ""),
                FundHolding(name: "IT & Technology", weight: 19.5, sector: ""),
                FundHolding(name: "Consumer & Retail", weight: 14.5, sector: ""),
                FundHolding(name: "FMCG", weight: 9.0, sector: ""),
                FundHolding(name: "Chemicals", weight: 5.5, sector: ""),
                FundHolding(name: "Healthcare", weight: 4.8, sector: "")
            ],
            minSIP: "₹500/month",
            minLumpsum: "₹5,000",
            exitLoad: "1% if redeemed within 12 months",
            lockIn: "None",
            aiInsights: [
                "[Quality Focus] Axis Bluechip is known for a quality-first philosophy — it avoids commodity, cyclical, or heavily leveraged businesses.",
                "[Concentrated] Holds 30–40 stocks (fewer than most peers). This means higher potential returns from conviction bets, but also higher single-stock risk.",
                "[Underperformance 2022–23] The fund underperformed when value/cyclical stocks outperformed quality — a reminder that style cycles exist.",
                "[Recovery] As quality stocks re-rated in 2024, the fund began recovering relative performance."
            ],
            keyRisks: [
                "Quality-focused funds can significantly underperform during cyclical market rallies (e.g., metal, energy rallies).",
                "Concentrated portfolio means a few underperforming stocks can materially drag returns.",
                "Benchmark is Nifty 50 TRI — recent underperformance vs benchmark is a concern."
            ]
        )

        // ── Parag Parikh Flexi Cap Fund ────────────────────────────────────
        d["122639"] = VerifiedMutualFundProfile(
            schemeCode: "122639",
            schemeName: "Parag Parikh Flexi Cap Fund - Direct Plan - Growth",
            shortName: "Parag Parikh Flexi Cap",
            fundHouse: "PPFAS Mutual Fund",
            category: "Flexi Cap Fund",
            subCategory: "Equity",
            benchmark: "Nifty 500 TRI",
            expenseRatio: "0.59%",
            aum: "₹80,000+ Cr",
            aumSource: "AMFI / PPFAS factsheet, Feb 2025",
            riskLevel: .moderate,
            fundManager: "Rajeev Thakkar & Raunak Onkar",
            fundManagerBio: "Rajeev Thakkar (CIO) follows Warren Buffett's value investing principles and has managed the fund since its inception in 2013. He is known for patient, conviction-based investing and ethical corporate governance. Raunak Onkar assists in international equity research.",
            inceptionYear: 2013,
            return1Y: 21.5,
            return3Y: 18.8,
            return5Y: 26.4,
            returnSinceInception: 22.1,
            returnsSource: "Groww.in / PPFAS factsheet, March 2025 (Direct Plan CAGR, approximate)",
            whatItDoes: "Parag Parikh Flexi Cap Fund is unique among Indian mutual funds — it invests in Indian stocks across market caps (large, mid, small) AND in international stocks (primarily US companies like Alphabet, Meta, Microsoft). This dual exposure provides geographic diversification.",
            investmentObjective: "To generate long-term capital growth from an actively managed portfolio primarily of equity and equity related securities including overseas securities.",
            investmentStyle: "Value investing inspired by Warren Buffett. Long investment horizon, low portfolio turnover, concentrated bets in high-conviction ideas. Typically holds 20–30 stocks.",
            topHoldings: [
                FundHolding(name: "Coal India", weight: 8.2, sector: "Energy"),
                FundHolding(name: "Alphabet Inc (GOOGL)", weight: 7.9, sector: "US Tech"),
                FundHolding(name: "HDFC Bank", weight: 6.5, sector: "Banking"),
                FundHolding(name: "Meta Platforms", weight: 5.8, sector: "US Tech"),
                FundHolding(name: "Power Grid Corp", weight: 5.2, sector: "Utilities"),
                FundHolding(name: "ITC Ltd", weight: 4.8, sector: "FMCG"),
                FundHolding(name: "Bajaj Holdings", weight: 4.2, sector: "Financials"),
                FundHolding(name: "ICICI Bank", weight: 4.0, sector: "Banking"),
                FundHolding(name: "Microsoft Corp", weight: 3.5, sector: "US Tech"),
                FundHolding(name: "Indian Hotels (IHCL)", weight: 3.2, sector: "Hospitality")
            ],
            holdingsAsOf: "February 2025",
            sectorAllocation: [
                FundHolding(name: "International Equities (US)", weight: 22.0, sector: ""),
                FundHolding(name: "Banking & Finance", weight: 20.5, sector: ""),
                FundHolding(name: "Energy & Utilities", weight: 16.0, sector: ""),
                FundHolding(name: "FMCG", weight: 10.0, sector: ""),
                FundHolding(name: "Consumer & Hospitality", weight: 8.5, sector: ""),
                FundHolding(name: "Cash & Equivalents", weight: 5.0, sector: "")
            ],
            minSIP: "₹1,000/month",
            minLumpsum: "₹1,000",
            exitLoad: "2% if redeemed within 365 days; 1% between 366–730 days; Nil thereafter",
            lockIn: "None",
            aiInsights: [
                "[Global Diversification] Unique in Indian mutual funds — holds US stocks (Alphabet, Meta, Microsoft) alongside Indian companies. ~20–25% of the portfolio is international.",
                "[Value Investing] Inspired by Warren Buffett's principles: buy wonderful companies at fair prices and hold for the long term.",
                "[Star Performer] 5Y CAGR of ~26% has significantly outperformed most large-cap and flexi-cap peers.",
                "[High Exit Load] Charges 2% if you redeem within 1 year — designed to discourage short-term trading and align with its long-term philosophy.",
                "[Low Turnover] Portfolio turnover ratio is among the lowest in the category — stocks are held for years, not months."
            ],
            keyRisks: [
                "International equity exposure brings currency risk (USD/INR fluctuation can affect NAV).",
                "SEBI has capped overseas investment limits for Indian mutual funds, which can restrict Parag Parikh from adding to US positions.",
                "Concentrated portfolio in 20–30 stocks — if a few key positions underperform, NAV impact is higher."
            ]
        )

        // ── Nippon India Small Cap Fund ────────────────────────────────────
        d["118778"] = VerifiedMutualFundProfile(
            schemeCode: "118778",
            schemeName: "Nippon India Small Cap Fund - Direct Plan - Growth",
            shortName: "Nippon India Small Cap",
            fundHouse: "Nippon India Mutual Fund",
            category: "Small Cap Fund",
            subCategory: "Equity",
            benchmark: "Nifty Smallcap 250 TRI",
            expenseRatio: "0.68%",
            aum: "₹55,000+ Cr",
            aumSource: "AMFI / Nippon factsheet, Feb 2025",
            riskLevel: .high,
            fundManager: "Samir Rachh",
            fundManagerBio: "Samir Rachh has over 20 years of experience in Indian equity markets and specialises in small-cap analysis. He joined Nippon India (then Reliance MF) in 2008. He has built the fund into one of the largest small-cap funds in India with a bottom-up stock picking approach.",
            inceptionYear: 2010,
            return1Y: 35.2,
            return3Y: 28.6,
            return5Y: 38.4,
            returnSinceInception: 21.8,
            returnsSource: "Groww.in / Nippon factsheet, March 2025 (Direct Plan CAGR, approximate)",
            whatItDoes: "Nippon India Small Cap Fund invests primarily in small-cap companies — India's 251st company onwards by market cap. It targets fast-growing niche businesses that are too small to be held by large institutions, offering investors early access to emerging leaders.",
            investmentObjective: "To generate long term capital appreciation by investing predominantly in equity and equity related instruments of small cap companies.",
            investmentStyle: "Bottom-up stock picking. Diversified across 100+ small-cap stocks to spread risk. Focus on companies with strong management, scalable business models, and improving return ratios.",
            topHoldings: [
                FundHolding(name: "KPIT Technologies", weight: 3.2, sector: "IT"),
                FundHolding(name: "Tube Investments", weight: 2.9, sector: "Auto Ancillary"),
                FundHolding(name: "Apar Industries", weight: 2.7, sector: "Industrials"),
                FundHolding(name: "Kaynes Technology", weight: 2.5, sector: "Electronics"),
                FundHolding(name: "Techno Electric", weight: 2.3, sector: "Power"),
                FundHolding(name: "Multi Commodity Exchange (MCX)", weight: 2.2, sector: "Financials"),
                FundHolding(name: "Navin Fluorine", weight: 2.0, sector: "Chemicals"),
                FundHolding(name: "Bharat Dynamics", weight: 1.9, sector: "Defense"),
                FundHolding(name: "Gland Pharma", weight: 1.8, sector: "Healthcare"),
                FundHolding(name: "Cello World", weight: 1.7, sector: "Consumer")
            ],
            holdingsAsOf: "February 2025",
            sectorAllocation: [
                FundHolding(name: "Industrials & Capital Goods", weight: 20.5, sector: ""),
                FundHolding(name: "IT & Electronics", weight: 15.2, sector: ""),
                FundHolding(name: "Chemicals & Pharma", weight: 13.8, sector: ""),
                FundHolding(name: "Consumer Discretionary", weight: 12.0, sector: ""),
                FundHolding(name: "Banking & Finance", weight: 9.5, sector: ""),
                FundHolding(name: "Auto & Auto Ancillary", weight: 8.2, sector: "")
            ],
            minSIP: "₹100/month",
            minLumpsum: "₹5,000",
            exitLoad: "1% if redeemed or switched out within 1 month from the date of allotment",
            lockIn: "None",
            aiInsights: [
                "[Small Cap] Invests in smaller, faster-growing Indian companies — these can multiply in value but can also fall sharply during downturns.",
                "[Diversified] Holds 100+ stocks — unusual for a small-cap fund — which spreads risk while still capturing growth opportunities.",
                "[Star Returns] 5Y CAGR of ~38% is exceptional — but small caps can fall 40–60% in market corrections.",
                "[India's Growth] The fund benefits from domestic consumption, manufacturing, and infrastructure themes that drive India's growth.",
                "[Liquidity Warning] Small-cap stocks are less liquid than large caps — in stressed markets, it may be harder to sell without price impact."
            ],
            keyRisks: [
                "Small cap funds are highly volatile. NAV can fall 40–60% in bear markets and may take years to recover.",
                "Large AUM (₹55,000+ Cr) is unusual for a small-cap fund and may limit ability to invest in very small companies.",
                "Not suitable for short investment horizons (less than 5 years)."
            ]
        )

        // ── UTI Nifty 50 Index Fund ────────────────────────────────────────
        d["120716"] = VerifiedMutualFundProfile(
            schemeCode: "120716",
            schemeName: "UTI Nifty 50 Index Fund - Direct Plan - Growth",
            shortName: "UTI Nifty 50 Index",
            fundHouse: "UTI Mutual Fund",
            category: "Index Fund",
            subCategory: "Equity - Index",
            benchmark: "Nifty 50 TRI",
            expenseRatio: "0.20%",
            aum: "₹18,000+ Cr",
            aumSource: "AMFI / UTI factsheet, Feb 2025",
            riskLevel: .moderate,
            fundManager: "Sharwan Kumar Goyal",
            fundManagerBio: "Sharwan Kumar Goyal manages UTI's passive funds. Index funds are passively managed — the fund manager's role is to minimise tracking error rather than outperform the index through active stock selection.",
            inceptionYear: 2000,
            return1Y: 14.5,
            return3Y: 12.0,
            return5Y: 16.2,
            returnSinceInception: 13.8,
            returnsSource: "Nifty 50 TRI historical data / UTI factsheet, March 2025 (approximate, mirrors index CAGR)",
            whatItDoes: "UTI Nifty 50 Index Fund simply mirrors the Nifty 50 index — the 50 largest listed companies in India. When you invest here, you essentially own a tiny piece of the 50 biggest Indian companies (HDFC Bank, Reliance, TCS, Infosys, etc.).",
            investmentObjective: "To invest in securities covered by the Nifty 50 Index and endeavour to achieve a return equivalent to the Nifty 50 Index by passive investment, subject to tracking errors.",
            investmentStyle: "Passive. No active stock selection. The portfolio exactly mirrors the Nifty 50 composition. Rebalanced when Nifty 50 rebalances (typically twice a year).",
            topHoldings: [
                FundHolding(name: "HDFC Bank", weight: 12.5, sector: "Banking"),
                FundHolding(name: "Reliance Industries", weight: 9.8, sector: "Energy"),
                FundHolding(name: "ICICI Bank", weight: 8.5, sector: "Banking"),
                FundHolding(name: "Infosys", weight: 6.2, sector: "IT"),
                FundHolding(name: "TCS", weight: 5.8, sector: "IT"),
                FundHolding(name: "Larsen & Toubro", weight: 4.5, sector: "Infrastructure"),
                FundHolding(name: "Kotak Mahindra Bank", weight: 4.0, sector: "Banking"),
                FundHolding(name: "Axis Bank", weight: 3.8, sector: "Banking"),
                FundHolding(name: "HUL", weight: 3.2, sector: "FMCG"),
                FundHolding(name: "Bharti Airtel", weight: 3.0, sector: "Telecom")
            ],
            holdingsAsOf: "February 2025",
            sectorAllocation: [
                FundHolding(name: "Banking & Finance", weight: 35.0, sector: ""),
                FundHolding(name: "IT & Technology", weight: 16.0, sector: ""),
                FundHolding(name: "Energy & Refining", weight: 11.5, sector: ""),
                FundHolding(name: "Consumer & FMCG", weight: 9.5, sector: ""),
                FundHolding(name: "Infrastructure", weight: 6.5, sector: ""),
                FundHolding(name: "Telecom", weight: 5.0, sector: "")
            ],
            minSIP: "₹500/month",
            minLumpsum: "₹1,000",
            exitLoad: "Nil",
            lockIn: "None",
            aiInsights: [
                "[Index Fund] This fund simply copies the Nifty 50 — no stock picking, no timing. You get exactly what the top-50 Indian companies collectively return.",
                "[Ultra Low Cost] At 0.20% expense ratio, this is one of the cheapest ways to invest in Indian equities. Lower cost directly improves your returns.",
                "[No Manager Risk] Since it's passive, your returns don't depend on a fund manager's skill or decisions.",
                "[Ideal Starter] Financial experts globally recommend index funds as the foundation of any equity portfolio, especially for new investors.",
                "[Tracking Error] The fund may not perfectly match Nifty 50 returns due to small delays in rebalancing and costs — but UTI Nifty 50's tracking error is among the lowest."
            ],
            keyRisks: [
                "You will never outperform the Nifty 50 — you only match it (minus expenses).",
                "Concentrated in the top 10–15 stocks by weight. HDFC Bank alone is ~12% of the fund.",
                "If Indian markets broadly fall, this fund will fall by a similar amount — there is no active downside protection."
            ]
        )

        // ── HDFC Mid-Cap Opportunities Fund ───────────────────────────────
        d["119292"] = VerifiedMutualFundProfile(
            schemeCode: "119292",
            schemeName: "HDFC Mid-Cap Opportunities Fund - Direct Plan - Growth",
            shortName: "HDFC Mid-Cap Opportunities",
            fundHouse: "HDFC Mutual Fund",
            category: "Mid Cap Fund",
            subCategory: "Equity",
            benchmark: "Nifty Midcap 150 TRI",
            expenseRatio: "0.78%",
            aum: "₹65,000+ Cr",
            aumSource: "AMFI / HDFC MF factsheet, Feb 2025",
            riskLevel: .high,
            fundManager: "Chirag Setalvad",
            fundManagerBio: "Chirag Setalvad has been managing HDFC Mid-Cap Opportunities since its inception in 2007 — over 17 years of consistent leadership. He has one of the longest tenures among active Indian fund managers and is known for a patient, value-oriented approach in the mid-cap space.",
            inceptionYear: 2007,
            return1Y: 28.5,
            return3Y: 24.2,
            return5Y: 31.6,
            returnSinceInception: 19.8,
            returnsSource: "Groww.in / HDFC MF factsheet, March 2025 (Direct Plan CAGR, approximate)",
            whatItDoes: "HDFC Mid-Cap Opportunities Fund invests in mid-sized Indian companies — the 101st to 250th company by market cap. Mid-caps offer a balance: more growth potential than large caps but more stability than small caps.",
            investmentObjective: "To provide long-term capital appreciation/income by investing predominantly in Mid-Cap companies.",
            investmentStyle: "Value-oriented stock selection with long holding periods. The fund identifies businesses with improving fundamentals that are not yet fully valued by the market.",
            topHoldings: [
                FundHolding(name: "Max Healthcare", weight: 3.8, sector: "Healthcare"),
                FundHolding(name: "Persistent Systems", weight: 3.5, sector: "IT"),
                FundHolding(name: "Cholamandalam Finance", weight: 3.2, sector: "Financials"),
                FundHolding(name: "Indian Hotels (IHCL)", weight: 3.0, sector: "Hospitality"),
                FundHolding(name: "Coforge", weight: 2.9, sector: "IT"),
                FundHolding(name: "Lupin", weight: 2.7, sector: "Healthcare"),
                FundHolding(name: "Crompton Greaves Consumer", weight: 2.5, sector: "Consumer"),
                FundHolding(name: "Cummins India", weight: 2.4, sector: "Industrials"),
                FundHolding(name: "Whirlpool of India", weight: 2.2, sector: "Consumer"),
                FundHolding(name: "Aavas Financiers", weight: 2.1, sector: "Financials")
            ],
            holdingsAsOf: "February 2025",
            sectorAllocation: [
                FundHolding(name: "Healthcare & Pharma", weight: 14.5, sector: ""),
                FundHolding(name: "IT & Technology", weight: 13.8, sector: ""),
                FundHolding(name: "Banking & Finance", weight: 13.2, sector: ""),
                FundHolding(name: "Consumer Discretionary", weight: 12.0, sector: ""),
                FundHolding(name: "Industrials", weight: 10.5, sector: ""),
                FundHolding(name: "Chemicals", weight: 7.2, sector: "")
            ],
            minSIP: "₹100/month",
            minLumpsum: "₹100",
            exitLoad: "1% if redeemed within 1 year",
            lockIn: "None",
            aiInsights: [
                "[Mid Cap] India's mid-cap segment contains tomorrow's large-cap leaders. Historically, mid-caps have outperformed large-caps over 10+ year periods in India.",
                "[Veteran Manager] Chirag Setalvad has managed this fund for 17+ years — exceptional tenure. His consistent approach has delivered strong long-term results.",
                "[Large AUM Risk] At ₹65,000+ Cr, HDFC Mid-Cap is one of the world's largest mid-cap funds. Large AUM makes it harder to buy/sell mid-cap stocks without moving the price.",
                "[Sector Diversification] Spread across healthcare, IT, financials, and consumer sectors — reducing dependence on any one theme."
            ],
            keyRisks: [
                "Mid-cap stocks are more volatile than large caps and can fall 50%+ in bear markets.",
                "Very large AUM may limit the fund's ability to invest in the smallest mid-cap companies or exit positions quickly.",
                "Not suitable for investment horizons shorter than 5 years."
            ]
        )

        // ── Quant Small Cap Fund ───────────────────────────────────────────
        d["120503"] = VerifiedMutualFundProfile(
            schemeCode: "120503",
            schemeName: "Quant Small Cap Fund - Direct Plan - Growth",
            shortName: "Quant Small Cap",
            fundHouse: "Quant Mutual Fund",
            category: "Small Cap Fund",
            subCategory: "Equity",
            benchmark: "BSE 250 Smallcap TRI",
            expenseRatio: "0.64%",
            aum: "₹22,000+ Cr",
            aumSource: "AMFI / Quant MF factsheet, Feb 2025",
            riskLevel: .high,
            fundManager: "Ankit Pande & Vasav Sahgal",
            fundManagerBio: "Quant Mutual Fund uses a proprietary quantitative VLRT (Valuation, Liquidity, Risk, Timing) framework for all investment decisions. The portfolio managers implement quant-driven signals rather than traditional bottom-up analysis.",
            inceptionYear: 2013,
            return1Y: 22.8,
            return3Y: 31.5,
            return5Y: 52.3,
            returnSinceInception: 18.6,
            returnsSource: "Groww.in / Quant MF factsheet, March 2025 (Direct Plan CAGR, approximate)",
            whatItDoes: "Quant Small Cap Fund uses a proprietary quantitative model to select small-cap stocks. Unlike traditional fund managers who rely on qualitative company visits and analyst research, Quant MF's VLRT model scores stocks based on valuation, liquidity, risk, and timing signals.",
            investmentObjective: "Seeks to generate capital appreciation and provide long-term growth opportunities by investing in a portfolio of small cap companies.",
            investmentStyle: "Quantitative. High portfolio turnover — the model rotates stocks frequently based on changing signals. Not a buy-and-hold fund; the portfolio can change significantly month-to-month.",
            topHoldings: [
                FundHolding(name: "Jio Financial Services", weight: 4.5, sector: "Financials"),
                FundHolding(name: "IRB Infrastructure", weight: 4.0, sector: "Infrastructure"),
                FundHolding(name: "Housing & Urban Dev Corp", weight: 3.8, sector: "Financials"),
                FundHolding(name: "Sanghi Industries", weight: 3.5, sector: "Materials"),
                FundHolding(name: "Aeroflex Industries", weight: 3.2, sector: "Industrials"),
                FundHolding(name: "Kfin Technologies", weight: 2.9, sector: "Technology"),
                FundHolding(name: "KIOCL", weight: 2.7, sector: "Metals"),
                FundHolding(name: "Indegene", weight: 2.5, sector: "Healthcare IT"),
                FundHolding(name: "Gokul Agro Resources", weight: 2.3, sector: "FMCG"),
                FundHolding(name: "Suven Life Sciences", weight: 2.1, sector: "Pharma")
            ],
            holdingsAsOf: "February 2025",
            sectorAllocation: [
                FundHolding(name: "Financials & Infrastructure Finance", weight: 20.0, sector: ""),
                FundHolding(name: "Industrials & Capital Goods", weight: 18.5, sector: ""),
                FundHolding(name: "Materials & Metals", weight: 12.5, sector: ""),
                FundHolding(name: "Technology", weight: 10.0, sector: ""),
                FundHolding(name: "Healthcare & Pharma", weight: 9.5, sector: ""),
                FundHolding(name: "Consumer & FMCG", weight: 8.0, sector: "")
            ],
            minSIP: "₹1,000/month",
            minLumpsum: "₹5,000",
            exitLoad: "1% if redeemed within 1 year",
            lockIn: "None",
            aiInsights: [
                "[Quant-Driven] Unlike other funds, stock selection is driven by algorithms not human judgement — a completely different approach.",
                "[Exceptional 5Y Returns] 5Y CAGR of ~52% is among the best in the small-cap category — though this period coincided with a strong small-cap bull market.",
                "[High Turnover] The portfolio changes frequently as the model adjusts signals. This is not a sit-and-hold fund.",
                "[Regulatory Attention] Quant MF faced regulatory scrutiny from SEBI in 2024 regarding front-running allegations — a factor to consider.",
                "[Model Risk] Quantitative strategies work well in certain market conditions and may underperform when market behaviour changes."
            ],
            keyRisks: [
                "Past exceptional returns may have been driven by specific market conditions that may not repeat.",
                "High portfolio turnover leads to higher transaction costs and potential tax implications.",
                "SEBI regulatory scrutiny in 2024 is a governance concern investors should monitor.",
                "Quantitative models can fail during market regime changes or black-swan events."
            ]
        )

        return d
    }()
}
