import SwiftUI
internal import UniformTypeIdentifiers

struct InsuranceDetailsScreen: View {
    @Bindable var data: CompleteAssessmentData
    @Environment(\.dismiss) private var dismiss
    @State private var goNext           = false
    @State private var showFilePicker    = false
    @State private var uploadedFileName: String? = nil

    private var helpText: String {
        var base = "Reviewing your insurance coverage ensures you and your family are adequately protected.\n\n• Add-on/Rider Cost: Extra fee for additional benefits (like accidental death or critical illness) added to a base policy."
        
        let types = Set(data.insuranceEntries.map { $0.currentType })
        
        if types.contains(.health) {
            base += "\n\n• Health Insurance: Covers medical expenses. Can be Individual or Family Floater (covering multiple family members)."
        }
        if types.contains(.life) || types.contains(.term) || types.contains(.ulip) {
            base += "\n\n• Term Life: High coverage at low cost for a fixed period.\n\n• Endowment: Combines protection and savings.\n\n• ULIP: Market-linked investment + insurance."
        }
        if types.contains(.motor) {
            base += "\n\n• Motor Insurance: Mandatory coverage for vehicles against damage, theft, and third-party liability."
        }
        if types.contains(.criticalIllness) {
            base += "\n\n• Critical Illness: Pays a lumpsum on diagnosis of specific major diseases."
        }
        
        return base
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                AssessmentProgressHeader(progress: 0.9, title: "Insurance & Protection", subtitle: "Your coverage keeps your family and finances safe.")
                    .padding(.top, 16).padding(.horizontal, 20).padding(.bottom, 12)

                Form {
                    Section(header: Text("Your Insurance Status")) {
                        Toggle("Are you insured?", isOn: $data.isInsured.animation())
                            .onChange(of: data.isInsured) { _, newValue in
                                if newValue && data.insuranceEntries.isEmpty {
                                    data.insuranceEntries.append(AssessmentInsuranceEntry())
                                }
                            }
                    }

                    if data.isInsured && !data.insuranceEntries.isEmpty {
                        Section("Your Policy Details") {
                            
                            Picker("Insurance Type", selection: $data.insuranceEntries[0].details) {
                                Text("Life").tag(AssessmentInsuranceEntry.InsuranceDetails.life(AssessmentInsuranceEntry.LifeDetails()))
                                Text("Health").tag(AssessmentInsuranceEntry.InsuranceDetails.health(AssessmentInsuranceEntry.HealthDetails()))
                                Text("Critical Illness").tag(AssessmentInsuranceEntry.InsuranceDetails.criticalIllness(AssessmentInsuranceEntry.CriticalIllnessDetails()))
                            }
//                            AssessmentField(
//                                icon: "indianrupeesign",
//                                label: "Cover Amount",
//                                placeholder: "e.g. 45000",
//                                text: $data.insuranceEntries[0].coverAmount
//                            )
                            HStack(spacing:90){
                                Text("Cover Amount")
                                
                                TextField("Cover Amount (₹)", text: $data.insuranceEntries[0].coverAmount)
                                    .keyboardType(.numberPad)
                            }

                            DatePicker("Policy Valid Upto", selection: $data.insuranceEntries[0].expiryDate, displayedComponents: .date)
                        }
                    }

                    Section("Dependents") {
//                        AssessmentField(
//                            icon: "person.2",
//                            label: "Number of dependents",
//                            placeholder: "e.g. 3",
//                            text: $data.numberOfDependents
//                        )
//                        .listRowBackground(Color.clear)
                        HStack {
                            Text("Number of Dependents")

                            Spacer()

                            TextField("e.g. 3", text: $data.numberOfDependents)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                        Toggle("Are Dependents insured?", isOn: $data.areDependentsInsured.animation())
                    }
                    
                    if data.areDependentsInsured {
                        Section("Dependent Insurance Details") {
                            Button {
                                data.dependentInsuranceEntries.append(AssessmentInsuranceEntry())
                            } label: {
                                Label("Add Dependent Policy", systemImage: "plus.circle")
                            }
                            ForEach($data.dependentInsuranceEntries) { $depEntry in
                                
                                // Header row
                                HStack {
                                    Text("Dependent Policy")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.secondary)

                                    Spacer()

                                    Button(role: .destructive) {
                                        let idToDelete = depEntry.id
                                        data.dependentInsuranceEntries.removeAll(where: { $0.id == idToDelete })
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }

                                // Type row
                                HStack {
                                    Text("Type")
                                    Spacer()
                                    Picker("", selection: $depEntry.details) {
                                        Text("Life").tag(AssessmentInsuranceEntry.InsuranceDetails.life(AssessmentInsuranceEntry.LifeDetails()))
                                        Text("Health").tag(AssessmentInsuranceEntry.InsuranceDetails.health(AssessmentInsuranceEntry.HealthDetails()))
                                    }
                                    .labelsHidden()
                                }

                                // Cover amount row
                                HStack {
                                    Text("Cover Amount")
                                    Spacer()
                                    TextField("Cover Amount (₹)", text: $depEntry.coverAmount)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                }

                                // Date row
                                HStack {
                                    Text("Valid Upto")
                                    Spacer()
                                    DatePicker(
                                        "",
                                        selection: $depEntry.expiryDate,
                                        displayedComponents: .date
                                    )
                                    .labelsHidden()
                                }
                            }
                        }
                    }
                    
                    Color.clear.frame(height: 100).listRowBackground(Color.clear)
                }
            }
            AssessmentFooterButton(label: "See My Report", enabled: true, isLast: true) {
                //if let onComplete { onComplete() } else { goNext = true }
                goNext = true
            }
        }
        .navigationTitle("Financial Assessment")
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
