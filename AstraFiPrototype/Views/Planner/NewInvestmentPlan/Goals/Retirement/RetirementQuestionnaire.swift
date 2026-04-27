import SwiftUI


// MARK: - Uniform Info Row (label + value)
private struct InfoRow: View {
    let label: String
    let value: String
    let valueColor: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(valueColor)
        }
    }
}

// MARK: - Main View
struct RetirementQuestionnaire: View {
    @Binding var input: InvestmentPlanInputModel
    let stepId: String
    let profileAge: Int?
    let goalAccentColor: Color

    @Environment(AppStateManager.self) private var appState
    @Environment(\.dismiss) private var dismiss
    
    @State private var showExpenseSheet = false
    @State private var savingPlan: SavingPlanOption? = nil
    @State private var expectedSIPAmount: String = ""

    var body: some View {
        ScrollView(showsIndicators: false){
            VStack(spacing: 16) {
                
                // ── 1. Timeline Card
                SectionCard {
                    VStack(spacing: 16) {
                        SectionHeader2(
                            icon: "clock.fill",
                            iconColor: goalAccentColor,
                            title: "Retirement Timeline",
                            subtitle: "When do you plan to stop working?"
                        )
                        
                        Divider()
                        
                        // ✅ Simple inline row — no nested card
                        HStack {
                            Text("Retirement Age")
                                .font(.system(size: 15, design: .rounded))
                                .foregroundStyle(.secondary)
                            Spacer()
                            TextField("e.g. 60", text: Binding(
                                get: { String(input.retirementAge ?? 60) },
                                set: { input.retirementAge = Int($0) }
                            ))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .frame(width: 80)
                        }
                        
                        if let age = profileAge {
                            HStack(spacing: 8) {
                                Image(systemName: "person.crop.circle.fill.badge.checkmark")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.blue)
                                Text("Current age: \(age) years")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(.blue)
                                Text("· From your profile")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        
                        if let age = profileAge, let rAge = input.retirementAge, rAge > age {
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundStyle(goalAccentColor)
                                    .font(.system(size: 14))
                                Text("Time to retirement:")
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundStyle(.secondary)
                                Text("\(rAge - age) years")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(goalAccentColor)
                                Spacer()
                            }
                        }
                        
                        Divider()
                        
                        LabeledField(
                            label: "Years in Retirement",
                            icon: "sun.max.fill",
                            note: "Used to calculate total corpus needed"
                        ) {
                            PlanSliderStepper(
                                value: Binding(
                                    get: { input.yearsPostRetirement ?? 25 },
                                    set: { input.yearsPostRetirement = $0 }
                                ),
                                range: 10...40,
                                unit: "yrs"
                            )
                        }
                    }
                }
                // ── 2. Lifestyle Selection Card
//                SectionCard {
//                    VStack(alignment: .leading, spacing: 16) {
//                        SectionHeader(
//                            icon: "hand.tap.fill",
//                            iconColor: .purple,
//                            title: "Retirement Lifestyle",
//                            subtitle: "What type of life do you want after retirement?"
//                        )
//
//                        Divider()
//
//                        VStack(spacing: 10) {
//                            LifestyleChoiceCard(
//                                title: "Lavish",
//                                description: "Dining in best hotels, trips, pubs & luxury lifestyle",
//                                isSelected: input.lifestylePreference == "Lavish",
//                                color: .purple
//                            ) { input.lifestylePreference = "Lavish" }
//
//                            LifestyleChoiceCard(
//                                title: "Normal",
//                                description: "Comfortable trips, good food & occasional luxury",
//                                isSelected: input.lifestylePreference == "Normal",
//                                color: .blue
//                            ) { input.lifestylePreference = "Normal" }
//
//                            LifestyleChoiceCard(
//                                title: "Average",
//                                description: "Essential comforts with budget-friendly trips",
//                                isSelected: input.lifestylePreference == "Average",
//                                color: .green
//                            ) { input.lifestylePreference = "Average" }
//                        }
//                    }
//                }
                // ── 2. Lifestyle Selection Card
                SectionCard {
                    VStack(alignment: .leading, spacing: 0) {  // ✅ spacing: 0, dividers handle gaps
                        SectionHeader2(
                            icon: "hand.tap.fill",
                            iconColor: .purple,
                            title: "Retirement Lifestyle",
                            subtitle: "What type of life do you want after retirement?"
                        )
                        .padding(.bottom, 14)

                        Divider()

                        LifestyleChoiceCard(
                            title: "Lavish",
                            description: "Dining in best hotels, trips, pubs & luxury lifestyle",
                            isSelected: input.lifestylePreference == "Lavish",
                            color: .purple
                        ) { input.lifestylePreference = "Lavish" }

                        Divider().padding(.leading, 54)  // ✅ inset divider aligns with text

                        LifestyleChoiceCard(
                            title: "Normal",
                            description: "Comfortable trips, good food & occasional luxury",
                            isSelected: input.lifestylePreference == "Normal",
                            color: .blue
                        ) { input.lifestylePreference = "Normal" }

                        Divider().padding(.leading, 54)

                        LifestyleChoiceCard(
                            title: "Average",
                            description: "Essential comforts with budget-friendly trips",
                            isSelected: input.lifestylePreference == "Average",
                            color: .green
                        ) { input.lifestylePreference = "Average" }
                    }
                }
                
                // ── 3. Dynamic Insights Card
                if let preference = input.lifestylePreference {
                    SectionCard {
                        VStack(spacing: 16) {
                            SectionHeader2(
                                icon: "sparkles",
                                iconColor: .orange,
                                title: "Corpus Estimate",
                                subtitle: "Based on your lifestyle choice"
                            )
                            Divider()
                            RetirementInsightCard(
                                preference: preference,
                                targetAge: input.retirementAge ?? 60,
                                tenure: input.yearsPostRetirement ?? 25,
                                onInfoTap: { showExpenseSheet = true }
                            )
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // ── 4. Plan Section (Universal)
                GoalSavingPlanSection(
                    savingPlan: $savingPlan,
                    expectedSIPAmount: $expectedSIPAmount,
                    projectedMFCorpus: projectedMFCorpus,
                    projectedStocksCorpus: projectedStocksCorpus,
                    totalCorpus: getTargetCorpusValue(),
                    goalAccentColor: goalAccentColor,
                    onSave: {
                        let planModel = InvestmentPlanModel(
                            name: "Retirement Plan",
                            dateSaved: DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none),
                            targetGoal: "Retirement",
                            input: buildTrackerInput()
                        )
                        appState.savePlan(planModel)
                        dismiss()
                    },
                    destination: RetirementResultView(input: buildTrackerInput())
                )
                
                Spacer(minLength: 40)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: input.lifestylePreference)
            .sheet(isPresented: $showExpenseSheet) {
                LifestyleExpenseSheet(preference: input.lifestylePreference ?? "Normal")
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture { hideKeyboard() }
    }
    
    private var projectedMFCorpus: Double {
        let sip = Double(expectedSIPAmount) ?? 0
        let years = Double(max(1, (input.retirementAge ?? 60) - (profileAge ?? 35)))
        let months = years * 12
        let rate = 0.12 / 12
        guard rate > 0 && months > 0 else { return 0 }
        return sip * ((pow(1 + rate, months) - 1) / rate) * (1 + rate)
    }

    private var projectedStocksCorpus: Double {
        let sip = Double(expectedSIPAmount) ?? 0
        let years = Double(max(1, (input.retirementAge ?? 60) - (profileAge ?? 35)))
        let months = years * 12
        let rate = 0.15 / 12
        guard rate > 0 && months > 0 else { return 0 }
        return sip * ((pow(1 + rate, months) - 1) / rate) * (1 + rate)
    }
    
    private func buildTrackerInput() -> InvestmentPlanInputModel {
        var trackerInput = input
        trackerInput.investmentType = "Monthly SIP"
        trackerInput.amount = savingPlan == .sip ? expectedSIPAmount : "0"
        trackerInput.targetAmount = String(format: "%.0f", getTargetCorpusValue())
        let age = (profileAge == 0 || profileAge == nil) ? 35 : profileAge!
        trackerInput.timePeriod = String(max(1, (input.retirementAge ?? 60) - age))
        trackerInput.goalPlanType = savingPlan?.rawValue
        trackerInput.goalSIPAmount = expectedSIPAmount
        return trackerInput
    }

    private func getTargetCorpusValue() -> Double {
        let base: Double
        switch input.lifestylePreference {
        case "Lavish": base = 120_000_000.0
        case "Normal": base = 45_000_000.0
        default:       base = 22_000_000.0
        }
        let tenure = Double(input.yearsPostRetirement ?? 25)
        return base * (tenure / 25.0)
    }
}

// MARK: - Lifestyle Choice Card (redesigned)
struct LifestyleChoiceCard: View {
    let title: String
    let description: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    private var icon: String {
        switch title {
        case "Lavish": return "crown.fill"
        case "Normal": return "star.fill"
        default:       return "leaf.fill"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? color : .primary)
                    Text(description)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // ✅ Radio circle only — no card background
                ZStack {
                    Circle()
                        .stroke(isSelected ? color : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(color)
                            .frame(width: 13, height: 13)
                    }
                }
            }
            .padding(.vertical, 10)
            // ✅ Removed .background and .overlay — no more inner card
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}



// MARK: - Scenario Impact Row (unchanged logic, tightened padding)
struct ScenarioImpactRow: View {
    let title: String; let impact: String; let loss: String; let icon: String; let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.1), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .bold, design: .rounded))
                Text(impact).font(.system(size: 11, design: .rounded)).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Potential Loss")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.red.opacity(0.8))
                Text("- \(loss)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.red)
            }
        }
        .padding(10)
        .background(AppTheme.elevatedCardBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Insight Card (redesigned)
struct InsightCard: View {
    let title: String; let icon: String; let iconColor: Color
    let message: String; let scenarios: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(iconColor.opacity(0.12)).frame(width: 32, height: 32)
                    Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(iconColor)
                }
                Text(title).font(.system(size: 14, weight: .bold, design: .rounded))
            }
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(.secondary).lineSpacing(3)
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Label("KEY CONSIDERATIONS", systemImage: "list.bullet")
                    .font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary)
                ForEach(scenarios, id: \.self) { s in
                    HStack(alignment: .top, spacing: 8) {
                        Circle().fill(iconColor.opacity(0.5)).frame(width: 5, height: 5).padding(.top, 5)
                        Text(s).font(.system(size: 12, design: .rounded)).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(14)
        .background(iconColor.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(iconColor.opacity(0.18), lineWidth: 1))
    }
}

// MARK: - Retirement Insight Card (redesigned)
struct RetirementInsightCard: View {
    let preference: String; let targetAge: Int; let tenure: Int; let onInfoTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: headerIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accentColor)
                Text(headerTitle)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: onInfoTap) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.blue.opacity(0.8))
                }
            }

            Text(insightText)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(.primary.opacity(0.8))
                .lineSpacing(3)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ESTIMATED CORPUS")
                        .font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
                    Text("₹\(estimatedCorpus)")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(accentColor)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("MONTHLY BUDGET")
                        .font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
                    Text("₹\(monthlyBudget)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
            }
            .padding(12)
            .background(accentColor.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(spacing: 8) {
                InsightRow(icon: "chart.line.uptrend.xyaxis", text: "Inflation Impact: 6% p.a. included", color: .red)
                InsightRow(icon: "calendar.badge.clock",      text: "Supports lifestyle for \(tenure) years", color: .blue)
            }

            HStack {
                Spacer()
                Text("Based on current market cost estimates")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var accentColor: Color {
        switch preference { case "Lavish": return .purple; case "Normal": return .blue; default: return .green }
    }
    private var headerIcon: String {
        switch preference { case "Lavish": return "crown.fill"; case "Normal": return "star.fill"; default: return "leaf.fill" }
    }
    private var headerTitle: String {
        switch preference { case "Lavish": return "That's smart thinking!"; case "Normal": return "Comfortable Planning"; default: return "Secure Foundations" }
    }
    private var insightText: String {
        switch preference {
        case "Lavish": return "Live a grand life with dining at best hotels every 3 days, premium pub visits, and luxury shopping (₹50K+ watches, branded labels). This corpus supports an elite lifestyle for \(tenure) years."
        case "Normal": return "A comfortable life with annual domestic trips, regular dining at good restaurants, and some lavish expenses. Your savings will maintain your standard of living."
        default: return "A simple, budget-conscious life focusing on essentials and local travel. No lavish expenses, but complete peace of mind for \(tenure) years."
        }
    }
    private var estimatedCorpus: String {
        let base: Double = preference == "Lavish" ? 12.0 : preference == "Normal" ? 4.5 : 2.2
        return String(format: "%.1f Cr", base * (Double(tenure) / 25.0))
    }
    private var monthlyBudget: String {
        switch preference { case "Lavish": return "4.0L+"; case "Normal": return "1.5L"; default: return "75K" }
    }
}

// MARK: - Insight Row (unchanged)
struct InsightRow: View {
    let icon: String; let text: String; let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.10), in: Circle())
            Text(text)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary.opacity(0.75))
            Spacer()
        }
    }
}

// MARK: - Lifestyle Expense Sheet + Row (logic unchanged, minor polish)
struct LifestyleExpenseSheet: View {
    let preference: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Assumed Monthly Expenses")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("Detailed breakdown for a \(preference.lowercased()) retirement.")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 2) {
                        ForEach(expenseBreakdown) { item in
                            LifestyleExpenseRow(item: item)
                            if item.id != expenseBreakdown.last?.id { Divider().padding(.leading, 60) }
                        }
                    }
                    .padding(16)
                    .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Total Monthly Budget")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text("₹\(totalAmount)")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(accentColor)
                    }

                    Text("These are estimated monthly expenses in today's value. The actual corpus accounts for 25 years of inflation and returns.")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(20)
            }
            .background(AppTheme.darkBackground)
            .navigationTitle("\(preference) Lifestyle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }

    private var accentColor: Color {
        switch preference { case "Lavish": return .purple; case "Normal": return .blue; default: return .green }
    }
    private var totalAmount: String {
        switch preference { case "Lavish": return "4,50,000"; case "Normal": return "1,50,000"; default: return "75,000" }
    }
    private var expenseBreakdown: [LifestyleExpenseItem] {
        switch preference {
        case "Lavish":
            return [
                .init(name: "Luxury Dining",     amount: "1,50,000", note: "Best hotels every 3 days",       icon: "fork.knife"),
                .init(name: "Travel & Leisure",  amount: "1,00,000", note: "Intl. trips, pubs, golf",        icon: "airplane"),
                .init(name: "Shopping",          amount: "80,000",   note: "Branded labels, ₹50K+ watches",  icon: "bag.fill"),
                .init(name: "Household & Staff", amount: "70,000",   note: "Luxury amenities & services",    icon: "house.fill"),
                .init(name: "Health & Misc",     amount: "50,000",   note: "Premium insurance & personal",   icon: "heart.text.square.fill")
            ]
        case "Normal":
            return [
                .init(name: "Fine Dining",     amount: "40,000", note: "Regular good restaurants",      icon: "fork.knife"),
                .init(name: "Domestic Travel", amount: "30,000", note: "Annual trips, occasional pubs", icon: "airplane"),
                .init(name: "Shopping",        amount: "20,000", note: "Good quality brands",           icon: "bag.fill"),
                .init(name: "Home Utilities",  amount: "15,000", note: "Standard utilities & upkeep",   icon: "house.fill"),
                .init(name: "Health & Misc",   amount: "45,000", note: "Insurance & daily essentials",  icon: "heart.text.square.fill")
            ]
        default:
            return [
                .init(name: "Local Dining",    amount: "15,000", note: "Occasional eating out",         icon: "fork.knife"),
                .init(name: "Budget Travel",   amount: "10,000", note: "Local trips & visits",          icon: "airplane"),
                .init(name: "Shopping",        amount: "10,000", note: "Essential shopping only",       icon: "bag.fill"),
                .init(name: "Home Essentials", amount: "10,000", note: "Standard utilities",            icon: "house.fill"),
                .init(name: "Health & Misc",   amount: "30,000", note: "Essentials & baseline health",  icon: "heart.text.square.fill")
            ]
        }
    }
}

struct LifestyleExpenseItem: Identifiable {
    let id = UUID()
    let name: String; let amount: String; let note: String; let icon: String
}

struct LifestyleExpenseRow: View {
    let item: LifestyleExpenseItem

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.blue.opacity(0.08)).frame(width: 42, height: 42)
                Image(systemName: item.icon).font(.system(size: 16)).foregroundStyle(.blue)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.system(size: 14, weight: .bold, design: .rounded))
                Text(item.note).font(.system(size: 12, design: .rounded)).foregroundStyle(.secondary)
            }
            Spacer()
            Text("₹\(item.amount)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        AppTheme.darkBackground.ignoresSafeArea()
        ScrollView {
            RetirementQuestionnaire(
                input: .constant(InvestmentPlanInputModel.sampleRetirement),
                stepId: "retirement_details",
                profileAge: 35,
                goalAccentColor: .purple
            )
            .padding(.top, 16)
        }
    }
}
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}
