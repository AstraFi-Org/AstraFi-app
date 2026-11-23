import SwiftUI

struct FinancialSimulatorsHubView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    init() {}

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header Hero
                heroSection

                // Three Simulators
                VStack(spacing: 16) {
                    // 1. Fixed-Income Ladder
                    NavigationLink(destination: FixedIncomeLadderInputView()) {
                        SimulatorCard(
                            title: "Fixed-Income Ladder Strategy",
                            subtitle: "Stagger bank FDs, G-Secs, T-bills, and corporate bonds to optimize cash flow and liquidity.",
                            icon: "stairs",
                            gradientColors: [Color(hex: "#007AFF"), Color(hex: "#5E5CE6")],
                            badgeText: "DEBT & LIQUIDITY",
                            metric: "7.0–8.5% YTM",
                            tag: "Capital Preservation"
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    // 2. REIT & Listed Assets
                    NavigationLink(destination: REITSimulatorInputView()) {
                        SimulatorCard(
                            title: "REIT & Listed Assets Strategy",
                            subtitle: "Simulate quarterly rental distributions, commercial unit price changes, and DRIP compounding.",
                            icon: "building.2.crop.circle.fill",
                            gradientColors: [Color(hex: "#30D158"), Color(hex: "#00C7BE")],
                            badgeText: "COMMERCIAL REAL ESTATE",
                            metric: "6.5–8.0% Yield",
                            tag: "Inflation-Hedge"
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    // 3. Retirement SWP
                    NavigationLink(destination: RetirementSWPInputView()) {
                        SimulatorCard(
                            title: "Retirement Income & SWP Engine",
                            subtitle: "Month-by-month decumulation engine stress-testing inflation, healthcare drag, and sequence risk.",
                            icon: "figure.walk.arrival",
                            gradientColors: [Color(hex: "#BF5AF2"), Color(hex: "#5E5CE6")],
                            badgeText: "DECUMULATION & RETIREMENT",
                            metric: "Solvency Engine",
                            tag: "Longevity Protection"
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .background(AppTheme.appBackground(for: colorScheme))
        .navigationTitle("Financial Simulators")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var heroSection: some View {
        VStack(spacing: 8) {
            Text("Advanced Financial Engines")
                .font(.auraHeader(size: 22))
                .multilineTextAlignment(.center)

            Text("Explore deterministic cash flow, listed income, and systematic withdrawal simulations built to model real-world risks.")
                .font(.system(size: 14, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
        }
    }
}

// MARK: - Simulator Card
private struct SimulatorCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradientColors: [Color]
    let badgeText: String
    let metric: String
    let tag: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top Badge Bar
            HStack {
                Text(badgeText)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Text(tag)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
            )

            // Card Body
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(gradientColors.first?.opacity(0.12) ?? Color.blue.opacity(0.12))
                            .frame(width: 46, height: 46)

                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(gradientColors.first ?? Color.blue)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text(subtitle)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.secondary.opacity(0.5))
                }

                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(gradientColors.first ?? Color.blue)
                        Text("Deterministic Math")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(gradientColors.first?.opacity(0.08) ?? Color.blue.opacity(0.08))
                    .clipShape(Capsule())

                    Spacer()

                    Text(metric)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(16)
            .background(AppTheme.cardBackground)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 5)
    }
}
