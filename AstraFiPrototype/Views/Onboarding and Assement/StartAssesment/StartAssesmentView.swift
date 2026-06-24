import SwiftUI

enum AssessmentFlowMode {
    case onboarding
    case update
}

struct StartAssesmentView: View {
    @Environment(AppStateManager.self) var appState
    private let mode: AssessmentFlowMode
    @State private var data: CompleteAssessmentData

    init(mode: AssessmentFlowMode = .onboarding, prefilledData: CompleteAssessmentData? = nil) {
        self.mode = mode
        _data = State(initialValue: prefilledData ?? CompleteAssessmentData())
    }

    var body: some View {
        NavigationStack {
            BasicDetailView(data: data, mode: mode)
        }
    }
}

#Preview {
    StartAssesmentView()
        .environment(AppStateManager.withSampleData())
}
