import SwiftUI

// MARK: - Saving Plan Option
public enum SavingPlanOption: String, CaseIterable, Identifiable {
    case sip, saveLeftover, noPlan
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .sip: return "I will start SIP"
        case .saveLeftover: return "Save as the amount left"
        case .noPlan: return "No plan yet"
        }
    }
    
    public var icon: String {
        switch self {
        case .sip: return "chart.line.uptrend.xyaxis"
        case .saveLeftover: return "indianrupeesign.circle.fill"
        case .noPlan: return "questionmark.circle.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .sip: return .green
        case .saveLeftover: return .orange
        case .noPlan: return .red
        }
    }
}


// MARK: - Goal Saving Plan Section
public struct GoalSavingPlanSection<Destination: View>: View {
    @Binding public var savingPlan: SavingPlanOption?
    @Binding public var expectedSIPAmount: String
    
    public let projectedMFCorpus: Double
    public let projectedStocksCorpus: Double
    public let totalCorpus: Double
    public let goalAccentColor: Color
    
    public let onSave: () -> Void
    public let destination: Destination
    
    public init(
        savingPlan: Binding<SavingPlanOption?>,
        expectedSIPAmount: Binding<String>,
        projectedMFCorpus: Double,
        projectedStocksCorpus: Double,
        totalCorpus: Double,
        goalAccentColor: Color,
        onSave: @escaping () -> Void,
        destination: Destination
    ) {
        self._savingPlan = savingPlan
        self._expectedSIPAmount = expectedSIPAmount
        self.projectedMFCorpus = projectedMFCorpus
        self.projectedStocksCorpus = projectedStocksCorpus
        self.totalCorpus = totalCorpus
        self.goalAccentColor = goalAccentColor
        self.onSave = onSave
        self.destination = destination
    }
    
    private func fmt(_ v: Double) -> String {
        if v >= 10_000_000 { return String(format: "₹%.2f Cr", v / 10_000_000) }
        if v >= 100_000    { return String(format: "₹%.2f L", v / 100_000) }
        return "₹\(Int(v))"
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // ── Saving Plan Question
            SectionCard {
                VStack(alignment: .leading, spacing: 0) {
                    SectionHeader2(
                        icon: "questionmark.circle.fill",
                        iconColor: goalAccentColor,
                        title: "What will be your plan?",
                        subtitle: "Choose how you intend to reach this goal"
                    )
                    .padding(.bottom, 14)
                    
                    Divider()
                    
                    ForEach(Array(SavingPlanOption.allCases.enumerated()), id: \.element.id) { index, plan in
                        Button {
                            savingPlan = plan
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: plan.icon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .frame(width: 40, height: 40)
                                    .foregroundStyle(plan.color)
                                    .background(plan.color.opacity(0.1),
                                                in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(plan.title)
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(savingPlan == plan ? plan.color : .primary)
                                    Text(planSubtitle(for: plan))
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                ZStack {
                                    Circle()
                                        .stroke(savingPlan == plan ? plan.color : Color.secondary.opacity(0.3), lineWidth: 2)
                                        .frame(width: 22, height: 22)
                                    if savingPlan == plan {
                                        Circle().fill(plan.color).frame(width: 13, height: 13)
                                    }
                                }
                            }
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: savingPlan)
                        
                        if index < SavingPlanOption.allCases.count - 1 {
                            Divider().padding(.leading, 54)
                        }
                    }
                    
                    if savingPlan == .sip {
                        Divider().padding(.top, 4).padding(.bottom, 16)
                        
                        HStack {
                            Text("Expected SIP (₹)")
                                .font(.system(size: 15, design: .rounded))
                                .foregroundStyle(.secondary)
                            Spacer()
                            GoalAmountField(text: $expectedSIPAmount, placeholder: "e.g. 10000")
                                .frame(width: 120)
                        }
                        .padding(.horizontal, 4)
                        
                        if let sipAmt = Double(expectedSIPAmount), sipAmt > 0 {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("MF Growth (12%)")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundStyle(.secondary)
                                    Text(fmt(projectedMFCorpus))
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundStyle(.green)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Stocks Growth (15%)")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundStyle(.secondary)
                                    Text(fmt(projectedStocksCorpus))
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundStyle(.indigo)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(12)
                            .background(AppTheme.elevatedCardBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            
            // ── Plan Action / Insight
            let sipAmt = Double(expectedSIPAmount) ?? 0
            if let plan = savingPlan, (plan != .sip || sipAmt > 0) {
                SectionCard {
                    VStack(spacing: 16) {
                        if plan == .sip && projectedMFCorpus >= totalCorpus {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.green)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Goal Achievable!")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundStyle(.green)
                                    Text("By starting a SIP, you are on the right track to achieve this goal comfortably.")
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button {
                                onSave()
                            } label: {
                                Text("Save Plan to Tracker")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }
                        } else {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.orange)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Goal at Risk")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundStyle(.orange)
                                    
                                    if plan == .sip {
                                        let shortfall = max(0, totalCorpus - projectedMFCorpus)
                                        Text("By SIP you can build \(fmt(projectedMFCorpus)), facing a shortfall of \(fmt(shortfall)).\n\nWanna know better plans?")
                                            .font(.system(size: 13, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("Without a structured plan or with insufficient savings, inflation might outpace you. Wanna know better plans?")
                                            .font(.system(size: 13, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            NavigationLink {
                                destination
                            } label: {
                                Text("Continue")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(goalAccentColor)
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: savingPlan)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: expectedSIPAmount)
    }
    
    private func planSubtitle(for plan: SavingPlanOption) -> String {
        switch plan {
        case .sip: return "Invest regularly to beat inflation"
        case .saveLeftover: return "Save whatever is left at month end"
        case .noPlan: return "Haven't decided yet"
        }
    }
}
