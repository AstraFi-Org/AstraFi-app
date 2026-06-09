import SwiftUI
import Foundation

struct TableHeaderCell: View {
    let text: String
    let alignment: Alignment
    var flex: CGFloat = 1

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity * flex, alignment: alignment)
    }
}

func riskText(_ level: AstraRiskLevel) -> String {
    switch level {
    case .low: return "Low"
    case .mid: return "Medium"
    case .high: return "High"
    }
}

func riskColor(_ level: AstraRiskLevel) -> Color {
    switch level {
    case .low: return .green
    case .mid: return .orange
    case .high: return .red
    }
}


struct ScenarioHeaderRow: View {
    var body: some View {
        HStack(spacing: 8) {
            TableHeaderCell(text: "Scenario", alignment: .leading, flex: 1.0)
            TableHeaderCell(text: "Gain/Loss", alignment: .trailing, flex: 1.0)
            TableHeaderCell(text: "Final Value", alignment: .trailing, flex: 1.0)
        }
    }
}

struct ScenarioDataRow: View {
    let scenario: String
    let gainLoss: String
    let finalValue: String
    let isNegative: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(scenario).font(.caption).foregroundColor(.primary).frame(maxWidth: .infinity, alignment: .leading)
            Text(gainLoss).font(.caption).fontWeight(.semibold).foregroundColor(isNegative ? .red : .primary).frame(maxWidth: .infinity, alignment: .trailing)
            Text(finalValue).font(.caption).fontWeight(.medium).foregroundColor(.primary).frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

struct InvestmentTableRow: View {
    let asset: PortfolioAsset
    let invested: String
    let expected: String

    var body: some View {
        HStack(spacing: 4) {
            // Asset Category
            Text(asset.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Allocation
            Text(invested)
                .font(.system(size: 11))
                .foregroundColor(.primary)
                .frame(width: 70, alignment: .trailing)
            
            // Role
            Text(asset.role)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .trailing)
            
            // Risk Tag
            Text(riskText(asset.riskLevel))
                .font(.system(size: 9, weight: .bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(riskColor(asset.riskLevel).opacity(0.1))
                .foregroundColor(riskColor(asset.riskLevel))
                .cornerRadius(4)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
    }
}

struct AllAssetsInfoSheet: View {
    let assets: [PortfolioAsset]
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(assets) { asset in
                        VStack(alignment: .leading, spacing: 20) {
                            // Header
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(asset.name)
                                        .font(.title3)
                                        .fontWeight(.black)
                                    
                                    HStack(spacing: 8) {
                                        Text(riskText(asset.riskLevel) + " Risk")
                                            .font(.system(size: 10, weight: .bold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(riskColor(asset.riskLevel).opacity(0.1))
                                            .foregroundColor(riskColor(asset.riskLevel))
                                            .cornerRadius(6)
                                        
                                        Text(asset.role)
                                            .font(.system(size: 10, weight: .bold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.05))
                                            .foregroundColor(.blue)
                                            .cornerRadius(6)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.bottom, 4)
                            
                            VStack(alignment: .leading, spacing: 20) {
                                infoSection(title: "What is this?", content: asset.description, icon: "questionmark.circle.fill")
                                infoSection(title: "How it works", content: asset.howItWorks, icon: "gearshape.fill")
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(riskColor(asset.riskLevel)).font(.system(size: 14))
                                        Text("Risk Level").font(.subheadline).fontWeight(.bold)
                                    }
                                    Text("\(riskText(asset.riskLevel)): \(riskDescription(asset.riskLevel))")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                infoSection(title: "Why it is included in your plan", content: asset.whyIncluded, icon: "target")
                                
                                // Example Card
                                if !asset.fundExamples.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Examples")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.secondary)
                                            .padding(.bottom, -4)
                                        
                                        ForEach(asset.fundExamples, id: \.self) { fund in
                                            Text(fund)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.primary)
                                                .padding(14)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .background(AppTheme.appBackground(for: colorScheme).opacity(0.5))
                                                .cornerRadius(12)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                                                )
                                        }
                                    }
                                    .padding(16)
                                    .background(Color.blue.opacity(0.03))
                                    .cornerRadius(16)
                                }
                            }
                        }
                        .padding(20)
                        .background(AppTheme.cardBackground)
                        .cornerRadius(20)
                        .shadow(color: AppTheme.adaptiveShadow.opacity(0.5), radius: 8)
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 24)
            }
            .background(AppTheme.appBackground(for: colorScheme))
            .navigationTitle("Investment Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    private func infoSection(title: String, content: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(.blue).font(.system(size: 14))
                Text(title).font(.subheadline).fontWeight(.bold)
            }
            Text(content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func riskDescription(_ level: AstraRiskLevel) -> String {
        switch level {
        case .low: return "Stable with minimal price fluctuations."
        case .mid: return "Balanced growth with moderate market movements."
        case .high: return "Significant growth potential but high volatility."
        }
    }
}

struct RiskOptionCard: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? color.opacity(0.15) : Color.gray.opacity(0.05))
            .foregroundColor(isSelected ? color : .secondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
    }
}
