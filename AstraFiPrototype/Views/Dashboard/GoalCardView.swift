import SwiftUI

struct CircularActivityRing: View {
    let percentage: Double
    let gradient: [Color]
    let symbol: String
    let size: CGFloat = 80
    
    var body: some View {
        ZStack {
            // Background Ring
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 10)
                .frame(width: size, height: size)
            
            // Progress Ring
            Circle()
                .trim(from: 0, to: CGFloat(min(percentage / 100, 1.0)))
                .stroke(
                    LinearGradient(colors: gradient, startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .shadow(color: gradient[0].opacity(0.3), radius: 5, x: 0, y: 0)
            
            // SF Symbol
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(LinearGradient(colors: gradient, startPoint: .top, endPoint: .bottom))
        }
    }
}

struct EnhancedGoalCard: View {
    let title: String
    let percentage: Int
    let targetAmount: String
    let gradient: [Color]
    
    private var goalSymbol: String {
        let lower = title.lowercased()
        if lower.contains("home") || lower.contains("house") { return "house.fill" }
        if lower.contains("car") || lower.contains("auto") { return "car.fill" }
        if lower.contains("edu") || lower.contains("study") || lower.contains("book") { return "book.closed.fill" }
        if lower.contains("travel") || lower.contains("trip") || lower.contains("vaca") { return "airplane" }
        if lower.contains("retire") { return "figure.walk" }
        if lower.contains("wedding") || lower.contains("marry") { return "heart.fill" }
        return "star.fill"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            CircularActivityRing(percentage: Double(percentage), gradient: gradient, symbol: goalSymbol)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.auraHeader(size: 18))
                    .foregroundColor(AppTheme.auraIndigo)
                
                Text(targetAmount)
                    .font(.auraCaption(size: 14))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 4) {
                Text("\(percentage)%")
                    .font(.auraDigital(size: 20))
                    .foregroundColor(gradient[0])
                
                Text("Achieved")
                    .font(.auraCaption(size: 12, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(gradient[0].opacity(0.1))
                    .foregroundColor(gradient[0])
                    .cornerRadius(6)
            }
        }
        .padding(24)
        .frame(width: 180)
        .auraCardStyle(radius: 32)
    }
}

#Preview {
    EnhancedGoalCard(
        title: "Home Goal",
        percentage: 65,
        targetAmount: "₹50.0L",
        gradient: [Color.blue, Color.cyan]
    )
    .padding()
}

struct LegendItem2: View {
    let color: Color; let label: String
    var body: some View {
        HStack(spacing: 4) { Circle().fill(color).frame(width: 7, height: 7).padding(2); Text(label).foregroundColor(.secondary) }
    }
}
