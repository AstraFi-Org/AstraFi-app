import SwiftUI

struct Plan2InteractiveTimelineView: View {
    let yearlyData: [Plan2YearlyDetail]
    let loanAmount: Double
    let totalTenure: Int
    @Binding var emiFrequency: EMIFrequency
    @Binding var interestType: InterestType
    var onRecalculate: (() -> Void)? = nil

    @State private var selectedYearIndex: Int? = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            HStack {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.blue)
                        .font(.headline)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Repayment Timeline")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Interactive yearly breakdown")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

            }

            HStack(spacing: 16) {

                VStack(alignment: .leading, spacing: 12) {
                    Text("Interest Type")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Picker("Interest Type", selection: $interestType) {
                        ForEach(InterestType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: interestType) { _, _ in
                        onRecalculate?()
                    }
                }
            }
            HStack(spacing: 12) {
                Text("EMI Frequency")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Picker("EMI Frequency", selection: $emiFrequency) {
                    ForEach(EMIFrequency.allCases, id: \.self) { freq in
                        Text(freq.rawValue).tag(freq)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: emiFrequency) { _, _ in
                    onRecalculate?()
                }
            }
            if !yearlyData.isEmpty {
                barChartTimeline()
            } else {
                Text("No data available.")
                    .font(.caption).foregroundColor(.secondary)
            }

            if let index = selectedYearIndex, index < yearlyData.count {
                Divider()
                detailSection(for: yearlyData[index])
            }
        }
        .padding(24)
        .background(AppTheme.cardBackground)
        .cornerRadius(24)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.5), radius: 12, x: 0, y: 6)
        .onAppear {
            if !yearlyData.isEmpty { selectedYearIndex = 0 }
        }
        .onChange(of: yearlyData) { _, _ in
            if !yearlyData.isEmpty { selectedYearIndex = 0 }
        }
    }

    private var maxEmi: Double {
        let m = yearlyData.map { $0.emiPaidYearly }.max() ?? 1.0
        return m > 0 ? m : 1.0
    }

    private func barChartTimeline() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 16) {

                VStack(spacing: 4) {
                    Spacer()
                    Text("Plan")
                    Text("starts")
                    Text("\(Date().formatted(.dateTime.year()))")
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .frame(width: 50)
                .padding(.bottom, 48) 

                VStack(spacing: 8) {
                    HStack(alignment: .bottom, spacing: 20) {
                        ForEach(Array(yearlyData.enumerated()), id: \.offset) { index, detail in
                            let isSelected = selectedYearIndex == index
                            let heightRatio = CGFloat(detail.emiPaidYearly / maxEmi)
                            let barHeight = max(20, heightRatio * 140) 

                            VStack(spacing: 12) {

                                Text(formatL(detail.emiPaidYearly))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.primary)

                                Capsule()
                                    .fill(isSelected ? Color.blue : Color.blue.opacity(0.25))
                                    .frame(width: 38, height: barHeight)
                                    .animation(.spring(response: 0.4), value: selectedYearIndex)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedYearIndex = index
                            }
                        }
                    }

                    Rectangle()
                        .fill(Color(UIColor.separator))
                        .frame(height: 2)
                        .padding(.vertical, 4)

                    HStack(alignment: .top, spacing: 20) {
                        ForEach(Array(yearlyData.enumerated()), id: \.offset) { index, detail in
                            let isSelected = selectedYearIndex == index

                            VStack(spacing: 4) {
                                Text("\(detail.date.formatted(.dateTime.year()))")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(isSelected ? .blue : .primary)

                                Text("\(formatL(detail.remainingPrincipal))")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 38) 
                        }
                    }
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 10)
        }
    }

    private func detailSection(for detail: Plan2YearlyDetail) -> some View {
        let paymentsCount = Int(emiFrequency.paymentsPerYear)

        let safePayments = max(1, paymentsCount)
        let emiValue = detail.emiPaidYearly / Double(safePayments)

        return VStack(alignment: .leading, spacing: 16) {
            Text("Breakdown for \(detail.date.formatted(.dateTime.year()))")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            VStack(spacing: 16) {
                ForEach(0..<safePayments, id: \.self) { i in
                    HStack(spacing: 16) {
                        Text(paymentLabel(for: i))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 45, alignment: .leading)

                        Capsule()
                            .fill(Color.blue.opacity(0.5))
                            .frame(height: 5)
                            .frame(maxWidth: .infinity)

                        Text("₹\(Int(emiValue).formatted())")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .frame(width: 80, alignment: .trailing)
                    }
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(UIColor.separator), lineWidth: 1)
            )
        }
    }

    private func paymentLabel(for index: Int) -> String {
        switch emiFrequency {
        case .monthly:
            let formatter = DateFormatter()
            return formatter.shortMonthSymbols[index % 12] 
        case .quarterly:
            return "Q\(index + 1)"
        case .halfYearly:
            return "H\(index + 1)"
        case .yearly:
            return "Annual"
        }
    }

    private func formatL(_ value: Double) -> String {
        let v = abs(value)
        if v >= 10000000 { return String(format: "%.2fCr", value / 10000000) }
        else if v >= 100000 { return String(format: "%.2fL", value / 100000) }
        else if v >= 1000 { return String(format: "%.1fK", value / 1000) }
        return String(format: "%.0f", value)
    }
}
