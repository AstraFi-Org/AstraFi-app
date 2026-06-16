import SwiftUI

struct CompanyAnalyzerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var fundName: String = ""
    @State private var fundType: String = "Equity Mutual Fund"
    @State private var analysisQuery: String = ""
    @State private var showResultView = false
    @State private var isAnalyzing = false

    let fundTypes = [
        "Equity Mutual Fund",
        "Debt Mutual Fund",
        "Hybrid Fund",
        "Index Fund",
        "ETF",
        "Stock"
    ]

    let queryOptions = [
        "How's the fund making progress",
        "What are the returns?",
        "Is it safe to invest?",
        "Compare with similar funds",
        "Check fund manager performance"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    headerSection
                    formSection
                    analyzeButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Company Analyzer")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.body)
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .background(AppTheme.appBackground(for: colorScheme))
            .navigationDestination(isPresented: $showResultView) {
                FundAnalysisResultView(
                    fundName: fundName.isEmpty ? "ICICI Prudential Fund" : fundName,
                    fundType: fundType
                )
            }
        }
    }

    private var headerSection: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.accentColor)
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)

                Image(systemName: "building.2.fill")
                    .foregroundColor(.white)
                    .font(.title2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Analyze any company")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text("Get detailed insights and analysis")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    private var formSection: some View {
        VStack(spacing: 24) {

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text.fill")
                        .font(.caption)
                        .foregroundColor(.cyan)
                    Text("Fund Name")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }

                TextField("ICICI Prudential Fund", text: $fundName)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                fundName.isEmpty ? Color.gray.opacity(0.2) : .cyan.opacity(0.4),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.04), radius: 8, x: 0, y: 2)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Fund Type")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }

                Menu {
                    ForEach(fundTypes, id: \.self) { type in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                fundType = type
                            }
                        }) {
                            HStack {
                                Text(type)
                                if fundType == type {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(fundType)
                            .font(.body)
                            .foregroundColor(.primary)

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.04), radius: 8, x: 0, y: 2)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.caption)
                        .foregroundColor(.purple)
                    Text("What you are looking for?")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }

                Menu {
                    ForEach(queryOptions, id: \.self) { query in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                analysisQuery = query
                            }
                        }) {
                            Text(query)
                        }
                    }
                } label: {
                    HStack {
                        Text(analysisQuery.isEmpty ? "How's the fund making progress" : analysisQuery)
                            .font(.body)
                            .foregroundColor(analysisQuery.isEmpty ? .secondary : .primary)
                            .lineLimit(1)

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.04), radius: 8, x: 0, y: 2)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var analyzeButton: some View {
        Button(action: {
            isAnalyzing = true
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isAnalyzing = false
                    showResultView = true
                }
            }
        }) {
            HStack(spacing: 12) {
                if isAnalyzing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }

                Text(isAnalyzing ? "Analyzing..." : "Provide Analysis")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.accentColor)
            .cornerRadius(14)
            .shadow(color: Color.accentColor.opacity(colorScheme == .dark ? 0.5 : 0.4), radius: 12, x: 0, y: 6)
        }
        .disabled(isAnalyzing)
        .padding(.top, 12)
    }
}

#Preview {
    CompanyAnalyzerView()
}
