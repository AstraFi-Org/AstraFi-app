import SwiftUI

// MARK: - Enums
public enum InvestmentMode: String, CaseIterable {
    case sip = "Monthly SIP"
    case lumpsum = "One-time"
    case hybrid = "SIP + Lumpsum"
}
public enum LiquidityLevel: String, CaseIterable {
    case high = "High"; case medium = "Medium"; case low = "Low"
}
public enum RiskLevel: String, CaseIterable {
    case low = "Low"; case mid = "Moderate"; case high = "High"
}

func fmtL(_ v: Double) -> String {
    let val = abs(v)
    if val >= 10000000 { return String(format: "%.1fCr", v / 10000000) }
    if val >= 100000 { return String(format: "%.1fL", v / 100000) }
    if val >= 1000 { return String(format: "%.1fK", v / 1000) }
    return String(format: "%.0f", v)
}

// MARK: - Reusable Form Components

public extension View {
    func cardStyle() -> some View {
        self.padding(18)
            .background(AppTheme.cardBackground)
            .cornerRadius(20)
            .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 5)
    }
}

struct PlanSliderStepper: View {
    @Binding var value: Int
    var range: ClosedRange<Int>
    var unit: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(value) \(unit)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                Spacer()
            }
            
            Slider(value: Binding(
                get: { Double(value) },
                set: { value = Int($0) }
            ), in: Double(range.lowerBound)...Double(range.upperBound), step: 1.0)
            .accentColor(.blue)
        }
    }
}

struct GoalAmountField: View {
    var label: String = ""
    @Binding var text: String
    var placeholder: String = ""
    
    var body: some View {
        TextField(placeholder, text: Binding(
            get: { text },
            set: { newValue in
                let expanded = InvestmentPlannerEngine.expandAmountSuffix(newValue)
                text = expanded
            }
        ))
        .keyboardType(.numbersAndPunctuation)
        .multilineTextAlignment(.trailing)
        .font(.system(size: 15, weight: .semibold, design: .rounded))
    }
}

struct PlanSegmentChips: View {
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        PlanFlowLayout(spacing: 8) {
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                } label: {
                    Text(option)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selection == option ? Color.blue : AppTheme.elevatedCardBackground)
                        .foregroundColor(selection == option ? .white : .primary)
                        .cornerRadius(20)
                }
            }
        }
    }
}

struct PlanEnumSegmentChips<T: Hashable & RawRepresentable>: View where T.RawValue == String {
    @Binding var selection: T
    let options: [T]
    
    var body: some View {
        PlanFlowLayout(spacing: 8) {
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                } label: {
                    Text(option.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selection == option ? Color.blue : AppTheme.elevatedCardBackground)
                        .foregroundColor(selection == option ? .white : .primary)
                        .cornerRadius(20)
                }
            }
        }
    }
}

struct PlanStackedChips: View {
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        PlanFlowLayout(spacing: 8) {
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                } label: {
                    Text(option)
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selection == option ? Color.blue : AppTheme.elevatedCardBackground)
                        .foregroundColor(selection == option ? .white : .primary)
                        .cornerRadius(10)
                }
            }
        }
    }
}

struct PlanMenuPicker: View {
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        Menu {
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { Text($0).tag($0) }
            }
        } label: {
            HStack {
                Text(selection)
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppTheme.elevatedCardBackground)
            .cornerRadius(12)
        }
    }
}

struct PlanAssetRow: View {
    let mentality: InvestmentMentality
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: mentality.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 40, height: 40)
                    .background(isSelected ? Color.blue : AppTheme.elevatedCardBackground)
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(mentality.rawValue)
                        .font(.system(size: 15, weight: .bold))
                    Text("\(Int(mentality.avgGrowthRate))% Expected Return")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(12)
            .background(isSelected ? Color.blue.opacity(0.05) : Color.clear)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LabeledField<Content: View>: View {
    let label: String
    let icon: String
    var note: String? = nil
    let content: Content
    
    init(label: String, icon: String, note: String? = nil, @ViewBuilder content: () -> Content) {
        self.label = label
        self.icon = icon
        self.note = note
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.system(size: 14, weight: .bold))
                Text(label)
                    .font(.system(size: 14, weight: .bold))
                Spacer()
            }
            
            content
            
            if let note = note {
                Text(note)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
    }
}

struct PlanDivider: View {
    var body: some View {
        Divider().padding(.vertical, 8)
    }
}

struct ProfileBanner: View {
    let icon: String
    let text: String
    let note: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(note)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(AppTheme.elevatedCardBackground.opacity(0.4))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Flow Layout
struct PlanFlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var maxWidth: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width {
                totalHeight += lineHeight + spacing
                currentX = 0
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxWidth = max(maxWidth, currentX)
        }
        totalHeight += lineHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX {
                currentY += lineHeight + spacing
                currentX = bounds.minX
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
    }
}
//// MARK: - Shared Card Wrapper
struct SectionCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(18)
            .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: AppTheme.adaptiveShadow, radius: 12, x: 0, y: 4)
    }
}

// MARK: - Shared Section Header
struct SectionHeader2: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }
}

// MARK: - Extensions
extension Int {
    var formattedWithComma: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
