import SwiftUI

struct ProfileSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(20)
            .padding(.horizontal)
            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        }
    }
}

struct ProfileMenuLink<Destination: View>: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var iconColor: Color = .blue
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                if let icon = icon {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(iconColor.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(iconColor)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

struct SetuLoanBanner: View {
    var body: some View {
        HStack {
            Image(systemName: "link.circle.fill").foregroundColor(.red)
            VStack(alignment: .leading) {
                Text("Linked via Setu")
                    .font(.subheadline).fontWeight(.semibold)
                Text("Your loans are automatically tracked and cannot be edited manually.")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            ProfileSection(title: "FINANCIAL ASSETS") {
                ProfileMenuLink(
                    title: "Investments",
                    subtitle: "2 active funds",
                    icon: "chart.pie.fill",
                    iconColor: .blue,
                    destination: Text("Investments Destination")
                )
                Divider().padding(.leading, 68)
                ProfileMenuLink(
                    title: "Insurance",
                    subtitle: "3 active policies",
                    icon: "shield.fill",
                    iconColor: .blue,
                    destination: Text("Insurance Destination")
                )
            }
            .padding(.top)

            ProfileSection(title: "EXTERNAL DATA") {
                SetuLoanBanner()
                    .padding(.horizontal)
            }
            .padding(.top)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
}
