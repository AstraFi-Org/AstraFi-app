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
                        ForEach(assets.prefix(6)) { asset in
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
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                AssetIcon(kind: asset.kind, size: 36)
                VStack(alignment: .leading, spacing: 5) {
                    Text(asset.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(asset.sector)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
            }
            
            Spacer(minLength: 0)

            HStack(spacing: 8) {
                InfoPill(title: asset.kind == .mutualFund ? "Current NAV" : "Current Price", value: valueText(for: asset), color: asset.kind.accent)
                InfoPill(title: "Growth", value: growthText(for: asset), color: growthColor(for: asset))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .frame(width: 248, height: 152, alignment: .topLeading)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.7), radius: 10, x: 0, y: 3)
    }
}

struct InvestmentHomePreviewCard: View {
    let asset: InvestmentSummaryAsset

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                AssetIcon(kind: asset.kind, size: 36)
                VStack(alignment: .leading, spacing: 5) {
                    Text(asset.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(asset.sector)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
            }
            
            Spacer(minLength: 0)

            HStack(spacing: 8) {
                InfoPill(title: asset.kind == .mutualFund ? "Current NAV" : "Current Price", value: valueText(for: asset), color: asset.kind.accent)
                InfoPill(title: "Growth", value: growthText(for: asset), color: growthColor(for: asset))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .frame(width: 248, height: 152, alignment: .topLeading)
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
                    HStack(alignment: .top, spacing: 12) {
                        if let url = profile.logoURL {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                AssetIcon(kind: asset.kind, size: 42)
                            }
                            .frame(width: 42, height: 42)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            MetricGrid(metrics: [
                                InvestmentMetric(title: "Sector", value: profile.sector, systemImage: "square.3.layers.3d", color: asset.kind.accent),
                                InvestmentMetric(title: "Industry", value: profile.industry, systemImage: "gearshape.2.fill", color: AppTheme.auraMint),
                                InvestmentMetric(title: "Country", value: profile.country, systemImage: "globe.asia.australia.fill", color: AppTheme.vibrantCyan),
                                InvestmentMetric(title: "Exchange", value: profile.exchange, systemImage: "building.columns.fill", color: AppTheme.auraPurple)
                            ])
                            Text(profile.description)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
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
}

private struct FinancialsTab: View {
    let snapshot: InvestmentDetailSnapshot?
    let asset: InvestmentSummaryAsset

    var body: some View {
        DetailCard(title: "Financials", systemImage: "chart.bar.xaxis") {
            Label("Only provider fundamentals are shown. Missing values stay unavailable until Finnhub or another connected source returns them.", systemImage: "info.circle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            MetricGrid(metrics: metrics)

            let chartMetrics = numericMetrics
            if !chartMetrics.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Easy comparison")
                        .font(.system(size: 14, weight: .bold))
                    Chart(chartMetrics) { metric in
                        BarMark(
                            x: .value("Value", abs(metric.value)),
                            y: .value("Metric", metric.title)
                        )
                        .foregroundStyle(metric.color)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks { value in
                            AxisValueLabel()
                                .font(.system(size: 11, weight: .semibold))
                        }
                    }
                    .frame(height: CGFloat(max(120, chartMetrics.count * 34)))
                    .accessibilityLabel("Financial metric comparison chart")
                }
                .padding(14)
                .background(AppTheme.elevatedCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var metrics: [InvestmentMetric] {
        if let financials = snapshot?.financials {
            return [
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

        return [
            InvestmentMetric(title: "Current NAV", value: asset.currentValue?.intelligenceCurrency ?? "Loading", systemImage: "indianrupeesign.circle.fill", color: AppTheme.auraGreen),
            InvestmentMetric(title: "1Y Return", value: asset.oneYearReturn?.percentText ?? "Based on NAV history", systemImage: "chart.line.uptrend.xyaxis", color: AppTheme.auraIndigo),
            InvestmentMetric(title: "Risk Level", value: asset.riskLevel.rawValue, systemImage: "exclamationmark.triangle.fill", color: asset.riskLevel.color),
            InvestmentMetric(title: "Category", value: asset.sector, systemImage: "square.grid.2x2.fill", color: AppTheme.auraPurple)
        ]
    }

    private func numericValue(_ string: String) -> Double {
        Double(string.replacingOccurrences(of: "%", with: "")) ?? 1
    }

    private var numericMetrics: [FinancialChartMetric] {
        metrics.compactMap { metric in
            let value = numericValue(metric.value)
            guard value != 1 || metric.value.contains("1") else { return nil }
            return FinancialChartMetric(title: metric.title, value: value, color: metric.color)
        }
        .prefix(6)
        .map { $0 }
    }
}


private struct InsightsTab: View {
    let asset: InvestmentSummaryAsset
    let aiInsight: String?
    let insights: [InvestmentInsight]
    let recommendations: [RecommendationTrend]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !recommendations.isEmpty {
                DetailCard(title: "Recommendation Trends", systemImage: "chart.bar.fill") {
                    Chart(recommendations) { trend in
                        BarMark(x: .value("Count", trend.count), y: .value("Rating", trend.label))
                            .foregroundStyle(AppTheme.auraIndigo)
                    }
                    .frame(height: 180)
                    .accessibilityLabel("Analyst recommendation trend bar chart")
                }
            }

            DetailCard(title: "Rule-Based Insights", systemImage: "lightbulb.fill") {
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
        }
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
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(color.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
    let assets: [InvestmentSummaryAsset]
    @State private var searchText = ""

    private var filteredAssets: [InvestmentSummaryAsset] {
        if searchText.isEmpty {
            return assets
        }
        return assets.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.symbol.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 10) {
                if filteredAssets.isEmpty {
                    ContentUnavailableView("No matches", systemImage: "magnifyingglass", description: Text("Could not find any \(title.lowercased()) matching your search."))
                        .padding(.top, 40)
                } else {
                    ForEach(filteredAssets) { asset in
                        NavigationLink(destination: InvestmentIntelligenceDetailView(asset: asset)) {
                            SearchResultRow(asset: asset)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, AppTheme.auraPadding)
            .padding(.vertical, 20)
        }
        .background(AppTheme.appBackground(for: colorScheme))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search \(title.lowercased())")
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
    return value.intelligenceCurrency
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
