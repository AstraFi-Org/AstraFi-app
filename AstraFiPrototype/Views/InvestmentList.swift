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
        UserInvestment(name: "ICICI Bank FD", amount: 56000, category: "Debt"),
        UserInvestment(name: "Axis Bluechip Mutual Fund", amount: 18900, category: "Equity"),
        UserInvestment(name: "Gold ETF", amount: 10000, category: "Commodity")
    ] as! [AstraInvestment])
    .padding()
}
