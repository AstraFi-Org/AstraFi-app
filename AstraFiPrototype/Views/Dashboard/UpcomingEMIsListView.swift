import SwiftUI

struct UpcomingEMIsListView: View {
    @Environment(\.colorScheme) var colorScheme
    let loans: [AstraLoan]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if loans.isEmpty {
                    Text("No loans recorded")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(loans) { loan in
                        NavigationLink(destination: LoanDetailView(loanID: loan.id)) {
                            EnhancedPaymentRow(
                                title: loan.displayName,
                                subtitle: loan.displayLender,
                                amount: String(format: "%.0f", loan.calculatedEMI),
                                iconColor: loan.loanType.displayColor,
                                isDueSoon: isDueSoon(loan: loan)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(AppTheme.auraPadding)
        }
        .navigationTitle("Upcoming EMIs")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.appBackground(for: colorScheme))
    }
    
    private func isDueSoon(loan: AstraLoan) -> Bool {
        let day = Calendar.current.component(.day, from: Date())
        return day >= 25 || day <= 5
    }
}
