import SwiftUI

struct AddCustomEntrySheet: View {
    let title: String
    let placeholder: String
    let accentColor: Color
    @Binding var name: String
    @Binding var value: String
    let onAdd: () -> Void
    @Environment(\.dismiss) var dismiss

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.1))
                            .frame(width: 68, height: 68)
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 34))
                            .foregroundColor(accentColor)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            TextField(placeholder, text: $name)
                                .padding(14)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .font(.system(size: 16))
                                .autocorrectionDisabled()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Value (₹)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            HStack(spacing: 0) {
                                Text("₹")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 14)
                                TextField("0", text: $value)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 16))
                                    .padding(.vertical, 14)
                                    .padding(.trailing, 14)
                                    .padding(.leading, 6)
                            }
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer()

                Button {
                    onAdd()
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                        Text("Add \(title.components(separatedBy: " ").last ?? "")")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isValid ? accentColor : Color.gray.opacity(0.4))
                    .cornerRadius(14)
                }
                .disabled(!isValid)
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationCornerRadius(20)
    }
}
#Preview {
    @Previewable @State var previewName: String = ""
    @Previewable @State var previewValue: String = ""

    return AddCustomEntrySheet(
        title: "Add Item",
        placeholder: "Enter name",
        accentColor: .green,
        name: $previewName,
        value: $previewValue,
        onAdd: {}
    )
}
