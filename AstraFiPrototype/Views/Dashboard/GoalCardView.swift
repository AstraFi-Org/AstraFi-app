import SwiftUI

struct CircularActivityRing: View {
    let percentage: Double
    let gradient: [Color]
    let symbol: String
    let size: CGFloat = 80
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 10)

            Circle()
                .trim(from: 0, to: CGFloat(min(percentage / 100, 1.0)))
                .stroke(
                    LinearGradient(colors: gradient, startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: gradient[0].opacity(0.3), radius: 5)

            Image(systemName: symbol)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(
                    LinearGradient(colors: gradient, startPoint: .top, endPoint: .bottom)
                )
        }
        .frame(width: size, height: size)
    }
}

struct EnhancedGoalCard: View {
    let title: String
    let percentage: Int
    let targetAmount: String
    let gradient: [Color]
    
    private var goalSymbol: String {
        let lower = title.lowercased()
        if lower.contains("home") { return "house.fill" }
        if lower.contains("car") { return "car.fill" }
        if lower.contains("edu") { return "book.closed.fill" }
        if lower.contains("travel") { return "airplane" }
        if lower.contains("retire") { return "figure.walk" }
        if lower.contains("wedding") { return "heart.fill" }
        return "star.fill"
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 20) {

            // LEFT SIDE (RING)
            VStack(spacing: 8) {
                CircularActivityRing(
                    percentage: Double(percentage),
                    gradient: gradient,
                    symbol: goalSymbol
                )

                Text("\(percentage)%")
                    .font(.auraDigital(size: 18))
                    .foregroundColor(gradient.first)

                Text("Achieved")
                    .font(.auraCaption(size: 11, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(gradient.first!.opacity(0.1))
                    .foregroundColor(gradient.first)
                    .cornerRadius(6)
            }

            // RIGHT SIDE (TEXT)
            VStack(alignment: .leading, spacing: 6) {

                Text(title)
                    .font(.auraHeader(size: 20)) // reduced from 28
                    .foregroundColor(AppTheme.auraIndigo)
                    .lineLimit(2)

                Text(targetAmount)
                    .font(.auraCaption(size: 16)) // reduced from 28
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .frame(width:230) 
        .auraCardStyle(radius: 28)
    }
}

#Preview {
    VStack(spacing: 16) {
        EnhancedGoalCard(
            title: "Home Goal",
            percentage: 65,
            targetAmount: "₹50.0L",
            gradient: [Color.blue, Color.cyan]
        )

        EnhancedGoalCard(
            title: "Car Purchase",
            percentage: 40,
            targetAmount: "₹10.0L",
            gradient: [Color.orange, Color.red]
        )
    }
    .padding()
}
