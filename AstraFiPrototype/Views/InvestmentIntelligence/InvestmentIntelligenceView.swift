import Charts
import SwiftUI

struct InvestmentIntelligenceView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var homeViewModel = InvestmentIntelligenceHomeViewModel()
    @State private var searchViewModel = InvestmentSearchViewModel()
    @Environment(\.isSearching) private var isSearching
    @State private var isSearchPresented = false
    @Namespace private var cardNamespace

    var body: some View {
        ScrollView(showsIndicators: false) {
            if searchViewModel.query.isEmpty && !isSearching {
                VStack(alignment: .leading, spacing: 26) {
                    assetSection(title: "Stocks", subtitle: "Popular companies with live prices when available", assets: homeViewModel.stocks)
                    assetSection(title: "Mutual Funds", subtitle: "Popular categories from AMFI data", assets: homeViewModel.mutualFunds)
                    assetSection(title: "Gold ETFs", subtitle: "Indian listed Gold ETFs", assets: homeViewModel.goldETFs)
                    educationFooter
                }
                .padding(.horizontal, AppTheme.auraPadding)
                .padding(.bottom, 44)
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    if !searchViewModel.recentSearches.isEmpty && searchViewModel.query.isEmpty {
                        searchSection(title: "Recent Searches", assets: searchViewModel.recentSearches)
                    }

                    if searchViewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 {
                        searchResults
                    } else if searchViewModel.query.isEmpty {
                        searchSection(title: "Provider Stocks", assets: searchViewModel.trendingStocks)
                        searchSection(title: "AMFI Mutual Funds", assets: searchViewModel.popularFunds)
                        searchSection(title: "Gold ETFs", assets: searchViewModel.topGoldETFs)
                    }
                }
                .padding(.horizontal, AppTheme.auraPadding)
                .padding(.bottom, 40)
            }
        }
        .background(AppTheme.appBackground(for: colorScheme))
        .navigationTitle("Investment Intelligence")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchViewModel.query, isPresented: $isSearchPresented, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search stocks, mutual funds, Gold ETFs")
        .task { 
            await homeViewModel.load() 
            await searchViewModel.loadDiscovery()
        }
        .onChange(of: searchViewModel.query) { _, _ in
            Task { await searchViewModel.search() }
        }
        .onAppear {
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).clearButtonMode = .never
        }
    }

    // header removed

    private func assetSection(title: String, subtitle: String, assets: [InvestmentSummaryAsset]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 21, weight: .bold))
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                NavigationLink(destination: InvestmentCategoryListView(title: title, assets: assets)) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.auraIndigo)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    if assets.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(AppTheme.auraIndigo)
                            Text("Use Search")
                                .font(.system(size: 17, weight: .bold))
                            Text("No verified provider list is loaded here yet.")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(18)
                        .frame(width: 260, alignment: .leading)
                        .frame(minHeight: 120, alignment: .leading)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    } else {
                        ForEach(assets.prefix(12)) { asset in
                            NavigationLink(destination: InvestmentIntelligenceDetailView(asset: asset)) {
                                InvestmentSummaryCard(asset: asset)
                                    .matchedGeometryEffect(id: asset.id, in: cardNamespace)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Text(asset.kind.rawValue)
                                Text(asset.symbol)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var educationFooter: some View {
        Label("Educational insights only. AstraFi does not guarantee returns or tell you to buy or sell.", systemImage: "info.circle.fill")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    private var searchResults: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Results")
                    .font(.system(size: 21, weight: .bold))
                Spacer()
                if searchViewModel.isSearching {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if searchViewModel.results.isEmpty && !searchViewModel.isSearching {
                ContentUnavailableView("No matches", systemImage: "magnifyingglass", description: Text("Try a company, fund house, sector, or ETF name."))
            } else {
                VStack(spacing: 10) {
                    ForEach(searchViewModel.results) { asset in
                        NavigationLink(destination: InvestmentIntelligenceDetailView(asset: asset)) {
                            SearchResultRow(asset: asset)
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(TapGesture().onEnded { searchViewModel.recordRecent(asset) })
                    }
                }
            }
        }
    }

    private func searchSection(title: String, assets: [InvestmentSummaryAsset]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 21, weight: .bold))

            VStack(spacing: 10) {
                if assets.isEmpty {
                    ContentUnavailableView("No provider data", systemImage: "tray", description: Text("Search for a company, mutual fund, or ETF to load verified data."))
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(assets.prefix(8)) { asset in
                        NavigationLink(destination: InvestmentIntelligenceDetailView(asset: asset)) {
                            SearchResultRow(asset: asset)
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(TapGesture().onEnded { searchViewModel.recordRecent(asset) })
                    }
                }
            }
        }
    }
}

struct InvestmentIntelligenceDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel: InvestmentDetailViewModel
    @State private var stockIntelligenceViewModel = StockIntelligenceViewModel()

    init(asset: InvestmentSummaryAsset) {
        _viewModel = State(initialValue: InvestmentDetailViewModel(asset: asset))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                detailHeader
                singleScreenContent
            }
            .padding(.horizontal, AppTheme.auraPadding)
            .padding(.bottom, 44)
        }
        .background(AppTheme.appBackground(for: colorScheme))
        .navigationTitle(viewModel.asset.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    private var detailHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                AssetIcon(kind: viewModel.asset.kind)
                VStack(alignment: .leading, spacing: 5) {
                    Text(viewModel.asset.name)
                        .font(.system(size: 24, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(viewModel.asset.sector) • \(viewModel.asset.symbol)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(valueText(for: viewModel.asset))
                        .font(.system(size: 28, weight: .bold))
                    Text(changeText(for: viewModel.asset))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(changeColor(for: viewModel.asset))
                }
                Spacer()
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
        .padding(18)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 14, x: 0, y: 5)
    }

    @ViewBuilder
    private var singleScreenContent: some View {
        let snapshot = viewModel.snapshot

        if viewModel.isLoading && snapshot == nil {
            DetailCard(title: "Loading Intelligence", systemImage: "arrow.triangle.2.circlepath") {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Fetching provider data and preparing this screen...")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }

        Group {
            OverviewTab(snapshot: snapshot, asset: viewModel.asset)
            FinancialsTab(snapshot: snapshot, asset: viewModel.asset)
            if viewModel.asset.kind == .stock {
                StockIntelligenceSection(viewModel: stockIntelligenceViewModel)
                    .task(id: viewModel.asset.symbol) {
                        await stockIntelligenceViewModel.loadIntelligence(for: viewModel.asset)
                    }
            }
            InsightsTab(
                asset: viewModel.asset,
                aiInsight: snapshot?.aiInsight,
                insights: snapshot?.insights ?? [],
                recommendations: snapshot?.recommendations ?? []
            )



            FAQTab(faqs: snapshot?.faqs ?? FAQService().faqs())
        }
    }
}

private struct InvestmentSummaryCard: View {
    let asset: InvestmentSummaryAsset

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                AssetIcon(kind: asset.kind, size: 36)
                VStack(alignment: .leading, spacing: 5) {
                    Text(asset.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                    Text(asset.sector)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(height: 58, alignment: .topLeading)
                Spacer(minLength: 8)
            }
            
            Spacer(minLength: 8)

            HStack(spacing: 8) {
                InfoPill(title: asset.kind == .mutualFund ? "Current NAV" : "Current Price", value: valueText(for: asset), color: asset.kind.accent)
                InfoPill(title: "Growth", value: growthText(for: asset), color: growthColor(for: asset))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 18)
        .frame(width: 248, height: 166, alignment: .topLeading)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.7), radius: 10, x: 0, y: 3)
    }
}

struct InvestmentHomePreviewCard: View {
    let asset: InvestmentSummaryAsset

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                AssetIcon(kind: asset.kind, size: 36)
                VStack(alignment: .leading, spacing: 5) {
                    Text(asset.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                    Text(asset.sector)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(height: 58, alignment: .topLeading)
                Spacer(minLength: 8)
            }
            
            Spacer(minLength: 8)

            HStack(spacing: 8) {
                InfoPill(title: asset.kind == .mutualFund ? "Current NAV" : "Current Price", value: valueText(for: asset), color: asset.kind.accent)
                InfoPill(title: "Growth", value: growthText(for: asset), color: growthColor(for: asset))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 18)
        .frame(width: 248, height: 166, alignment: .topLeading)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.7), radius: 10, x: 0, y: 3)
    }
}

private struct SearchResultRow: View {
    let asset: InvestmentSummaryAsset

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AssetIcon(kind: asset.kind, size: 42)
            VStack(alignment: .leading, spacing: 7) {
                Text(asset.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text("\(asset.kind.rawValue) • \(asset.sector)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    RiskBadge(level: asset.riskLevel)
                    Text(asset.metadata)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(valueText(for: asset))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(changeText(for: asset))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(changeColor(for: asset))
                    .lineLimit(1)
            }
        }
        .padding(15)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 3)
    }
}

private struct OverviewTab: View {
    let snapshot: InvestmentDetailSnapshot?
    let asset: InvestmentSummaryAsset

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PriceChartCard(
                title: asset.kind == .mutualFund ? "NAV History" : "Price History",
                points: snapshot?.chart ?? asset.sparkline,
                color: asset.kind.accent
            )

            if let profile = snapshot?.profile {
                DetailCard(title: "Company Profile", systemImage: "building.2.fill") {
                    VStack(alignment: .leading, spacing: 14) {
                        // Company header row: Logo + Name + Ticker/Exchange + Verified badge
                        HStack(spacing: 12) {
                            if let url = profile.logoURL {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFit()
                                } placeholder: {
                                    AssetIcon(kind: asset.kind, size: 42)
                                }
                                .frame(width: 42, height: 42)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            } else {
                                AssetIcon(kind: asset.kind, size: 42)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.name)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                Text("\(profile.ticker) • \(profile.exchange)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if profile.isVerifiedProfile {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(AppTheme.auraGreen)
                                    Text("Verified")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(AppTheme.auraGreen)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.auraGreen.opacity(0.12))
                                .clipShape(Capsule())
                            }
                        }

                        // Single 2x2 grid for metadata spanning full card width
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
                            HighlightPill(title: "Sector", value: profile.sector, color: asset.kind.accent)
                            HighlightPill(title: "Industry", value: profile.industry, color: AppTheme.auraMint)
                            HighlightPill(title: "Country", value: profile.country, color: AppTheme.vibrantCyan)
                            HighlightPill(title: "Exchange", value: profile.exchange, color: AppTheme.auraPurple)
                        }

                        // Business overview + See all details button
                        CompanyProfileSummary(profile: profile, accent: asset.kind.accent)
                    }
                }
            } else if asset.kind == .stock {
                DetailCard(title: "Company Snapshot", systemImage: "building.2.fill") {
                    MetricGrid(metrics: stockSnapshotMetrics)
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.vibrantCyan)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Detailed profile not yet available")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.primary)
                            Text("AstraFi has not yet verified a detailed profile for \(asset.symbol). You can look up this company on its exchange website or the NSE/BSE investor portal for business details.")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(12)
                    .background(AppTheme.elevatedCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            } else if let fund = snapshot?.mutualFund {
                DetailCard(title: "Mutual Fund Detail", systemImage: "chart.pie.fill") {
                    MetricGrid(metrics: [
                        InvestmentMetric(title: "Scheme", value: fund.schemeName, systemImage: "doc.text.fill", color: asset.kind.accent),
                        InvestmentMetric(title: "Fund House", value: fund.fundHouse, systemImage: "building.2.fill", color: AppTheme.auraMint),
                        InvestmentMetric(title: "Category", value: fund.category, systemImage: "square.grid.2x2.fill", color: AppTheme.auraPurple),
                        InvestmentMetric(title: "Current NAV", value: fund.currentNAV.intelligenceCurrency, systemImage: "indianrupeesign.circle.fill", color: AppTheme.auraGreen),
                        InvestmentMetric(title: "Asset Class", value: fund.assetClass, systemImage: "chart.dots.scatter", color: AppTheme.vibrantCyan),
                        InvestmentMetric(title: "Last Updated", value: fund.lastUpdated, systemImage: "calendar", color: AppTheme.vibrantOrange)
                    ])
                }
            } else if let gold = snapshot?.goldETF {
                DetailCard(title: "Gold ETF Detail", systemImage: "circle.hexagongrid.fill") {
                    MetricGrid(metrics: [
                        InvestmentMetric(title: "Fund House", value: gold.fundHouse, systemImage: "building.2.fill", color: AppTheme.auraGold),
                        InvestmentMetric(title: "Current Price", value: gold.currentPrice?.intelligenceCurrency ?? "Loading", systemImage: "indianrupeesign.circle.fill", color: AppTheme.auraGreen),
                        InvestmentMetric(title: "NAV", value: gold.nav?.intelligenceCurrency ?? "AMC factsheet", systemImage: "number.circle.fill", color: AppTheme.auraMint),
                        InvestmentMetric(title: "Tracking Error", value: gold.trackingError, systemImage: "point.topleft.down.curvedto.point.bottomright.up", color: AppTheme.vibrantOrange),
                        InvestmentMetric(title: "Expense Ratio", value: gold.expenseRatio, systemImage: "percent", color: AppTheme.auraPurple),
                        InvestmentMetric(title: "Risk", value: gold.riskLevel.rawValue, systemImage: "exclamationmark.triangle.fill", color: gold.riskLevel.color)
                    ])
                }
            }
        }
    }

    private var stockSnapshotMetrics: [InvestmentMetric] {
        [
            InvestmentMetric(title: "Company", value: asset.name, systemImage: "building.2.fill", color: asset.kind.accent),
            InvestmentMetric(title: "Symbol", value: asset.symbol, systemImage: "tag.fill", color: AppTheme.auraMint),
            InvestmentMetric(title: "Exchange", value: asset.metadata.isEmpty ? "Market" : asset.metadata, systemImage: "building.columns.fill", color: AppTheme.auraPurple),
            InvestmentMetric(title: "Sector", value: asset.sector, systemImage: "square.grid.2x2.fill", color: AppTheme.vibrantCyan),
            InvestmentMetric(title: "Current Price", value: asset.currentValue?.intelligenceCurrency ?? "Loading", systemImage: "indianrupeesign.circle.fill", color: AppTheme.auraGreen),
            InvestmentMetric(title: "Daily Change", value: asset.dailyChange?.percentText ?? "Unavailable", systemImage: "chart.line.uptrend.xyaxis", color: AppTheme.vibrantOrange)
        ]
    }
}

private struct FinancialsTab: View {
    let snapshot: InvestmentDetailSnapshot?
    let asset: InvestmentSummaryAsset
    @State private var showFinancialsInfo = false

    private static let financialsInfoData = SectionInfoData(
        title: "Financial Metrics",
        subtitle: "Understanding fundamental data",
        icon: "chart.bar.xaxis",
        badge: "Fundamentals Guide",
        whatItRepresents: "This section shows key financial fundamentals sourced from market data providers. Metrics like P/E ratio, ROE, and margins help you assess how efficiently a company earns money and how the market values it relative to its earnings.",
        howItIsCalculated: "Market Cap = Share Price × Total Shares Outstanding. P/E Ratio = Current Price ÷ Earnings Per Share. ROE = Net Income ÷ Shareholders' Equity. Operating Margin = Operating Income ÷ Revenue. All TTM (Trailing 12 Months) values use the last 4 quarters combined.",
        dataSource: "Finnhub Financial Modeling Prep (FMP) APIs. Data is pulled on-demand and may lag by 1–3 trading days for real-time prices and up to one quarter for fundamental metrics.",
        limitations: "Financial data is from third-party providers and may be delayed or incomplete, especially for smaller stocks. Ratios are TTM unless labelled otherwise. Missing fields show 'Unavailable' and are not estimated or interpolated. Do not treat any metric in isolation.",
        keyTakeaway: "Use these metrics as starting points, not conclusions. Compare a company's ROE, margins, and growth against its industry peers and its own historical trend before drawing any investment decision."
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Main financials card
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderWithInfo(
                    title: "Financials",
                    subtitle: snapshot?.financials != nil ? (snapshot?.financials?.measurementPeriod ?? "TTM") : "Available data",
                    systemImage: "chart.bar.xaxis",
                    infoData: Self.financialsInfoData
                )

                Label("Only provider fundamentals are shown. Missing values stay unavailable until a connected source returns them.", systemImage: "info.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                MetricGrid(metrics: metrics)
            }
            .padding(16)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: AppTheme.adaptiveShadow, radius: 12, x: 0, y: 4)

            // Easy Comparison section (replaces broken bar chart)
            if let financials = snapshot?.financials {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeaderWithInfo(
                        title: "Easy Comparison",
                        subtitle: "Percentage-based metrics at a glance",
                        systemImage: "chart.bar.horizontal.page.fill",
                        infoData: SectionInfoData(
                            title: "Easy Comparison",
                            subtitle: "How to read this section",
                            icon: "chart.bar.horizontal.page.fill",
                            badge: "Metrics Guide",
                            whatItRepresents: "Shows percentage-based financial ratios as visual bars so you can quickly compare performance across metrics. Only metrics that are percentages (margins, growth rates, returns) are shown here — they share the same 0–100% scale.",
                            howItIsCalculated: "Each bar fills from 0% to the metric's actual value, capped at 100% for display. Negative values are shown in red. The raw number is always displayed alongside the bar.",
                            dataSource: "Same as Financial Metrics — Finnhub and FMP APIs, TTM basis.",
                            limitations: "This is a simplified visual aid. Very high or negative numbers are capped or shown differently. Do not use bar length alone to compare across very different companies or sectors.",
                            keyTakeaway: "A higher operating margin, ROE, or net margin generally means the business converts revenue to profit efficiently. Compare these values to the industry average, not just the bar length."
                        )
                    )
                    ForEach(easyComparisonRows(financials: financials), id: \.name) { row in
                        EasyComparisonRow(row: row)
                    }
                }
                .padding(16)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: AppTheme.adaptiveShadow, radius: 12, x: 0, y: 4)
            }
        }
    }

    private var metrics: [InvestmentMetric] {
        let sym = asset.symbol
        if let financials = snapshot?.financials {
            return [
                InvestmentMetric(title: "Market Cap", value: financials.marketCap?.formattedMarketCap(for: sym) ?? "Unavailable", systemImage: "building.columns.fill", color: AppTheme.auraIndigo),
                InvestmentMetric(title: "P/E Ratio", value: financials.peRatio.map { String(format: "%.1fx", $0) } ?? "Unavailable", systemImage: "scale.3d", color: AppTheme.auraPurple),
                InvestmentMetric(title: "52W High", value: financials.weekHigh52?.formattedCurrency(for: sym) ?? "Unavailable", systemImage: "arrow.up.right.circle.fill", color: AppTheme.auraGreen),
                InvestmentMetric(title: "52W Low", value: financials.weekLow52?.formattedCurrency(for: sym) ?? "Unavailable", systemImage: "arrow.down.right.circle.fill", color: AppTheme.vibrantOrange),
                InvestmentMetric(title: "Revenue Growth", value: financials.revenue?.percentText ?? "Unavailable", systemImage: "chart.line.uptrend.xyaxis", color: AppTheme.auraGreen),
                InvestmentMetric(title: "Net Profit Margin", value: financials.netProfit?.percentText ?? "Unavailable", systemImage: "banknote.fill", color: AppTheme.auraMint),
                InvestmentMetric(title: "EPS", value: financials.eps.map { String(format: "%.2f", $0) } ?? "Unavailable", systemImage: "plus.forwardslash.minus", color: AppTheme.auraIndigo),
                InvestmentMetric(title: "Cash Flow/Share", value: financials.cashFlow.map { String(format: "%.2f", $0) } ?? "Unavailable", systemImage: "arrow.left.arrow.right.circle.fill", color: AppTheme.vibrantCyan),
                InvestmentMetric(title: "Operating Margin", value: financials.operatingMargin?.percentText ?? "Unavailable", systemImage: "gauge.with.dots.needle.50percent", color: AppTheme.auraPurple),
                InvestmentMetric(title: "ROE", value: financials.roe?.percentText ?? "Unavailable", systemImage: "arrow.up.right.circle.fill", color: AppTheme.auraGreen),
                InvestmentMetric(title: "ROA", value: financials.roa?.percentText ?? "Unavailable", systemImage: "chart.dots.scatter", color: AppTheme.auraMint),
                InvestmentMetric(title: "Debt Ratio", value: financials.debtRatio.map { String(format: "%.2f", $0) } ?? "Unavailable", systemImage: "scale.3d", color: AppTheme.vibrantOrange),
                InvestmentMetric(title: "Quarterly Growth", value: financials.quarterlyGrowth?.percentText ?? "Unavailable", systemImage: "calendar.badge.clock", color: AppTheme.auraIndigo),
                InvestmentMetric(title: "Historical Growth", value: financials.historicalGrowth?.percentText ?? "Unavailable", systemImage: "clock.arrow.circlepath", color: AppTheme.vibrantCyan)
            ]
        }
        let sym2 = asset.symbol
        return [
            InvestmentMetric(title: asset.kind == .mutualFund ? "Current NAV" : "Current Price", value: asset.currentValue?.formattedCurrency(for: sym2) ?? "Loading", systemImage: "indianrupeesign.circle.fill", color: AppTheme.auraGreen),
            InvestmentMetric(title: "1Y Return", value: asset.oneYearReturn?.percentText ?? (asset.kind == .mutualFund ? "Based on NAV history" : "Based on price history"), systemImage: "chart.line.uptrend.xyaxis", color: AppTheme.auraIndigo),
            InvestmentMetric(title: "Risk Level", value: asset.riskLevel.rawValue, systemImage: "exclamationmark.triangle.fill", color: asset.riskLevel.color),
            InvestmentMetric(title: "Category", value: asset.sector, systemImage: "square.grid.2x2.fill", color: AppTheme.auraPurple)
        ]
    }

    fileprivate struct EasyComparisonRowData {
        let name: String
        let value: Double?
        let formatted: String
        let color: Color
        let period: String
    }

    private func easyComparisonRows(financials: CompanyFinancialSnapshot) -> [EasyComparisonRowData] {
        [
            EasyComparisonRowData(name: "Operating Margin", value: financials.operatingMargin, formatted: financials.operatingMargin?.percentText ?? "Unavailable", color: AppTheme.auraPurple, period: "TTM"),
            EasyComparisonRowData(name: "Net Profit Margin", value: financials.netProfit, formatted: financials.netProfit?.percentText ?? "Unavailable", color: AppTheme.auraMint, period: "TTM"),
            EasyComparisonRowData(name: "ROE", value: financials.roe, formatted: financials.roe?.percentText ?? "Unavailable", color: AppTheme.auraGreen, period: "TTM"),
            EasyComparisonRowData(name: "ROA", value: financials.roa, formatted: financials.roa?.percentText ?? "Unavailable", color: AppTheme.vibrantCyan, period: "TTM"),
            EasyComparisonRowData(name: "Revenue Growth", value: financials.revenue, formatted: financials.revenue?.percentText ?? "Unavailable", color: AppTheme.auraIndigo, period: "YoY"),
            EasyComparisonRowData(name: "Quarterly Growth", value: financials.quarterlyGrowth, formatted: financials.quarterlyGrowth?.percentText ?? "Unavailable", color: AppTheme.vibrantOrange, period: "QoQ")
        ]
    }
}

private struct EasyComparisonRow: View {
    let row: FinancialsTab.EasyComparisonRowData

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(row.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text(row.period)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
                if let _ = row.value {
                    Text(row.formatted)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(row.value ?? 0 >= 0 ? row.color : AppTheme.vibrantRed)
                        .monospacedDigit()
                        .frame(minWidth: 60, alignment: .trailing)
                } else {
                    Text("Unavailable")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 60, alignment: .trailing)
                }
            }
            if let val = row.value {
                GeometryReader { geo in
                    let capped = min(max(val, 0), 100) / 100.0
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.secondary.opacity(0.12))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(val >= 0 ? row.color : AppTheme.vibrantRed)
                            .frame(width: geo.size.width * CGFloat(capped), height: 6)
                    }
                }
                .frame(height: 6)
            } else {
                HStack(spacing: 5) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text("Data unavailable from provider")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(AppTheme.elevatedCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}


private struct InsightsTab: View {
    let asset: InvestmentSummaryAsset
    let aiInsight: String?
    let insights: [InvestmentInsight]
    let recommendations: [RecommendationTrend]

    private static let recommendationsInfoData = SectionInfoData(
        title: "Recommendation Trends",
        subtitle: "What broker ratings mean",
        icon: "chart.bar.fill",
        badge: "Analyst Consensus",
        whatItRepresents: "This section aggregates buy, hold, and sell ratings from professional stock analysts at brokerages. It shows how many analysts currently recommend buying, holding, or selling this stock.",
        howItIsCalculated: "Each brokerage publishes a rating (Strong Buy / Buy / Hold / Sell / Strong Sell). The counts here are the sum of all active analyst ratings from the most recent consensus period. Percentages = count ÷ total analysts × 100.",
        dataSource: "Source: Finnhub Broker Consensus API. Data is updated when analysts publish new reports, typically quarterly or after earnings.",
        limitations: "Analyst ratings represent professional opinion but are not always accurate. Ratings can be influenced by investment banking relationships. This is NOT AstraFi's own investment recommendation.",
        keyTakeaway: "A high proportion of 'Strong Buy' ratings reflects positive analyst sentiment, but always cross-check with the price target vs current price and your own research. Consensus alone should not drive decisions."
    )

    private static let insightsInfoData = SectionInfoData(
        title: "Rule-Based Insights",
        subtitle: "How AstraFi generates signals",
        icon: "lightbulb.fill",
        badge: "Signal Guide",
        whatItRepresents: "These insights are generated by applying simple financial rules to the company's fundamental metrics. They flag potentially interesting or concerning patterns — for example, a rising P/E ratio, improving margins, or debt level changes.",
        howItIsCalculated: "Rules are applied to metrics like P/E ratio, ROE, revenue growth, debt ratio, and quarterly EPS. Each rule checks if a threshold is crossed and generates a signal with an explanation. No AI model is used for this section.",
        dataSource: "AstraFi rule engine applied to fundamental data from Finnhub and FMP APIs.",
        limitations: "Rules are simplified and not tailored to the specific company or industry. A high P/E may be normal for a growth stock. Always interpret signals in context. These are not buy or sell recommendations.",
        keyTakeaway: "Use these signals as conversation starters, not conclusions. Each insight includes an explanation to help you understand what the metric means and why it might matter."
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !recommendations.isEmpty {
                let totalAnalysts = recommendations.reduce(0) { $0 + $1.count }
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeaderWithInfo(
                        title: "Recommendation Trends",
                        subtitle: "Broker analyst consensus",
                        systemImage: "chart.bar.fill",
                        infoData: Self.recommendationsInfoData
                    )
                    if totalAnalysts > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.auraIndigo)
                            Text("\(totalAnalysts) analysts surveyed")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("Source: Finnhub")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.secondary.opacity(0.10))
                                .clipShape(Capsule())
                        }
                    }
                    VStack(spacing: 8) {
                        ForEach(recommendations) { trend in
                            RecommendationBarRow(trend: trend, total: totalAnalysts)
                        }
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.vibrantOrange)
                        Text("Not AstraFi's investment recommendation. Broker consensus reflects third-party analyst opinions only.")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                    .background(AppTheme.vibrantOrange.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .padding(16)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: AppTheme.adaptiveShadow, radius: 12, x: 0, y: 4)
            }

            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderWithInfo(
                    title: "Rule-Based Insights",
                    subtitle: "Signals derived from fundamentals",
                    systemImage: "lightbulb.fill",
                    infoData: Self.insightsInfoData
                )
                VStack(spacing: 10) {
                    ForEach(insights) { insight in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: insight.systemImage)
                                .foregroundStyle(insight.color)
                                .frame(width: 22)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(insight.title)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.primary)
                                Text(insight.explanation)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(AppTheme.elevatedCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
            .padding(16)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: AppTheme.adaptiveShadow, radius: 12, x: 0, y: 4)
        }
    }
}

private struct RecommendationBarRow: View {
    let trend: RecommendationTrend
    let total: Int

    private var barColor: Color {
        let l = trend.label.lowercased()
        if l.contains("strong buy") { return AppTheme.auraGreen }
        if l.contains("buy") { return AppTheme.auraMint }
        if l.contains("hold") { return AppTheme.vibrantOrange }
        if l.contains("strong sell") { return AppTheme.vibrantRed }
        if l.contains("sell") { return Color.orange }
        return AppTheme.auraIndigo
    }

    private var pct: Double {
        guard total > 0 else { return 0 }
        return Double(trend.count) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(trend.label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(trend.count) analyst\(trend.count == 1 ? "" : "s")")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(String(format: "%.0f%%", pct * 100))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(barColor)
                    .monospacedDigit()
                    .frame(minWidth: 36, alignment: .trailing)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.secondary.opacity(0.12))
                        .frame(height: 7)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(barColor)
                        .frame(width: geo.size.width * CGFloat(pct), height: 7)
                        .animation(.easeOut(duration: 0.5), value: pct)
                }
            }
            .frame(height: 7)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(AppTheme.elevatedCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct StockIntelligenceCard: View {
    let viewModel: StockIntelligenceViewModel

    var body: some View {
        StockIntelligenceSection(viewModel: viewModel)
    }
}

private struct IntelligenceSection: View {
    let title: String
    let text: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                Text(text.isEmpty ? "Unavailable" : text)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(AppTheme.elevatedCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct FAQTab: View {
    let faqs: [InvestmentFAQ]
    @State private var expandedIDs: Set<UUID> = []

    var body: some View {
        DetailCard(title: "FAQ", systemImage: "questionmark.circle.fill") {
            VStack(spacing: 10) {
                ForEach(faqs) { faq in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedIDs.contains(faq.id) },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedIDs.insert(faq.id)
                                } else {
                                    expandedIDs.remove(faq.id)
                                }
                            }
                        )
                    ) {
                        Text(faq.answer)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)
                            .fixedSize(horizontal: false, vertical: true)
                    } label: {
                        Text(faq.question)
                            .font(.system(size: 14, weight: .bold))
                    }
                    .padding(13)
                    .background(AppTheme.elevatedCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }
}

private struct DetailCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 18, weight: .bold))
            content
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 12, x: 0, y: 4)
    }
}

private struct InfoPill: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .background(color.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct CompanyProfileSummary: View {
    let profile: CompanyProfileSnapshot
    let accent: Color

    @State private var showFullProfile = false

    private var overviewPoints: [String] {
        if let whatItDoes = profile.whatItDoes, !whatItDoes.isEmpty {
            let sentences = whatItDoes
                .replacingOccurrences(of: "\n", with: " ")
                .components(separatedBy: CharacterSet(charactersIn: ".!?"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.count > 15 }
                .map { $0.hasSuffix(".") ? $0 : "\($0)." }
            return sentences.isEmpty ? [whatItDoes] : Array(sentences.prefix(3))
        }
        return ProfileTextSection.build(from: profile.description).first?.points ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // What It Does preview card
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(accent)
                    Text("What It Does")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                }

                ForEach(overviewPoints, id: \.self) { point in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(accent.opacity(0.75))
                            .frame(width: 5, height: 5)
                            .padding(.top, 6)
                        Text(point)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.elevatedCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            // See all button
            Button {
                showFullProfile = true
            } label: {
                HStack(spacing: 6) {
                    Text("See all company details")
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(accent)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 2)
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showFullProfile) {
            CompanyProfileDetailSheet(profile: profile, accent: accent)
        }
    }
}

private struct CompanyProfileDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let profile: CompanyProfileSnapshot
    let accent: Color

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header card with Logo, Name, Ticker, Exchange & Verified badge
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            if let url = profile.logoURL {
                                AsyncImage(url: url) { img in
                                    img.resizable().scaledToFit()
                                } placeholder: {
                                    Image(systemName: "building.2.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(accent)
                                }
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.name)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                Text("\(profile.ticker) • \(profile.exchange) • \(profile.country)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }

                        if profile.isVerifiedProfile {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(AppTheme.auraGreen)
                                Text("Verified by AstraFi Intelligence")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(AppTheme.auraGreen)
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.auraGreen.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.elevatedCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // 2x2 Highlight Pills
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 10) {
                        HighlightPill(title: "Sector", value: profile.sector, color: accent)
                        HighlightPill(title: "Industry", value: profile.industry, color: AppTheme.auraMint)
                        HighlightPill(title: "Country", value: profile.country, color: AppTheme.vibrantCyan)
                        HighlightPill(title: "Exchange", value: profile.exchange, color: AppTheme.auraPurple)
                    }

                    if profile.isVerifiedProfile {
                        // 1. What It Does
                        if let whatItDoes = profile.whatItDoes ?? (profile.description.isEmpty ? nil : profile.description) {
                            ProfileDetailCard(title: "What The Company Does", icon: "building.2.fill", color: accent) {
                                Text(whatItDoes)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                                    .lineSpacing(3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        // 2. Business Segments
                        if !profile.operatingSegments.isEmpty {
                            ProfileDetailCard(title: "Primary Business Segments", icon: "chart.pie.fill", color: AppTheme.auraIndigo) {
                                VStack(spacing: 8) {
                                    ForEach(profile.operatingSegments) { seg in
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 8) {
                                                Text(seg.name)
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundStyle(.primary)
                                                if let share = seg.sharePercentage {
                                                    Text(share)
                                                        .font(.system(size: 11, weight: .bold))
                                                        .foregroundStyle(.white)
                                                        .padding(.horizontal, 7)
                                                        .padding(.vertical, 2)
                                                        .background(accent)
                                                        .clipShape(Capsule())
                                                }
                                                Spacer()
                                            }
                                            Text(seg.description)
                                                .font(.system(size: 12))
                                                .foregroundStyle(.secondary)
                                                .lineSpacing(2)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        .padding(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(AppTheme.cardBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                }
                            }
                        }

                        // 3. Products & Platforms
                        if !profile.productsAndPlatforms.isEmpty {
                            ProfileDetailCard(title: "Key Products & Platforms", icon: "cube.box.fill", color: AppTheme.auraMint) {
                                VStack(spacing: 8) {
                                    ForEach(profile.productsAndPlatforms, id: \.self) { item in
                                        HStack(alignment: .top, spacing: 10) {
                                            Circle()
                                                .fill(AppTheme.auraMint)
                                                .frame(width: 6, height: 6)
                                                .padding(.top, 6)
                                            Text(item)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundStyle(.primary)
                                                .lineSpacing(2)
                                                .fixedSize(horizontal: false, vertical: true)
                                            Spacer()
                                        }
                                        .padding(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(AppTheme.cardBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                }
                            }
                        }

                        // 4. Revenue Model
                        if !profile.revenueModel.isEmpty {
                            ProfileDetailCard(title: "How It Makes Money", icon: "dollarsign.circle.fill", color: AppTheme.auraGreen) {
                                VStack(spacing: 8) {
                                    ForEach(profile.revenueModel, id: \.self) { item in
                                        HStack(alignment: .top, spacing: 10) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(AppTheme.auraGreen)
                                                .padding(.top, 2)
                                            Text(item)
                                                .font(.system(size: 13))
                                                .foregroundStyle(.secondary)
                                                .lineSpacing(2)
                                                .fixedSize(horizontal: false, vertical: true)
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }

                        // 5. Target Markets
                        if !profile.targetMarkets.isEmpty {
                            ProfileDetailCard(title: "Target Markets & Customers", icon: "person.3.fill", color: AppTheme.vibrantCyan) {
                                VStack(spacing: 8) {
                                    ForEach(profile.targetMarkets, id: \.self) { item in
                                        HStack(alignment: .top, spacing: 10) {
                                            Image(systemName: "arrow.right.circle.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(AppTheme.vibrantCyan)
                                                .padding(.top, 2)
                                            Text(item)
                                                .font(.system(size: 13))
                                                .foregroundStyle(.secondary)
                                                .lineSpacing(2)
                                                .fixedSize(horizontal: false, vertical: true)
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }

                        // 6. Growth Drivers
                        if !profile.secularGrowthDrivers.isEmpty {
                            ProfileDetailCard(title: "Secular Growth Drivers", icon: "arrow.up.right.circle.fill", color: AppTheme.auraIndigo) {
                                VStack(spacing: 8) {
                                    ForEach(profile.secularGrowthDrivers, id: \.self) { item in
                                        HStack(alignment: .top, spacing: 10) {
                                            Image(systemName: "bolt.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(AppTheme.auraIndigo)
                                                .padding(.top, 2)
                                            Text(item)
                                                .font(.system(size: 13))
                                                .foregroundStyle(.secondary)
                                                .lineSpacing(2)
                                                .fixedSize(horizontal: false, vertical: true)
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }

                        // 7. Key Business Risks
                        if !profile.keyBusinessRisks.isEmpty {
                            ProfileDetailCard(title: "Key Business Risks", icon: "exclamationmark.triangle.fill", color: AppTheme.vibrantOrange) {
                                VStack(spacing: 8) {
                                    ForEach(profile.keyBusinessRisks, id: \.self) { item in
                                        HStack(alignment: .top, spacing: 10) {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(AppTheme.vibrantOrange)
                                                .padding(.top, 2)
                                            Text(item)
                                                .font(.system(size: 13))
                                                .foregroundStyle(.secondary)
                                                .lineSpacing(2)
                                                .fixedSize(horizontal: false, vertical: true)
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }

                        // 8. Key Metrics to Monitor
                        if !profile.keyMetricsToMonitor.isEmpty {
                            ProfileDetailCard(title: "Key Metrics to Monitor", icon: "gauge.with.dots.needle.50percent", color: AppTheme.auraMint) {
                                VStack(spacing: 8) {
                                    ForEach(profile.keyMetricsToMonitor, id: \.self) { item in
                                        HStack(alignment: .top, spacing: 10) {
                                            Image(systemName: "chart.line.uptrend.xyaxis")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(AppTheme.auraMint)
                                                .padding(.top, 2)
                                            Text(item)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundStyle(.primary)
                                                .lineSpacing(2)
                                                .fixedSize(horizontal: false, vertical: true)
                                            Spacer()
                                        }
                                        .padding(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(AppTheme.cardBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                }
                            }
                        }
                    } else {
                        // Unverified profile fallback
                        ForEach(ProfileTextSection.build(from: profile.description)) { section in
                            ProfileBulletSection(section: section)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Provider Text")
                                .font(.system(size: 15, weight: .bold))
                            Text(profile.description)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.elevatedCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(16)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Company Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
}

private struct ProfileDetailCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)
                Spacer()
            }
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.elevatedCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct HighlightPill: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value.isEmpty ? "Unknown" : value)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(color.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct ProfileBulletSection: View {
    let section: ProfileTextSection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.title)
                .font(.system(size: 14, weight: .bold))

            ForEach(section.points, id: \.self) { point in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(AppTheme.auraIndigo.opacity(0.75))
                        .frame(width: 5, height: 5)
                        .padding(.top, 6)

                    Text(point)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .background(AppTheme.elevatedCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct ProfileTextSection: Identifiable {
    let id = UUID()
    let title: String
    let points: [String]

    static func build(from text: String) -> [ProfileTextSection] {
        let sentences = text
            .replacingOccurrences(of: "\n", with: " ")
            .components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 18 }
            .map { sentence in
                sentence.hasSuffix(".") ? sentence : "\(sentence)."
            }

        guard !sentences.isEmpty else {
            return [ProfileTextSection(title: "Overview", points: ["Provider profile text is unavailable for this company."])]
        }

        let overview = Array(sentences.prefix(2))
        let segmentKeywords = ["segment", "banking", "manufacturing", "retail", "consumer", "communication", "healthcare", "services"]
        let productKeywords = ["platform", "software", "solution", "product", "automation", "cloud", "AI", "blockchain", "analytics"]

        let segments = sentences
            .dropFirst(2)
            .filter { containsAny($0, keywords: segmentKeywords) }
            .prefix(3)
            .map { $0 }

        let products = sentences
            .dropFirst(2)
            .filter { containsAny($0, keywords: productKeywords) }
            .prefix(3)
            .map { $0 }

        var sections = [ProfileTextSection(title: "What It Does", points: overview)]

        if !segments.isEmpty {
            sections.append(ProfileTextSection(title: "Business Areas", points: Array(segments)))
        }

        if !products.isEmpty {
            sections.append(ProfileTextSection(title: "Platforms & Solutions", points: Array(products)))
        }

        let used = Set(sections.flatMap(\.points))
        let remaining = sentences.filter { !used.contains($0) }.prefix(4).map { $0 }
        if !remaining.isEmpty {
            sections.append(ProfileTextSection(title: "More Highlights", points: remaining))
        }

        return sections
    }

    private static func containsAny(_ sentence: String, keywords: [String]) -> Bool {
        let lower = sentence.lowercased()
        return keywords.contains { lower.contains($0.lowercased()) }
    }
}

private struct RiskBadge: View {
    let level: IntelligenceRiskLevel

    var body: some View {
        Label(level.rawValue, systemImage: "shield.lefthalf.filled")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(level.color)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(level.color.opacity(0.12))
            .clipShape(Capsule())
    }
}

private struct ChartSummaryRow: View {
    let points: [InvestmentChartPoint]
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            SummaryTile(title: "Latest", value: latest?.compactCurrency ?? "-", color: color)
            SummaryTile(title: "High", value: high?.compactCurrency ?? "-", color: AppTheme.auraGreen)
            SummaryTile(title: "Low", value: low?.compactCurrency ?? "-", color: AppTheme.vibrantOrange)
            SummaryTile(title: "Trend", value: trendText, color: trendColor)
        }
    }

    private var latest: Double? { points.last?.value }
    private var high: Double? { points.map(\.value).max() }
    private var low: Double? { points.map(\.value).min() }

    private var trendText: String {
        guard let first = points.first?.value, let latest, first > 0 else { return "-" }
        let change = ((latest - first) / first) * 100
        return "\(change >= 0 ? "+" : "")\(String(format: "%.1f", change))%"
    }

    private var trendColor: Color {
        guard let first = points.first?.value, let latest else { return .secondary }
        return latest >= first ? AppTheme.auraGreen : AppTheme.vibrantRed
    }
}

struct InvestmentCategoryListView: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let kind: IntelligenceAssetKind
    @State private var viewModel: InvestmentCategoryListViewModel

    init(title: String, assets: [InvestmentSummaryAsset]) {
        self.title = title
        let resolvedKind: IntelligenceAssetKind
        if title.localizedCaseInsensitiveContains("fund") {
            resolvedKind = .mutualFund
        } else if title.localizedCaseInsensitiveContains("gold") || title.localizedCaseInsensitiveContains("etf") {
            resolvedKind = .goldETF
        } else {
            resolvedKind = .stock
        }
        self.kind = resolvedKind
        _viewModel = State(initialValue: InvestmentCategoryListViewModel(kind: resolvedKind, initialAssets: assets))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                // Category filter chips when not actively searching
                if viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.availableFilters, id: \.self) { filter in
                                Button {
                                    Task { await viewModel.selectFilter(filter) }
                                } label: {
                                    Text(filter)
                                        .font(.system(size: 13, weight: .semibold))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(viewModel.selectedFilter == filter ? kind.accent : AppTheme.cardBackground)
                                        .foregroundStyle(viewModel.selectedFilter == filter ? .white : .primary)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(viewModel.selectedFilter == filter ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.top, 4)
                }

                // Loading or searching indicator
                if viewModel.isSearching || (viewModel.isLoading && viewModel.displayAssets.isEmpty) {
                    HStack(spacing: 10) {
                        ProgressView()
                            .controlSize(.small)
                        Text(viewModel.isSearching ? "Searching all \(title.lowercased())..." : "Loading \(title.lowercased())...")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)
                } else if viewModel.displayAssets.isEmpty {
                    ContentUnavailableView(
                        "No matches",
                        systemImage: "magnifyingglass",
                        description: Text("Could not find any \(title.lowercased()) matching your search.")
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(viewModel.displayAssets) { asset in
                        NavigationLink(destination: InvestmentIntelligenceDetailView(asset: asset)) {
                            SearchResultRow(asset: asset)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, AppTheme.auraPadding)
            .padding(.vertical, 16)
        }
        .background(AppTheme.appBackground(for: colorScheme))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search all \(title.lowercased())")
        .task {
            await viewModel.load()
        }
        .onChange(of: viewModel.searchText) { _, _ in
            Task { await viewModel.performSearch() }
        }
    }
}

private struct SummaryTile: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.elevatedCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct FinancialChartMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: Double
    let color: Color
}

private struct PriceChartCard: View {
    let title: String
    let points: [InvestmentChartPoint]
    let color: Color

    var body: some View {
        DetailCard(title: title, systemImage: "chart.xyaxis.line") {
            VStack(alignment: .leading, spacing: 14) {
                ChartSummaryRow(points: points, color: color)
                ChartPanel(points: points, color: color, compact: false)
                    .frame(height: 230)
            }
        }
    }
}

private struct ChartPanel: View {
    let points: [InvestmentChartPoint]
    let color: Color
    var compact: Bool

    var body: some View {
        VStack(spacing: 0) {
            Chart(points) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: compact ? 2.4 : 3.2, lineCap: .round, lineJoin: .round))
                .foregroundStyle(color)

                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [color.opacity(compact ? 0.22 : 0.28), color.opacity(0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                if !compact, point.id == points.last?.id {
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .symbolSize(60)
                    .foregroundStyle(color)
                }
            }
            .chartXAxis(compact ? .hidden : .automatic)
            .chartYAxis(compact ? .hidden : .automatic)
            .chartYScale(domain: chartDomain)
            .accessibilityLabel("Historical value chart")
        }
        .padding(compact ? 8 : 12)
        .background(color.opacity(compact ? 0.08 : 0.07))
        .clipShape(RoundedRectangle(cornerRadius: compact ? 14 : 18, style: .continuous))
    }

    private var chartDomain: ClosedRange<Double> {
        let values = points.map(\.value)
        guard let minValue = values.min(), let maxValue = values.max(), minValue != maxValue else {
            let value = values.first ?? 1
            return (value * 0.9)...(value * 1.1)
        }
        let padding = Swift.max((maxValue - minValue) * 0.18, maxValue * 0.02)
        return (minValue - padding)...(maxValue + padding)
    }
}

private struct MetricGrid: View {
    let metrics: [InvestmentMetric]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(metrics) { metric in
                HStack(spacing: 10) {
                    Image(systemName: metric.systemImage)
                        .foregroundStyle(metric.color)
                        .frame(width: 22)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(metric.title)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text(metric.value)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                    }
                    Spacer(minLength: 0)
                }
                .padding(12)
                .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
                .background(AppTheme.elevatedCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }
}

private struct AssetIcon: View {
    let kind: IntelligenceAssetKind
    var size: CGFloat = 46

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(kind.accent.opacity(0.14))
                .frame(width: size, height: size)
            Image(systemName: kind.systemImage)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(kind.accent)
        }
    }
}

private struct NewsRow: View {
    let item: InvestmentNewsItem

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(item.headline)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            if !item.summary.isEmpty {
                Text(item.summary)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            HStack {
                Text(item.source)
                Spacer()
                Text(item.publishedAt, style: .date)
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
        }
        .padding(13)
        .background(AppTheme.elevatedCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct EmptyDetailMessage: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray.fill")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(size: 15, weight: .bold))
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(AppTheme.elevatedCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private extension InvestmentCompetitor {
    var asset: InvestmentSummaryAsset {
        InvestmentSummaryAsset(
            id: "stock-\(symbol)",
            kind: .stock,
            symbol: symbol,
            name: name,
            sector: "Competitor",
            currentValue: currentPrice,
            dailyChange: dailyChange,
            oneYearReturn: nil,
            riskLevel: .moderate,
            sparkline: [],
            metadata: marketCap.map { "Market cap \($0.compactCurrency)" } ?? "Peer"
        )
    }
}

private func valueText(for asset: InvestmentSummaryAsset) -> String {
    guard let value = asset.currentValue, value > 0 else {
        return asset.kind == .mutualFund ? "NAV loading" : "Price loading"
    }
    return value.formattedCurrency(for: asset.symbol)
}

private func changeText(for asset: InvestmentSummaryAsset) -> String {
    if let daily = asset.dailyChange, abs(daily) > 0.0001 {
        return "\(daily >= 0 ? "+" : "")\(daily.percentText) today"
    }
    if let oneYear = asset.oneYearReturn {
        return "\(oneYear >= 0 ? "+" : "")\(oneYear.percentText) 1Y"
    }
    return "Growth loading"
}

private func shortChangeText(for asset: InvestmentSummaryAsset) -> String {
    if let daily = asset.dailyChange, abs(daily) > 0.0001 {
        return "\(daily >= 0 ? "+" : "")\(daily.percentText)"
    }
    if let oneYear = asset.oneYearReturn {
        return "\(oneYear >= 0 ? "+" : "")\(oneYear.percentText)"
    }
    return "N/A"
}

private func growthText(for asset: InvestmentSummaryAsset) -> String {
    if let daily = asset.dailyChange, abs(daily) > 0.0001 {
        return "\(daily >= 0 ? "+" : "")\(daily.percentText)"
    }
    if let oneYear = asset.oneYearReturn {
        return "\(oneYear >= 0 ? "+" : "")\(oneYear.percentText)"
    }
    return "N/A"
}

private func growthColor(for asset: InvestmentSummaryAsset) -> Color {
    if let daily = asset.dailyChange, abs(daily) > 0.0001 {
        return daily >= 0 ? AppTheme.auraGreen : AppTheme.vibrantRed
    }
    if let oneYear = asset.oneYearReturn {
        return oneYear >= 0 ? AppTheme.auraGreen : AppTheme.vibrantRed
    }
    return .secondary
}

private func changeColor(for asset: InvestmentSummaryAsset) -> Color {
    if let daily = asset.dailyChange, abs(daily) > 0.0001 {
        return daily >= 0 ? AppTheme.auraGreen : AppTheme.vibrantRed
    }
    if let oneYear = asset.oneYearReturn {
        return oneYear >= 0 ? AppTheme.auraGreen : AppTheme.vibrantRed
    }
    return asset.riskLevel.color
}

#Preview {
    NavigationStack {
        InvestmentIntelligenceView()
    }
}

#Preview("Company Profile Summary") {
    ScrollView {
        CompanyProfileSummary(
            profile: CompanyProfileSnapshot(
                name: "Tata Consultancy Services",
                ticker: "TCS.NS",
                sector: "Technology",
                industry: "Information Technology Services",
                country: "India",
                exchange: "NSE",
                logoURL: nil,
                description: "Tata Consultancy Services Limited is a worldwide leader in delivering information technology and IT-enabled services. Its operations are structured into business segments including Banking, Financial Services and Insurance, Manufacturing, Retail and Consumer Business, Communication, Media and Technology, and Life Sciences and Healthcare. The company provides proprietary platforms and software solutions including CHROMA, ignio, TCS iON, TAP, TCS MasterCraft, Quartz, TCS OmniStore, OPTUMERA, and TwinX. TCS also offers cloud, consulting, cybersecurity, analytics, and enterprise transformation services for global clients."
            ),
            accent: AppTheme.auraIndigo
        )
        .padding()
    }
}
