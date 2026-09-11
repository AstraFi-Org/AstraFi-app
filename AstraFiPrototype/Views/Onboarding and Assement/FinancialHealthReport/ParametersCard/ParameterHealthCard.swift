import SwiftUI

struct ParameterHealthCard: View {
    let result: FinancialHealthParameterResult
    var action: (() -> Void)? = nil

    private var accent: Color { FinancialHealthUIStyle.accent(for: result.parameter) }
    private var statusColor: Color { FinancialHealthUIStyle.parameterColor(result.status) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: FinancialHealthUIStyle.icon(for: result.parameter))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 36, height: 36)
                    .background(accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(result.parameter.title)
                        .font(.headline)
                    Text(result.displayScore)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(statusColor)
                }
                Spacer()
                Text(result.statusTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 10) {
                ForEach(result.metrics.prefix(6)) { metric in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(metric.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(metric.value)
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }

            labeledBlock(title: "Why", text: result.whyItMatters, color: accent)
            if result.status != .fine {
                labeledBlock(title: "Impact", text: result.financialImpact, color: Color(hex: "#FF9F0A"))
            }

            if let action {
                Button(action: action) {
                    Text(result.actionTitle)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .foregroundStyle(.white)
                        .background(AppTheme.auraIndigo, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }

    private func labeledBlock(title: String, text: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
                .textCase(.uppercase)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct ParameterExplainDetailView: View {
    let result: FinancialHealthParameterResult
    var onAction: () -> Void

    private var statusColor: Color { FinancialHealthUIStyle.parameterColor(result.status) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(result.parameter.title)
                        .font(.title2.bold())
                    Text(result.displayScore)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(statusColor)
                    Text(result.statusTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(statusColor)
                }

                section("What we found") {
                    ForEach(result.metrics) { metric in
                        HStack {
                            Text(metric.label).foregroundStyle(.secondary)
                            Spacer()
                            Text(metric.value).fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                }

                section("Why it matters") {
                    Text(result.whyItMatters)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                section("What it can affect") {
                    ForEach(result.affectedAreas, id: \.self) { area in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text(area)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }

                section("Score impact") {
                    Text("Weight: \(result.weightPercent)%")
                        .font(.subheadline.weight(.semibold))
                    Text(result.contributionSentence)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Based on AstraFi's scoring model.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                section("How to improve") {
                    Text(result.recommendedAction)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button(action: onAction) {
                        Text(result.actionTitle)
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .foregroundStyle(.white)
                            .background(AppTheme.auraIndigo, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(result.parameter.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
