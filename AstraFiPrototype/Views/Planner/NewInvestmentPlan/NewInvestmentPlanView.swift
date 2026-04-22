import SwiftUI

// MARK: - NewInvestmentPlanView (Redesigned)
// True iOS-native grouped UI, goal-specific questions only, correct financial inputs

struct NewInvestmentPlanView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppStateManager.self) var appState

    var initialGoal: String

    @State private var currentStep: Int = 0
    @State private var showResultView = false

    // Universal
    @State private var targetAmount: String = ""
    @State private var timePeriod: Int = 5
    @State private var riskType: RiskLevel = .mid
    @State private var investmentMode: InvestmentMode = .sip
    @State private var monthlySIP: String = ""
    @State private var lumpsumAmount: String = ""
    @State private var selectedMentality: InvestmentMentality = .mutualFunds
    @State private var liquidity: LiquidityLevel = .medium
    @State private var yearlyStepUp: Int = 10

    // Retirement
    @State private var retireAge: Int = 60
    @State private var postRetireYears: Int = 20
    @State private var lifestyle: String = "Same as today"
    @State private var withdrawPref: String = "Fixed Monthly"
    @State private var hasOtherPension: Bool = false
    @State private var pensionAmount: String = ""
    @State private var monthlyExpenseAtRetirement: String = ""

    // Education
    @State private var eduFor: String = "Child"
    @State private var childCurrentAge: String = ""
    @State private var eduStartAge: Int = 18
    @State private var eduDuration: Int = 4
    @State private var eduLocation: String = "India"
    @State private var eduInstitutionType: String = "Private University"
    @State private var fundStrategy: String = "Partial Loan"

    // Home Purchase
    @State private var homeCity: String = "Metro (Mumbai/Delhi/Bengaluru)"
    @State private var homeBHK: String = "2 BHK"
    @State private var homePropertyType: String = "Apartment"
    @State private var downpay: String = ""
    @State private var openToLoan: Bool = true
    @State private var homeLoanTenure: Int = 20
    @State private var homeLoanRate: String = "8.5"

    // Vehicle
    @State private var vehicleType: String = "SUV"
    @State private var vehicleSegment: String = "Mid-range (5-15L)"
    @State private var vehicleOpenToLoan: Bool = true
    @State private var vehicleLoanDownPay: String = ""
    @State private var vehicleBuyOnlyIfFunded: Bool = false

    // Travel
    @State private var tripType: String = "International"
    @State private var tripDestination: String = "Europe / USA"
    @State private var tripTravellers: Int = 2
    @State private var tripDuration: Int = 10
    @State private var flexibleTrip: Bool = true

    // Wedding
    @State private var wedScale: String = "Medium (100-300 guests)"
    @State private var wedVenueCity: String = "Tier 1 City"
    @State private var wedSplit: String = "Self-funded"

    // Wealth Creation
    @State private var wealthGoal: String = "Financial Freedom"
    @State private var wealthPassiveIncome: String = ""
    @State private var targetCorpus: String = ""

    // Business Fund
    @State private var businessType: String = "Startup"
    @State private var businessStage: String = "Idea stage"
    @State private var businessMonthlyRunway: String = ""
    @State private var businessOpenToInvestor: Bool = false

    // Other
    @State private var otherGoalName: String = ""
    @State private var otherGoalFlexible: Bool = true

    enum InvestmentMode: String, CaseIterable {
        case sip = "Monthly SIP"
        case lumpsum = "Lumpsum"
        case hybrid = "SIP + Lumpsum"
    }
    enum LiquidityLevel: String, CaseIterable {
        case high = "High"; case medium = "Medium"; case low = "Low"
    }
    enum RiskLevel: String, CaseIterable {
        case low = "Conservative"; case mid = "Moderate"; case high = "Aggressive"
    }

    private var profile: AstraUserProfile? { appState.currentProfile }
    private var profileAge: Int? { profile?.basicDetails.age }
    private var profileIncome: Double { profile?.basicDetails.monthlyIncomeAfterTax ?? 0 }
    private var profileEMIs: Double { profile?.loans.reduce(0) { $0 + $1.calculatedEMI } ?? 0 }
    private var profileSavings: Double { profile?.investments.reduce(0) { $0 + $1.investmentAmount } ?? 0 }

    private var steps: [GoalStep] { GoalStep.steps(for: initialGoal, profile: profile) }
    private var totalSteps: Int { steps.count }
    private var progressFraction: Double {
        totalSteps > 1 ? Double(currentStep) / Double(totalSteps - 1) : 1.0
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                stepProgressBar
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        stepHeader
                        stepContent
                        Spacer(minLength: 130)
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 20)
                }
            }
            bottomButtons
        }
        .navigationTitle("\(initialGoal) Plan")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showResultView) {
            InvestmentPlanResultView(input: buildInputModel())
        }
        .onAppear { prefillFromProfile() }
    }

    // MARK: - Progress Bar
    private var stepProgressBar: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Step \(currentStep + 1) of \(totalSteps)")
                    .font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                Spacer()
                Text(steps[currentStep].title)
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)

            HStack(spacing: 4) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Capsule()
                        .fill(i <= currentStep ? goalAccentColor : Color(uiColor: .systemFill))
                        .frame(height: 4)
                        .frame(maxWidth: i == currentStep ? .infinity : 28)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
        .background(.bar)
    }

    private var stepHeader: some View {
        let step = steps[currentStep]
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text(step.emoji).font(.largeTitle)
                Text(step.title).font(.title2).fontWeight(.bold)
            }
            Text(step.subtitle)
                .font(.subheadline).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        stepFields(for: steps[currentStep].id)
    }

    private var bottomButtons: some View {
        HStack(spacing: 12) {
            if currentStep > 0 {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.35)) { currentStep -= 1 }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left").font(.subheadline.bold())
                        Text("Back").font(.subheadline.bold())
                    }
                    .foregroundStyle(.primary)
                    .frame(width: 90, height: 54)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                }
            }
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if currentStep < totalSteps - 1 {
                    withAnimation(.spring(response: 0.35)) { currentStep += 1 }
                } else {
                    showResultView = true
                }
            } label: {
                HStack(spacing: 8) {
                    Text(currentStep < totalSteps - 1 ? "Continue" : "Generate My Plan")
                        .font(.headline).fontWeight(.bold)
                    Image(systemName: currentStep < totalSteps - 1 ? "chevron.right" : "sparkles")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(goalAccentColor, in: RoundedRectangle(cornerRadius: 14))
                .shadow(color: goalAccentColor.opacity(0.3), radius: 10, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
        .padding(.top, 12)
        .background(.bar)
    }

    // MARK: - Step Fields
    @ViewBuilder
    private func stepFields(for stepID: String) -> some View {
        switch stepID {

        case "target":
            NativeFormCard {
                NativeFormRow(label: "Target Amount", icon: "flag.fill", iconColor: goalAccentColor) {
                    TextField("e.g. 50,00,000", text: $targetAmount)
                        .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                }
                Divider().padding(.leading, 44)
                NativeStepperRow(label: "Time Horizon", icon: "calendar", iconColor: goalAccentColor,
                                 value: $timePeriod, range: 1...40, unit: "yrs")
            }
            if !targetAmountHint.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill").font(.caption).foregroundStyle(goalAccentColor)
                    Text(targetAmountHint).font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(goalAccentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }

        case "investment":
            NativeFormCard {
                NativeSegmentedRow(label: "Investment Mode", icon: "arrow.triangle.2.circlepath",
                                   iconColor: goalAccentColor, selection: $investmentMode,
                                   options: InvestmentMode.allCases, optionLabel: { $0.rawValue })
                if investmentMode != .lumpsum {
                    Divider().padding(.leading, 44)
                    NativeFormRow(label: "Monthly SIP (Rs)", icon: "indianrupeesign.circle.fill", iconColor: .green) {
                        TextField("e.g. 10,000", text: $monthlySIP)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                    Divider().padding(.leading, 44)
                    NativeStepperRow(label: "Annual Step-up", icon: "chart.line.uptrend.xyaxis",
                                     iconColor: .green, value: $yearlyStepUp, range: 0...30, unit: "%")
                }
                if investmentMode != .sip {
                    Divider().padding(.leading, 44)
                    NativeFormRow(label: "Lumpsum Amount (Rs)", icon: "banknote.fill", iconColor: .orange) {
                        TextField("e.g. 1,00,000", text: $lumpsumAmount)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                }
            }
            if profileIncome > 0 {
                ProfileDataBanner(
                    lines: [
                        ("person.fill.checkmark", "Income: Rs \(fmtL(profileIncome)) / mo", Color.green),
                        ("creditcard.fill", "EMIs: Rs \(fmtL(profileEMIs)) / mo", profileEMIs > 0 ? Color.orange : Color.secondary)
                    ],
                    note: "Auto-filled from your profile — not re-asked"
                )
            }

        case "strategy":
            NativeFormCard {
                NativeSegmentedRow(label: "Risk Appetite", icon: "bolt.ring.closed",
                                   iconColor: riskColor, selection: $riskType,
                                   options: RiskLevel.allCases, optionLabel: { $0.rawValue })
                Divider().padding(.leading, 44)
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(goalAccentColor, in: RoundedRectangle(cornerRadius: 7))
                        Text("Preferred Asset Class").font(.body)
                    }
                    VStack(spacing: 8) {
                        ForEach(InvestmentMentality.allCases, id: \.self) { m in
                            AssetClassRow(mentality: m, isSelected: selectedMentality == m, accentColor: goalAccentColor) {
                                selectedMentality = m
                            }
                        }
                    }
                }
                .padding(.top, 4)
                Divider().padding(.leading, 44)
                NativeSegmentedRow(label: "Liquidity Need", icon: "drop.fill",
                                   iconColor: .blue, selection: $liquidity,
                                   options: LiquidityLevel.allCases, optionLabel: { $0.rawValue })
            }
            NativeCaptionNote(text: "Risk and asset class determine your portfolio blend and expected CAGR. Liquidity affects which instruments are recommended.")

        case "retirement_timeline":
            if let age = profileAge {
                ProfileDataBanner(lines: [("person.fill.checkmark", "Current age: \(age) years", Color.green)],
                                  note: "From your profile")
            }
            NativeFormCard {
                NativeStepperRow(label: "Target retirement age", icon: "figure.walk",
                                 iconColor: .purple, value: $retireAge, range: 40...75, unit: "yrs")
                Divider().padding(.leading, 44)
                NativeStepperRow(label: "Plan for years in retirement", icon: "sun.max.fill",
                                 iconColor: .orange, value: $postRetireYears, range: 10...40, unit: "yrs")
            }
            if let age = profileAge {
                NativeCaptionNote(text: "Investment window: \(retireAge - age) years. Post-retirement corpus must last \(postRetireYears) years. We apply inflation-adjusted corpus calculation.")
            }

        case "retirement_lifestyle":
            NativeFormCard {
                NativeFormRow(label: "Expected monthly expenses at retirement (Rs)", icon: "cart.fill", iconColor: .purple) {
                    TextField("e.g. 60,000", text: $monthlyExpenseAtRetirement)
                        .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                }
                Divider().padding(.leading, 44)
                NativePickerRow(label: "Withdrawal strategy", icon: "arrow.down.to.line",
                                iconColor: .purple, selection: $withdrawPref,
                                options: ["Fixed Monthly", "Flexible / Need-based", "SWP from Corpus"])
                Divider().padding(.leading, 44)
                NativeToggleRow(label: "Pension / EPF / Gratuity expected?",
                                icon: "building.columns.fill", iconColor: .green, isOn: $hasOtherPension)
                if hasOtherPension {
                    Divider().padding(.leading, 44)
                    NativeFormRow(label: "Expected monthly pension (Rs)", icon: "indianrupeesign.circle.fill", iconColor: .green) {
                        TextField("e.g. 20,000", text: $pensionAmount)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                }
            }
            NativeCaptionNote(text: "Required corpus = Monthly expenses x 12 x post-retirement years, adjusted for 6% inflation. Pension reduces the corpus you must build.")

        case "edu_who":
            NativeFormCard {
                NativePickerRow(label: "Planning education for", icon: "person.fill",
                                iconColor: .blue, selection: $eduFor,
                                options: ["Child", "Sibling / Relative", "Myself"])
                if eduFor != "Myself" {
                    Divider().padding(.leading, 44)
                    NativeFormRow(label: "Child's current age", icon: "figure.child", iconColor: .blue) {
                        TextField("e.g. 5", text: $childCurrentAge)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                    Divider().padding(.leading, 44)
                    NativeStepperRow(label: "Age education starts", icon: "graduationcap.fill",
                                     iconColor: .blue, value: $eduStartAge, range: 15...25, unit: "yrs")
                }
            }
            if eduFor != "Myself", let childAge = Int(childCurrentAge), childAge < eduStartAge {
                NativeCaptionNote(text: "Investment window: \(eduStartAge - childAge) years to build the education corpus. Shorter windows need higher SIP.")
            }

        case "edu_details":
            NativeFormCard {
                NativeStepperRow(label: "Course duration", icon: "clock.fill",
                                 iconColor: .blue, value: $eduDuration, range: 1...6, unit: "yrs")
                Divider().padding(.leading, 44)
                NativePickerRow(label: "Country of study", icon: "globe",
                                iconColor: .blue, selection: $eduLocation,
                                options: ["India", "USA", "UK", "Canada", "Australia"])
                Divider().padding(.leading, 44)
                NativePickerRow(label: "Institution type", icon: "building.columns.fill",
                                iconColor: .blue, selection: $eduInstitutionType,
                                options: ["Government / IIT / NIT", "Private University", "Deemed University", "Ivy League / Top 50"])
                Divider().padding(.leading, 44)
                NativePickerRow(label: "Funding strategy", icon: "creditcard.fill",
                                iconColor: .blue, selection: $fundStrategy,
                                options: ["Self-funded", "Partial Loan", "Full Loan"])
            }
            NativeCaptionNote(text: "Institution type and country set cost benchmarks. Partial/full loan reduces required corpus. Education inflation assumed at 10% p.a.")

        case "home_details":
            NativeFormCard {
                NativePickerRow(label: "City / Location", icon: "map.fill",
                                iconColor: .green, selection: $homeCity,
                                options: ["Metro (Mumbai/Delhi/Bengaluru)", "Tier 1 (Pune/Hyd/Chennai)", "Tier 2 City", "Tier 3 / Town"])
                Divider().padding(.leading, 44)
                NativePickerRow(label: "BHK Configuration", icon: "bed.double.fill",
                                iconColor: .green, selection: $homeBHK,
                                options: ["1 BHK", "2 BHK", "3 BHK", "4+ BHK"])
                Divider().padding(.leading, 44)
                NativePickerRow(label: "Property type", icon: "house.fill",
                                iconColor: .green, selection: $homePropertyType,
                                options: ["Apartment", "Independent House", "Villa", "Plot"])
            }
            NativeCaptionNote(text: "City tier and BHK config determine the benchmark property price. This sets your down payment target and loan amount.")

        case "home_finance":
            NativeFormCard {
                NativeFormRow(label: "Down payment you can arrange (Rs)", icon: "indianrupeesign.circle.fill", iconColor: .green) {
                    TextField("e.g. 10,00,000", text: $downpay)
                        .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                }
                Divider().padding(.leading, 44)
                NativeToggleRow(label: "Taking a Home Loan?", icon: "building.2.fill",
                                iconColor: .green, isOn: $openToLoan)
                if openToLoan {
                    Divider().padding(.leading, 44)
                    NativeStepperRow(label: "Loan tenure", icon: "calendar",
                                     iconColor: .green, value: $homeLoanTenure, range: 5...30, unit: "yrs")
                    Divider().padding(.leading, 44)
                    NativeFormRow(label: "Interest rate (%)", icon: "percent", iconColor: .green) {
                        TextField("e.g. 8.5", text: $homeLoanRate)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                }
            }
            NativeCaptionNote(text: "Down payment target = \(timePeriod) year SIP goal. Typical: 10-20% of property value. Home loan rates currently 8.5-9.5% p.a.")
            if profileSavings > 0 {
                ProfileDataBanner(lines: [("banknote.fill", "Existing investments: Rs \(fmtL(profileSavings))", Color.green)],
                                  note: "Counted toward your down payment corpus")
            }

        case "vehicle_details":
            NativeFormCard {
                NativePickerRow(label: "Vehicle type", icon: "car.fill",
                                iconColor: .orange, selection: $vehicleType,
                                options: ["Hatchback", "Sedan", "SUV", "Electric", "Luxury", "Bike / Scooter"])
                Divider().padding(.leading, 44)
                NativePickerRow(label: "Budget segment", icon: "indianrupeesign.circle",
                                iconColor: .orange, selection: $vehicleSegment,
                                options: ["Entry (< Rs 5L)", "Mid-range (Rs 5-15L)", "Premium (Rs 15-30L)", "Luxury (Rs 30L+)"])
                Divider().padding(.leading, 44)
                NativeToggleRow(label: "Planning to take a car loan?", icon: "creditcard.fill",
                                iconColor: .orange, isOn: $vehicleOpenToLoan)
                if vehicleOpenToLoan {
                    Divider().padding(.leading, 44)
                    NativeFormRow(label: "Down payment target (Rs)", icon: "indianrupeesign.circle.fill", iconColor: .orange) {
                        TextField("e.g. 1,00,000", text: $vehicleLoanDownPay)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                }
            }
            NativeCaptionNote(text: "Loan plan: SIP goal = down payment corpus. Car loan EMI is checked against your monthly surplus. Self-fund: SIP goal = full vehicle price.")

        case "travel_details":
            NativeFormCard {
                NativePickerRow(label: "Trip type", icon: "airplane",
                                iconColor: .cyan, selection: $tripType,
                                options: ["Domestic", "International"])
                if tripType == "International" {
                    Divider().padding(.leading, 44)
                    NativePickerRow(label: "Destination region", icon: "globe.asia.australia.fill",
                                    iconColor: .cyan, selection: $tripDestination,
                                    options: ["South-East Asia", "Europe / USA", "Middle East", "Japan / Korea", "Other"])
                }
                Divider().padding(.leading, 44)
                NativeStepperRow(label: "Number of travellers", icon: "person.3.fill",
                                 iconColor: .cyan, value: $tripTravellers, range: 1...10, unit: "")
                Divider().padding(.leading, 44)
                NativeStepperRow(label: "Trip duration", icon: "clock.fill",
                                 iconColor: .cyan, value: $tripDuration, range: 3...30, unit: "days")
                Divider().padding(.leading, 44)
                NativeToggleRow(label: "Flexible on travel date?", icon: "calendar.badge.clock",
                                iconColor: .cyan, isOn: $flexibleTrip)
            }
            NativeCaptionNote(text: "Destination, duration, and travellers determine total cost. Flexibility allows SIP timing optimisation for better rates.")

        case "wedding_details":
            NativeFormCard {
                NativePickerRow(label: "Wedding scale", icon: "person.3.sequence.fill",
                                iconColor: .pink, selection: $wedScale,
                                options: ["Intimate (< 100 guests)", "Medium (100-300 guests)", "Grand (300-700 guests)", "Lavish (700+ guests)"])
                Divider().padding(.leading, 44)
                NativePickerRow(label: "Venue city tier", icon: "building.2.fill",
                                iconColor: .pink, selection: $wedVenueCity,
                                options: ["Tier 1 City", "Tier 2 City", "Destination Wedding", "Home / Farmhouse"])
                Divider().padding(.leading, 44)
                NativePickerRow(label: "Who funds the wedding?", icon: "person.2.fill",
                                iconColor: .pink, selection: $wedSplit,
                                options: ["Self-funded", "Family Contribution", "Mixed (50-50)", "Partially Financed"])
            }
            NativeCaptionNote(text: "Guest count and venue tier set Indian benchmark costs. Your SIP target = your share of total estimated cost.")

        case "wealth_details":
            NativeFormCard {
                NativePickerRow(label: "Primary wealth goal", icon: "crown.fill",
                                iconColor: .indigo, selection: $wealthGoal,
                                options: ["General Wealth Building", "Early Retirement (FIRE)", "Financial Freedom", "Passive Income Creation", "Legacy / Generational Wealth"])
                if wealthGoal == "Passive Income Creation" {
                    Divider().padding(.leading, 44)
                    NativeFormRow(label: "Target monthly passive income (Rs)", icon: "arrow.down.circle.fill", iconColor: .indigo) {
                        TextField("e.g. 50,000", text: $wealthPassiveIncome)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                }
                if wealthGoal == "Early Retirement (FIRE)" || wealthGoal == "Financial Freedom" {
                    Divider().padding(.leading, 44)
                    NativeFormRow(label: "Target corpus (Rs)", icon: "banknote.fill", iconColor: .indigo) {
                        TextField("e.g. 5,00,00,000", text: $targetCorpus)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                }
            }
            if profileSavings > 0 {
                ProfileDataBanner(lines: [("banknote.fill", "Current investments: Rs \(fmtL(profileSavings))", Color.green)],
                                  note: "Counted as your starting corpus for compounding")
            }
            if wealthGoal == "Passive Income Creation" {
                if let income = Double(wealthPassiveIncome.replacingOccurrences(of: ",", with: "")), income > 0 {
                    NativeCaptionNote(text: "At 4% SWP rule, corpus needed = Rs \(fmtL(income * 12 / 0.04)). This is auto-used as your target.")
                } else {
                    NativeCaptionNote(text: "Enter your desired monthly passive income. We back-calculate the corpus using the 4% safe withdrawal rate.")
                }
            } else {
                NativeCaptionNote(text: "FIRE corpus is typically 25x your annual expenses (4% rule). Financial Freedom = enough corpus to sustain lifestyle indefinitely.")
            }

        case "business_details":
            NativeFormCard {
                NativePickerRow(label: "Business type", icon: "briefcase.fill",
                                iconColor: .teal, selection: $businessType,
                                options: ["Startup", "Franchise", "Retail / Shop", "Manufacturing", "Online Business", "Professional Practice"])
                Divider().padding(.leading, 44)
                NativePickerRow(label: "Current stage", icon: "chart.bar.fill",
                                iconColor: .teal, selection: $businessStage,
                                options: ["Idea stage", "MVP / Planning", "Revenue generating", "Scaling phase"])
                Divider().padding(.leading, 44)
                NativeFormRow(label: "Monthly capital needed (Rs)", icon: "calendar.badge.clock", iconColor: .teal) {
                    TextField("e.g. 1,00,000", text: $businessMonthlyRunway)
                        .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                }
                Divider().padding(.leading, 44)
                NativeToggleRow(label: "Open to external investors / loans?",
                                icon: "building.2.fill", iconColor: .teal, isOn: $businessOpenToInvestor)
            }
            NativeCaptionNote(text: "Total corpus = monthly capital x 12-18 months runway. Stage determines burn rate. Investor openness shapes your Plan 2 and Plan 3 structure.")

        case "other_details":
            NativeFormCard {
                NativeFormRow(label: "Describe your goal", icon: "pencil", iconColor: .gray) {
                    TextField("E.g. Medical fund, Gadget...", text: $otherGoalName)
                        .multilineTextAlignment(.trailing)
                }
                Divider().padding(.leading, 44)
                NativeToggleRow(label: "Flexible on timeline?", icon: "calendar.badge.clock",
                                iconColor: .gray, isOn: $otherGoalFlexible)
            }

        default:
            EmptyView()
        }
    }

    // MARK: - Helpers
    private var targetAmountHint: String {
        switch initialGoal {
        case "Retirement":      return "Optional — we calculate corpus from your monthly expenses and lifestyle."
        case "Education":       return "Optional — we estimate from institution type, country, and course duration."
        case "Travel / Trip":   return "Optional — we estimate from destination, duration, and number of travellers."
        default:                return ""
        }
    }

    private var riskColor: Color {
        switch riskType {
        case .low:  return .green
        case .mid:  return .orange
        case .high: return .red
        }
    }

    private var goalAccentColor: Color {
        switch initialGoal {
        case "Retirement":      return .purple
        case "Education":       return .blue
        case "Home Purchase":   return Color(red: 0.13, green: 0.55, blue: 0.26)
        case "Vehicle":         return .orange
        case "Travel / Trip":   return .cyan
        case "Wedding":         return .pink
        case "Wealth Creation": return .indigo
        case "Business Fund":   return .teal
        default:                return .blue
        }
    }

    private func fmtL(_ v: Double) -> String {
        if v >= 10_000_000 { return String(format: "%.1fCr", v / 10_000_000) }
        if v >= 100_000    { return String(format: "%.1fL", v / 100_000) }
        if v >= 1_000      { return String(format: "%.1fK", v / 1_000) }
        return String(format: "%.0f", v)
    }

    private func prefillFromProfile() {
        guard let p = profile else { return }
        let age = p.basicDetails.age
        retireAge = min(65, max(50, age + 25))
        if monthlySIP.isEmpty {
            let surplus = p.basicDetails.monthlyIncomeAfterTax - (p.loans.reduce(0) { $0 + $1.calculatedEMI })
            let suggested = (surplus * 0.20).rounded(.toNearestOrEven)
            monthlySIP = String(Int(max(1000, suggested)))
        }
    }

    private func buildInputModel() -> InvestmentPlanInputModel {
        var resolvedTarget = targetAmount
        if resolvedTarget.isEmpty {
            if wealthGoal == "Passive Income Creation",
               let income = Double(wealthPassiveIncome.replacingOccurrences(of: ",", with: "")), income > 0 {
                resolvedTarget = String(Int(income * 12 / 0.04))
            } else if !targetCorpus.isEmpty {
                resolvedTarget = targetCorpus
            }
        }

        let sipAmt = investmentMode == .lumpsum ? "0" : monthlySIP
        let lumpAmt = investmentMode == .sip ? "0" : lumpsumAmount

        return InvestmentPlanInputModel(
            investmentType: investmentMode.rawValue,
            amount: sipAmt.isEmpty ? lumpAmt : sipAmt,
            liquidity: liquidity.rawValue,
            riskType: riskType.rawValue,
            timePeriod: String(timePeriod),
            scheduleInvestmentDate: Date(),
            scheduleSIPDate: Date(),
            purposeOfInvestment: initialGoal,
            targetAmount: resolvedTarget,
            savedAmount: profileSavings > 0 ? String(format: "%.0f", profileSavings) : "0",
            hasEmergencyFund: true,
            investmentMentality: selectedMentality,
            monthlyIncome: profileIncome,
            existingEMIs: profileEMIs,
            openToLoan: openToLoan || vehicleOpenToLoan,
            preferredLoanTenureYears: openToLoan ? homeLoanTenure : 4,
            bankName: nil,
            interestRate: Double(homeLoanRate) ?? 8.5,
            loanAmount: Double(resolvedTarget.replacingOccurrences(of: ",", with: "")),
            retirementAge: retireAge,
            yearsPostRetirement: postRetireYears,
            lifestylePreference: lifestyle,
            yearlyStepUpPct: Double(yearlyStepUp),
            withdrawalPreference: withdrawPref,
            educationFor: eduFor,
            educationDurationYrs: eduDuration,
            educationLocation: eduLocation,
            fundingStrategy: fundStrategy,
            downPaymentAffordable: Double(downpay.replacingOccurrences(of: ",", with: "")),
            vehicleBuyLogic: vehicleBuyOnlyIfFunded ? "Funded" : (vehicleOpenToLoan ? "Loan" : "Funded"),
            destinationType: tripType,
            isFlexibleTimeline: flexibleTrip || otherGoalFlexible,
            contributionSplit: wedSplit,
            wealthIntent: wealthGoal
        )
    }
}

// MARK: - GoalStep Model
struct GoalStep: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let emoji: String

    static func steps(for goal: String, profile: AstraUserProfile?) -> [GoalStep] {
        let targetStep = GoalStep(id: "target", title: "Your Goal",
                                  subtitle: "Set your target amount and timeline", emoji: "🎯")
        let investStep = GoalStep(id: "investment", title: "Investment",
                                  subtitle: "How much will you invest and how?", emoji: "💸")
        let stratStep  = GoalStep(id: "strategy", title: "Strategy",
                                  subtitle: "Risk, asset class & liquidity preference", emoji: "🧠")

        var goalSpecific: [GoalStep] = []
        switch goal {
        case "Retirement":
            goalSpecific = [
                GoalStep(id: "retirement_timeline", title: "Retirement Age",
                         subtitle: "When do you want to retire?", emoji: "📅"),
                GoalStep(id: "retirement_lifestyle", title: "Lifestyle & Corpus",
                         subtitle: "Monthly expenses, withdrawal & pension", emoji: "🌴")
            ]
        case "Education":
            goalSpecific = [
                GoalStep(id: "edu_who", title: "Who & When",
                         subtitle: "For whom and when does education start?", emoji: "👨‍🎓"),
                GoalStep(id: "edu_details", title: "Course Details",
                         subtitle: "Course type, country & funding approach", emoji: "🏫")
            ]
        case "Home Purchase":
            goalSpecific = [
                GoalStep(id: "home_details", title: "Property",
                         subtitle: "Location, size & type of property", emoji: "🏠"),
                GoalStep(id: "home_finance", title: "Down Payment & Loan",
                         subtitle: "How you plan to finance the purchase", emoji: "🏦")
            ]
        case "Vehicle":
            goalSpecific = [GoalStep(id: "vehicle_details", title: "Vehicle Details",
                                     subtitle: "Type, budget & loan plan", emoji: "🚗")]
        case "Travel / Trip":
            goalSpecific = [GoalStep(id: "travel_details", title: "Trip Details",
                                     subtitle: "Destination, duration & travellers", emoji: "✈️")]
        case "Wedding":
            goalSpecific = [GoalStep(id: "wedding_details", title: "Wedding Details",
                                     subtitle: "Scale, venue city & who contributes", emoji: "💍")]
        case "Wealth Creation":
            goalSpecific = [GoalStep(id: "wealth_details", title: "Wealth Intent",
                                     subtitle: "What does wealth mean to you?", emoji: "💰")]
        case "Business Fund":
            goalSpecific = [GoalStep(id: "business_details", title: "Business Details",
                                     subtitle: "Type, stage & monthly capital requirement", emoji: "🏢")]
        default:
            goalSpecific = [GoalStep(id: "other_details", title: "Goal Details",
                                     subtitle: "Tell us what you are saving for", emoji: "🎯")]
        }
        return [targetStep] + goalSpecific + [investStep, stratStep]
    }
}

// MARK: - Native Form Components

struct NativeFormCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .background(Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 16))
    }
}

struct NativeFormRow<Trailing: View>: View {
    let label: String; let icon: String; let iconColor: Color; let trailing: Trailing
    init(label: String, icon: String, iconColor: Color, @ViewBuilder trailing: () -> Trailing) {
        self.label = label; self.icon = icon; self.iconColor = iconColor; self.trailing = trailing()
    }
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(iconColor, in: RoundedRectangle(cornerRadius: 7))
            Text(label).font(.body).foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            trailing.font(.body).foregroundStyle(.secondary)
                .frame(maxWidth: 150, alignment: .trailing)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}

struct NativeStepperRow: View {
    let label: String; let icon: String; let iconColor: Color
    @Binding var value: Int; let range: ClosedRange<Int>; let unit: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(iconColor, in: RoundedRectangle(cornerRadius: 7))
            Text(label).font(.body).fixedSize(horizontal: false, vertical: true)
            Spacer()
            HStack(spacing: 0) {
                Button {
                    if value > range.lowerBound {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        value -= 1
                    }
                } label: {
                    Image(systemName: "minus").font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.primary).frame(width: 34, height: 34)
                }
                Text(unit.isEmpty ? "\(value)" : "\(value) \(unit)")
                    .font(.subheadline.bold()).foregroundStyle(.primary).frame(minWidth: 60)
                Button {
                    if value < range.upperBound {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        value += 1
                    }
                } label: {
                    Image(systemName: "plus").font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.primary).frame(width: 34, height: 34)
                }
            }
            .background(Color(uiColor: .tertiarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }
}

struct NativePickerRow: View {
    let label: String; let icon: String; let iconColor: Color
    @Binding var selection: String; let options: [String]
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { opt in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selection = opt
                } label: {
                    HStack {
                        Text(opt)
                        if selection == opt { Image(systemName: "checkmark") }
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(iconColor, in: RoundedRectangle(cornerRadius: 7))
                Text(label).font(.body).foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Text(selection).font(.body).foregroundStyle(.secondary)
                    .lineLimit(1).truncationMode(.tail).frame(maxWidth: 130, alignment: .trailing)
                Image(systemName: "chevron.up.chevron.down").font(.caption2.bold())
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
            }
            .padding(.horizontal, 16).padding(.vertical, 12).contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NativeSegmentedRow<T: Hashable>: View {
    let label: String; let icon: String; let iconColor: Color
    @Binding var selection: T; let options: [T]; let optionLabel: (T) -> String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(iconColor, in: RoundedRectangle(cornerRadius: 7))
                Text(label).font(.body)
            }
            PlanFlowLayout(spacing: 8) {
                ForEach(Array(options.enumerated()), id: \.offset) { _, opt in
                    Button { selection = opt } label: {
                        Text(optionLabel(opt)).font(.subheadline).fontWeight(.medium)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(selection == opt ? iconColor : Color(uiColor: .tertiarySystemGroupedBackground), in: Capsule())
                            .foregroundStyle(selection == opt ? .white : .primary)
                            .overlay(Capsule().stroke(selection == opt ? Color.clear : Color(uiColor: .systemFill), lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}

struct NativeToggleRow: View {
    let label: String; let icon: String; let iconColor: Color; @Binding var isOn: Bool
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(iconColor, in: RoundedRectangle(cornerRadius: 7))
            Text(label).font(.body).fixedSize(horizontal: false, vertical: true)
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden().tint(iconColor)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}

struct NativeCaptionNote: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "info.circle").font(.caption2).foregroundStyle(.secondary)
            Text(text).font(.caption2).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
    }
}

struct ProfileDataBanner: View {
    let lines: [(String, String, Color)]; let note: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(lines.indices, id: \.self) { i in
                HStack(spacing: 8) {
                    Image(systemName: lines[i].0).font(.caption).foregroundStyle(lines[i].2)
                    Text(lines[i].1).font(.caption).fontWeight(.semibold).foregroundStyle(.primary)
                }
            }
            Text(note).font(.caption2).foregroundStyle(.secondary)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.2), lineWidth: 1))
    }
}

struct AssetClassRow: View {
    let mentality: InvestmentMentality; let isSelected: Bool
    let accentColor: Color; let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: mentality.icon).font(.system(size: 14))
                    .foregroundStyle(isSelected ? .white : accentColor).frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(mentality.rawValue).font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(isSelected ? .white : .primary)
                    Text("\(Int(mentality.avgGrowthRate))% avg CAGR").font(.caption2)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.white).font(.subheadline)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(isSelected ? accentColor : Color(uiColor: .tertiarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Flow Layout
struct PlanFlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? 0; var x: CGFloat = 0; var y: CGFloat = 0; var rowH: CGFloat = 0
        for (i, sv) in subviews.enumerated() {
            let sz = sv.sizeThatFits(.unspecified)
            let needed = i == 0 ? sz.width : sz.width + spacing
            if x + needed > maxW && x > 0 { y += rowH + spacing; x = 0; rowH = 0 }
            rowH = max(rowH, sz.height); x += x == 0 ? sz.width : sz.width + spacing
        }
        return CGSize(width: maxW, height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX; var y = bounds.minY; var rowH: CGFloat = 0
        var row: [(LayoutSubview, CGSize)] = []
        func flush() {
            var rx = bounds.minX
            for (sv, sz) in row { sv.place(at: CGPoint(x: rx, y: y), proposal: ProposedViewSize(sz)); rx += sz.width + spacing }
            y += rowH + spacing; rowH = 0; row = []
        }
        for sv in subviews {
            let sz = sv.sizeThatFits(.unspecified)
            let needed = row.isEmpty ? sz.width : sz.width + spacing
            if x + needed > bounds.maxX && !row.isEmpty { flush(); x = bounds.minX }
            row.append((sv, sz)); rowH = max(rowH, sz.height)
            x += row.count == 1 ? sz.width : sz.width + spacing
        }
        if !row.isEmpty { flush() }
    }
}

// MARK: - Backward-compatible stubs (used by other files in project)

struct StepFormCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 20) { content }
            .padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardBackground).cornerRadius(20)
            .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 4)
    }
}

struct PlanDivider: View {
    var body: some View { Divider().opacity(0.4) }
}

struct LabeledField<Content: View>: View {
    let label: String; var icon: String = ""; var note: String? = nil; let content: Content
    init(label: String, icon: String = "", note: String? = nil, @ViewBuilder content: () -> Content) {
        self.label = label; self.icon = icon; self.note = note; self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                if !icon.isEmpty { Image(systemName: icon).font(.caption).foregroundColor(.blue) }
                Text(label).font(.footnote).fontWeight(.semibold).foregroundColor(.secondary)
            }
            content.font(.body)
            if let note { Text(note).font(.caption2).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true) }
        }
    }
}

struct FormStepperField: View {
    let label: String; @Binding var value: Int; var range: ClosedRange<Int>
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.footnote).foregroundColor(.secondary).padding(.leading, 4)
            HStack {
                Text("\(value)").font(.body).fontWeight(.bold)
                Spacer()
                Stepper("", value: $value, in: range)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Color(UIColor.secondarySystemBackground).opacity(0.3)).cornerRadius(12)
        }
    }
}

struct FormPickerField<T: Hashable>: View {
    @Environment(\.colorScheme) var colorScheme
    let label: String; @Binding var selection: T; let options: [T]
    var icon: String = "slider.horizontal.3"; var description: String? = nil
    private var labelForOption: (T) -> String {
        { option in (option as? any RawRepresentable)?.rawValue as? String ?? "\(option)" }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.footnote).foregroundColor(.secondary).padding(.leading, 4)
            ZStack {
                HStack {
                    Text(labelForOption(selection)).font(.body).foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundColor(.blue)
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(Color(UIColor.secondarySystemBackground).opacity(colorScheme == .dark ? 0.3 : 1.0))
                .cornerRadius(12)
                Menu {
                    Picker(label, selection: $selection) {
                        ForEach(options, id: \.self) { Text(labelForOption($0)).tag($0) }
                    }
                } label: { Color.white.opacity(0.001) }
            }
            if let desc = description {
                Text(desc).font(.caption2).foregroundStyle(.secondary).padding(.horizontal, 4)
            }
        }
    }
}

struct SectionCard<Content: View>: View {
    let title: String; let icon: String; let content: Content
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title; self.icon = icon; self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundStyle(.blue).font(.subheadline)
                Text(title).font(.subheadline).fontWeight(.bold).foregroundStyle(.primary)
                Spacer()
            }
            VStack(spacing: 16) { content }
        }
        .padding(18).background(AppTheme.cardBackground).cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 5)
    }
}

struct FormTextField: View {
    @Environment(\.colorScheme) var colorScheme
    let label: String; @Binding var value: String
    var keyboardType: UIKeyboardType = .default; var icon: String = "pencil"
    var description: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.footnote).foregroundColor(.secondary).padding(.leading, 4)
            TextField("Enter Value", text: $value).font(.body).keyboardType(keyboardType)
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(Color(UIColor.secondarySystemBackground).opacity(colorScheme == .dark ? 0.3 : 1.0))
                .cornerRadius(12)
            if let d = description { Text(d).font(.caption2).foregroundColor(.secondary).padding(.leading, 4) }
        }
    }
}

struct FormDateField: View {
    @Environment(\.colorScheme) var colorScheme
    let label: String; @Binding var date: Date
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.footnote).foregroundColor(.secondary).padding(.leading, 4)
            HStack {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact).labelsHidden()
                Spacer()
            }
            .padding(.horizontal, 8).padding(.vertical, 8)
            .background(Color(UIColor.secondarySystemBackground).opacity(colorScheme == .dark ? 0.3 : 1.0))
            .cornerRadius(12)
        }
    }
}

struct FormToggleField: View {
    let label: String; @Binding var isOn: Bool
    var body: some View {
        Toggle(isOn: $isOn) { Text(label).font(.subheadline).foregroundColor(.primary) }.padding(.vertical, 4)
    }
}

struct GoalInfoChip: View {
    let icon: String; let text: String
    var body: some View {
        HStack(spacing: 8) {
            Text(icon).font(.title3)
            Text(text).font(.caption).fontWeight(.medium).foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(Color.blue.opacity(0.06)).cornerRadius(10)
    }
}

struct ProfileBanner: View {
    let icon: String; let text: String; let note: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(.green).font(.subheadline)
            VStack(alignment: .leading, spacing: 2) {
                Text(text).font(.caption).fontWeight(.semibold).foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(note).font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green).font(.caption)
        }
        .padding(12)
        .background(Color.green.opacity(0.08))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.2), lineWidth: 1))
    }
}

#Preview {
    NavigationStack {
        NewInvestmentPlanView(initialGoal: "Education")
            .environment(AppStateManager.withSampleData())
    }
}
