import SwiftUI

struct InsuranceDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppStateManager.self) var appState
    let insurance: AstraInsurance

    @State private var showingEdit = false
    @State private var showingDeleteConfirm = false
    @State private var showPolicyDetails = false

    private var activeInsurance: AstraInsurance {
        appState.currentProfile?.insurances.first(where: { $0.id == insurance.id }) ?? insurance
    }

    private var df: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }

    private var analysis: InsuranceAnalysisResult? {
        guard let profile = appState.currentProfile else { return nil }
        return InsuranceAnalysisEngine.analyze(policy: activeInsurance, profile: profile)
    }

    private var policyPeriodText: String {
        let end = activeInsurance.maturityDate ?? activeInsurance.expiryDate
        let startYear = Calendar.current.component(.year, from: activeInsurance.startDate)
        if let end {
            return "\(startYear) → \(Calendar.current.component(.year, from: end))"
        }
        if let years = activeInsurance.policyTermYears {
            return "\(startYear) → \(startYear + years)"
        }
        return "\(df.string(from: activeInsurance.startDate)) → Not provided"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerCard
                if let analysis { insuranceInsightsSection(analysis) }
                if let analysis, !analysis.benefits.isEmpty { coversSection(analysis) }
                if let analysis, !analysis.scenarios.isEmpty { scenariosSection(analysis) }
                if let analysis, analysis.hasProtectionAnalysis { protectionCheckSection(analysis) }
                if let analysis { financialImpactSection(analysis) }
                if let analysis, analysis.policyProgress != nil || analysis.premiumProgress != nil { progressSection(analysis) }
                if let analysis { trackingSection(analysis) }
                if let analysis { actionsSection(analysis) }

                DisclosureGroup(isExpanded: $showPolicyDetails) {
                    VStack(spacing: 24) {
                        premiumSection
                        if let life = activeInsurance.lifeDetails { lifeDetailsSection(life) }
                        if let health = activeInsurance.healthDetails { healthDetailsSection(health) }
                        if let motor = activeInsurance.motorDetails { motorDetailsSection(motor) }
                        datesSection
                    }
                    .padding(.top, 12)
                } label: {
                    Label("Policy Details", systemImage: "doc.text.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .padding(16)
                .background(AppTheme.cardBackground)
                .cornerRadius(16)

                documentsSection
                paymentHistorySection
                if !activeInsurance.riders.isEmpty { ridersSection }
                if !activeInsurance.claims.isEmpty { claimsSection }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 30)
        .background(AppTheme.appBackground(for: colorScheme))
        .navigationTitle(activeInsurance.insuranceType.rawValue + " Insurance")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showingEdit) {
            EditInsuranceView(insurance: activeInsurance)
        }
        .alert("Delete Policy", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive, action: deletePolicy)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this policy? This action cannot be undone.")
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { showingEdit = true } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) { showingDeleteConfirm = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                }
            }
        }
    }

    private func deletePolicy() {
        if var userProfile = appState.currentProfile {
            userProfile.insurances.removeAll { $0.id == insurance.id }
            appState.currentProfile = userProfile
            appState.recalculateFinancials()
            dismiss()
        }
    }

    private func money(_ value: Double?) -> String {
        guard let value, value > 0 else { return "Not provided" }
        return value.toCurrency()
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(activeInsurance.provider)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(activeInsurance.planName?.isEmpty == false ? activeInsurance.planName! : activeInsurance.insuranceType.rawValue + " Insurance")
                        .font(.title2)
                        .fontWeight(.bold)
                    if let planNum = activeInsurance.planNumber, !planNum.isEmpty {
                        Text("Plan \(planNum)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    if let analysis {
                        Text(analysis.purposeLabel)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                statusBadge(activeInsurance.status)
            }

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Basic cover").font(.caption).foregroundColor(.secondary)
                    Text(money(activeInsurance.sumAssured > 0 ? activeInsurance.sumAssured : nil)).font(.title3).fontWeight(.bold).foregroundColor(.primary)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("How often you pay").font(.caption).foregroundColor(.secondary)
                    Text(activeInsurance.premiumFrequency.rawValue).font(.title3).fontWeight(.bold).foregroundColor(.accentColor)
                }
            }

            Divider()

            HStack {
                Label("Policy Number", systemImage: "doc.text.fill").font(.subheadline).foregroundColor(.secondary)
                Spacer()
                Text(activeInsurance.policyNumber.isEmpty ? "Not provided" : activeInsurance.policyNumber).font(.subheadline).fontWeight(.semibold)
            }
        }
        .padding(24)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(activeInsurance.provider) policy overview")
    }

    private func insuranceInsightsSection(_ analysis: InsuranceAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("INSURANCE INSIGHTS").font(.caption.weight(.bold)).foregroundStyle(.white.opacity(0.75))
                    Text(analysis.insuranceHealthScore.map { "\($0) / 100" } ?? "Verification needed")
                        .font(.system(size: 30, weight: .bold)).foregroundStyle(.white)
                    Text(analysis.insuranceHealthStatus.rawValue).font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                Image(systemName: "shield.checkered").font(.system(size: 30)).foregroundStyle(.white.opacity(0.9))
            }
            Text(analysis.summary).font(.subheadline).foregroundStyle(.white.opacity(0.9))

            if !analysis.scoreComponents.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Transparent Components").font(.caption2.weight(.bold)).foregroundStyle(.white.opacity(0.85))
                    ForEach(analysis.scoreComponents, id: \.label) { comp in
                        HStack {
                            Text(comp.label).font(.caption2).foregroundStyle(.white.opacity(0.8))
                            Spacer()
                            Text("\(Int((comp.score * 100).rounded()))% • Weight \(Int((comp.weight * 100).rounded()))%")
                                .font(.caption2.weight(.semibold)).foregroundStyle(.white)
                        }
                    }
                }
                .padding(10)
                .background(Color.white.opacity(0.12))
                .cornerRadius(10)
            }

            Text(analysis.sourceCaption).font(.caption).foregroundStyle(.white.opacity(0.7))
        }
        .padding(20)
        .background(AppTheme.accentGradient)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func coversSection(_ analysis: InsuranceAnalysisResult) -> some View {
        _DetailSection(title: "What This Policy Does", icon: "checkmark.seal.fill") {
            VStack(spacing: 14) {
                _DetailRow(icon: "shield.fill", label: analysis.productKind == .term ? "Family protection" : "Protection", value: money(analysis.currentCoverage > 0 ? analysis.currentCoverage : nil), isBold: true)
                if analysis.productKind == .endowment || analysis.productKind == .moneyBack || analysis.productKind == .ulip || analysis.productKind == .wholeLife {
                    let matBenefit = analysis.benefits.first { $0.title == "Maturity" || $0.title.contains("Fund") }
                    _DetailRow(icon: "banknote.fill", label: "Maturity", value: money(matBenefit?.amount))
                    if matBenefit?.amount == nil {
                        Text(matBenefit?.detail ?? "Maturity value requires bonus or policy-value information from the policy document or latest statement.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                if analysis.productKind == .moneyBack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Milestone Timeline").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                        HStack(spacing: 6) {
                            Text("Start").font(.caption2.weight(.bold)).padding(4).background(Color.secondary.opacity(0.1)).cornerRadius(4)
                            Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.secondary)
                            Text("Survival Milestones").font(.caption2.weight(.bold)).padding(4).background(Color.secondary.opacity(0.1)).cornerRadius(4)
                            Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.secondary)
                            Text("Maturity").font(.caption2.weight(.bold)).padding(4).background(AppTheme.auraGreen.opacity(0.15)).foregroundColor(AppTheme.auraGreen).cornerRadius(4)
                        }
                        Text("Milestone amounts are shown only when documented in your policy.").font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 2)
                }
                if analysis.productKind == .ulip {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Insurance & Investment Separation").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                        HStack {
                            Label("Life Cover: \(analysis.currentCoverage.toCurrency())", systemImage: "shield.fill")
                                .font(.caption.weight(.semibold)).foregroundStyle(AppTheme.vibrantRed)
                            Spacer()
                            Label("Fund: \(money(activeInsurance.expectedMaturityAmount))", systemImage: "chart.line.uptrend.xyaxis")
                                .font(.caption.weight(.semibold)).foregroundStyle(AppTheme.auraIndigo)
                        }
                        Text("Insurance protection and investment fund values are tracked separately and not merged.").font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 2)
                }
                _DetailRow(icon: "calendar", label: "Policy", value: policyPeriodText)
                _DetailRow(icon: "creditcard.fill", label: "Premium you pay", value: "\(analysis.actualPremium.toCurrency()) / \(analysis.premiumFrequency.rawValue.lowercased())")
                Text("Sum assured is the basic insured amount defined by the policy. Calculated values are labelled separately.").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func scenariosSection(_ analysis: InsuranceAnalysisResult) -> some View {
        _DetailSection(title: "When Do You Get the Benefit?", icon: "arrow.triangle.branch") {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(analysis.scenarios) { scenario in
                    HStack(alignment: .top, spacing: 12) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(toneColor(scenario.tone))
                            .frame(width: 4)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(scenario.title).font(.subheadline.weight(.bold))
                            Text(scenario.trigger).font(.caption).foregroundStyle(.secondary)
                            Text("Goes to: \(scenario.recipient)").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                            Text(scenario.benefitDescription).font(.subheadline)
                            Text(scenario.estimatedAmount.map { $0.toCurrency() } ?? "Not provided")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(scenario.estimatedAmount == nil ? Color.secondary : AppTheme.auraGreen)
                        }
                    }
                    if scenario.id != analysis.scenarios.last?.id { Divider() }
                }
            }
        }
    }

    private func protectionCheckSection(_ analysis: InsuranceAnalysisResult) -> some View {
        _DetailSection(title: "Protection Check", icon: "shield.lefthalf.filled") {
            VStack(spacing: 14) {
                _DetailRow(icon: "shield.fill", label: "Current protection", value: analysis.currentCoverage.toCurrency(), isBold: true)
                _DetailRow(icon: "target", label: "Estimated required", value: money(analysis.estimatedRequiredCoverage))
                _DetailRow(icon: "exclamationmark.triangle", label: "Possible family protection shortfall", value: money(analysis.protectionGap), isBold: true)
                HStack {
                    Circle().fill(protectionColor(analysis.protectionStatus)).frame(width: 8, height: 8)
                    Text(analysis.protectionStatus.rawValue).font(.subheadline.weight(.semibold))
                    Spacer()
                }
                if let required = analysis.estimatedRequiredCoverage, required > 0 {
                    ProgressView(value: min(1, analysis.currentCoverage / required))
                        .tint(protectionColor(analysis.protectionStatus))
                }
                Text("This is an estimate using income, dependents, loans, a portion of unmet goals, and liquid savings. It is not an official insurance requirement.").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func progressSection(_ analysis: InsuranceAnalysisResult) -> some View {
        _DetailSection(title: "Policy Progress", icon: "chart.bar.fill") {
            VStack(spacing: 14) {
                if let progress = analysis.policyProgress { progressRow("Policy progress", progress) }
                if let progress = analysis.premiumProgress { progressRow("Premium paying progress", progress) }
                if analysis.premiumProgress == nil {
                    Text("Premium-paying progress is shown only when a premium-paying term is recorded.").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func progressRow(_ label: String, _ progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack { Text(label).font(.subheadline); Spacer(); Text("\(Int((progress * 100).rounded()))%").font(.subheadline.weight(.bold)) }
            ProgressView(value: progress).tint(AppTheme.auraIndigo)
        }
    }

    private func trackingSection(_ analysis: InsuranceAnalysisResult) -> some View {
        _DetailSection(title: "What You Should Track", icon: "checklist") {
            VStack(alignment: .leading, spacing: 10) {
                if let used = analysis.healthCoverageUsed, let remaining = analysis.healthCoverageRemaining {
                    _DetailRow(icon: "cross.case.fill", label: "Coverage used", value: used.toCurrency())
                    _DetailRow(icon: "cross.case", label: "Coverage remaining", value: remaining.toCurrency(), isBold: true)
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 12) {
                    ForEach(analysis.trackingItems, id: \.self) { item in
                        Label(item, systemImage: "checkmark.circle.fill").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func financialImpactSection(_ analysis: InsuranceAnalysisResult) -> some View {
        _DetailSection(title: "Premium & Financial Impact", icon: "chart.line.uptrend.xyaxis") {
            VStack(spacing: 14) {
                _DetailRow(icon: "creditcard.fill", label: "Premium you pay", value: "\(analysis.actualPremium.toCurrency()) every \(analysis.premiumFrequency.rawValue.lowercased())")
                _DetailRow(icon: "calendar", label: "Annualized premium", value: analysis.annualizedPremium.toCurrency(), isBold: true)
                _DetailRow(icon: "indianrupeesign", label: "Monthly equivalent", value: analysis.monthlyPremiumEquivalent.toCurrency())
                if let burden = analysis.premiumBurdenPercentage {
                    _DetailRow(icon: "percent", label: "Impact on your income", value: String(format: "%.1f%%", burden))
                }
                if let surplus = analysis.surplusBurdenPercentage {
                    _DetailRow(icon: "chart.pie", label: "Impact on monthly surplus", value: String(format: "%.0f%%", surplus))
                }
                _DetailRow(icon: "flag", label: "Impact on financial goals", value: goalImpactLabel(analysis), isBold: true)
                if let due = analysis.nextPremiumDue {
                    _DetailRow(icon: "calendar.badge.clock", label: "Next premium", value: "\(df.string(from: due))\(analysis.daysUntilPremiumDue.map { " • \($0)d" } ?? "")")
                }
                if activeInsurance.payments.isEmpty {
                    Text("Payment status not updated. AstraFi does not assume a premium was missed.").font(.caption).foregroundStyle(.secondary)
                }
                if let due = analysis.nextPremiumDue {
                    Menu {
                        Button("Paid") { recordPayment(status: .paid, date: due) }
                        Button("Pending") { recordPayment(status: .pending, date: due) }
                        Button("Skipped") { recordPayment(status: .skipped, date: due) }
                        Button("Unknown") { recordPayment(status: .unknown, date: due) }
                    } label: {
                        Label("Update payment status", systemImage: "checkmark.circle")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.auraIndigo)
                    }
                }
                Text("Monthly equivalent is a comparison figure. It is not the amount you pay each month unless the policy is monthly.").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func goalImpactLabel(_ analysis: InsuranceAnalysisResult) -> String {
        if let surplus = analysis.surplusBurdenPercentage {
            if surplus >= 40 { return "High" }
            if surplus >= 20 { return "Moderate" }
            return "Low"
        }
        return "Not provided"
    }

    private func actionsSection(_ analysis: InsuranceAnalysisResult) -> some View {
        _DetailSection(title: "Action Center", icon: "checklist") {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(analysis.topIssues.prefix(3))) { action in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Circle().fill(priorityColor(action.priority)).frame(width: 8, height: 8)
                            Text(action.title).font(.subheadline.weight(.bold))
                        }
                        Text("Why: \(action.detail)").font(.subheadline).foregroundStyle(.secondary)
                        if !action.impact.isEmpty {
                            Text("Impact: \(action.impact)").font(.subheadline).foregroundStyle(.secondary)
                        }
                        Text("Next step: \(action.nextStep)").font(.caption).foregroundStyle(.secondary)
                    }
                    if action.id != analysis.topIssues.prefix(3).last?.id { Divider() }
                }
            }
        }
    }

    private var paymentHistorySection: some View {
        _DetailSection(title: "Payment History", icon: "list.bullet.rectangle") {
            VStack(spacing: 12) {
                if activeInsurance.payments.isEmpty {
                    Text("No payments have been recorded. Add a status only after checking your payment record.").font(.subheadline).foregroundStyle(.secondary)
                } else {
                    ForEach(activeInsurance.payments.sorted { $0.date > $1.date }) { payment in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(df.string(from: payment.date)).font(.subheadline.weight(.semibold))
                                Text(payment.status.rawValue).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(payment.amount.toCurrency()).font(.subheadline.weight(.bold))
                        }
                        if payment.id != activeInsurance.payments.sorted(by: { $0.date > $1.date }).last?.id { Divider() }
                    }
                }
            }
        }
    }

    private func recordPayment(status: AstraPaymentStatus, date: Date) {
        var updated = activeInsurance
        updated.payments.removeAll { Calendar.current.isDate($0.date, inSameDayAs: date) }
        let amount = InsuranceAnalysisEngine.normalizedPremium(updated).installment
        updated.payments.append(AstraInsurancePayment(date: date, amount: amount, status: status))
        appState.updateInsurance(updated)
    }

    private var documentsSection: some View {
        _DetailSection(title: "Documents & Verification", icon: "folder.fill") {
            VStack(spacing: 14) {
                _DetailRow(icon: "doc.fill", label: "Policy document available", value: activeInsurance.hasPolicyDocument == true ? "Yes" : (activeInsurance.hasPolicyDocument == false ? "No" : "Not provided"))
                _DetailRow(icon: "checkmark.seal", label: "Data source", value: activeInsurance.hasPolicyDocument == true ? InsuranceDataSource.policyDocument.rawValue : (activeInsurance.userConfirmed == true ? InsuranceDataSource.userConfirmed.rawValue : InsuranceDataSource.userEntered.rawValue))
                _DetailRow(icon: "clock", label: "Last updated", value: activeInsurance.lastUpdated.map { df.string(from: $0) } ?? "Not provided")
                if let paidUp = activeInsurance.paidUpValue {
                    _DetailRow(icon: "shield.slash", label: "Paid-up value", value: money(paidUp))
                }
                if let loan = activeInsurance.loanAvailable {
                    _DetailRow(icon: "banknote", label: "Loan against policy", value: loan ? "Available" : "Not available")
                }
                Text("AstraFi does not invent bonus rates, surrender values, or claim outcomes from missing documents.").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var premiumSection: some View {
        _DetailSection(title: "Payment Information", icon: "creditcard.fill") {
            VStack(spacing: 16) {
                _DetailRow(icon: "clock.arrow.2.circlepath", label: "How often you pay", value: activeInsurance.premiumFrequency.rawValue)
                _DetailRow(icon: "indianrupeesign", label: "Base Premium", value: money(activeInsurance.basePremium > 0 ? activeInsurance.basePremium : nil))
                _DetailRow(icon: "percent", label: "Taxes (GST)", value: money(activeInsurance.taxesGST > 0 ? activeInsurance.taxesGST : nil))
                if activeInsurance.addOnCost > 0 {
                    _DetailRow(icon: "plus.circle", label: "Add-on Costs", value: activeInsurance.addOnCost.toCurrency())
                }
                Divider()
                _DetailRow(icon: "banknote.fill", label: "Total yearly (annualized)", value: activeInsurance.annualPremium.toCurrency(), isBold: true)
            }
        }
    }

    private func lifeDetailsSection(_ life: AstraLifeInsuranceDetails) -> some View {
        _DetailSection(title: "Life Coverage", icon: "heart.fill") {
            VStack(spacing: 16) {
                _DetailRow(icon: "person.2.fill", label: "Nominee", value: life.nomineeName?.isEmpty == false ? life.nomineeName! : "Not provided")
                _DetailRow(icon: "tag.fill", label: "Plan type", value: life.lifeInsuranceType ?? "Not provided")
                _DetailRow(icon: "checkmark.seal.fill", label: "Maturity benefit", value: money(life.maturityBenefit))
                _DetailRow(icon: "cross.fill", label: "Death benefit", value: money(life.deathBenefit ?? (activeInsurance.sumAssured > 0 ? activeInsurance.sumAssured : nil)))
                _DetailRow(icon: "arrow.uturn.backward.circle.fill", label: "Amount you may receive if you exit early", value: money(activeInsurance.surrenderValue))
                if activeInsurance.planNumber?.isEmpty == false {
                    _DetailRow(icon: "number", label: "Plan number", value: activeInsurance.planNumber ?? "Not provided")
                }
            }
        }
    }

    private func healthDetailsSection(_ health: AstraHealthInsuranceDetails) -> some View {
        _DetailSection(title: "Health Coverage", icon: "cross.case.fill") {
            VStack(spacing: 16) {
                _DetailRow(icon: "person.fill", label: "Plan Type", value: health.planType ?? "Not provided")
                _DetailRow(icon: "bed.double.fill", label: "Room rent limit", value: money(health.roomRentLimit))
                _DetailRow(icon: "clock.fill", label: "Daycare", value: health.daycareProcedures ? "Included" : "Not provided")
                _DetailRow(icon: "indianrupeesign", label: "Deductible", value: money(health.deductible))
                _DetailRow(icon: "percent", label: "Co-pay", value: health.copayPercent.map { String(format: "%.0f%%", $0) } ?? "Not provided")
                if let waiting = health.waitingPeriodMonths {
                    _DetailRow(icon: "hourglass", label: "Waiting period", value: "\(waiting) months")
                }
                if let prePost = health.prePostHospitalization, !prePost.isEmpty {
                    _DetailRow(icon: "calendar", label: "Pre/Post Hosp.", value: prePost)
                }
                if let count = health.networkHospitalsCount {
                    _DetailRow(icon: "building.2.fill", label: "Network Hospitals", value: "\(count)+")
                }
                if !health.coveredMembers.isEmpty {
                    Divider().padding(.vertical, 4)
                    HStack {
                        Image(systemName: "person.3.fill").foregroundColor(.secondary)
                        Text("Covered Members").font(.caption).fontWeight(.bold).foregroundColor(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(health.coveredMembers) { member in
                        HStack {
                            Text(member.name).font(.subheadline).fontWeight(.medium)
                            Spacer()
                            Text("\(member.age) yrs • \(member.relationship)").font(.caption).foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(6)
                    }
                }
            }
        }
    }

    private func motorDetailsSection(_ motor: AstraMotorInsuranceDetails) -> some View {
        _DetailSection(title: "Motor Coverage", icon: "car.fill") {
            VStack(spacing: 16) {
                _DetailRow(icon: "info.circle.fill", label: "Vehicle Model", value: motor.vehicleModel ?? "Not provided")
                _DetailRow(icon: "shield.righthalf.filled", label: "IDV", value: money(motor.idv))
                _DetailRow(icon: "car.side", label: "Own damage", value: motor.ownDamageCoverage ? "Recorded" : "Not provided")
                _DetailRow(icon: "person.2", label: "Third-party", value: motor.thirdPartyCoverage ? "Recorded" : "Not provided")
                _DetailRow(icon: "arrow.down.square.fill", label: "Zero Dep", value: motor.zeroDep ? "Enabled" : "Not provided")
                _DetailRow(icon: "help.circle.fill", label: "Roadside Asst.", value: motor.roadsideAssistance ? "Enabled" : "Not provided")
            }
        }
    }

    private var ridersSection: some View {
        _DetailSection(title: "Active Riders", icon: "plus.square.fill.on.square.fill") {
            VStack(spacing: 16) {
                ForEach(activeInsurance.riders) { rider in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(rider.name).font(.subheadline).fontWeight(.semibold)
                            Spacer()
                            Text(rider.premium.toCurrency()).font(.subheadline).foregroundColor(.accentColor).fontWeight(.bold)
                        }
                        Text(rider.benefit).font(.caption).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                    if rider.id != activeInsurance.riders.last?.id { Divider() }
                }
            }
        }
    }

    private var claimsSection: some View {
        _DetailSection(title: "Claim History", icon: "list.clipboard.fill") {
            VStack(spacing: 16) {
                ForEach(activeInsurance.claims) { claim in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(claimStatusColor(claim.status).opacity(0.1)).frame(width: 40, height: 40)
                            Image(systemName: claimStatusIcon(claim.status)).foregroundColor(claimStatusColor(claim.status))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(df.string(from: claim.date)).font(.subheadline).fontWeight(.semibold)
                            if let desc = claim.description { Text(desc).font(.caption).foregroundColor(.secondary) }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(claim.amount.toCurrency()).font(.subheadline).fontWeight(.bold)
                            Text(claim.status.rawValue).font(.caption2).fontWeight(.bold).padding(.horizontal, 8).padding(.vertical, 2).background(claimStatusColor(claim.status).opacity(0.15)).foregroundColor(claimStatusColor(claim.status)).cornerRadius(6)
                        }
                    }
                    if claim.id != activeInsurance.claims.last?.id { Divider() }
                }
            }
        }
    }

    private var datesSection: some View {
        _DetailSection(title: "Policy Timeline", icon: "calendar") {
            VStack(spacing: 16) {
                _DetailRow(icon: "calendar.badge.plus", label: "Start Date", value: df.string(from: activeInsurance.startDate))
                if let expiry = activeInsurance.expiryDate {
                    _DetailRow(icon: "calendar.badge.exclamationmark", label: "Expiry Date", value: df.string(from: expiry))
                } else {
                    _DetailRow(icon: "calendar.badge.exclamationmark", label: "Expiry Date", value: "Not provided")
                }
                if let maturity = activeInsurance.maturityDate {
                    _DetailRow(icon: "flag", label: "Maturity date", value: df.string(from: maturity))
                }
                if let term = activeInsurance.policyTermYears {
                    _DetailRow(icon: "hourglass", label: "Policy term", value: "\(term) years")
                }
                if let ppt = activeInsurance.premiumPayingTermYears {
                    _DetailRow(icon: "creditcard", label: "Premium-paying term", value: "\(ppt) years")
                }
            }
        }
    }

    private func statusBadge(_ status: AstraPolicyStatus) -> some View {
        Text(status.rawValue)
            .font(.caption).fontWeight(.bold)
            .foregroundColor(policyStatusColor(status))
            .padding(.horizontal, 14).padding(.vertical, 6)
            .background(policyStatusColor(status).opacity(0.15))
            .cornerRadius(20)
    }

    private func policyStatusColor(_ status: AstraPolicyStatus) -> Color {
        switch status {
        case .active: return .green
        case .lapsed: return .red
        case .gracePeriod: return .orange
        case .matured: return .blue
        }
    }

    private func toneColor(_ tone: InsuranceScenario.Tone) -> Color {
        switch tone {
        case .protection: return AppTheme.vibrantRed
        case .maturity: return AppTheme.auraGreen
        case .caution: return AppTheme.vibrantOrange
        case .information: return .secondary
        }
    }

    private func protectionColor(_ status: InsuranceProtectionStatus) -> Color {
        switch status {
        case .adequate: return AppTheme.auraGreen
        case .review: return AppTheme.vibrantOrange
        case .significantGap: return AppTheme.vibrantRed
        case .notApplicable: return .secondary
        }
    }

    private func priorityColor(_ priority: InsuranceAction.Priority) -> Color {
        switch priority {
        case .critical: return AppTheme.vibrantRed
        case .high: return AppTheme.vibrantOrange
        case .medium: return AppTheme.auraIndigo
        case .low: return AppTheme.auraGreen
        }
    }

    private func claimStatusColor(_ status: AstraClaimStatus) -> Color {
        switch status {
        case .approved: return .green
        case .rejected: return .red
        case .pending: return .blue
        }
    }

    private func claimStatusIcon(_ status: AstraClaimStatus) -> String {
        switch status {
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .pending: return "clock.fill"
        }
    }
}

struct _DetailSection<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(.secondary).font(.caption)
                Text(title.uppercased()).font(.caption).fontWeight(.bold).foregroundColor(.secondary)
            }.padding(.leading, 4)

            VStack { content() }
                .padding(20)
                .background(AppTheme.cardBackground)
                .cornerRadius(16)
                .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 4)
        }
    }
}

struct _DetailRow: View {
    let icon: String
    let label: String
    let value: String
    var isBold: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(.secondary).font(.subheadline).frame(width: 20)
            Text(label).font(.subheadline).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.subheadline).fontWeight(isBold ? .bold : .semibold).foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }
}

#Preview {
    NavigationStack {
        InsuranceDetailView(insurance: AstraInsurance(
            insuranceType: .health,
            provider: "Star Health",
            policyNumber: "POL-12345678",
            sumAssured: 500000,
            annualPremium: 15000,
            startDate: Date(),
            basePremium: 12000,
            taxesGST: 2160,
            premiumFrequency: .yearly,
            healthDetails: AstraHealthInsuranceDetails(
                planType: "Family Floater",
                coveredMembers: [
                    AstraCoveredMember(name: "John Doe", age: 35, relationship: "Self"),
                    AstraCoveredMember(name: "Jane Doe", age: 32, relationship: "Spouse")
                ],
                roomRentLimit: 5000,
                daycareProcedures: true,
                networkHospitalsCount: 500
            ),
            claims: [
                AstraClaim(date: Date(), amount: 15000, status: .approved, description: "Fever Treatment")
            ]
        ))
    }
    .environment(AppStateManager.withSampleData())
}
