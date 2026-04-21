//import SwiftUI
//
//struct ScreenshotMetricRow: View {
//    let icon: String; let title: String; let status: String; let iconColor: Color; let bgColor: Color; let statusColor: Color
//    var body: some View {
//        HStack(spacing: 12) {
//            ZStack { 
//                RoundedRectangle(cornerRadius: 12).fill(bgColor).frame(width: 44, height: 44)
//                Image(systemName: icon).foregroundColor(iconColor).font(.system(size: 20)) 
//            }
//
//            Text(title)
//                .font(.system(size: 14, weight: .medium))
//                .foregroundColor(.primary)
//                .lineLimit(1)
//                .layoutPriority(0)
//
//            Spacer(minLength: 4)
//
//            Text(status)
//                .font(.system(size: 14, weight: .semibold))
//                .foregroundColor(statusColor)
//                .lineLimit(1)
//                .fixedSize(horizontal: true, vertical: false)
//                .layoutPriority(1)
//        }
//        .padding(.vertical, 12).padding(.horizontal, 16)
//    }
//}
//
//#Preview {
//    VStack {
//        ScreenshotMetricRow(
//            icon: "chart.line.uptrend.xyaxis",
//            title: "Portfolio Growth",
//            status: "+12.5%",
//            iconColor: .blue,
//            bgColor: .blue.opacity(0.1),
//            statusColor: .green
//        )
//        ScreenshotMetricRow(
//            icon: "bitcoinsign.circle.fill",
//            title: "Crypto Holdings",
//            status: "-2.4%",
//            iconColor: .orange,
//            bgColor: .orange.opacity(0.1),
//            statusColor: .red
//        )
//    }
//    .padding()
//    .background(AppTheme.cardBackground)
//}
