import SwiftUI

struct StockIntelligenceSection: View {
    let viewModel: StockIntelligenceViewModel
    @State private var isExpanded: Bool = false

    private var infoData: SectionInfoData {
        SectionInfoData(
            title: "AI Stock Intelligence",
            subtitle: "Fundamental synthesis for everyday investors",
            icon: "sparkles",
            badge: "AI Synthesis",
            whatItRepresents: "Breaks down complex corporate disclosures, revenue mechanics, long-term secular growth catalysts, and business risks into clear, understandable answers.",
            howItIsCalculated: "Synthesizes verified corporate annual reports (10-Ks), business operating segments, gross margins, and debt ratios through AstraFi's fundamental analysis engine.",
            dataSource: "AstraFi Intelligence Engine, Official SEC / NSE Filings, and Broker Consensus Reports.",
            limitations: "AI synthesis is provided for educational and analytical purposes only. It is not personal investment advice, a price forecast, or a recommendation to buy or sell securities.",
            keyTakeaway: "Evaluate both the growth catalysts and the operational risks together before making any investment decision."
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderWithInfo(
                title: "AI Stock Intelligence",
                subtitle: "Plain-language fundamental synthesis",
                systemImage: "sparkles",
                infoData: infoData
            )

            if viewModel.isLoading {
                loadingView
            } else if let intelligence = viewModel.companyIntelligence {
                let allItems = items(from: intelligence)
                let displayedItems = isExpanded ? allItems : Array(allItems.prefix(4))

                VStack(spacing: 12) {
                    ForEach(displayedItems) { item in
                        answerCard(item)
                    }

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(isExpanded ? "Show Key Highlights" : "See All \(allItems.count) Analysis Topics")
                                .font(.system(size: 13, weight: .bold))
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(AppTheme.auraIndigo)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.auraIndigo.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.top, 4)
                }
            } else if let errorMessage = viewModel.errorMessage {
                emptyView(title: "AI intelligence unavailable", message: errorMessage)
            } else {
                emptyView(title: "AI intelligence ready", message: "Open a stock to generate dynamic business, risk, market, employee, and competitor insights.")
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 12, x: 0, y: 4)
    }

    private var loadingView: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text("Building company facts and generating intelligence...")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.elevatedCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func answerCard(_ item: IntelligenceDisplayItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(item.emoji)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)
                    .background(item.color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                Text(item.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
            }

            VStack(alignment: .leading, spacing: 10) {
                let points = item.points.isEmpty ? ["Data unavailable"] : item.points
                ForEach(points, id: \.self) { point in
                    let cleaned = cleanBullet(point)
                    let parsed = parseTaggedPoint(cleaned)

                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 5, height: 5)
                            .padding(.top, 6)

                        VStack(alignment: .leading, spacing: 3) {
                            if let tag = parsed.tag {
                                Text(tag)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(item.color)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(item.color.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            }
                            Text(parsed.text)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(15)
        .background(AppTheme.elevatedCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func emptyView(title: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "tray.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(size: 15, weight: .bold))
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(AppTheme.elevatedCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func items(from intelligence: CompanyIntelligence) -> [IntelligenceDisplayItem] {
        [
            IntelligenceDisplayItem(id: "whyCanGrow", emoji: "🚀", title: "Why Can This Company Grow?", points: intelligence.whyCanGrow, color: AppTheme.auraGreen),
            IntelligenceDisplayItem(id: "biggestRisk", emoji: "⚠", title: "Biggest Risks to Monitor", points: intelligence.biggestRisk, color: AppTheme.vibrantOrange),
            IntelligenceDisplayItem(id: "eli20", emoji: "🎓", title: "Explain Like I'm 20", points: intelligence.eli20, color: AppTheme.vibrantCyan),
            IntelligenceDisplayItem(id: "revenueModel", emoji: "💰", title: "How Does It Make Money?", points: intelligence.revenueModel, color: AppTheme.auraMint),
            IntelligenceDisplayItem(id: "analystBullishReason", emoji: "📈", title: "Analyst Consensus Factors", points: intelligence.analystBullishReason, color: AppTheme.auraIndigo),
            IntelligenceDisplayItem(id: "whatCanGoWrong", emoji: "❌", title: "What Can Go Wrong?", points: intelligence.whatCanGoWrong, color: AppTheme.vibrantRed),
            IntelligenceDisplayItem(id: "addressableMarket", emoji: "🌍", title: "Addressable Market & Footprint", points: intelligence.addressableMarket, color: AppTheme.auraGold),
            IntelligenceDisplayItem(id: "employees", emoji: "👨‍💼", title: "Workforce & Operational Scale", points: intelligence.employees, color: AppTheme.auraPurple),
            IntelligenceDisplayItem(id: "competitors", emoji: "🏢", title: "Operating Segments & Peers", points: intelligence.competitors, color: AppTheme.auraIndigo),
            IntelligenceDisplayItem(id: "growthOpportunities", emoji: "🎯", title: "Secular Growth Opportunities", points: intelligence.growthOpportunities, color: AppTheme.auraGreen)
        ]
    }

    private func cleanBullet(_ point: String) -> String {
        let trimmed = point.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("- ") {
            return String(trimmed.dropFirst(2))
        }
        if trimmed.hasPrefix("• ") {
            return String(trimmed.dropFirst(2))
        }
        return trimmed
    }

    private func parseTaggedPoint(_ text: String) -> (tag: String?, text: String) {
        if text.hasPrefix("[") && text.contains("]") {
            let parts = text.split(separator: "]", maxSplits: 1, omittingEmptySubsequences: true)
            if parts.count == 2 {
                let tag = String(parts[0].dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
                let remaining = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
                return (tag, remaining)
            }
        }
        return (nil, text)
    }
}

private struct IntelligenceDisplayItem: Identifiable {
    let id: String
    let emoji: String
    let title: String
    let points: [String]
    let color: Color
}
