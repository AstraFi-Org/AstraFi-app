import SwiftUI

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

                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height

                    ZStack(alignment: .bottomLeading) {

                        ForEach([0.0, 0.33, 0.66, 1.0], id: \.self) { frac in
                            Path { p in
                                let y = h * CGFloat(frac)
                                p.move(to:    CGPoint(x: 0, y: y))
                                p.addLine(to: CGPoint(x: w, y: y))
                            }
                            .stroke(Color.gray.opacity(0.18), lineWidth: 0.5)
                        }

                        NAVAreaShape(animate: animateNAV)
                            .fill(LinearGradient(
                                colors: [.cyan.opacity(0.22),
                                         .cyan.opacity(0.04)],
                                startPoint: .top, endPoint: .bottom))

                        NAVLineShape(animate: animateNAV)
                            .stroke(.cyan,
                                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    }
                }
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
                    Circle()
                        .trim(from: 0, to: animateDonut ? 0.75 : 0)
                        .stroke(.green,
                                style: StrokeStyle(lineWidth: 32, lineCap: .butt))
                        .rotationEffect(.degrees(-90))

                    Circle()
                        .trim(from: 0.75, to: animateDonut ? 1.0 : 0.75)
                        .stroke(.cyan,
                                style: StrokeStyle(lineWidth: 32, lineCap: .butt))
                        .rotationEffect(.degrees(-90))

                    Circle()
                        .fill(AppTheme.cardBackground)
                        .frame(width: 72, height: 72)
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

struct NAVLineShape: Shape {
    var animate: Bool
    var animatableData: Double {
        get { animate ? 1 : 0 }
        set { }
    }

    private let pts: [CGFloat] = [
        0.18, 0.14, 0.16, 0.13, 0.10, 0.14, 0.18, 0.22, 0.25,
        0.28, 0.32, 0.36, 0.40, 0.45, 0.50, 0.54, 0.58, 0.63,
        0.67, 0.70, 0.74, 0.78, 0.82, 0.87, 0.90, 0.94, 0.97, 1.0
    ]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard pts.count > 1 else { return path }

        let stepX = rect.width / CGFloat(pts.count - 1)
        var points: [CGPoint] = []

        for i in 0..<pts.count {
            points.append(CGPoint(x: stepX * CGFloat(i), y: rect.height * (1 - pts[i])))
        }

        let visibleCount = Int(Double(points.count) * (animate ? 1.0 : 0.05))
        guard visibleCount > 1 else { return path }

        path.move(to: points[0])

        for i in 1..<visibleCount {
            let p1 = points[i-1]
            let p2 = points[i]
            let midPoint = CGPoint(x: (p1.x + p2.x)/2, y: (p1.y + p2.y)/2)
            path.addQuadCurve(to: midPoint, control: p1)
            if i == visibleCount - 1 {
                path.addLine(to: p2)
            }
        }
        return path
    }
}

struct NAVAreaShape: Shape {
    var animate: Bool
    var animatableData: Double {
        get { animate ? 1 : 0 }
        set { }
    }

    private let pts: [CGFloat] = [
        0.18, 0.14, 0.16, 0.13, 0.10, 0.14, 0.18, 0.22, 0.25,
        0.28, 0.32, 0.36, 0.40, 0.45, 0.50, 0.54, 0.58, 0.63,
        0.67, 0.70, 0.74, 0.78, 0.82, 0.87, 0.90, 0.94, 0.97, 1.0
    ]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard pts.count > 1 else { return path }

        let stepX = rect.width / CGFloat(pts.count - 1)
        var points: [CGPoint] = []

        for i in 0..<pts.count {
            points.append(CGPoint(x: stepX * CGFloat(i), y: rect.height * (1 - pts[i])))
        }

        let visibleCount = Int(Double(points.count) * (animate ? 1.0 : 0.05))
        guard visibleCount > 1 else { return path }

        path.move(to: points[0])

        for i in 1..<visibleCount {
            let p1 = points[i-1]
            let p2 = points[i]
            let midPoint = CGPoint(x: (p1.x + p2.x)/2, y: (p1.y + p2.y)/2)
            path.addQuadCurve(to: midPoint, control: p1)
        }

        path.addLine(to: CGPoint(x: points[visibleCount-1].x, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
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

            GeometryReader { geo in
                let totalW  = geo.size.width
                let totalH  = geo.size.height
                let yAxisW: CGFloat = 54
                let chartW  = totalW - yAxisW

                ZStack(alignment: .topLeading) {

                    Path { p in
                        p.move(to:    CGPoint(x: 0, y: 0))
                        p.addLine(to: CGPoint(x: 0, y: totalH))
                    }
                    .stroke(Color.primary.opacity(0.7), lineWidth: 1.5)

                    Path { p in
                        let y = totalH * 0.28
                        p.move(to:    CGPoint(x: 0,      y: y))
                        p.addLine(to: CGPoint(x: chartW, y: y))
                    }
                    .stroke(Color.gray.opacity(0.40),
                            style: StrokeStyle(lineWidth: 1, dash: [5, 4]))

                    Path { p in
                        let y = totalH * 0.70
                        p.move(to:    CGPoint(x: 0,      y: y))
                        p.addLine(to: CGPoint(x: chartW, y: y))
                    }
                    .stroke(Color.gray.opacity(0.40),
                            style: StrokeStyle(lineWidth: 1, dash: [5, 4]))

                    polylinePath(pts: redPts, w: chartW, h: totalH)
                        .stroke(
                            LinearGradient(colors: [Color.red, Color.red.opacity(0.7)], startPoint: .top, endPoint: .bottom),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                        )
                        .shadow(color: .red.opacity(0.3), radius: 4)

                    polylinePath(pts: greenPts, w: chartW, h: totalH)
                        .stroke(
                            LinearGradient(colors: [Color.green, Color.green.opacity(0.7)], startPoint: .top, endPoint: .bottom),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                        )
                        .shadow(color: .green.opacity(0.3), radius: 4)

                    endDot(pts: redPts,   w: chartW, h: totalH,
                           color: .red)

                    endDot(pts: greenPts, w: chartW, h: totalH,
                           color: .green)

                    Circle()
                        .fill(.cyan)
                        .frame(width: 7, height: 7)
                        .position(x: chartW - 1, y: totalH * 0.70)

                    Text("Nifty50")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.red)
                        .position(x: chartW - 22, y: 10)

                    let step = totalH / CGFloat(yLabels.count - 1)
                    ForEach(Array(yLabels.enumerated()), id: \.offset) { i, lbl in
                        Text(lbl)
                            .font(.system(size: 8.5))
                            .foregroundColor(.secondary)
                            .frame(width: yAxisW - 2, alignment: .trailing)
                            .position(x: chartW + (yAxisW / 2) + 1,
                                      y: CGFloat(i) * step)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.primary.opacity(0.03))
                )
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

    private func polylinePath(pts: [CGFloat], w: CGFloat, h: CGFloat) -> Path {
        var path = Path()
        guard pts.count > 1 else { return path }
        let stepX = w / CGFloat(pts.count - 1)
        path.move(to: CGPoint(x: 0, y: h * (1 - pts[0])))
        for i in 1..<pts.count {
            path.addLine(to: CGPoint(x: stepX * CGFloat(i),
                                     y: h * (1 - pts[i])))
        }
        return path
    }

    private func endDot(pts: [CGFloat], w: CGFloat, h: CGFloat, color: Color) -> some View {
        let stepX = w / CGFloat(pts.count - 1)
        let lastX = stepX * CGFloat(pts.count - 1)
        let lastY = h * (1 - pts[pts.count - 1])
        return Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .position(x: lastX, y: lastY)
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
