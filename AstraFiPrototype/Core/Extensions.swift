import SwiftUI
import Foundation

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

extension Double {
    func toCurrency(compact: Bool = false) -> String {
        guard self.isFinite else { return "₹0" }
        let absValue = abs(self)
        if absValue >= 10000000 {
            let crores = self / 10000000
            return String(format: "%@₹%.2f Cr", self < 0 ? "-" : "", abs(crores))
        } else if absValue >= 100000 {
            let lakhs = self / 100000
            if compact {
                return String(format: "%@₹%.1fL", self < 0 ? "-" : "", abs(lakhs))
            }
            return String(format: "%@₹%.2f L", self < 0 ? "-" : "", abs(lakhs))
        } else if absValue >= 1000 {

            if compact {
                let thousands = absValue / 1000
                return String(format: "%@₹%.1fK", self < 0 ? "-" : "", thousands)
            }
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = "₹"
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: self)) ?? "₹0"
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = "₹"
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: self)) ?? "₹0"
        }
    }

    func formatToLakhs() -> String {
        guard self.isFinite else { return "₹0" }
        if self >= 10000000 {
            return String(format: "₹%.1f Cr", self / 10000000)
        }
        return String(format: "₹%.1f L", self / 100000)
    }

    var safeInt: Int {
        self.isFinite ? Int(self) : 0
    }
}
