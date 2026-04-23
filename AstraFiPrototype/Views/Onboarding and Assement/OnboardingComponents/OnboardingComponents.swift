//keep if further any components wants to add

import SwiftUI
import PhotosUI

var brandGradient: LinearGradient {
    LinearGradient(
        colors: [
            .blue,
            .blue
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}
//struct StepBadge: View {
//    let current: Int
//    let total: Int
//    let title: String
//    let helpText: String?
//
//    @State private var showHelp = false
//
//    init(current: Int, total: Int, title: String, helpText: String? = nil) {
//        self.current = current
//        self.total = total
//        self.title = title
//        self.helpText = helpText
//    }
//
//    var body: some View {
//        HStack(spacing: 12) {
//            ZStack {
//                Circle()
//                    .fill(.blue)
//                    .frame(width: 36, height: 36)
//                Text("\(current)").font(.headline).fontWeight(.bold).foregroundStyle(.white)
//            }
//            VStack(alignment: .leading, spacing: 1) {
//                Text(title).font(.title3).fontWeight(.bold).foregroundStyle(.primary)
//                Text("Step \(current) of \(total)").font(.caption).foregroundStyle(.secondary)
//            }
//            Spacer()
//            
//            if let helpText = helpText {
//                Button {
//                    showHelp = true
//                } label: {
//                    Image(systemName: "info.circle")
//                        .font(.title3)
//                        .foregroundStyle(.blue)
//                        .padding(8)
//                        .background(Circle().fill(.blue.opacity(0.1)))
//                }
//                .alert("Information", isPresented: $showHelp) {
//                    Button("Got it", role: .cancel) { }
//                } message: {
//                    Text(helpText)
//                }
//            }
//        }
//    }
//}
//
//struct FormCard<Content: View>: View {
//    private let content: Content
//
//    init(@ViewBuilder content: () -> Content) {
//        self.content = content()
//    }
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 14) {
//            content
//        }
//        .padding(18)
//        .background(AppTheme.cardBackground)
//        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
//        .shadow(
//            color: AppTheme.adaptiveShadow,
//            radius: 8,
//            x: 0,
//            y: 2
//        )
//        .padding(.horizontal, 16)
//        .padding(.top, 10)
//    }
//}
//
//struct CardHeader: View {
//    let icon: String
//    let title: String
//    var body: some View {
//        HStack(spacing: 8) {
//            Image(systemName: icon).font(.subheadline).fontWeight(.semibold).foregroundStyle(.blue)
//            Text(title).font(.subheadline).fontWeight(.semibold).foregroundStyle(.primary)
//        }
//    }
//}
//
//struct NativeField: View {
//    let label: String
//    let placeholder: String
//    @Binding var text: String
//    var keyboard: UIKeyboardType = .default
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 5) {
//            Text(label).font(.footnote).foregroundStyle(.primary).tracking(0.4)
//            TextField(placeholder, text: $text)
//                .keyboardType(keyboard)
//                .font(.body)
//                .padding(.vertical, 10)
//                .padding(.horizontal, 12)
//                .background(Color.tableHeaderBackground)
//                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
//        }
//    }
//}
//
//struct StepperLabel: View {
//    let label: String
//    let count: Int
//    var body: some View {
//        HStack(spacing: 0) {
//            Text(label).font(.subheadline).foregroundStyle(.primary)
//            Spacer()
//            Text("\(count)").font(.headline).fontWeight(.bold).foregroundStyle(.blue).frame(minWidth: 28, alignment: .trailing).padding(.trailing, 8)
//        }
//    }
//}
//
//struct Hint: View {
//    let text: String
//    init(_ text: String) { self.text = text }
//    var body: some View {
//        Text(text).font(.caption).foregroundStyle(.secondary).lineSpacing(3)
//    }
//}
//
//struct CustomDivider: View {
//    var body: some View {
//        Divider().padding(.vertical, 2)
//    }
//}
//
struct UploadDropZone: View {
    let fileName: String?
    var placeholderText: String = "Tap to upload PDF"
    var supportText: String = "Supports: PDF only"
    var changeFileText: String = "Tap to change file"
    var action: (() -> Void)? = nil

    @State private var isPressed = false

    private let green = Color.blue

    var body: some View {
        Button {
            action?()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        green.opacity(isPressed ? 0.8 : 0.4),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(green.opacity(isPressed ? 0.10 : 0.05))
                    )
                    .frame(height: 110)

                VStack(spacing: 8) {
                    Image(systemName: fileName == nil ? "arrow.down.doc.fill" : "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(green.opacity(0.75))

                    Text(fileName == nil ? placeholderText : fileName!)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(green.opacity(0.85))

                    Text(fileName == nil ? supportText : changeFileText)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        ._onButtonGesture(pressing: { isPressed = $0 }, perform: {})
    }
}
//
//struct OrDivider: View {
//    var text: String = "or"
//    var body: some View {
//        HStack(spacing: 12) {
//            Rectangle().fill(Color.tableBorder).frame(height: 1)
//            Text(text).font(.footnote).fontWeight(.medium).foregroundStyle(.secondary).padding(.horizontal, 4)
//            Rectangle().fill(Color.tableBorder).frame(height: 1)
//        }
//        .padding(.horizontal, 24).padding(.vertical, 6)
//    }
//}
//
//
//
//#Preview {
//    struct PreviewWrapper: View {
//        @State private var text = ""
//        @State private var date = Date()
//
//        var body: some View {
//            ScrollView {
//                VStack(spacing: 20) {
//                    StepBadge(current: 1, total: 4, title: "Basic Details")
//
//                    FormCard {
//                        CardHeader(icon: "person.fill", title: "Personal Info")
//                        NativeField(label: "Full Name", placeholder: "e.g. Rahul Sharma", text: $text)
//                        CustomDivider()
//                        StepperLabel(label: "Adult dependents", count: 2)
//                        Hint("This is a hint for the user.")
//                    }
//
//                    OrDivider()
//
//                    FormCard {
//                        UploadDropZone(fileName: nil)
//                        UploadDropZone(fileName: "statement.pdf")
//                    }
//
////                    FormCard {
////                        HStack(spacing: 0) {
////                            SummaryTile(label: "Total Cover", value: "₹50L", icon: "shield.fill", color: .blue)
////                            SummaryTile(label: "Policies", value: "3", icon: "doc.text.fill", color: .blue)
////                        }
////                    }
//
////                    SingleNavFooter(isLast: false, onNext: {})
//                }
//                .padding(.vertical)
//            }
//            .background(Color(.systemGroupedBackground))
//        }
//    }
//    return PreviewWrapper()
//}
