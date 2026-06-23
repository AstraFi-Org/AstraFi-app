import SwiftUI
import Charts

struct TrackerFundAllocationSection: View {
    let allocations: [FundAllocation]
    @Environment(\.colorScheme) private var colorScheme

    private var validAllocations: [FundAllocation] {
        allocations.filter { $0.percentage.isFinite && $0.percentage > 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fund Allocation")
                .font(.system(size: 22, weight: .bold))

            VStack(spacing: 24) {
                if validAllocations.isEmpty {
                    TrackerEmptyState(icon: "chart.pie.fill", message: "No fund allocations found.")
                } else {
                    FundAllocationChart(allocations: validAllocations)
                        .frame(height: 220)
                        .padding(.top, 16)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 16) {
                        ForEach(validAllocations) { allocation in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(allocation.color.gradient)
                                    .frame(width: 12, height: 12)
                                    .padding(.top, 3)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(allocation.name)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Text(String(format: "%.1f%%", allocation.percentage))
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: AppTheme.adaptiveShadow, radius: 6, x: 0, y: 3)
        }
    }
}

@available(iOS 17.0, *)
struct FundAllocationChart: View {
    let allocations: [FundAllocation]
    @State private var isVisible = false

    var body: some View {
        Chart(allocations) { alloc in
            SectorMark(
                // Never animate sector angles from an all-zero data set.
                // Charts can generate NaN arc geometry when every angle is zero.
                angle: .value("Percentage", alloc.percentage),
                innerRadius: .ratio(0.65),
                angularInset: 2.0
            )
            .foregroundStyle(alloc.color.gradient)
            .cornerRadius(6)
            .opacity(isVisible ? 1 : 0.01)
            .annotation(position: .overlay, alignment: .center) {
                if alloc.percentage >= 5 {
                    VStack(spacing: 0) {
                        Text(alloc.name)
                            .font(.system(size: 9, weight: .bold))
                        Text("\(alloc.percentage.safeInt)%")
                            .font(.system(size: 10, weight: .heavy))
                    }
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                }
            }
        }
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                if let plotFrame = chartProxy.plotFrame {
                    let frame = geometry[plotFrame]
                    VStack {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary.opacity(0.3))
                            .padding(.bottom, 2)
                        Text("Total")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .position(x: frame.midX, y: frame.midY)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) {
                isVisible = true
            }
        }
    }
}

#Preview {
    TrackerFundAllocationSection(allocations: [
        FundAllocation(name: "Equity", percentage: 45.5, color: .blue),
        FundAllocation(name: "Debt", percentage: 25.0, color: .orange),
        FundAllocation(name: "Commodity", percentage: 15.5, color: .yellow),
        FundAllocation(name: "Others", percentage: 14.0, color: .purple)
    ])
    .padding()
}
