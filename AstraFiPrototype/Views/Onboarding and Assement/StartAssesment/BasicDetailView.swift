import SwiftUI

// MARK: - Phase 1: Core Vitals (Name, Age, Income, Expenses only)

struct BasicDetailView: View {
    @Bindable var data: CompleteAssessmentData
    @Environment(AppStateManager.self) var appState
    @Environment(\.dismiss) private var dismiss

    @State private var goNext = false

    // ── Live computed values
    private var income: Double   { Double(data.income) ?? 0 }
    private var expenses: Double { Double(data.expenditure) ?? 0 }
    private var age: Int         { Int(data.age) ?? 0 }

    private var surplus: Double    { max(0, income - expenses) }
    private var savingsRate: Double { income > 0 ? (surplus / income) * 100 : 0 }
    private var expenseRatio: Double { income > 0 ? (expenses / income) * 100 : 0 }

    // Show live insight card as soon as income is entered
    private var showCard: Bool { income > 0 }

    private var canContinue: Bool {
        !data.name.trimmingCharacters(in: .whitespaces).isEmpty
        && income > 0
        && expenses > 0
        && age > 0
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Progress indicator
                    VStack(alignment: .leading, spacing: 12) {
                        AssessmentProgressBar(progress: 0.2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Let's get started")
                                .font(.system(size: 28, weight: .bold))
                            Text("Your basics help us calculate your financial health in real time.")
                                .font(.system(size: 15, design: .rounded))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 24)

                    // ── 4 core fields
                    VStack(spacing: 14) {
                        AssessmentField(
                            icon: "person.fill",
                            label: "Your Name",
                            placeholder: "e.g. Rahul Sharma",
                            text: $data.name,
                            keyboard: .default
                        )
                        AssessmentField(
                            icon: "person.crop.circle",
                            label: "Your Age",
                            placeholder: "e.g. 28",
                            text: $data.age,
                            keyboard: .numberPad
                        )
                        AssessmentField(
                            icon: "indianrupeesign.circle.fill",
                            label: "Monthly Income (₹)",
                            placeholder: "e.g. 75000",
                            text: $data.income,
                            keyboard: .numberPad
                        )
                        AssessmentField(
                            icon: "cart.fill",
                            label: "Monthly Expenses (₹)",
                            placeholder: "e.g. 40000",
                            text: $data.expenditure,
                            keyboard: .numberPad
                        )
                    }
                    .padding(.horizontal, 20)

                    // ── Live insight card (savings rate + expense ratio)
                    if showCard {
                        CoreVitalsCard(
                            income: income,
                            expenses: expenses,
                            surplus: surplus,
                            savingsRate: savingsRate,
                            expenseRatio: expenseRatio
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Spacer().frame(height: 120)
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: showCard)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: savingsRate)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: expenseRatio)

            // ── Footer
            VStack(spacing: 0) {
                if !canContinue {
                    Text(data.name.trimmingCharacters(in: .whitespaces).isEmpty ? "Enter your name to continue" :
                         income == 0 ? "Enter your monthly income to continue" :
                         expenses == 0 ? "Enter your monthly expenses to continue" :
                         "Enter your age to continue")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }
                AssessmentFooterButton(
                    label: "Next",
                    enabled: canContinue,
                    isLast: false,
                    action: { goNext = true }
                )
            }
        }
        .navigationTitle("Financial Assessment")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Skip") {
                    appState.setupEmptyProfile(name: "User")
                    appState.isAssessmentSkipped = true
                    appState.showDashboard = true
                }
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
            }
        }
        .navigationDestination(isPresented: $goNext) {
            Phase1BView(data: data)
        }
        .onAppear {
            if data.name.isEmpty && !appState.tempName.isEmpty {
                data.name = appState.tempName
            }
            data.email    = appState.tempEmail
            data.password = appState.tempPassword
        }
    }
}




#Preview {
    @Previewable @State var data = CompleteAssessmentData()
    let appState = AppStateManager.withSampleData()

    NavigationStack {
        BasicDetailView(data: data)
            .environment(appState)
    }
}
