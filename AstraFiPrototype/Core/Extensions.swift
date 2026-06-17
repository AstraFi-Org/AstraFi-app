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
    var safeFinite: Double {
        self.isFinite ? self : 0
    }

    func toCurrency(compact: Bool = false) -> String {
        guard self.isFinite else { return "₹0" }
        let absValue = abs(self)
        let sign = self < 0 ? "-" : ""
        
        if compact {
            if absValue >= 10000000 {
                return String(format: "%@%.1fCr", sign, absValue / 10000000)
            } else if absValue >= 100000 {
                return String(format: "%@%.1fL", sign, absValue / 100000)
            } else if absValue >= 1000 {
                return String(format: "%@%.1fK", sign, absValue / 1000)
            } else {
                return String(format: "%@%.0f", sign, absValue)
            }
        }
        
        if absValue >= 10000000 {
            let crores = absValue / 10000000
            return String(format: "%@₹%.2f Cr", sign, crores)
        } else if absValue >= 100000 {
            let lakhs = absValue / 100000
            return String(format: "%@₹%.2f L", sign, lakhs)
        } else if absValue >= 1000 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = "₹"
            formatter.maximumFractionDigits = 0
            formatter.locale = Locale(identifier: "en_IN")
            return formatter.string(from: NSNumber(value: self)) ?? "₹0"
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = "₹"
            formatter.maximumFractionDigits = 0
            formatter.locale = Locale(identifier: "en_IN")
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
        guard self.isFinite else { return 0 }
        if self > Double(Int.max) { return Int.max }
        if self < Double(Int.min) { return Int.min }
        return Int(self)
    }
}
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
