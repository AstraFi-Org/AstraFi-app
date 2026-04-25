//
//  InvestmentQuestionView.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 24/04/26.
//

//
//  InvestmentQuestionView.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 24/04/26.
//

import SwiftUI

// MARK: - Investment Question Screen
// Reached via: BasicDetailView → No EF → Next
// Also reachable from Phase1BView after EF amount entry

struct InvestmentQuestionView: View {
    @Bindable var data: CompleteAssessmentData
    @Environment(\.dismiss) private var dismiss

    @State private var doesInvest: Bool?    = nil
    @State private var goInvestments        = false   // → InvestmentDetailsScreen
    @State private var goReport             = false   // → ChoiceToReport (skip investments)

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Header
                    VStack(alignment: .leading, spacing: 12) {
                        AssessmentProgressBar(progress: 0.5)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your money at work")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                            Text("Investing is what separates saving from wealth-building.")
                                .font(.system(size: 15, design: .rounded))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 24)

                    // ── Question Card
                    InvestmentQuestionCard(doesInvest: $doesInvest)
                        .padding(.horizontal, 20)

                    // ── Conditional result cards
                    if let invests = doesInvest {
                        if invests {
                            // YES → analyse card with CTA
                            InvestmentAnalyseCard(
                                onAnalyse: { goInvestments = true },
                                onSkip: { goReport = true }
                            )
                                .padding(.horizontal, 20)
                                .padding(.top, 14)
                                .transition(.scale(scale: 0.95).combined(with: .opacity))
                        } else {
                            // NO → necessity card
                            InvestmentNecessityCard()
                                .padding(.horizontal, 20)
                                .padding(.top, 14)
                                .transition(.scale(scale: 0.95).combined(with: .opacity))
                        }
                    }

                    Spacer().frame(height: 120)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: doesInvest)

            // ── Footer: only show for "No" path → leads to report
            if doesInvest == false {
                AssessmentFooterButton(
                    label: "Skip to Report",
                    enabled: true,
                    isLast: false,
                    action: { goReport = true }
                )
            }
        }
        .navigationTitle("Financial Assessment")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").fontWeight(.semibold).foregroundColor(.primary)
                }
            }
        }
        .navigationDestination(isPresented: $goInvestments) {
            InvestmentDetailsScreen(data: data)
        }
        .navigationDestination(isPresented: $goReport) {
            ChoiceToReport(data: data)
        }
    }
}

// MARK: - Preview
#Preview {
    var sample = CompleteAssessmentData()
    sample.income = "80000"
    sample.expenditure = "40000"
    return NavigationStack { InvestmentQuestionView(data: sample) }
}
