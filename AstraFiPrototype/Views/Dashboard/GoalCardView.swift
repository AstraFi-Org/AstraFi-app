import SwiftUI

struct CircularActivityRing: View {
    let percentage: Double
    let gradient: [Color]
    let symbol: String
    let size: CGFloat = 80
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 10)

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
    var cardWidth: CGFloat? = 230
    
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
        HStack(alignment: .top, spacing: 16) {

            // LEFT SIDE (RING)
            VStack(spacing: 12) {
                CircularActivityRing(
                    percentage: Double(percentage),
                    gradient: gradient,
                    symbol: goalSymbol
                )

                Text("Achieved: \(percentage)%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(gradient.first)
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
            .frame(height: 80) // Aligns perfectly with the 80pt ring
            
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(width: cardWidth)
        .frame(maxWidth: cardWidth == nil ? .infinity : nil)
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
