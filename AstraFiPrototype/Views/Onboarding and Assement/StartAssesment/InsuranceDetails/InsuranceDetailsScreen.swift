import SwiftUI
internal import UniformTypeIdentifiers

struct InsuranceDetailsScreen: View {
    @Bindable var data: CompleteAssessmentData
    @Environment(\.dismiss) private var dismiss
    @Environment(AppStateManager.self) private var appState
    @State private var goNext           = false
    @State private var showFilePicker    = false
    @State private var uploadedFileName: String? = nil

    private var income: Double { Double(data.income) ?? 0 }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Page header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Insurance & Protection")
                            .font(.system(size: 28, weight: .bold))
                        Text("Your coverage keeps your family and finances safe.")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 24)

                    // ── Your Insurance Status
                    sectionCard {
                        sectionHeader("Your Insurance Status")
                        Toggle("Are you insured?", isOn: $data.isInsured.animation())
                            .onChange(of: data.isInsured) { _, newValue in
                                if newValue && data.insuranceEntries.isEmpty {
                                    data.insuranceEntries.append(AssessmentInsuranceEntry())
                                }
                            }
                    }
                    .padding(.horizontal, 20)

                    // ── Policy Details
                    if data.isInsured && !data.insuranceEntries.isEmpty {
                        sectionCard {
                            sectionHeader("Your Policy Details")

                            HStack {
                                Text("Insurance Type")
                                    .font(.system(size: 16, design: .rounded))
                                Spacer()
                                Picker("", selection: $data.insuranceEntries[0].details) {
                                    Text("Life").tag(AssessmentInsuranceEntry.InsuranceDetails.life(AssessmentInsuranceEntry.LifeDetails()))
                                    Text("Health").tag(AssessmentInsuranceEntry.InsuranceDetails.health(AssessmentInsuranceEntry.HealthDetails()))
                                    Text("Critical Illness").tag(AssessmentInsuranceEntry.InsuranceDetails.criticalIllness(AssessmentInsuranceEntry.CriticalIllnessDetails()))
                                }
                                .labelsHidden()
                            }

                            Divider().opacity(0.5)

                            HStack {
                                Text("Cover Amount (₹)")
                                    .font(.system(size: 16, design: .rounded))
                                Spacer()
                                TextField("e.g. 10000000", text: $data.insuranceEntries[0].coverAmount)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 140)
                            }

                            Divider().opacity(0.5)

                            DatePicker(
                                "Policy Valid Upto",
                                selection: $data.insuranceEntries[0].expiryDate,
                                displayedComponents: .date
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // ── Dependents
                    sectionCard {
                        sectionHeader("Dependents")

                        HStack {
                            Text("Number of Dependents")
                                .font(.system(size: 16, design: .rounded))
                            Spacer()
                            TextField("e.g. 3", text: $data.numberOfDependents)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }

                        Divider().opacity(0.5)

                        Toggle("Are Dependents insured?", isOn: $data.areDependentsInsured.animation())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // ── Dependent Policy Details
                    if data.areDependentsInsured {
                        sectionCard {
                            sectionHeader("Dependent Insurance Details")

                            Button {
                                data.dependentInsuranceEntries.append(AssessmentInsuranceEntry())
                            } label: {
                                Label("Add Dependent Policy", systemImage: "plus.circle")
                                    .font(.system(size: 15, design: .rounded))
                                    .foregroundStyle(AppTheme.auraIndigo)
                            }
                            .buttonStyle(.plain)

                            ForEach($data.dependentInsuranceEntries) { $depEntry in
                                Divider().opacity(0.4)

                                HStack {
                                    Text("Dependent Policy")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Button(role: .destructive) {
                                        let idToDelete = depEntry.id
                                        data.dependentInsuranceEntries.removeAll(where: { $0.id == idToDelete })
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 13))
                                    }
                                }
                                .padding(.top, 4)

                                HStack {
                                    Text("Type")
                                        .font(.system(size: 16, design: .rounded))
                                    Spacer()
                                    Picker("", selection: $depEntry.details) {
                                        Text("Life").tag(AssessmentInsuranceEntry.InsuranceDetails.life(AssessmentInsuranceEntry.LifeDetails()))
                                        Text("Health").tag(AssessmentInsuranceEntry.InsuranceDetails.health(AssessmentInsuranceEntry.HealthDetails()))
                                    }
                                    .labelsHidden()
                                }

                                Divider().opacity(0.4)

                                HStack {
                                    Text("Cover Amount (₹)")
                                        .font(.system(size: 16, design: .rounded))
                                    Spacer()
                                    TextField("e.g. 500000", text: $depEntry.coverAmount)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 140)
                                }

                                Divider().opacity(0.4)

                                HStack {
                                    Text("Valid Upto")
                                        .font(.system(size: 16, design: .rounded))
                                    Spacer()
                                    DatePicker("", selection: $depEntry.expiryDate, displayedComponents: .date)
                                        .labelsHidden()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // ── Live Insurance Insight Card
                    InsuranceInsightCard(
                        isInsured: data.isInsured,
                        coverAmountStr: data.insuranceEntries.first?.coverAmount ?? "",
                        income: income,
                        numDependentsStr: data.numberOfDependents,
                        areDependentsInsured: data.areDependentsInsured,
                        dependentEntries: data.dependentInsuranceEntries,
                        policyDetails: data.insuranceEntries.first?.details,
                        expiryDate: data.isInsured ? data.insuranceEntries.first?.expiryDate : nil
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    Spacer().frame(height: 120)
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: data.isInsured)
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: data.areDependentsInsured)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: data.insuranceEntries.first?.coverAmount)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: data.numberOfDependents)
            .safeAreaInset(edge: .top, spacing: 0) {
                AssessmentProgressBar(progress: 0.9)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(.systemGroupedBackground))
            }

            AssessmentFooterButton(label: "See My Report", enabled: true, isLast: true) {
                // Merge dependent insurance policies into the main insuranceEntries
                // so the report and AppStateManager both see them as one unified list.
                for depEntry in data.dependentInsuranceEntries {
                    if !data.insuranceEntries.contains(where: { $0.id == depEntry.id }) {
                        data.insuranceEntries.append(depEntry)
                    }
                }
                // Persist insurance (and all other assessment) data to the profile
                // before navigating to the report so that the report always reads
                // from an up-to-date profile rather than the raw assessment object.
                appState.updateProfile(from: data)
                goNext = true
            }
        }
        .navigationTitle("Financial Assessment")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
        }
        .navigationDestination(isPresented: $goNext) {
            FinancialHealthReportView(data: data)
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.pdf, .commaSeparatedText, .spreadsheet],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                uploadedFileName = url.lastPathComponent
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 6, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.gray.opacity(0.10), lineWidth: 1)
        )
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

private typealias LifeDetails             = AssessmentInsuranceEntry.LifeDetails
private typealias HealthDetails           = AssessmentInsuranceEntry.HealthDetails
private typealias MotorDetails            = AssessmentInsuranceEntry.MotorDetails
private typealias TravelDetails           = AssessmentInsuranceEntry.TravelDetails
private typealias CriticalIllnessDetails  = AssessmentInsuranceEntry.CriticalIllnessDetails
private typealias ULIPDetails             = AssessmentInsuranceEntry.ULIPDetails

#Preview {
    @Previewable var data = CompleteAssessmentData()
    NavigationStack {
        InsuranceDetailsScreen(data: data)
    }
}
