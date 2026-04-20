import SwiftUI

struct NetWorthCard: View {
    let netWorth: Double
    let growthAmount: Double
    let accounts: [Account]
    @State private var isExpanded = true
    @State private var showAddNetWorth = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Total Net Worth").font(.auraCaption()).foregroundColor(.secondary)
                    Text(netWorth.toCurrency())
                        .font(.auraDigital(size: 32))
                        
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                        Text(growthAmount.toCurrency())
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(AppTheme.auraGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.auraGreen.opacity(0.1))
                    .cornerRadius(8)
                }
                Spacer()
                Button(action: { showAddNetWorth = true }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppTheme.auraIndigo)
                }
            }

            if !accounts.isEmpty {
                VStack(spacing: 14) {
                    Divider().background(Color.gray.opacity(0.1))
                    ForEach(accounts) { account in
                        AccountRow(account: account)
                    }
                }
            }
        }
        .auraCardStyle(radius: 34)
        .sheet(isPresented: $showAddNetWorth) {
            AddNetWorthView()
        }
    }
}

struct AccountRow: View {
    let account: Account

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.auraHeader(size: 15))
                    
                Text(account.institution)
                    .font(.auraCaption())
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(account.balance.toCurrency())
                .font(.auraDigital(size: 16))
                .foregroundColor(account.balance >= 0 ? AppTheme.auraGreen : .red)
        }
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
