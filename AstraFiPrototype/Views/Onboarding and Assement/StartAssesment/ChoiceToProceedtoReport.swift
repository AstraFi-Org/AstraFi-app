//import SwiftUI
//
//struct ChoiceToReport: View {
//    @Bindable var data: CompleteAssessmentData
//    @Environment(\.dismiss) private var dismiss
//
//    @State private var goDeep = false
//    @State private var goReport = false
//
//    var body: some View {
//        VStack(spacing: 0) {
//
//            // MARK: Header
//            VStack(spacing: 16) {
//
//                AssessmentProgressBar(progress: 0.5)
//                //Spacer()
//                VStack(spacing: 6) {
//                    Text("How would you like to continue?")
//                        .font(.title2.weight(.bold))
//                        .multilineTextAlignment(.center)
//
//                    Text("Adding more details improves your report accuracy.")
//                        .font(.subheadline)
//                        .foregroundStyle(.secondary)
//                        .multilineTextAlignment(.center)
//                }
//            }
//            .padding(.horizontal, 20)
//            .padding(.top, 16)
//
//            Spacer().frame(height: 24)
//
//            // MARK: Options
//            VStack(spacing: 14) {
//
//                // PRIMARY OPTION
//                Button {
//                    goDeep = true
//                } label: {
//                    HStack(spacing: 14) {
//
//                        Image(systemName: "sparkles")
//                            .font(.title3)
//                            .foregroundColor(AppTheme.auraIndigo)
//                            .frame(width: 36, height: 36)
//                            .background(AppTheme.auraIndigo.opacity(0.15))
//                            .clipShape(RoundedRectangle(cornerRadius: 10))
//
//                        VStack(alignment: .leading, spacing: 2) {
//                            HStack {
//                                Text("Add More Details")
//                                    .font(.headline)
//
//                                Spacer()
//
//                                Text("Recommended")
//                                    .font(.caption2.weight(.semibold))
//                                    .padding(.horizontal, 6)
//                                    .padding(.vertical, 3)
//                                    .background(AppTheme.auraIndigo.opacity(0.15))
//                                    .foregroundColor(AppTheme.auraIndigo)
//                                    .cornerRadius(5)
//                            }
//
//                            Text("Investments, loans & insurance")
//                                .font(.subheadline)
//                                .foregroundColor(.secondary)
//
//                            Text("Takes ~2–3 min")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                        }
//
//                        Image(systemName: "chevron.right")
//                            .foregroundColor(.secondary)
//                    }
//                    .padding()
//                    .background(Color(.systemBackground))
//                    .clipShape(RoundedRectangle(cornerRadius: 14))
//                    .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
//                }
//                .buttonStyle(.plain)
//                // SECONDARY OPTION
//                Button {
//                    goReport = true
//                } label: {
//                    HStack(spacing: 14) {
//
//                        Image(systemName: "chart.line.uptrend.xyaxis")
//                            .font(.title3)
//                            .foregroundColor(AppTheme.auraGreen)
//                            .frame(width: 36, height: 36)
//                            .background(AppTheme.auraGreen.opacity(0.15))
//                            .clipShape(RoundedRectangle(cornerRadius: 10))
//
//                        VStack(alignment: .leading, spacing: 2) {
//                            Text("See My Report")
//                                .font(.headline)
//
//                            Text("Based on current inputs")
//                                .font(.subheadline)
//                                .foregroundColor(.secondary)
//                        }
//
//                        Spacer()
//
//                        Image(systemName: "chevron.right")
//                            .foregroundColor(.secondary)
//                    }
//                    .padding()
//                    .background(Color(.systemBackground))
//                    .clipShape(RoundedRectangle(cornerRadius: 14))
//                }
//                .buttonStyle(.plain)
//            }
//            .padding(.horizontal, 20)
//            Spacer()
//        }
//        .background(Color(.systemGroupedBackground).ignoresSafeArea())
//        .navigationTitle("Financial Assessment")
//        .navigationBarTitleDisplayMode(.inline)
//        .navigationBarBackButtonHidden(true)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarLeading) {
//                Button { dismiss() } label: {
//                    Image(systemName: "chevron.left")
//                        .fontWeight(.semibold)
//                }
//            }
//        }
//        .navigationDestination(isPresented: $goDeep) {
//            InvestmentDetailsScreen(data: data)
//        }
//        .navigationDestination(isPresented: $goReport) {
//            FinancialHealthReportView(data: data)
//        }
//    }
//}
//#Preview {
//    @Previewable var data = CompleteAssessmentData()
//
//    NavigationStack {
//        ChoiceToReport(data: data)
//    }
//}
