import SwiftUI

// MARK: - Section Header
struct SimulatorSectionHeader: View {
    let title: String
    let subtitle: String?
    let icon: String
    var iconColor: Color = AppTheme.auraIndigo

    init(title: String, subtitle: String? = nil, icon: String, iconColor: Color = AppTheme.auraIndigo) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.auraHeader(size: 18))
                    .foregroundStyle(.primary)
                if let sub = subtitle {
                    Text(sub)
                        .font(.auraCaption())
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
        }
    }
}

// MARK: - Metric Card
struct SimulatorMetricCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    var color: Color = AppTheme.auraIndigo
    var icon: String? = nil

    init(title: String, value: String, subtitle: String? = nil, color: Color = AppTheme.auraIndigo, icon: String? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.color = color
        self.icon = icon
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.auraCaption())
                    .foregroundStyle(.secondary)
                Spacer()
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(color)
                }
            }

            Text(value)
                .font(.auraDigital(size: 20))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            if let sub = subtitle {
                Text(sub)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 3)
    }
}

// MARK: - Feasibility Banner
struct SimulatorFeasibilityBanner: View {
    let status: PlanFeasibility
    let explanation: String

    init(status: PlanFeasibility, explanation: String) {
        self.status = status
        self.explanation = explanation
    }

    private var bannerColor: Color {
        switch status {
        case .healthy: return AppTheme.auraGreen
        case .manageable: return AppTheme.vibrantCyan
        case .aggressive: return AppTheme.vibrantOrange
        case .notCurrentlyFeasible: return AppTheme.vibrantRed
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: status.icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(bannerColor)
                Text(status.rawValue.uppercased())
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(bannerColor)
                Spacer()
            }

            Text(explanation)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(bannerColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(bannerColor.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Numeric / Currency Input Field
struct SimulatorInputField: View {
    let title: String
    @Binding var value: Double
    var prefix: String = "₹"
    var suffix: String = ""
    var step: Double = 10_000
    var range: ClosedRange<Double> = 0...100_000_000

    init(title: String, value: Binding<Double>, prefix: String = "₹", suffix: String = "", step: Double = 10_000, range: ClosedRange<Double> = 0...100_000_000) {
        self.title = title
        self._value = value
        self.prefix = prefix
        self.suffix = suffix
        self.step = step
        self.range = range
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            HStack {
                if !prefix.isEmpty {
                    Text(prefix)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                TextField("0", value: $value, format: .number)
                    .keyboardType(.numberPad)
                    .font(.system(size: 16, weight: .bold, design: .rounded))

                if !suffix.isEmpty {
                    Text(suffix)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 6) {
                    Button {
                        if value - step >= range.lowerBound {
                            value -= step
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        if value + step <= range.upperBound {
                            value += step
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(AppTheme.auraIndigo)
                    }
                }
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

// MARK: - Save and Follow Footer
struct SimulatorSaveFooter: View {
    let planName: String
    let targetGoal: String
    let planInput: InvestmentPlanInputModel
    @Environment(TrackerViewModel.self) private var trackerVM
    @State private var showingAlert = false
    @State private var alertMessage = ""

    init(planName: String, targetGoal: String, planInput: InvestmentPlanInputModel) {
        self.planName = planName
        self.targetGoal = targetGoal
        self.planInput = planInput
    }

    var body: some View {
        VStack(spacing: 12) {
            Button {
                trackerVM.savePlan(
                    planName: planName,
                    input: planInput
                )
                alertMessage = "“\(planName)” has been saved to your Tracker tab illustrations."
                showingAlert = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bookmark.fill")
                    Text("Save Plan to Tracker")
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.accentGradient)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: AppTheme.auraIndigo.opacity(0.3), radius: 10, x: 0, y: 5)
            }

            Button {
                trackerVM.followPlan(
                    planName: planName,
                    input: planInput
                )
                alertMessage = "Now following “\(planName)”. Track ongoing contributions and returns in your Dashboard!"
                showingAlert = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                    Text("Follow This Plan")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.auraIndigo)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.auraIndigo.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .alert("Plan Status", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}
