import SwiftUI

struct NewsCardView: View {
    let newsItems: [NewsItem] = [
        NewsItem(title: "RBI holds repo rate steady at 6.5% — what it means for your home loan EMI", description: "Stable rates mean your floating-rate EMIs remain unchanged for now.", time: "2h ago", category: "Market News", categoryColor: .blue),
        NewsItem(title: "Nifty 50 crosses 23,000 — midcap funds see renewed interest", description: "Analysts suggest reviewing your equity allocation if midcaps cross 15% of portfolio.", time: "5h ago", category: "Market Update", categoryColor: .green)
    ]
    var body: some View {
        VStack(spacing: 12) { ForEach(newsItems) { item in EnhancedNewsCard(news: item) } }
    }
}

struct NewsItem: Identifiable {
    let id = UUID(); let title: String; let description: String; let time: String; let category: String; let categoryColor: Color
}

struct EnhancedNewsCard: View {
    @Environment(\.colorScheme) var colorScheme
    let news: NewsItem
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(news.category).font(.caption).fontWeight(.semibold).foregroundColor(news.categoryColor).padding(.horizontal, 10).padding(.vertical, 4).background(news.categoryColor.opacity(0.12)).cornerRadius(8)
                Spacer()
                Text(news.time).font(.caption).foregroundColor(.secondary)
            }
            Text(news.title).font(.headline).fontWeight(.semibold).foregroundColor(.primary).fixedSize(horizontal: false, vertical: true)
            Text(news.description).font(.subheadline).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
        }
        .padding(18).background(AppTheme.cardBackground).cornerRadius(18).shadow(color: AppTheme.adaptiveShadow, radius: 12, x: 0, y: 6)
    }
}

#Preview {
    NewsCardView()
        .padding()
}
