import SwiftUI

// MARK: - Education Plan Input Model
@Observable
class EducationPlanInputModel {
    var yearsUntilCourse: String = ""
    var courseAmount: String = ""
    var location: EducationLocation? = nil
    var courseDurationYears: Int = 2
    
    // Computed monthly living expenses based on location
    var computedMonthlyLiving: Double {
        guard let location = location else { return 0 }
        switch location {
        case .india: return 25000 // Normal lifestyle in India
        case .abroad: return 150000 // Normal lifestyle Abroad (~$1800)
        }
    }
}
enum EducationLocation {
    case india, abroad
    var label: String { self == .india ? "India" : "Abroad" }
    var emoji: String { self == .india ? "🇮🇳" : "✈️" }
    var color: Color { self == .india ? .green : .blue }
}

// MARK: - Education Questionnaire
struct EducationQuestionnaire: View {
    @State private var input = EducationPlanInputModel()
    //@StateObject private var input = EducationPlanInputModel()
    let profileAge: Int?
    let goalAccentColor: Color

    var body: some View {
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

                        if let age = profileAge, let years = Int(input.yearsUntilCourse), years > 0 {
                            HStack(spacing: 8) {
                                Image(systemName: "person.crop.circle.fill.badge.checkmark")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.blue)
                                Text("You'll be \(age + years) years old")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(.blue)
                                Text("· when you start")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }

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
                            TextField("e.g. 500000", text: $input.courseAmount)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
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

                // ── 4. Course Duration Card (shows after location selected)
                if input.location != nil {
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
                        accentColor: goalAccentColor
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer(minLength: 40)
            }
            .padding(.vertical, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture { hideKeyboard() }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: input.location)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showInsights)
    }

    private var showInsights: Bool {
        !input.courseAmount.isEmpty &&
        !input.yearsUntilCourse.isEmpty &&
        input.location != nil
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
                Text(location.emoji)
                    .font(.system(size: 22))
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

// MARK: - Education Insight Card
struct EducationInsightCard: View {
    let courseAmount: Double
    let monthlyLiving: Double
    let durationYears: Int
    let yearsToSave: Int
    let location: EducationLocation
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
                        EducationExpenseSheet(location: location, accentColor: accentColor)
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

                // Footer note
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
}

// MARK: - Expense Sheet Component
struct EducationExpenseSheet: View {
    let location: EducationLocation
    let accentColor: Color
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Header Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Assumed Monthly Expenses")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("Detailed breakdown for a normal lifestyle \(location == .india ? "in India" : "abroad").")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    // Breakdown List
                    VStack(spacing: 0) {
                        if location == .india {
                            expenseRow(icon: "fork.knife", color: .orange, title: "Food & Dining", subtitle: "Mess food + eating out", amount: 8000)
                            expenseRow(icon: "bus.fill", color: .blue, title: "Transport", subtitle: "Local commute & auto", amount: 4000)
                            expenseRow(icon: "airplane", color: .indigo, title: "Travel", subtitle: "2 domestic trips (annualized)", amount: 5000)
                            expenseRow(icon: "music.note.house.fill", color: .purple, title: "Social & Fun", subtitle: "2 parties or movie nights", amount: 3000)
                            expenseRow(icon: "pills.fill", color: .red, title: "Misc & Health", subtitle: "Personal care & supplies", amount: 5000)
                        } else {
                            expenseRow(icon: "house.fill", color: .green, title: "Rent & Utilities", subtitle: "Shared apartment + bills", amount: 80000)
                            expenseRow(icon: "cart.fill", color: .orange, title: "Food & Groceries", subtitle: "Home cooking + occasional dining", amount: 30000)
                            expenseRow(icon: "tram.fill", color: .blue, title: "Transport", subtitle: "Public transport pass", amount: 15000)
                            expenseRow(icon: "airplane", color: .indigo, title: "International Travel", subtitle: "Annual trips (annualized)", amount: 15000)
                            expenseRow(icon: "sparkles", color: .purple, title: "Misc & Social", subtitle: "Student activities & fun", amount: 10000)
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
                        
                        Text("₹\(Int(location == .india ? 25000 : 150000).formattedWithComma)")
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
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                        .buttonStyle(.borderedProminent)
                        .tint(accentColor)
                        .clipShape(Capsule())
                }
            }
            .navigationTitle("Normal Lifestyle")
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


// MARK: - Preview
#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        EducationQuestionnaire(profileAge: 28, goalAccentColor: .indigo)
            .padding(.top, 16)
    }
}
