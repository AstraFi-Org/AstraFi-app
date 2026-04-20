import SwiftUI

struct LoanRow: View {
    let loan: AstraLoan
    let isSetuConnected: Bool
    @Binding var editingLoan: AstraLoan?

    private var totalProgress: Int {
        max(1, loan.loanTenureMonths)
    }

    private var paidProgress: Int {
        max(0, min(loan.installmentsPaid, loan.loanTenureMonths))
    }

    var body: some View {
        HStack {
            loanDetails
            if !isSetuConnected {
                editButton
            }
        }
        .padding(.vertical, 4)
    }

    private var loanDetails: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(loan.displayName)
                    .font(.headline)
                Spacer()
                Text("₹\(Int(loan.loanAmount))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
            HStack {
                Text(loan.displayLender)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.1f", loan.interestRate) + "% p.a.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            ProgressView(value: Double(paidProgress), total: Double(totalProgress))
                .tint(.red)
            HStack {
                Text("\(loan.installmentsPaid) paid")
                Spacer()
                Text("\(max(0, loan.loanTenureMonths - loan.installmentsPaid)) months left")
            }
            .font(.system(size: 10))
            .foregroundColor(.secondary)
        }
    }

    private var editButton: some View {
        Button { editingLoan = loan } label: {
            Image(systemName: "pencil.circle.fill")
                .font(.title3)
                .foregroundColor(.blue)
        }
        .buttonStyle(.plain)
        .padding(.leading, 8)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var editingLoan: AstraLoan? = nil
        let loan = AstraLoan(
            loanType: .homeLoan,
            lender: .hdfcBank,
            loanAmount: 8500000,
            interestRate: 8.5,
            loanStartDate: Date().addingTimeInterval(-86400 * 30 * 48),
            loanTenureMonths: 240,
            installmentsPaid: 48
        )

        var body: some View {
            List {
                LoanRow(loan: loan, isSetuConnected: false, editingLoan: $editingLoan)
            }
        }
    }
    return PreviewWrapper()
}
