import SwiftUI

public struct SectionInfoData: Identifiable, Equatable {
    public var id: String { title }
    public let title: String
    public let subtitle: String
    public let icon: String
    public let badge: String
    public let whatItRepresents: String
    public let howItIsCalculated: String
    public let dataSource: String
    public let limitations: String
    public let keyTakeaway: String

    public init(
        title: String,
        subtitle: String = "Understanding this section",
        icon: String = "info.circle.fill",
        badge: String = "Analysis Guide",
        whatItRepresents: String,
        howItIsCalculated: String,
        dataSource: String,
        limitations: String,
        keyTakeaway: String
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.badge = badge
        self.whatItRepresents = whatItRepresents
        self.howItIsCalculated = howItIsCalculated
        self.dataSource = dataSource
        self.limitations = limitations
        self.keyTakeaway = keyTakeaway
    }
}

public struct InvestmentSectionInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let data: SectionInfoData

    public init(data: SectionInfoData) {
        self.data = data
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text(data.badge.uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(AppTheme.auraIndigo)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.auraIndigo.opacity(0.12))
                                .clipShape(Capsule())
                            Spacer()
                        }
                        HStack(spacing: 12) {
                            Image(systemName: data.icon)
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(AppTheme.auraIndigo)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(data.title)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.primary)
                                Text(data.subtitle)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.elevatedCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    // 1. What This Section Represents
                    infoBlock(
                        title: "What This Section Shows",
                        icon: "eye.fill",
                        color: AppTheme.auraIndigo,
                        content: data.whatItRepresents
                    )

                    // 2. How It Is Calculated & Assembled
                    infoBlock(
                        title: "How It Is Calculated & Assembled",
                        icon: "function",
                        color: AppTheme.auraMint,
                        content: data.howItIsCalculated
                    )

                    // 3. Data Source Attribution
                    infoBlock(
                        title: "Data Sources & Provenance",
                        icon: "server.rack",
                        color: AppTheme.vibrantCyan,
                        content: data.dataSource
                    )

                    // 4. Limitations & Caution
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(AppTheme.vibrantOrange)
                            Text("Important Limitations & Cautions")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(AppTheme.vibrantOrange)
                        }
                        Text(data.limitations)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.vibrantOrange.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppTheme.vibrantOrange.opacity(0.25), lineWidth: 1)
                    )

                    // 5. Investor Key Takeaway
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppTheme.auraGreen)
                            Text("Key Takeaway for Investors")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppTheme.auraGreen)
                        }
                        Text(data.keyTakeaway)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.auraGreen.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    // Close Button
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.auraIndigo)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.top, 6)
                }
                .padding(18)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func infoBlock(title: String, icon: String, color: Color, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
            }
            Text(content)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.elevatedCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

public struct SectionHeaderWithInfo: View {
    public let title: String
    public let subtitle: String?
    public let systemImage: String?
    public let infoData: SectionInfoData
    @State private var showingInfoSheet = false

    public init(
        title: String,
        subtitle: String? = nil,
        systemImage: String? = nil,
        infoData: SectionInfoData
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.infoData = infoData
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.auraIndigo)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                showingInfoSheet = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(6)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Information about \(title)")
        }
        .sheet(isPresented: $showingInfoSheet) {
            InvestmentSectionInfoSheet(data: infoData)
        }
    }
}
