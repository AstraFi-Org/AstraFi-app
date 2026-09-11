import SwiftUI
struct InvestmentList: View {
    @Environment(\.colorScheme) var colorScheme
    let investments: [AstraInvestment]  

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(investments.enumerated()), id: \.element.id) { index, investment in
                InvestmentListRow(investment: investment, editAction: {})  

                if index < investments.count - 1 {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.04), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    InvestmentList(investments: [
        AstraInvestment(
            investmentType: .deposits,
            investmentName: "ICICI Bank FD",
            investmentAmount: 56000,
            startDate: Date()
        ),
        AstraInvestment(
            investmentType: .mutualFund,
            subtype: .equityFund,
            investmentName: "Axis Bluechip Mutual Fund",
            investmentAmount: 18900,
            startDate: Date(),
            mode: .sip
        ),
        AstraInvestment(
            investmentType: .goldETF,
            investmentName: "Gold ETF",
            investmentAmount: 10000,
            startDate: Date()
        )
    ])
    .padding()
    .environment(AppStateManager.withSampleData())
}
