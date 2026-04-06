import SwiftUI

struct NetWorthCard: View {
    let netWorth: Double
    let growthAmount: Double
    let accounts: [Account]
    @State private var isExpanded = true
    @State private var showAddNetWorth = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Net Worth")
                        .font(.system(size: 17, weight: .semibold))
                    Text(netWorth.toCurrency())
                        .font(.system(size: 28, weight: .bold))
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 11))
                        Text(growthAmount.toCurrency())
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.green)
                }
                Spacer()
                Button(action: { showAddNetWorth = true }) {
                    Text("Edit")
                        .font(.system(size: 15))
                        .foregroundColor(.blue)
                }
            }

            if isExpanded {
                VStack(spacing: 12) {
                    ForEach(accounts) { account in
                        AccountRow(account: account)
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.adaptiveShadow, radius: 8)
        .sheet(isPresented: $showAddNetWorth) {
            AddNetWorthView()
        }
    }
}

struct AccountRow: View {
    let account: Account

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.system(size: 15, weight: .medium))
                Text(account.institution)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(account.balance.toCurrency())
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(account.balance >= 0 ? .primary : .red)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NetWorthCard(
        netWorth: 1250000,
        growthAmount: 45000,
        accounts: [
            Account(name: "Savings Account", institution: "HDFC Bank", balance: 150000),
            Account(name: "Mutual Funds", institution: "Goal Based", balance: 850000),
            Account(name: "Credit Card", institution: "SBI", balance: -25000)
        ]
    )
    .environment(AppStateManager())
    .padding()
}
