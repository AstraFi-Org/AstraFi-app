import SwiftUI

// MARK: - NewInvestmentPlanView
// Step-based questionnaire for Goal-based Planning
//
// Design principles:
//   1. Never re-ask data already in user profile (age, income, EMIs, savings)
//   2. Every question feeds directly into InvestmentPlanInputModel
//   3. Fixed alignment – chips wrap cleanly, no overflow
//   4. Clear visual hierarchy per step

struct NewInvestmentPlanView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppStateManager.self) var appState

    var initialGoal: String

    // ── Navigation ────────────────────────────────────────────────────────────
    @State private var currentStep: Int = 0
    @State private var showResultView = false

    // ── Core (all goals) ─────────────────────────────────────────────────────
    @State private var targetAmount: String = ""
    @State private var timePeriod: Int = 5
    @State private var riskType: RiskLevel = .mid
    @State private var investmentMode: InvestmentMode = .sip
    @State private var monthlySIP: String = ""
    @State private var lumpsumAmount: String = ""
    @State private var selectedMentality: InvestmentMentality = .mutualFunds
    @State private var liquidity: LiquidityLevel = .medium
    @State private var yearlyStepUp: String = "10"

    // ── Retirement ────────────────────────────────────────────────────────────
    @State private var retireAge: Int = 60
    @State private var postRetireYears: Int = 20
    @State private var lifestyle: String = "Same as today"
    @State private var withdrawPref: String = "Fixed Monthly"
    @State private var hasOtherPension: Bool = false
    @State private var pensionAmount: String = ""

    // ── Education ─────────────────────────────────────────────────────────────
    @State private var eduFor: String = "Myself"
    @State private var childCurrentAge: String = ""
    @State private var eduStartAge: String = "18"
    @State private var eduDuration: Int = 4
    @State private var eduLocation: String = "India"
    @State private var eduInstitutionType: String = "Private University"
    @State private var fundStrategy: String = "Partial loan"

    // ── Home Purchase ─────────────────────────────────────────────────────────
    @State private var homeCity: String = "Metro"
    @State private var homeBHK: String = "2 BHK"
    @State private var homePropertyType: String = "Apartment"
    @State private var downpay: String = ""
    @State private var openToLoan: Bool = true
    @State private var homeLoanTenure: Int = 20
    @State private var homeLoanRate: String = "8.5"

    // ── Vehicle ───────────────────────────────────────────────────────────────
    @State private var vehicleType: String = "SUV"
    @State private var vehicleSegment: String = "Mid-range (₹5–15L)"
    @State private var vehicleOpenToLoan: Bool = true
    @State private var vehicleLoanDownPay: String = ""
    @State private var vehicleBuyOnlyIfFunded: Bool = false

    // ── Travel ────────────────────────────────────────────────────────────────
    @State private var tripType: String = "International"
    @State private var tripDestination: String = "Europe / USA"
    @State private var tripTravellers: Int = 2
    @State private var tripDuration: Int = 10
    @State private var flexibleTrip: Bool = true

    // ── Wedding ───────────────────────────────────────────────────────────────
    @State private var wedScale: String = "Medium (100–300 guests)"
    @State private var wedVenueCity: String = "Tier 1"
    @State private var wedSplit: String = "Self-funded"

    // ── Wealth Creation ───────────────────────────────────────────────────────
    @State private var wealthGoal: String = "Financial Freedom"
    @State private var wealthPassiveIncome: String = ""

    // ── Business Fund ─────────────────────────────────────────────────────────
    @State private var businessType: String = "Startup"
    @State private var businessStage: String = "Idea stage"
    @State private var businessMonthlyRunway: String = ""
    @State private var businessOpenToInvestor: Bool = false

    // ── Other ─────────────────────────────────────────────────────────────────
    @State private var otherGoalName: String = ""
    @State private var otherGoalFlexible: Bool = true

    // ─────────────────────────────────────────────────────────────────────────
    enum InvestmentMode: String, CaseIterable {
        case sip = "Monthly SIP"
        case lumpsum = "One-time"
        case hybrid = "SIP + Lumpsum"
    }
    enum LiquidityLevel: String, CaseIterable {
        case high = "High"; case medium = "Medium"; case low = "Low"
    }
    enum RiskLevel: String, CaseIterable {
        case low = "Low"; case mid = "Moderate"; case high = "High"
    }

    // Profile shortcuts
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
            AppTheme.appBackground(for: colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                progressHeader

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        stepContent
                        Spacer(minLength: 130)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
            }

            bottomNav
        }
        .navigationTitle("\(initialGoal) Plan")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showResultView) {
            InvestmentPlanResultView(input: buildInputModel())
        }
        .onAppear {
            if let p = profile {
                let age = p.basicDetails.age
                retireAge = min(65, max(50, age + 25))
                if monthlySIP.isEmpty {
                    let suggested = (p.basicDetails.monthlyIncomeAfterTax * 0.15).rounded(.toNearestOrEven)
                    monthlySIP = String(Int(suggested))
                }
            }
        }
    }

    // MARK: - Progress Header
    private var progressHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Step \(currentStep + 1) of \(totalSteps)")
                    .font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
                Spacer()
                Text(steps[currentStep].title)
                    .font(.caption).foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(goalAccentColor)
                        .frame(width: geo.size.width * progressFraction, height: 4)
                        .animation(.spring(response: 0.4), value: currentStep)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }

    // MARK: - Bottom Nav
    private var bottomNav: some View {
        HStack(spacing: 14) {
            if currentStep > 0 {
                Button {
                    withAnimation(.spring(response: 0.35)) { currentStep -= 1 }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left").font(.subheadline.bold())
                        Text("Back").font(.subheadline).fontWeight(.semibold)
                    }
                    .foregroundColor(.primary)
                    .frame(width: 96)
                    .padding(.vertical, 17)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(14)
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
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(goalAccentColor)
                .cornerRadius(14)
                .shadow(color: goalAccentColor.opacity(0.32), radius: 10, x: 0, y: 5)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 36)
        .padding(.top, 14)
        .background(.ultraThinMaterial)
    }

    // MARK: - Step Content
    @ViewBuilder
    private var stepContent: some View {
        let step = steps[currentStep]

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(step.emoji).font(.title2)
                Text(step.title).font(.title2).fontWeight(.bold)
            }
            Text(step.subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }

        stepFields(for: step.id)
    }

    // MARK: - Step Fields
    @ViewBuilder
    private func stepFields(for stepID: String) -> some View {
        switch stepID {

        // ── SHARED: goal amount + timeline ──────────────────────────────────
        case "target":
            StepFormCard {
                LabeledField(label: "Target Amount", icon: "flag.fill") {
                    TextField("e.g. 50,00,000", text: $targetAmount)
                        .keyboardType(.numberPad)
                        .planInputStyle()
                }
                PlanDivider()
                LabeledField(label: "Time Horizon", icon: "calendar") {
                    PlanSliderStepper(value: $timePeriod, range: 1...40, unit: "yrs")
                }
            }

        // ── SHARED: SIP amount ───────────────────────────────────────────────
        case "investment":
            StepFormCard {
                LabeledField(label: "Investment Mode", icon: "repeat.circle.fill") {
                    PlanSegmentChips(selection: $investmentMode, options: InvestmentMode.allCases)
                }
                PlanDivider()
                if investmentMode == .sip || investmentMode == .hybrid {
                    LabeledField(label: "Monthly SIP Amount (₹)", icon: "indianrupeesign.circle.fill") {
                        TextField("e.g. 10,000", text: $monthlySIP)
                            .keyboardType(.numberPad).planInputStyle()
                    }
                }
                if investmentMode == .lumpsum || investmentMode == .hybrid {
                    if investmentMode == .hybrid { PlanDivider() }
                    LabeledField(label: "Lumpsum Amount (₹)", icon: "banknote.fill") {
                        TextField("e.g. 1,00,000", text: $lumpsumAmount)
                            .keyboardType(.numberPad).planInputStyle()
                    }
                }
                PlanDivider()
                LabeledField(label: "Annual SIP Step-up (%)", icon: "chart.line.uptrend.xyaxis",
                             note: "Increasing SIP yearly dramatically boosts your corpus") {
                    TextField("e.g. 10", text: $yearlyStepUp)
                        .keyboardType(.decimalPad).planInputStyle()
                }
            }

            if profileIncome > 0 {
                ProfileBanner(
                    icon: "person.fill.checkmark",
                    text: "Income: ₹\(fmtL(profileIncome))  ·  EMIs: ₹\(fmtL(profileEMIs))",
                    note: "Auto-filled from your profile – not re-asked"
                )
            }

        // ── SHARED: strategy ─────────────────────────────────────────────────
        case "strategy":
            StepFormCard {
                LabeledField(label: "Risk Appetite", icon: "bolt.ring.closed") {
                    PlanSegmentChips(selection: $riskType, options: RiskLevel.allCases)
                }
                PlanDivider()
                LabeledField(label: "Preferred Asset Class", icon: "chart.pie.fill",
                             note: "Primary growth engine for your money") {
                    VStack(spacing: 8) {
                        ForEach(InvestmentMentality.allCases, id: \.self) { m in
                            PlanAssetRow(mentality: m, isSelected: selectedMentality == m) {
                                selectedMentality = m
                            }
                        }
                    }
                }
                PlanDivider()
                LabeledField(label: "Liquidity Preference", icon: "drop.fill",
                             note: "How quickly might you need these funds?") {
                    PlanSegmentChips(selection: $liquidity, options: LiquidityLevel.allCases)
                }
            }

        // ── RETIREMENT ───────────────────────────────────────────────────────
        case "retirement_timeline":
            StepFormCard {
                if let age = profileAge {
                    ProfileBanner(icon: "person.fill.checkmark",
                                  text: "Current age: \(age) years",
                                  note: "From your profile")
                }
                PlanDivider()
                LabeledField(label: "Target Retirement Age", icon: "clock.fill") {
                    PlanSliderStepper(value: $retireAge, range: 40...75, unit: "yrs")
                }
                PlanDivider()
                LabeledField(label: "Years in Retirement", icon: "sun.max.fill",
                             note: "Used to calculate total corpus needed") {
                    PlanSliderStepper(value: $postRetireYears, range: 10...40, unit: "yrs")
                }
            }

        case "retirement_lifestyle":
            StepFormCard {
                LabeledField(label: "Post-Retirement Lifestyle", icon: "star.fill",
                             note: "Adjusts monthly expense assumption") {
                    PlanStackedChips(
                        selection: $lifestyle,
                        options: ["Minimal (−20%)", "Same as today", "Better (+30%)"]
                    )
                }
                PlanDivider()
                LabeledField(label: "Withdrawal Strategy", icon: "arrow.down.to.line",
                             note: "How you draw from your corpus") {
                    PlanStackedChips(
                        selection: $withdrawPref,
                        options: ["Fixed Monthly", "Flexible / Need-based", "SWP from Corpus"]
                    )
                }
                PlanDivider()
                VStack(alignment: .leading, spacing: 10) {
                    Toggle(isOn: $hasOtherPension) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Pension / EPF expected?")
                                .font(.subheadline).fontWeight(.medium)
                            Text("We'll subtract it from required corpus")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    if hasOtherPension {
                        PlanDivider()
                        LabeledField(label: "Expected Monthly Pension (₹)", icon: "building.columns.fill") {
                            TextField("e.g. 20,000", text: $pensionAmount)
                                .keyboardType(.numberPad).planInputStyle()
                        }
                    }
                }
            }

        // ── EDUCATION ────────────────────────────────────────────────────────
        case "edu_who":
            StepFormCard {
                LabeledField(label: "Planning education for", icon: "person.fill") {
                    PlanSegmentChips(
                        selection: $eduFor,
                        options: ["Myself", "Child", "Sibling / Relative"]
                    )
                }
                if eduFor != "Myself" {
                    PlanDivider()
                    LabeledField(label: "Child's Current Age", icon: "figure.child",
                                 note: "Used to compute your investment window") {
                        TextField("e.g. 5", text: $childCurrentAge)
                            .keyboardType(.numberPad).planInputStyle()
                    }
                    PlanDivider()
                    LabeledField(label: "Age When Education Starts", icon: "graduationcap.fill") {
                        TextField("e.g. 18", text: $eduStartAge)
                            .keyboardType(.numberPad).planInputStyle()
                    }
                }
            }

        case "edu_details":
            StepFormCard {
                LabeledField(label: "Course Duration", icon: "clock.fill") {
                    PlanSliderStepper(value: $eduDuration, range: 1...6, unit: "yrs")
                }
                PlanDivider()
                LabeledField(label: "Country of Study", icon: "globe",
                             note: "Affects total cost estimate") {
                    PlanStackedChips(
                        selection: $eduLocation,
                        options: ["India", "USA", "UK", "Australia", "Canada"]
                    )
                }
                PlanDivider()
                LabeledField(label: "Institution Type", icon: "building.columns.fill") {
                    PlanMenuPicker(selection: $eduInstitutionType,
                             options: ["Government / IIT / NIT",
                                       "Private University",
                                       "Deemed University",
                                       "Ivy League / Top 50"])
                }
                PlanDivider()
                LabeledField(label: "Funding Strategy", icon: "creditcard.fill",
                             note: "Affects how much you need to save vs borrow") {
                    PlanSegmentChips(
                        selection: $fundStrategy,
                        options: ["Self-funded", "Partial loan", "Full loan"]
                    )
                }
            }

        // ── HOME PURCHASE ────────────────────────────────────────────────────
        case "home_details":
            StepFormCard {
                LabeledField(label: "City Tier", icon: "building.2.fill",
                             note: "Determines property price benchmark") {
                    PlanMenuPicker(selection: $homeCity,
                             options: ["Metro (Mumbai/Delhi/Bengaluru)",
                                       "Tier 1 (Pune/Hyd/Chennai)",
                                       "Tier 2 City",
                                       "Tier 3 / Town"])
                }
                PlanDivider()
                LabeledField(label: "BHK Configuration", icon: "bed.double.fill") {
                    PlanSegmentChips(selection: $homeBHK, options: ["1 BHK", "2 BHK", "3 BHK", "4+ BHK"])
                }
                PlanDivider()
                LabeledField(label: "Property Type", icon: "house.and.flag.fill") {
                    PlanStackedChips(selection: $homePropertyType,
                                 options: ["Apartment", "Independent House", "Villa", "Plot"])
                }
            }

        case "home_finance":
            StepFormCard {
                LabeledField(label: "Down Payment You Can Afford (₹)", icon: "indianrupeesign.circle",
                             note: "Typically 10–20% of property value") {
                    TextField("e.g. 5,00,000", text: $downpay)
                        .keyboardType(.numberPad).planInputStyle()
                }
                PlanDivider()
                VStack(alignment: .leading, spacing: 10) {
                    Toggle(isOn: $openToLoan) {
                        Text("Open to Home Loan?")
                            .font(.subheadline).fontWeight(.medium)
                    }
                    if openToLoan {
                        PlanDivider()
                        LabeledField(label: "Preferred Loan Tenure", icon: "calendar") {
                            PlanSliderStepper(value: $homeLoanTenure, range: 5...30, unit: "yrs")
                        }
                        PlanDivider()
                        LabeledField(label: "Expected Interest Rate (%)", icon: "percent",
                                     note: "Current home loan rates: 8.5–9.5%") {
                            TextField("e.g. 8.5", text: $homeLoanRate)
                                .keyboardType(.decimalPad).planInputStyle()
                        }
                    }
                }
            }

            if profileSavings > 0 {
                ProfileBanner(icon: "banknote.fill",
                              text: "Existing investments: ₹\(fmtL(profileSavings))",
                              note: "Counted toward your down payment goal")
            }

        // ── VEHICLE ──────────────────────────────────────────────────────────
        case "vehicle_details":
            StepFormCard {
                LabeledField(label: "Vehicle Type", icon: "car.fill") {
                    PlanStackedChips(selection: $vehicleType,
                                 options: ["Hatchback", "Sedan", "SUV", "Electric", "Luxury", "Bike"])
                }
                PlanDivider()
                LabeledField(label: "Budget Segment", icon: "indianrupeesign.circle",
                             note: "Sets your savings target") {
                    PlanMenuPicker(selection: $vehicleSegment,
                             options: ["Entry (< ₹5L)",
                                       "Mid-range (₹5–15L)",
                                       "Premium (₹15–30L)",
                                       "Luxury (₹30L+)"])
                }
                PlanDivider()
                VStack(alignment: .leading, spacing: 10) {
                    Toggle(isOn: $vehicleOpenToLoan) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Open to Car Loan?").font(.subheadline).fontWeight(.medium)
                            Text("Affects EMI vs SIP strategy").font(.caption).foregroundColor(.secondary)
                        }
                    }
                    if vehicleOpenToLoan {
                        PlanDivider()
                        LabeledField(label: "Down Payment (₹)", icon: "indianrupeesign.circle",
                                     note: "Higher down pay = lower EMI") {
                            TextField("e.g. 1,00,000", text: $vehicleLoanDownPay)
                                .keyboardType(.numberPad).planInputStyle()
                        }
                    }
                }
                PlanDivider()
                Toggle(isOn: $vehicleBuyOnlyIfFunded) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Buy only when fully funded?").font(.subheadline).fontWeight(.medium)
                        Text("No loan – 100% savings first").font(.caption).foregroundColor(.secondary)
                    }
                }
            }

        // ── TRAVEL ───────────────────────────────────────────────────────────
        case "travel_details":
            StepFormCard {
                LabeledField(label: "Trip Type", icon: "globe") {
                    PlanSegmentChips(selection: $tripType, options: ["Domestic", "International"])
                }
                if tripType == "International" {
                    PlanDivider()
                    LabeledField(label: "Destination Region", icon: "map.fill",
                                 note: "Helps estimate total trip cost") {
                        PlanMenuPicker(selection: $tripDestination,
                                 options: ["South-East Asia",
                                           "Europe / USA",
                                           "Middle East",
                                           "Japan / Korea",
                                           "Other"])
                    }
                }
                PlanDivider()
                LabeledField(label: "Number of Travellers", icon: "person.3.fill") {
                    PlanSliderStepper(value: $tripTravellers, range: 1...10, unit: "")
                }
                PlanDivider()
                LabeledField(label: "Trip Duration", icon: "clock.fill") {
                    PlanSliderStepper(value: $tripDuration, range: 3...30, unit: "days")
                }
                PlanDivider()
                Toggle(isOn: $flexibleTrip) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Flexible travel date?").font(.subheadline).fontWeight(.medium)
                        Text("Allows us to suggest optimal booking windows").font(.caption).foregroundColor(.secondary)
                    }
                }
            }

        // ── WEDDING ──────────────────────────────────────────────────────────
        case "wedding_details":
            StepFormCard {
                LabeledField(label: "Wedding Scale", icon: "person.3.fill",
                             note: "Helps estimate total event cost") {
                    PlanMenuPicker(selection: $wedScale,
                             options: ["Intimate (< 100 guests)",
                                       "Medium (100–300 guests)",
                                       "Grand (300–700 guests)",
                                       "Lavish (700+ guests)"])
                }
                PlanDivider()
                LabeledField(label: "Venue City Tier", icon: "building.2.fill") {
                    PlanSegmentChips(selection: $wedVenueCity,
                                 options: ["Tier 1", "Tier 2", "Destination", "Home"])
                }
                PlanDivider()
                LabeledField(label: "Who Funds the Wedding?", icon: "person.2.fill",
                             note: "Affects how much you personally need to save") {
                    PlanSegmentChips(selection: $wedSplit,
                                 options: ["Self-funded", "Family Support", "Mixed"])
                }
            }

        // ── WEALTH CREATION ──────────────────────────────────────────────────
        case "wealth_details":
            StepFormCard {
                LabeledField(label: "Primary Wealth Intent", icon: "sparkles",
                             note: "Shapes portfolio allocation & corpus target") {
                    PlanMenuPicker(selection: $wealthGoal,
                             options: ["General Wealth Building",
                                       "Early Retirement (FIRE)",
                                       "Financial Freedom",
                                       "Passive Income Creation",
                                       "Legacy / Generational Wealth"])
                }
                if wealthGoal == "Passive Income Creation" {
                    PlanDivider()
                    LabeledField(label: "Target Monthly Passive Income (₹)", icon: "arrow.down.circle.fill",
                                 note: "We back-calculate the corpus you need") {
                        TextField("e.g. 50,000", text: $wealthPassiveIncome)
                            .keyboardType(.numberPad).planInputStyle()
                    }
                }
            }
            if profileSavings > 0 {
                ProfileBanner(icon: "banknote.fill",
                              text: "Existing investments: ₹\(fmtL(profileSavings))",
                              note: "Counted as your starting corpus")
            }

        // ── BUSINESS FUND ─────────────────────────────────────────────────────
        case "business_details":
            StepFormCard {
                LabeledField(label: "Business Type", icon: "building.2.fill") {
                    PlanMenuPicker(selection: $businessType,
                             options: ["Startup", "Franchise", "Retail / Shop",
                                       "Manufacturing", "Online Business",
                                       "Professional Practice"])
                }
                PlanDivider()
                LabeledField(label: "Current Stage", icon: "chart.bar.fill",
                             note: "Determines how much capital you need upfront") {
                    PlanStackedChips(selection: $businessStage,
                                 options: ["Idea stage", "MVP / Planning",
                                           "Revenue generating", "Scaling phase"])
                }
                PlanDivider()
                LabeledField(label: "Monthly Operating Budget Needed (₹)", icon: "calendar.badge.clock",
                             note: "Monthly burn you need covered for 6–12 months") {
                    TextField("e.g. 1,00,000", text: $businessMonthlyRunway)
                        .keyboardType(.numberPad).planInputStyle()
                }
                PlanDivider()
                Toggle(isOn: $businessOpenToInvestor) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Open to External Investors / Loans?")
                            .font(.subheadline).fontWeight(.medium)
                        Text("Affects Plan 2 & Plan 3 generation")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            }

        // ── OTHER ────────────────────────────────────────────────────────────
        case "other_details":
            StepFormCard {
                LabeledField(label: "What is your goal?", icon: "pencil",
                             note: "E.g. Emergency fund, Gadget, Medical, etc.") {
                    TextField("Describe your goal", text: $otherGoalName)
                        .planInputStyle()
                }
                PlanDivider()
                Toggle(isOn: $otherGoalFlexible) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Flexible timeline?").font(.subheadline).fontWeight(.medium)
                        Text("Allows us to optimise SIP amount for you")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            }

        default:
            EmptyView()
        }
    }

    // MARK: - Build Input Model
    private func buildInputModel() -> InvestmentPlanInputModel {
        let sipAmount: String
        switch investmentMode {
        case .sip: sipAmount = monthlySIP
        case .lumpsum: sipAmount = "0"
        case .hybrid: sipAmount = monthlySIP
        }

        return InvestmentPlanInputModel(
            investmentType: investmentMode.rawValue,
            amount: sipAmount,
            liquidity: liquidity.rawValue,
            riskType: riskType.rawValue,
            timePeriod: String(timePeriod),
            scheduleInvestmentDate: Date(),
            scheduleSIPDate: Date(),
            purposeOfInvestment: initialGoal,
            targetAmount: targetAmount,
            savedAmount: profileSavings > 0 ? String(format: "%.0f", profileSavings) : "0",
            hasEmergencyFund: true,
            investmentMentality: selectedMentality,
            monthlyIncome: profileIncome,
            existingEMIs: profileEMIs,
            openToLoan: openToLoan || vehicleOpenToLoan,
            preferredLoanTenureYears: homeLoanTenure,
            bankName: nil,
            interestRate: Double(homeLoanRate),
            loanAmount: Double(targetAmount.replacingOccurrences(of: ",", with: "")),
            retirementAge: retireAge,
            yearsPostRetirement: postRetireYears,
            lifestylePreference: lifestyle,
            yearlyStepUpPct: Double(yearlyStepUp) ?? 10,
            withdrawalPreference: withdrawPref,
            educationFor: eduFor,
            educationDurationYrs: eduDuration,
            educationLocation: eduLocation,
            fundingStrategy: fundStrategy,
            downPaymentAffordable: Double(downpay.replacingOccurrences(of: ",", with: "")),
            vehicleBuyLogic: vehicleBuyOnlyIfFunded ? "Funded" : "Loan",
            destinationType: tripType,
            isFlexibleTimeline: flexibleTrip,
            contributionSplit: wedSplit,
            wealthIntent: wealthGoal
        )
    }

    // MARK: - Helpers
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
        if v >= 100_000 { return String(format: "%.1fL", v / 100_000) }
        if v >= 1_000   { return String(format: "%.1fK", v / 1_000) }
        return String(format: "%.0f", v)
    }
}

// MARK: - Step Model
struct GoalStep: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let emoji: String

    static func steps(for goal: String, profile: AstraUserProfile?) -> [GoalStep] {
        let targetStep = GoalStep(id: "target", title: "Your Goal",
                                  subtitle: "Define what you want to achieve", emoji: "🎯")
        let sipStep    = GoalStep(id: "investment", title: "Investment Amount",
                                  subtitle: "How much can you invest monthly?", emoji: "💸")
        let stratStep  = GoalStep(id: "strategy", title: "Strategy",
                                  subtitle: "Risk, asset class & liquidity", emoji: "🧠")

        var goalSteps: [GoalStep] = []
        switch goal {
        case "Retirement":
            goalSteps = [
                GoalStep(id: "retirement_timeline", title: "Timeline",
                         subtitle: "When do you want to retire?", emoji: "📅"),
                GoalStep(id: "retirement_lifestyle", title: "Lifestyle & Withdrawal",
                         subtitle: "How you'll live and draw from your corpus", emoji: "🌴"),
            ]
        case "Education":
            goalSteps = [
                GoalStep(id: "edu_who", title: "For Whom?",
                         subtitle: "Who is this education plan for?", emoji: "👨‍🎓"),
                GoalStep(id: "edu_details", title: "Course Details",
                         subtitle: "Institution, country & duration", emoji: "🏫"),
            ]
        case "Home Purchase":
            goalSteps = [
                GoalStep(id: "home_details", title: "Property",
                         subtitle: "What kind of home are you buying?", emoji: "🏠"),
                GoalStep(id: "home_finance", title: "Financing",
                         subtitle: "Down payment & loan preferences", emoji: "🏦"),
            ]
        case "Vehicle":
            goalSteps = [
                GoalStep(id: "vehicle_details", title: "Vehicle",
                         subtitle: "Type, segment & loan preference", emoji: "🚗"),
            ]
        case "Travel / Trip":
            goalSteps = [
                GoalStep(id: "travel_details", title: "Trip Details",
                         subtitle: "Destination, duration & travellers", emoji: "✈️"),
            ]
        case "Wedding":
            goalSteps = [
                GoalStep(id: "wedding_details", title: "Wedding",
                         subtitle: "Scale, venue & funding split", emoji: "💍"),
            ]
        case "Wealth Creation":
            goalSteps = [
                GoalStep(id: "wealth_details", title: "Wealth Intent",
                         subtitle: "What does wealth mean to you?", emoji: "💰"),
            ]
        case "Business Fund":
            goalSteps = [
                GoalStep(id: "business_details", title: "Business",
                         subtitle: "Type, stage & capital need", emoji: "🏢"),
            ]
        default:
            goalSteps = [
                GoalStep(id: "other_details", title: "Your Goal",
                         subtitle: "Tell us more about what you need", emoji: "🎯"),
            ]
        }

        // Order: Target → Goal-specific → SIP → Strategy
        return [targetStep] + goalSteps + [sipStep, stratStep]
    }
}

// MARK: - Reusable Form Components

private extension View {
    func planInputStyle() -> some View {
        self
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(uiColor: .secondarySystemBackground).opacity(0.7))
            .cornerRadius(12)
    }
}

struct StepFormCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) { content }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardBackground)
            .cornerRadius(20)
            .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 4)
    }
}

struct PlanDivider: View {
    var body: some View { Divider().opacity(0.4) }
}

struct LabeledField<Content: View>: View {
    let label: String
    var icon: String = ""
    var note: String? = nil
    let content: Content

    init(label: String, icon: String = "", note: String? = nil,
         @ViewBuilder content: () -> Content) {
        self.label = label; self.icon = icon; self.note = note
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                if !icon.isEmpty {
                    Image(systemName: icon).font(.caption).foregroundColor(.blue)
                }
                Text(label)
                    .font(.footnote).fontWeight(.semibold).foregroundColor(.secondary)
            }
            content.font(.body)
            if let note {
                Text(note).font(.caption2).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Wrapping chip row – chips never overflow the card
struct PlanSegmentChips<T: Hashable>: View {
    @Binding var selection: T
    let options: [T]

    private func label(for opt: T) -> String {
        if let r = (opt as? any RawRepresentable)?.rawValue as? String { return r }
        return "\(opt)"
    }

    var body: some View {
        PlanFlowLayout(spacing: 8) {
            ForEach(options, id: \.self) { opt in
                Button { selection = opt } label: {
                    Text(label(for: opt))
                        .font(.caption).fontWeight(.semibold)
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .background(selection == opt ? Color.blue : Color(uiColor: .tertiarySystemBackground))
                        .foregroundColor(selection == opt ? .white : .primary)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(selection == opt ? Color.clear : Color.gray.opacity(0.25), lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

/// Vertical stack chips – for lists > 3 items
struct PlanStackedChips: View {
    @Binding var selection: String
    let options: [String]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(options, id: \.self) { opt in
                Button { selection = opt } label: {
                    HStack {
                        Text(opt)
                            .font(.subheadline)
                            .fontWeight(selection == opt ? .semibold : .regular)
                            .foregroundColor(selection == opt ? .white : .primary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        if selection == opt {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white).font(.subheadline)
                        }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 11)
                    .background(selection == opt ? Color.blue : Color(uiColor: .tertiarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selection == opt ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct PlanMenuPicker: View {
    @Binding var selection: String
    let options: [String]

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { opt in Button(opt) { selection = opt } }
        } label: {
            HStack {
                Text(selection).font(.body).foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundColor(.blue)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color(uiColor: .secondarySystemBackground).opacity(0.7))
            .cornerRadius(12)
        }
    }
}

struct PlanSliderStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String

    var body: some View {
        HStack {
            Text(unit.isEmpty ? "\(value)" : "\(value) \(unit)")
                .font(.body).fontWeight(.bold).foregroundColor(.primary)
            Spacer()
            Stepper("", value: $value, in: range).labelsHidden()
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Color(uiColor: .secondarySystemBackground).opacity(0.7))
        .cornerRadius(12)
    }
}

struct PlanAssetRow: View {
    let mentality: InvestmentMentality
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: mentality.icon)
                    .foregroundColor(isSelected ? .white : .blue).frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(mentality.rawValue).font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                    Text("\(Int(mentality.avgGrowthRate))% avg CAGR")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white).font(.subheadline)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(isSelected ? Color.blue : Color(uiColor: .tertiarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
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

/// Wrapping flow layout for chips
struct PlanFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var x: CGFloat = 0; var y: CGFloat = 0; var rowH: CGFloat = 0
        for (i, sv) in subviews.enumerated() {
            let sz = sv.sizeThatFits(.unspecified)
            let needed = i == 0 ? sz.width : sz.width + spacing
            if x + needed > maxWidth && x > 0 {
                y += rowH + spacing; x = 0; rowH = 0
            }
            rowH = max(rowH, sz.height)
            x += x == 0 ? sz.width : sz.width + spacing
        }
        return CGSize(width: maxWidth, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX; var y = bounds.minY; var rowH: CGFloat = 0
        var row: [(LayoutSubview, CGSize)] = []

        func placeRow() {
            var rx = bounds.minX
            for (sv, sz) in row {
                sv.place(at: CGPoint(x: rx, y: y), proposal: ProposedViewSize(sz))
                rx += sz.width + spacing
            }
            y += rowH + spacing; rowH = 0; row = []
        }

        for sv in subviews {
            let sz = sv.sizeThatFits(.unspecified)
            let neededX = row.isEmpty ? sz.width : sz.width + spacing
            if x + neededX > bounds.maxX && !row.isEmpty {
                placeRow(); x = bounds.minX
            }
            row.append((sv, sz))
            rowH = max(rowH, sz.height)
            x += row.count == 1 ? sz.width : sz.width + spacing
        }
        if !row.isEmpty { placeRow() }
    }
}

// MARK: - Backward-compatible components (used by other files in the project)

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
        Toggle(isOn: $isOn) {
            Text(label).font(.subheadline).foregroundColor(.primary)
        }.padding(.vertical, 4)
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

#Preview {
    NavigationStack {
        NewInvestmentPlanView(initialGoal: "Education")
            .environment(AppStateManager.withSampleData())
    }
}
