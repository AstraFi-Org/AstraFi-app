import SwiftUI

struct TrackerLoansSection: View {
    @Environment(AppStateManager.self) var appState

    private var loans: [AstraLoan] { appState.currentProfile?.loans ?? [] }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Your Loans")
                    .font(.system(size: 22, weight: .bold))
                Spacer()
                NavigationLink(destination: LoanTrackerView()) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
            VStack(spacing: 12) {
                ForEach(loans) { loan in
                    NavigationLink(destination: LoanDetailView(loanID: loan.id)) {
                        TrackerLoanCard(loan: loan)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                if loans.isEmpty {
                    Text("No loans recorded")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                        .background(AppTheme.cardBackground)
                        .cornerRadius(12)
                }
            }
        }
    }
}

struct TrackerLoanCard: View {
    let loan: AstraLoan
    @Environment(\.colorScheme) private var colorScheme

    private var color: Color { loan.loanType.displayColor }
    private var progress: Double {
        let p = loan.estimatedPaidAmount / max(loan.loanAmount, 1)
        return p.isFinite ? p : 0
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: loan.loanType.displayIcon)
                            .font(.system(size: 16))
                            .foregroundColor(color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(loan.loanType.rawValue)
                            .font(.system(size: 17, weight: .semibold))
                        Text(loan.lender.rawValue)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text(loan.loanAmount.toCurrency())
                        .font(.system(size: 17, weight: .bold))
                    Text("Total Amt")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(color.opacity(0.08))
                .cornerRadius(8)

                VStack(spacing: 4) {
                    Text(loan.estimatedPaidAmount.toCurrency())
                        .font(.system(size: 17, weight: .bold))
                    Text("Paid Amt")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(color.opacity(0.08))
                .cornerRadius(8)
            }

            HStack {
                Text("\(loan.installmentsPaid) of \(loan.loanTenureMonths) EMIs paid")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(max(0, loan.loanTenureMonths - loan.installmentsPaid)) remaining")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(min(max(0, progress), 1)), height: 5)
                }
            }
            .frame(height: 5)
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: AppTheme.adaptiveShadow, radius: 4, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        TrackerLoansSection()
            .environment(AppStateManager.withSampleData())
            .padding()
    }
}
