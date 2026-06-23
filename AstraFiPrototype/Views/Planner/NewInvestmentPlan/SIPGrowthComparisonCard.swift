import SwiftUI

struct SIPGrowthComparisonCard: View {
    @Environment(\.colorScheme) var colorScheme
    
    // Inputs (Bindings)
    @Binding var monthlySIP: Double
    @Binding var investmentYears: Int
    @Binding var selectedRisk: AstraRiskLevel
    @State private var showingInfo = false
    
    // Returns Mapping
    private var singleFundReturn: Double {
        switch selectedRisk {
        case .low: return 7.0
        case .high: return 15.0
        case .mid: return 12.0 // Mid/Moderate
        }
    }
    
    private var diversifiedReturn: Double {
        switch selectedRisk {
        case .low: return 9.0
        case .high: return 18.0
        case .mid: return 14.0 // Mid/Moderate
        }
    }
    
    // Calculations
    private var singleFundResult: SIPResult {
        calculateSIP(monthly: monthlySIP, rate: singleFundReturn, years: investmentYears)
    }
    
    private var diversifiedResult: SIPResult {
        calculateSIP(monthly: monthlySIP, rate: diversifiedReturn, years: investmentYears)
    }
    
    private var difference: Double {
        diversifiedResult.futureValue - singleFundResult.futureValue
    }
    
    private var isDiversifiedBetter: Bool {
        difference > 0
    }
    
    var body: some View {
        VStack(spacing: 22) {
            // Header
            HStack(alignment: .center, spacing: 12) {
                Text("SIP Growth Comparison")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .lineLimit(2)
                Spacer()
                Button {
                    showingInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            
            // Inputs
            VStack(spacing: 20) {
                // Monthly SIP Input
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Monthly Investment")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("₹\(Int(monthlySIP).formattedWithComma)")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    Slider(value: $monthlySIP, in: 500...500000, step: 500)
                        .accentColor(.blue)
                }
                
                // Duration Input
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Investment Duration")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(investmentYears) Years")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    Slider(value: Binding(get: { Double(investmentYears) }, set: { investmentYears = Int($0) }), in: 1...30, step: 1)
                        .accentColor(.blue)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
            .background(Color.blue.opacity(0.04))
            .cornerRadius(16)
            
            // 2-Column Comparison
            HStack(alignment: .top, spacing: 14) {
                comparisonColumn(
                    title: "Single Fund",
                    result: singleFundResult,
                    isHighlighted: !isDiversifiedBetter,
                    caption: "Higher dependence on one fund"
                )
                
                comparisonColumn(
                    title: "Diversified Portfolio",
                    result: diversifiedResult,
                    isHighlighted: isDiversifiedBetter,
                    caption: "Balanced across assets"
                )
            }
            
            // Visual Growth Difference
            if difference != 0 {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isDiversifiedBetter ? "Diversification Edge" : "Single Fund Edge")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .textCase(.uppercase)
                        HStack(spacing: 4) {
                            Text("+₹\(fmtLarge(abs(difference)))")
                                .font(.headline)
                                .fontWeight(.black)
                                .foregroundColor(.green)
                            Text("more returns")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    
                    // Mini Bar Comparison
                    HStack(alignment: .bottom, spacing: 6) {
                        let maxFV = max(singleFundResult.futureValue, diversifiedResult.futureValue)
                        bar(height: (singleFundResult.futureValue / maxFV) * 40, color: .gray.opacity(0.3))
                        bar(height: (diversifiedResult.futureValue / maxFV) * 40, color: .green)
                    }
                }
                .padding(16)
                .background(Color.green.opacity(0.08))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .background(AppTheme.cardBackground)
        .cornerRadius(24)
        .clipped()
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.3), radius: 12, x: 0, y: 6)
        .sheet(isPresented: $showingInfo) {
            InfoBottomSheet(
                isDiversifiedBetter: isDiversifiedBetter,
                monthlySIP: monthlySIP,
                investmentYears: investmentYears,
                singleFundReturn: singleFundReturn,
                diversifiedReturn: diversifiedReturn,
                singleFundResult: singleFundResult,
                diversifiedResult: diversifiedResult
            )
            .presentationDetents([.medium, .large])
            .presentationBackground(colorScheme == .dark ? Color(UIColor.systemBackground) : .white)
            .presentationDragIndicator(.visible)
        }
    }
    
    private func comparisonColumn(title: String, result: SIPResult, isHighlighted: Bool, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(isHighlighted ? .blue : .secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.86)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isHighlighted ? Color.blue.opacity(0.1) : Color.clear)
                .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 10) {
                metricRow(label: "Invested", value: "₹\(fmtLarge(result.invested))")
                metricRow(label: "Est. Value", value: "₹\(fmtLarge(result.futureValue))", color: .primary)
                metricRow(label: "Returns", value: "\(String(format: "%.1f", result.rate))%", color: .green)
            }
            
            Text(caption)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .italic()
                .padding(.top, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 172, alignment: .topLeading)
        .background(isHighlighted ? Color.blue.opacity(0.03) : Color.clear)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isHighlighted ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func metricRow(label: String, value: String, color: Color = .secondary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
    }
    
    private func bar(height: CGFloat, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 12, height: max(4, height))
    }
    
    private func fmtLarge(_ v: Double) -> String {
        let val = abs(v)
        if val >= 10000000 { return String(format: "%.1fCr", v / 10000000) }
        if val >= 100000 { return String(format: "%.1fL", v / 100000) }
        if val >= 1000 { return String(format: "%.1fK", v / 1000) }
        return String(format: "%.0f", v)
    }
    
    private func calculateSIP(monthly: Double, rate: Double, years: Int) -> SIPResult {
        let r = rate / 100 / 12
        let n = Double(years * 12)
        let invested = monthly * n
        
        let fv: Double
        if r == 0 {
            fv = invested
        } else {
            fv = monthly * (pow(1 + r, n) - 1) / r * (1 + r)
        }
        
        return SIPResult(invested: invested, futureValue: fv, rate: rate)
    }
    
    // Logic Helpers
    struct SIPResult {
        let invested: Double
        let futureValue: Double
        let rate: Double
    }
    
    struct InfoBottomSheet: View {
        @Environment(\.dismiss) var dismiss
        let isDiversifiedBetter: Bool
        let monthlySIP: Double
        let investmentYears: Int
        let singleFundReturn: Double
        let diversifiedReturn: Double
        let singleFundResult: SIPResult
        let diversifiedResult: SIPResult
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Empty to remove custom header
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(isDiversifiedBetter ?
                             "Diversification provides better growth with reduced risk by balancing multiple asset classes." :
                                "A single fund can outperform but depends heavily on selecting the right fund.")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Scenario 1: ONE Fund
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Image(systemName: "chart.bar.fill")
                            Text("Scenario 1: ₹\(Int(monthlySIP)) in ONE fund")
                                .font(.headline)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundColor(.primary)
                        
                        Text("Let's assume a **good performing equity mutual fund**")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Average return: **\(String(format: "%.1f", singleFundReturn))% annually**", systemImage: "hand.point.right.fill")
                            BulletText(text: "Monthly rate = \(String(format: "%.1f", singleFundReturn))% / 12 ≈ \(String(format: "%.2f", singleFundReturn / 12))%")
                            BulletText(text: "n = \(investmentYears * 12) (for \(investmentYears) years)")
                        }
                        .font(.footnote)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Result:")
                                .font(.footnote).bold()
                            BulletText(text: "Invested amount = ₹\(fmtLarge(singleFundResult.invested))")
                            BulletText(text: "Final value ≈ **₹\(fmtLarge(singleFundResult.futureValue))**")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.primary.opacity(0.03))
                        .cornerRadius(12)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.elevatedCardBackground)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))
                    
                    // Scenario 2: Diversified
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Image(systemName: "chart.pie.fill")
                            Text("Scenario 2: Diversified (AstraFi Idea)")
                                .font(.headline)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Allocation:")
                                .font(.footnote).bold()
                            AllocationRow(label: "₹\(Int(monthlySIP * 0.4)) → Large cap", value: "~40%")
                            AllocationRow(label: "₹\(Int(monthlySIP * 0.3)) → Small cap", value: "~30%")
                            AllocationRow(label: "₹\(Int(monthlySIP * 0.3)) → Stocks", value: "~30%")
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Result:")
                                .font(.footnote).bold()
                            Label("Overall portfolio ≈ **\(String(format: "%.1f", diversifiedReturn))% return**", systemImage: "hand.point.right.fill")
                                .font(.footnote)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                BulletText(text: "Invested amount = ₹\(fmtLarge(diversifiedResult.invested))")
                                BulletText(text: "Final value ≈ **₹\(fmtLarge(diversifiedResult.futureValue))**")
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.elevatedCardBackground)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.blue.opacity(0.2), lineWidth: 1))
                    
                    Divider()
                    
                    // General Advantages
                    VStack(alignment: .leading, spacing: 12) {
                        BulletPoint(text: "Diversification reduces volatility by spreading your capital.")
                        BulletPoint(text: "A single fund carries higher dependency risk—if that fund fails, your whole portfolio suffers.")
                        BulletPoint(text: "Long-term investing benefits most from the consistency of a balanced portfolio.")
                        BulletPoint(text: "If one asset underperforms, others (like Small Cap) can balance the returns.")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Summary Comparison
                    VStack(spacing: 12) {
                        HStack {
                            Text("Higher Risk, Higher Dependence")
                                .font(.caption)
                            Spacer()
                            Text("Single Fund")
                                .fontWeight(.bold)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                        
                        HStack {
                            Text("Balanced Growth, Lower Risk")
                                .font(.caption)
                            Spacer()
                            Text("Diversified")
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
            .background(AppTheme.appBackground(for: colorScheme))
            .navigationTitle("Which strategy is better?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
    }
        
        private func fmtLarge(_ v: Double) -> String {
            let val = abs(v)
            if val >= 10000000 { return String(format: "%.1fCr", v / 10000000) }
            if val >= 100000 { return String(format: "%.1fL", v / 100000) }
            if val >= 1000 { return String(format: "%.1fK", v / 1000) }
            return String(format: "%.0f", v)
        }
    }
    
    struct BulletText: View {
        let text: String
        var body: some View {
            HStack(alignment: .top, spacing: 6) {
                Circle().fill(Color.secondary).frame(width: 4, height: 4).padding(.top, 6)
                Text(LocalizedStringKey(text))
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    struct AllocationRow: View {
        let label: String
        let value: String
        var body: some View {
            HStack(spacing: 8) {
                Circle().fill(Color.blue).frame(width: 4, height: 4)
                Text(label)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)
                Spacer()
                Text(value).font(.footnote).bold()
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    struct BulletPoint: View {
        let text: String
        var body: some View {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                    .padding(.top, 2)
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    //#Preview {
    //    ZStack {
    //        Color.gray.opacity(0.1).ignoresSafeArea()
    //        SIPGrowthComparisonCard(monthlySIP: .constant(5000), investmentYears: .constant(10), selectedRisk: .constant(.mid))
    //            .padding()
    //    }
    //}
}
