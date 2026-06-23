import SwiftUI

struct StockIntelligenceSection: View {
    let viewModel: StockIntelligenceViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.auraIndigo)
                    .frame(width: 28, height: 28)
                    .background(AppTheme.auraIndigo.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("AI Stock Intelligence")
                        .font(.system(size: 18, weight: .bold))
                    Text("Simple answers generated from profile, financials, price history, sector, employees, and competitors.")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if viewModel.isLoading {
                loadingView
            } else if let intelligence = viewModel.companyIntelligence {
                VStack(spacing: 12) {
                    ForEach(items(from: intelligence)) { item in
                        answerCard(item)
                    }
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

            VStack(alignment: .leading, spacing: 9) {
                let points = item.points.isEmpty ? ["Data unavailable"] : item.points
                ForEach(points, id: \.self) { point in
                    HStack(alignment: .top, spacing: 9) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)
                        Text(cleanBullet(point))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
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
            IntelligenceDisplayItem(id: "biggestRisk", emoji: "⚠", title: "Biggest Risk", points: intelligence.biggestRisk, color: AppTheme.vibrantOrange),
            IntelligenceDisplayItem(id: "eli20", emoji: "🎓", title: "Explain Like I'm 20", points: intelligence.eli20, color: AppTheme.vibrantCyan),
            IntelligenceDisplayItem(id: "revenueModel", emoji: "💰", title: "How Does It Make Money?", points: intelligence.revenueModel, color: AppTheme.auraMint),
            IntelligenceDisplayItem(id: "analystBullishReason", emoji: "📈", title: "Why Are Analysts Bullish?", points: intelligence.analystBullishReason, color: AppTheme.auraIndigo),
            IntelligenceDisplayItem(id: "whatCanGoWrong", emoji: "❌", title: "What Can Go Wrong?", points: intelligence.whatCanGoWrong, color: AppTheme.vibrantRed),
            IntelligenceDisplayItem(id: "addressableMarket", emoji: "🌍", title: "Addressable Market", points: intelligence.addressableMarket, color: AppTheme.auraGold),
            IntelligenceDisplayItem(id: "employees", emoji: "👨‍💼", title: "Employees", points: intelligence.employees, color: AppTheme.auraPurple),
            IntelligenceDisplayItem(id: "competitors", emoji: "🏢", title: "Competitors", points: intelligence.competitors, color: AppTheme.auraIndigo),
            IntelligenceDisplayItem(id: "growthOpportunities", emoji: "🎯", title: "Growth Opportunities", points: intelligence.growthOpportunities, color: AppTheme.auraGreen)
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
}

private struct IntelligenceDisplayItem: Identifiable {
    let id: String
    let emoji: String
    let title: String
    let points: [String]
    let color: Color
}
