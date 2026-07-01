import SwiftUI

struct TrackerActionRequiredSection: View {
    @Environment(AppStateManager.self) var appState
    var onStartMonthlyAssessment: (() -> Void)? = nil
    
    var activeConcerns: [String] {
        // In a real app, we'd store these in the profile. 
        // For now, we can derive them or get from last assessment
        appState.currentProfile?.monthlyHealthAssessments.last?.keyInsights ?? []
    }

    private var actionItems: [TrackerActionItem] {
        var items: [TrackerActionItem] = []

        if appState.isMonthlyAssessmentDue() {
            items.append(.init(
                icon: "calendar.badge.exclamationmark",
                title: "Update monthly assessment",
                subtitle: "Refresh this month's income, expenses, investments, loans, and insurance.",
                isMonthlyAssessment: true
            ))
        }

        items.append(contentsOf: activeConcerns.prefix(3).map {
            .init(
                icon: "exclamationmark.circle.fill",
                title: $0,
                subtitle: nil,
                isMonthlyAssessment: false
            )
        })

        return items
    }

    var body: some View {
        if !actionItems.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Action Required")
                    .font(.system(size: 22, weight: .bold))
                
                VStack(spacing: 12) {
                    ForEach(actionItems) { item in
                        Button {
                            if item.isMonthlyAssessment {
                                onStartMonthlyAssessment?()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: item.icon)
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    if let subtitle = item.subtitle {
                                        Text(subtitle)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .background(AppTheme.cardBackground)
                .cornerRadius(16)
                .shadow(color: AppTheme.adaptiveShadow, radius: 6, x: 0, y: 3)
            }
        }
    }
}

private struct TrackerActionItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String?
    let isMonthlyAssessment: Bool
}
//#Preview {
//    let sampleState = AppStateManager.withSampleData()
//
//    TrackerActionRequiredSection()
//        .environment(sampleState)
//        .padding()
//        .background(Color(uiColor: .systemGroupedBackground))
//}

struct TrackerRecommendationSection: View {
    @Environment(AppStateManager.self) var appState
    
    var body: some View {
        if let recommendation = generateRecommendation() {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recommended for You")
                    .font(.system(size: 22, weight: .bold))
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text(recommendation.title)
                            .font(.headline)
                    }
                    
                    Text(recommendation.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let action = recommendation.action {
                        Button {
                            // Action path
                        } label: {
                            Text(action)
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .background(Color.blue)
                                .cornerRadius(20)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.cardBackground)
                .cornerRadius(16)
                .shadow(color: AppTheme.adaptiveShadow, radius: 6, x: 0, y: 3)
            }
        }
    }
    
    private func generateRecommendation() -> (title: String, description: String, action: String?)? {
        guard let profile = appState.currentProfile else { return nil }
        
        // Example logic from sketch: "Add some amount in stocks to get high returns"
        let totalAssets = profile.assets.totalAssets
        let stocksPct = totalAssets > 0 ? (profile.assets.stocksHoldingAmount / totalAssets) : 0
        
        if stocksPct < 0.15 && profile.basicDetails.riskTolerance == .high {
            return (
                "Boost Your Returns",
                "Your portfolio has only \((stocksPct * 100).safeInt)% in stocks. Adding more equity can help beat inflation in the long term.",
                "Explore Stocks"
            )
        }
        
        if profile.basicDetails.emergencyFundAmount < (profile.basicDetails.monthlyExpenses * 3) {
            return (
                "Build Your Buffer",
                "Your emergency fund is below 3 months of expenses. We recommend prioritizing this before new investments.",
                "Set Goal"
            )
        }
        
        return nil
    }
}
#Preview {
    let sampleState = AppStateManager.withSampleData()

    TrackerRecommendationSection()
        .environment(sampleState)
        .padding()
        .background(Color(uiColor: .systemGroupedBackground))
}
