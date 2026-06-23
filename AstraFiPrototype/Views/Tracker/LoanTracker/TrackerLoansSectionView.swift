import SwiftUI

struct TrackerLoansSection: View {
    @Environment(AppStateManager.self) var appState

    private var loans: [AstraLoan] { appState.currentProfile?.loans ?? [] }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Loans").font(.auraHeader(size: 22))
                Spacer()
                NavigationLink(destination: LoanTrackerView()) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.auraIndigo)
                }
            }
            .padding(.horizontal, 8)
            VStack(spacing: 12) {
                ForEach(Array(loans.prefix(3))) { loan in
                    NavigationLink(destination: LoanDetailView(loanID: loan.id)) {
                        TrackerLoanCard(loan: loan)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                if loans.isEmpty {
                    Text("No loans recorded")
                        .font(.auraBody(size: 15))
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
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(color.opacity(0.1))
                            .frame(width: 44, height: 44)
                        Image(systemName: loan.loanType.displayIcon)
                            .font(.system(size: 18))
                            .foregroundColor(color)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(loan.displayName).font(.auraHeader(size: 17)).foregroundColor(AppTheme.auraIndigo)
                        Text(loan.displayLender).font(.auraCaption()).foregroundColor(.secondary)
                    }
                }
                Spacer()
//                Image(systemName: "arrow.up.forward.app.fill")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary.opacity(0.5))
            }
            
            HStack(spacing: 12) {
                VStack(spacing: 6) {
                    Text(loan.loanAmount.toCurrency(compact: true)).font(.auraDigital(size: 16))
                    Text("Total").font(.auraCaption(size: 10, weight: .bold))
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)

                VStack(spacing: 6) {
                    Text(loan.estimatedPaidAmount.toCurrency(compact: true)).font(.auraDigital(size: 16))
                    Text("Paid").font(.auraCaption(size: 10, weight: .bold))
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
            }

            VStack(spacing: 8) {
                HStack {
                    Text("\(loan.installmentsPaid)/\(loan.loanTenureMonths) EMIs").font(.auraCaption(size: 11)).foregroundColor(.secondary)
                    Spacer()
                    Text("\((progress * 100).safeInt)%").font(.auraCaption(size: 11, weight: .bold)).foregroundColor(AppTheme.auraIndigo)
                }
                
                ProgressView(value: min(max(progress.safeFinite, 0), 1))
                    .progressViewStyle(.linear)
                    .tint(color)
            }
        }
        .auraCardStyle(radius: 28)
    }
}

#Preview {
    NavigationStack {
        TrackerLoansSection()
            .environment(AppStateManager.withSampleData())
            .padding()
    }
}
