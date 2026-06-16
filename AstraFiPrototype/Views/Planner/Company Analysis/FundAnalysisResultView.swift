import SwiftUI
import Charts

private struct FundAnalysisChartPoint: Identifiable {
    let index: Int
    let value: Double
    let series: String

    var id: String { "\(series)-\(index)" }
}

private struct FundAllocationSlice: Identifiable {
    let name: String
    let value: Double
    let color: Color

    var id: String { name }
}

struct FundAnalysisResultView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    let fundName: String
    let fundType: String

    @State private var animateDonut = false
    @State private var animateNAV   = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                HStack(spacing: 12) {
                    Text("Large Cap Fund")
                        .font(.subheadline).foregroundColor(.secondary)
                    Text("Sponsor by ICICI Bank")
                        .font(.subheadline).foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 20)

                mainCard
                    .padding(.horizontal, 16)

                Text("Similar Fund's Analysis")
                    .font(.title3).fontWeight(.bold)
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 12)

                SimilarFundCard()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
            }
        }
        .navigationTitle(fundName)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").fontWeight(.semibold)
                }
            }
        }
        .background(AppTheme.appBackground(for: colorScheme))
        .onAppear {
            withAnimation(.easeOut(duration: 0.9).delay(0.2)) { animateNAV   = true }
            withAnimation(.spring(response: 0.9, dampingFraction: 0.7).delay(0.4)) { animateDonut = true }
        }
    }

    private var mainCard: some View {
        VStack(alignment: .leading, spacing: 0) {

            Text("EQUITY MUTUAL FUND")
                .font(.title3).fontWeight(.bold)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 8)

            HStack {
                Text("Shyam Manek (Fund Manager)")
                    .font(.caption).foregroundColor(.secondary)
                Spacer()
                Text("Fund Size")
                    .font(.caption).foregroundColor(.secondary)
                Text("58700Cr")
                    .font(.caption).fontWeight(.semibold).foregroundColor(.primary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            FADivider()

            HStack(spacing: 0) {
                FAMetric(label: "Return(3Y)",    value: "17.3%",  color: .primary)
                FAMetric(label: "current NAV",   value: "172.34", color: .primary)
                FAMetric(label: "Expense Ratio", value: "1.3%",   color: .primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)

            FADivider()

            navChartSection
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 10)

            FADivider()

            FADetailRow(label: "Launched on",    value: "1 Jan 2013", valueColor: .primary)
            FADivider()
            FADetailRow(label: "Min SIP Amt",    value: "100",         valueColor: .primary)
            FADivider()
            FADetailRow(label: "Lock in Period", value: "NO",          valueColor: .primary)

            FADivider()

            allocationSection
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
        }
        .background(AppTheme.cardBackground)
        .cornerRadius(18)
        .shadow(color: AppTheme.adaptiveShadow, radius: 12, x: 0, y: 4)
    }

    private var navChartSection: some View {
        VStack(alignment: .leading, spacing: 6) {

            HStack(alignment: .bottom, spacing: 4) {

                VStack(alignment: .trailing, spacing: 0) {
                    Text("NAV")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(height: 14, alignment: .top)
                    Spacer()
                    ForEach(["195","185","175","-"].reversed(), id: \.self) { label in
                        Text(label)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .frame(height: 28, alignment: .top)
                    }
                }
                .frame(width: 26, height: 130)

                Chart {
                    ForEach([0.0, 0.33, 0.66, 1.0], id: \.self) { value in
                        RuleMark(y: .value("Grid", value))
                            .foregroundStyle(Color.gray.opacity(0.18))
                            .lineStyle(StrokeStyle(lineWidth: 0.5))
                    }

                    ForEach(navChartPoints) { point in
                        AreaMark(
                            x: .value("Point", point.index),
                            yStart: .value("Baseline", 0),
                            yEnd: .value("NAV", animateNAV ? point.value : navChartPoints.first?.value ?? 0)
                        )
                        .foregroundStyle(LinearGradient(
                            colors: [.cyan.opacity(0.22), .cyan.opacity(0.04)],
                            startPoint: .top,
                            endPoint: .bottom
                        ))

                        LineMark(
                            x: .value("Point", point.index),
                            y: .value("NAV", animateNAV ? point.value : navChartPoints.first?.value ?? 0)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.cyan)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    }
                }
                .chartXScale(domain: 0...(max(navChartPoints.count - 1, 1)))
                .chartYScale(domain: 0...1)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 130)
            }
        }
    }

    private var allocationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Allocation")
                .font(.headline).fontWeight(.bold)

            HStack(alignment: .center, spacing: 0) {

                ZStack {
                    Chart {
                        ForEach(fundAllocationSlices) { slice in
                            SectorMark(
                                angle: .value("Allocation", animateDonut ? slice.value : 0),
                                innerRadius: .ratio(0.58),
                                angularInset: 0
                            )
                            .foregroundStyle(slice.color)
                        }
                    }
                    .chartLegend(.hidden)
                    .frame(width: 116, height: 116)
                }
                .padding(16)
                .frame(width: 148, height: 148)
                .animation(.spring(response: 0.9, dampingFraction: 0.7), value: animateDonut)

                Spacer().frame(width: 24)

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(.green)
                            .frame(width: 14, height: 14)
                        Text("Equity")
                            .font(.subheadline).fontWeight(.medium)
                    }
                    HStack(spacing: 10) {
                        Circle()
                            .fill(.cyan)
                            .frame(width: 14, height: 14)
                        Text("Debt")
                            .font(.subheadline).fontWeight(.medium)
                    }
                }

                Spacer()
            }
        }
    }

    private var navChartPoints: [FundAnalysisChartPoint] {
        [
            0.18, 0.14, 0.16, 0.13, 0.10, 0.14, 0.18, 0.22, 0.25,
            0.28, 0.32, 0.36, 0.40, 0.45, 0.50, 0.54, 0.58, 0.63,
            0.67, 0.70, 0.74, 0.78, 0.82, 0.87, 0.90, 0.94, 0.97, 1.0
        ].enumerated().map { FundAnalysisChartPoint(index: $0.offset, value: $0.element, series: "NAV") }
    }

    private var fundAllocationSlices: [FundAllocationSlice] {
        [
            FundAllocationSlice(name: "Equity", value: 75, color: .green),
            FundAllocationSlice(name: "Debt", value: 25, color: .cyan)
        ]
    }
}

private struct FADivider: View {
    var body: some View {
        Divider().padding(.horizontal, 20)
    }
}

private struct FAMetric: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Text(label)
                .font(.caption).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Text(value)
                .font(.subheadline).fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct FADetailRow: View {
    let label: String
    let value: String
    let valueColor: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.body).foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.body).fontWeight(.semibold)
                .foregroundColor(valueColor)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

struct SimilarFundCard: View {
    @State private var selectedTF = "1Y"
    let timeframes = ["1D", "5D", "1M", "3M", "1Y", "5Y", "10Y"]

    private let redPts: [CGFloat] = [
        0.05,0.10,0.07,0.14,0.10,0.18,0.13,0.22,0.19,0.28,
        0.25,0.35,0.30,0.40,0.36,0.45,0.50,0.44,0.55,0.52,
        0.60,0.56,0.65,0.62,0.70,0.68,0.75,0.72,0.80,0.85
    ]
    private let greenPts: [CGFloat] = [
        0.07,0.12,0.09,0.16,0.12,0.20,0.15,0.24,0.21,0.30,
        0.27,0.37,0.33,0.42,0.38,0.47,0.52,0.46,0.57,0.54,
        0.61,0.57,0.63,0.60,0.66,0.64,0.68,0.65,0.70,0.72
    ]

    private let yLabels = ["122900","122800","122700","122600","122500",
                            "122400","122300","122200","122100","122000","121900"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Nippon India Fund")
                        .font(.headline).fontWeight(.bold)
                    Text("Large Cap Fund")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("1200$")
                        .font(.title2).fontWeight(.bold)
                        .foregroundColor(.green)
                    HStack(spacing: 3) {
                        Image(systemName: "arrowtriangle.up.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.green)
                        Text("450$")
                            .font(.caption).fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
            }

            Chart {
                RuleMark(y: .value("Upper", 0.72))
                    .foregroundStyle(Color.gray.opacity(0.40))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))
                RuleMark(y: .value("Lower", 0.30))
                    .foregroundStyle(Color.gray.opacity(0.40))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))

                ForEach(similarFundChartPoints) { point in
                    LineMark(
                        x: .value("Point", point.index),
                        y: .value("Value", point.value),
                        series: .value("Series", point.series)
                    )
                    .foregroundStyle(point.series == "Nifty50" ? Color.red : Color.green)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }

                ForEach(similarFundEndPoints) { point in
                    PointMark(
                        x: .value("Point", point.index),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(point.series == "Nifty50" ? Color.red : Color.green)
                    .symbolSize(64)
                }

                PointMark(x: .value("Point", redPts.count - 1), y: .value("Value", 0.30))
                    .foregroundStyle(.cyan)
                    .symbolSize(49)
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Nifty50")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.red)
                    }
            }
            .chartXScale(domain: 0...(max(redPts.count - 1, 1)))
            .chartYScale(domain: 0...1)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .trailing, values: yAxisValues) { value in
                    AxisValueLabel {
                        if let axisValue = value.as(Double.self),
                           let index = yAxisValues.firstIndex(where: { abs($0 - axisValue) < 0.0001 }),
                           yLabels.indices.contains(index) {
                            Text(yLabels[index])
                                .font(.system(size: 8.5))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartLegend(.hidden)
            .chartPlotStyle { plotArea in
                plotArea
                    .background(Color.primary.opacity(0.03))
                    .border(Color.primary.opacity(0.7), width: 1.5)
            }
            .frame(height: 220)

            HStack(spacing: 6) {
                ForEach(timeframes, id: \.self) { tf in
                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedTF = tf }
                    } label: {
                        Text(tf)
                            .font(.caption)
                            .fontWeight(selectedTF == tf ? .semibold : .regular)
                            .foregroundColor(selectedTF == tf ? .white : .secondary)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(
                                selectedTF == tf
                                    ? .gray
                                    : Color(UIColor.secondarySystemFill)
                            )
                            .cornerRadius(7)
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(18)
        .shadow(color: AppTheme.adaptiveShadow, radius: 12, x: 0, y: 4)
    }

    private var similarFundChartPoints: [FundAnalysisChartPoint] {
        redPts.enumerated().map { FundAnalysisChartPoint(index: $0.offset, value: $0.element, series: "Nifty50") }
        + greenPts.enumerated().map { FundAnalysisChartPoint(index: $0.offset, value: $0.element, series: "Fund") }
    }

    private var similarFundEndPoints: [FundAnalysisChartPoint] {
        [
            FundAnalysisChartPoint(index: redPts.count - 1, value: redPts.last ?? 0, series: "Nifty50"),
            FundAnalysisChartPoint(index: greenPts.count - 1, value: greenPts.last ?? 0, series: "Fund")
        ]
    }

    private var yAxisValues: [Double] {
        guard yLabels.count > 1 else { return [0] }
        return yLabels.indices.map { 1 - (Double($0) / Double(yLabels.count - 1)) }
    }
}

#Preview {
    NavigationStack {
        FundAnalysisResultView(
            fundName: "ICICI Prudential Fund",
            fundType:  "Equity Mutual Fund"
        )
    }
}
