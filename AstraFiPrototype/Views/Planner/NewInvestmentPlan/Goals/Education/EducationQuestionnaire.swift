import SwiftUI

// MARK: - Lifestyle Option
enum LifestyleOption: String, CaseIterable, Identifiable {
    case lavish, normal, average
    var id: String { rawValue }

    var label: String {
        switch self {
        case .lavish: return "Lavish"
        case .normal: return "Normal"
        case .average: return "Average"
        }
    }
    var icon: String {
        switch self {
        case .lavish: return "wineglass.fill"
        case .normal: return "house.fill"
        case .average: return "backpack.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .lavish: return .purple
        case .normal: return .blue
        case .average: return .orange
        }
    }
    
    var description: String {
        switch self {
        case .lavish: return "Five star hostel, eating out 3-4 days/wk"
        case .normal: return "Normal hostel, eating out 2-3 days/wk"
        case .average: return "Mess food, low cost transport"
        }
    }
    
    var detailedDescription: String {
        switch self {
        case .lavish: return "Five star hostel + MessFood + eating out 3-4 days in a week, local commute and cabs, 1 international trips, high class social fun and health and other."
        case .normal: return "Normal Hostel + MessFood + eating out 2-3 days in a week, local commute and auto, domestic trips, social fun and health and other."
        case .average: return "MessFood + eating out 1 days in a week, public low cost transport and auto, 1-2 local trips throughout the course, limited social fun and health and other."
        }
    }
}

// MARK: - Education Plan Input Model
@Observable
class EducationPlanInputModel {
    var yearsUntilCourse: String = ""
    var courseAmount: String = ""
    var location: EducationLocation? = nil
    var lifestyle: LifestyleOption? = nil
    var savingPlan: SavingPlanOption? = nil
    var expectedSIPAmount: String = ""
    var courseDurationYears: Int = 2
    
    // Computed monthly living expenses based on location
    var computedMonthlyLiving: Double {
        guard let location = location else { return 0 }
        let base: Double = location == .india ? 25000 : 150000
        var multiplier: Double {
            switch lifestyle {
            case .lavish: return 2.0
            case .normal: return 1.0
            case .average: return 0.6
            case nil: return 1.0
            }
        }
        return base * multiplier
    }
    
    var totalCorpus: Double {
        let amt = Double(courseAmount) ?? 0
        let yrs = Double(Int(yearsUntilCourse) ?? 0)
        let inflatedCourse = amt * pow(1.06, yrs)
        
        let totalLivingCost = computedMonthlyLiving * 12 * Double(courseDurationYears)
        let inflatedLiving = totalLivingCost * pow(1.06, yrs)
        
        return inflatedCourse + inflatedLiving
    }
    
    var projectedMFCorpus: Double {
        let sip = Double(expectedSIPAmount) ?? 0
        let years = Double(Int(yearsUntilCourse) ?? 0)
        let months = years * 12
        let rate = 0.12 / 12
        guard rate > 0 && months > 0 else { return 0 }
        return sip * ((pow(1 + rate, months) - 1) / rate) * (1 + rate)
    }
    
    var projectedStocksCorpus: Double {
        let sip = Double(expectedSIPAmount) ?? 0
        let years = Double(Int(yearsUntilCourse) ?? 0)
        let months = years * 12
        let rate = 0.15 / 12
        guard rate > 0 && months > 0 else { return 0 }
        return sip * ((pow(1 + rate, months) - 1) / rate) * (1 + rate)
    }
    
    func toTrackerModel() -> InvestmentPlanInputModel {
        var model = InvestmentPlanInputModel(
            investmentType: "Monthly SIP",
            amount: savingPlan == .sip ? expectedSIPAmount : "0",
            liquidity: "Medium",
            riskType: "Moderate",
            timePeriod: yearsUntilCourse,
            scheduleInvestmentDate: Date(),
            scheduleSIPDate: Date(),
            purposeOfInvestment: "Education",
            targetAmount: String(format: "%.0f", totalCorpus),
            savedAmount: "0",
            hasEmergencyFund: true,
            investmentMentality: .mutualFunds,
            educationFor: "Self",
            educationDurationYrs: courseDurationYears,
            educationLocation: location == .india ? "India" : "Abroad",
            yearsUntilEducation: Int(yearsUntilCourse)
        )
        model.goalPlanType = savingPlan?.rawValue
        model.goalSIPAmount = expectedSIPAmount
        return model
    }
}
enum EducationLocation {
    case india, abroad
    var label: String { self == .india ? "India" : "Abroad" }
    var icon: String { self == .india ? "map.fill" : "airplane" }
    var color: Color { self == .india ? .green : .blue }
}

// MARK: - Education Questionnaire
struct EducationQuestionnaire: View {
    @Environment(AppStateManager.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var input = EducationPlanInputModel()
    @State private var showLifestyleDetails: Bool = false
    //@StateObject private var input = EducationPlanInputModel()
    let profileAge: Int?
    let goalAccentColor: Color

    var body: some View {
        @Bindable var input = input
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {

                // ── 1. Timeline Card
                SectionCard{
                    VStack(spacing: 16) {
                        SectionHeader2(
                            icon: "calendar.badge.clock",
                            iconColor: goalAccentColor,
                            title: "Course Timeline",
                            subtitle: "When are you planning to pursue this course?"
                        )

                        Divider()

                        HStack {
                            Text("Years from now")
                                .font(.system(size: 15, design: .rounded))
                                .foregroundStyle(.secondary)
                            Spacer()
                            TextField("e.g. 3", text: $input.yearsUntilCourse)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .frame(width: 80)
                        }

//                        if let age = profileAge, let years = Int(input.yearsUntilCourse), years > 0 {
//                            HStack(spacing: 8) {
//                                Image(systemName: "person.crop.circle.fill.badge.checkmark")
//                                    .font(.system(size: 12))
//                                    .foregroundStyle(.blue)
//                                Text("You'll be \(age + years) years old")
//                                    .font(.system(size: 13, weight: .medium, design: .rounded))
//                                    .foregroundStyle(.blue)
//                                Text("· when you start")
//                                    .font(.system(size: 12, design: .rounded))
//                                    .foregroundStyle(.secondary)
//                                Spacer()
//                            }
//                            .padding(.horizontal, 12)
//                            .padding(.vertical, 8)
//                            .background(.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
//                        }

                        if let years = Int(input.yearsUntilCourse), years > 0 {
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundStyle(goalAccentColor)
                                    .font(.system(size: 14))
                                Text("Time to save:")
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundStyle(.secondary)
                                Text("\(years) years")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(goalAccentColor)
                                Spacer()
                            }
                        }
                    }
                }

                // ── 2. Course Amount Card
                SectionCard {
                    VStack(spacing: 16) {
                        SectionHeader2(
                            icon: "indianrupeesign.circle.fill",
                            iconColor: .orange,
                            title: "Course Fees",
                            subtitle: "Total fees needed at the start of the course"
                        )

                        Divider()

                        HStack {
                            Text("Course Amount (₹)")
                                .font(.system(size: 15, design: .rounded))
                                .foregroundStyle(.secondary)
                            Spacer()
                            GoalAmountField(text: $input.courseAmount, placeholder: "e.g. 500000")
                                .frame(width: 120)
                        }

                        if let amt = Double(input.courseAmount), amt > 0 {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.orange)
                                Text("With 6% inflation, you'll need \(inflatedAmount(amt)) at course start")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }

                // ── 3. Location Card
                SectionCard {
                    VStack(alignment: .leading, spacing: 0) {
                        SectionHeader2(
                            icon: "globe.asia.australia.fill",
                            iconColor: .teal,
                            title: "Where are you going?",
                            subtitle: "Location affects living expenses significantly"
                        )
                        .padding(.bottom, 14)

                        Divider()

                        EducationLocationRow(
                            location: .india,
                            isSelected: input.location == .india,
                            description: "Hostels, mess food & local transport"
                        ) { input.location = .india }

                        Divider().padding(.leading, 54)

                        EducationLocationRow(
                            location: .abroad,
                            isSelected: input.location == .abroad,
                            description: "Rent, groceries & international transport"
                        ) { input.location = .abroad }
                    }
                }

                // ── 3.5. Lifestyle Card (shows after location selected)
                if input.location != nil {
                    SectionCard {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                SectionHeader2(
                                    icon: "bed.double.fill",
                                    iconColor: .purple,
                                    title: "Living Lifestyle",
                                    subtitle: "Expected standard of living"
                                )
                                Spacer()
                                Button {
                                    showLifestyleDetails.toggle()
                                } label: {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.purple)
                                }
                                .sheet(isPresented: $showLifestyleDetails) {
                                    LifestyleDetailsSheet()
                                        .presentationDetents([.medium, .large])
                                }
                            }
                            .padding(.bottom, 14)

                            Divider()

                            EducationLifestyleRow(
                                lifestyle: .lavish,
                                isSelected: input.lifestyle == .lavish
                            ) { input.lifestyle = .lavish }

                            Divider().padding(.leading, 54)

                            EducationLifestyleRow(
                                lifestyle: .normal,
                                isSelected: input.lifestyle == .normal
                            ) { input.lifestyle = .normal }

                            Divider().padding(.leading, 54)

                            EducationLifestyleRow(
                                lifestyle: .average,
                                isSelected: input.lifestyle == .average
                            ) { input.lifestyle = .average }
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // ── 4. Course Duration Card (shows after lifestyle selected)
                if input.lifestyle != nil {
                    SectionCard {
                        VStack(spacing: 16) {
                            SectionHeader2(
                                icon: "calendar.badge.clock",
                                iconColor: input.location == .abroad ? .blue : .green,
                                title: "Course Duration",
                                subtitle: "How many years will the course take?"
                            )

                            Divider()

                            PlanSliderStepper(
                                value: Binding(
                                    get: { input.courseDurationYears },
                                    set: { input.courseDurationYears = $0 }
                                ),
                                range: 1...6,
                                unit: "yrs"
                            )
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // ── 5. Insights Card (shows when all filled)
                if showInsights {
                    EducationInsightCard(
                        courseAmount: Double(input.courseAmount) ?? 0,
                        monthlyLiving: input.computedMonthlyLiving,
                        durationYears: input.courseDurationYears,
                        yearsToSave: Int(input.yearsUntilCourse) ?? 1,
                        location: input.location ?? .india,
                        lifestyle: input.lifestyle ?? .normal,
                        accentColor: goalAccentColor
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    
                    // ── 6 & 7. Universal Goal Saving Plan Section
                    GoalSavingPlanSection(
                        savingPlan: $input.savingPlan,
                        expectedSIPAmount: $input.expectedSIPAmount,
                        projectedMFCorpus: input.projectedMFCorpus,
                        projectedStocksCorpus: input.projectedStocksCorpus,
                        totalCorpus: input.totalCorpus,
                        goalAccentColor: goalAccentColor,
                        onSave: {
                            let trackerInput = input.toTrackerModel()
                            let planModel = InvestmentPlanModel(
                                name: "Education Plan",
                                dateSaved: DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none),
                                targetGoal: "Education",
                                input: trackerInput
                            )
                            appState.savePlan(planModel)
                            dismiss()
                        },
                        destination: EducationResultView(input: input.toTrackerModel())
                    )
                }

                Spacer(minLength: 40)
            }
            .padding(.vertical, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture { hideKeyboard() }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: input.location)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: input.lifestyle)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: input.savingPlan)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showInsights)
    }

    private var showInsights: Bool {
        !input.courseAmount.isEmpty &&
        !input.yearsUntilCourse.isEmpty &&
        input.location != nil &&
        input.lifestyle != nil
    }

    private func fmt(_ v: Double) -> String {
        if v >= 10_000_000 { return String(format: "₹%.2f Cr", v / 10_000_000) }
        if v >= 100_000    { return String(format: "₹%.2f L", v / 100_000) }
        return "₹\(Int(v))"
    }

    private func inflatedAmount(_ base: Double) -> String {
        let years = Double(Int(input.yearsUntilCourse) ?? 0)
        let inflated = base * pow(1.06, years)
        if inflated >= 10_000_000 { return String(format: "₹%.1f Cr", inflated / 10_000_000) }
        if inflated >= 100_000    { return String(format: "₹%.1f L", inflated / 100_000) }
        return "₹\(Int(inflated))"
    }
}

// MARK: - Location Row
private struct EducationLocationRow: View {
    let location: EducationLocation
    let isSelected: Bool
    let description: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: location.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(location.color)
                    .frame(width: 40, height: 40)
                    .background(location.color.opacity(0.1),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(location.label)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? location.color : .primary)
                    Text(description)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? location.color : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle().fill(location.color).frame(width: 13, height: 13)
                    }
                }
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Education Lifestyle Row
private struct EducationLifestyleRow: View {
    let lifestyle: LifestyleOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: lifestyle.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(lifestyle.color)
                    .frame(width: 40, height: 40)
                    .background(lifestyle.color.opacity(0.1),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(lifestyle.label)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? lifestyle.color : .primary)
                    Text(lifestyle.description)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? lifestyle.color : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle().fill(lifestyle.color).frame(width: 13, height: 13)
                    }
                }
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Lifestyle Details Sheet
struct LifestyleDetailsSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Lifestyle Details")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("Detailed breakdown of living options.")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    VStack(spacing: 16) {
                        ForEach(LifestyleOption.allCases) { option in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: option.icon)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(option.color)
                                    Text(option.label)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(option.color)
                                }
                                Text(option.detailedDescription)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.elevatedCardBackground)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
                .padding(.top, 24)
            }
            .background(AppTheme.darkBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                        .tint(.purple)
                        .buttonStyle(.borderedProminent)
                        .clipShape(Capsule())
                }
            }
            .navigationTitle("Lifestyles")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Education Insight Card
struct EducationInsightCard: View {
    let courseAmount: Double
    let monthlyLiving: Double
    let durationYears: Int
    let yearsToSave: Int
    let location: EducationLocation
    let lifestyle: LifestyleOption
    let accentColor: Color

    private var totalLivingCost: Double {
        monthlyLiving * 12 * Double(durationYears)
    }

    private var inflatedCourse: Double {
        courseAmount * pow(1.06, Double(yearsToSave))
    }

    private var inflatedLiving: Double {
        totalLivingCost * pow(1.06, Double(yearsToSave))
    }

    private var totalCorpus: Double {
        inflatedCourse + inflatedLiving
    }

    private var requiredMonthlySIP: Double {
        let n = Double(max(1, yearsToSave)) * 12
        let r = 0.12 / 12
        return totalCorpus * (r / (pow(1 + r, n) - 1)) / (1 + r)
    }

    private var requiredMonthlyFD: Double {
        let n = Double(max(1, yearsToSave)) * 12
        let r = 0.065 / 12
        return totalCorpus * (r / (pow(1 + r, n) - 1)) / (1 + r)
    }

    private var isHighCost: Bool { totalCorpus > 5_000_000 }

    @State private var showFactors: Bool = false

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {

                // Header
                HStack {
                    SectionHeader2(
                        icon: "graduationcap.fill",
                        iconColor: accentColor,
                        title: "Education Corpus Plan",
                        subtitle: "Your complete financial target"
                    )
                    
                    Button {
                        showFactors.toggle()
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18))
                            .foregroundStyle(accentColor)
                    }
                    .sheet(isPresented: $showFactors) {
                        EducationExpenseSheet(location: location, lifestyle: lifestyle, accentColor: accentColor)
                            .presentationDetents([.medium, .large])
                    }
                }

                Divider()

                // Breakdown rows
                VStack(spacing: 10) {
                    corpusRow(
                        icon: "book.fill",
                        label: "Course Fees (inflation-adjusted)",
                        value: fmt(inflatedCourse),
                        color: .orange
                    )
                    corpusRow(
                        icon: location == .abroad ? "airplane" : "house.fill",
                        label: "Living Expenses (\(durationYears) yrs, adjusted)",
                        value: fmt(inflatedLiving),
                        color: location == .abroad ? .blue : .green
                    )

                    Divider()

                    // Total
                    HStack {
                        HStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(accentColor.opacity(0.12))
                                    .frame(width: 30, height: 30)
                                Image(systemName: "target")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(accentColor)
                            }
                            Text("Total Corpus Needed")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        Spacer()
                        Text(fmt(totalCorpus))
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(accentColor)
                    }
                    .padding(12)
                    .background(accentColor.opacity(0.07),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                Divider()

                // How to save section
                VStack(alignment: .leading, spacing: 10) {
                    Label("HOW TO BUILD THIS CORPUS", systemImage: "lightbulb.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)

                    savingOptionRow(
                        icon: "chart.line.uptrend.xyaxis",
                        color: .green,
                        title: "Via SIP (12% returns)",
                        value: "₹\(Int(requiredMonthlySIP).formattedWithComma)/month",
                        note: "Equity mutual funds — recommended"
                    )

                    savingOptionRow(
                        icon: "building.columns.fill",
                        color: .orange,
                        title: "Via FD (6.5% returns)",
                        value: "₹\(Int(requiredMonthlyFD).formattedWithComma)/month",
                        note: "Safe but needs more monthly savings"
                    )
                }

                // Location-specific insights
                if location == .abroad {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "globe.europe.africa.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("International Planning")
                                .font(.system(size: 11, weight: .bold))
                            Text("Costs include international travel & higher rent. Consider forex-hedged plans to avoid currency risk.")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(Color.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "indianrupeesign.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Domestic Planning")
                                .font(.system(size: 11, weight: .bold))
                            Text("Assuming hostel/PG stay and mess food. Indian inflation is assumed at 6-8% for education.")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(Color.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                HStack {
                    Spacer()
                    Text("Assumes 6% inflation · 12% SIP · 6.5% FD returns")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func corpusRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(color.opacity(0.10))
                        .frame(width: 26, height: 26)
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(color)
                }
                Text(label)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
    }

    private func savingOptionRow(icon: String, color: Color, title: String, value: String, note: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.10))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                Text(note)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .padding(10)
        .background(color.opacity(0.05),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func fmt(_ v: Double) -> String {
        if v >= 10_000_000 { return String(format: "₹%.1f Cr", v / 10_000_000) }
        if v >= 100_000    { return String(format: "₹%.1f L", v / 100_000) }
        return "₹\(Int(v))"
    }
}

// MARK: - Expense Sheet Component
struct EducationExpenseSheet: View {
    let location: EducationLocation
    let lifestyle: LifestyleOption
    let accentColor: Color
    @Environment(\.dismiss) var dismiss

    private var multiplier: Double {
        switch lifestyle {
        case .lavish: return 2.0
        case .normal: return 1.0
        case .average: return 0.6
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Header Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Assumed Monthly Expenses")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("Detailed breakdown for a \(lifestyle.label.lowercased()) lifestyle \(location == .india ? "in India" : "abroad").")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    // Breakdown List
                    VStack(spacing: 0) {
                        if location == .india {
                            expenseRow(icon: "fork.knife", color: .orange, title: "Food & Dining", subtitle: "Mess food + eating out", amount: 8000 * multiplier)
                            expenseRow(icon: "bus.fill", color: .blue, title: "Transport", subtitle: "Local commute & auto", amount: 4000 * multiplier)
                            expenseRow(icon: "airplane", color: .indigo, title: "Travel", subtitle: "Domestic trips (annualized)", amount: 5000 * multiplier)
                            expenseRow(icon: "music.note.house.fill", color: .purple, title: "Social & Fun", subtitle: "Parties or movie nights", amount: 3000 * multiplier)
                            expenseRow(icon: "pills.fill", color: .red, title: "Misc & Health", subtitle: "Personal care & supplies", amount: 5000 * multiplier)
                        } else {
                            expenseRow(icon: "house.fill", color: .green, title: "Rent & Utilities", subtitle: "Shared apartment + bills", amount: 80000 * multiplier)
                            expenseRow(icon: "cart.fill", color: .orange, title: "Food & Groceries", subtitle: "Home cooking + occasional dining", amount: 30000 * multiplier)
                            expenseRow(icon: "tram.fill", color: .blue, title: "Transport", subtitle: "Public transport pass", amount: 15000 * multiplier)
                            expenseRow(icon: "airplane", color: .indigo, title: "International Travel", subtitle: "Annual trips (annualized)", amount: 15000 * multiplier)
                            expenseRow(icon: "sparkles", color: .purple, title: "Misc & Social", subtitle: "Student activities & fun", amount: 10000 * multiplier)
                        }
                    }
                    .padding(8)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    .padding(.horizontal)

                    // Total Footer
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Monthly Budget")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.secondary)
                        
                        let totalBase = location == .india ? 25000.0 : 150000.0
                        Text("₹\(Int(totalBase * multiplier).formattedWithComma)")
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundStyle(accentColor)
                    }
                    .padding(.horizontal)
                    
                    Text("These are estimated monthly expenses in today's value. The actual corpus accounts for inflation over the saving period.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 24)
            }
            .background(AppTheme.darkBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                        .buttonStyle(.borderedProminent)
                        .tint(accentColor)
                        .clipShape(Capsule())
                }
            }
            .navigationTitle("\(lifestyle.label) Lifestyle")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func expenseRow(icon: String, color: Color, title: String, subtitle: String, amount: Double) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("₹\(Int(amount).formattedWithComma)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            
            Divider().padding(.leading, 72)
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        AppTheme.darkBackground.ignoresSafeArea()
        EducationQuestionnaire(profileAge: 28, goalAccentColor: .indigo)
            .padding(.top, 16)
    }
}
