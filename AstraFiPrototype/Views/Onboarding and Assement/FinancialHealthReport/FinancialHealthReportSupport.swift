import SwiftUI

enum FinancialHealthUIStyle {
    static func scoreColor(_ score: Int) -> Color {
        switch score {
        case 90...100: return Color(hex: "#30D158")
        case 75..<90: return Color(hex: "#30D158")
        case 60..<75: return Color(hex: "#FF9F0A")
        case 40..<60: return Color(hex: "#FF9F0A")
        default: return Color(hex: "#FF453A")
        }
    }

    static func parameterColor(_ status: AssessmentParameterStatus) -> Color {
        switch status {
        case .fine: return Color(hex: "#30D158")
        case .watch: return Color(hex: "#FF9F0A")
        case .concern, .critical: return Color(hex: "#FF453A")
        }
    }

    static func icon(for parameter: AssessmentParameter) -> String {
        switch parameter {
        case .vitals: return "heart.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .liabilities: return "creditcard.fill"
        case .insurance: return "shield.fill"
        case .emergencyFund: return "exclamationmark.shield.fill"
        }
    }

    static func accent(for parameter: AssessmentParameter) -> Color {
        switch parameter {
        case .vitals: return Color(hex: "#FF2D55")
        case .investment: return Color(hex: "#007AFF")
        case .liabilities: return Color(hex: "#BF5AF2")
        case .insurance: return Color(hex: "#30D158")
        case .emergencyFund: return Color(hex: "#FF9F0A")
        }
    }
}

struct FinancialHealthActionDestinationView: View {
    let destination: FinancialHealthActionDestination
    @State private var emergencyState = EmergencyFundSectionState()

    var body: some View {
        switch destination {
        case .emergencyPlanner:
            EmergencyFundSetupView(plannerState: emergencyState)
        case .loanTracker:
            LoanTrackerView()
        case .investments:
            InvestmentOverviewView()
                .environment(TrackerViewModel())
        case .protection:
            InsuranceListView()
        case .goals:
            AddGoalView()
        case .vitals:
            SpendingInsightsView()
        }
    }
}
