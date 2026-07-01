import SwiftUI

enum AssessmentFlowMode {
    case onboarding
    case update
}

struct StartAssesmentView: View {
    @Environment(AppStateManager.self) var appState
    private let mode: AssessmentFlowMode
    private let onSaveComplete: () -> Void
    @State private var data: CompleteAssessmentData

    init(
        mode: AssessmentFlowMode = .onboarding,
        prefilledData: CompleteAssessmentData? = nil,
        onSaveComplete: @escaping () -> Void = {}
    ) {
        self.mode = mode
        self.onSaveComplete = onSaveComplete
        _data = State(initialValue: prefilledData ?? CompleteAssessmentData())
    }

    var body: some View {
        NavigationStack {
            BasicDetailView(data: data, mode: mode, onSaveComplete: onSaveComplete)
        }
    }
}

#Preview {
    StartAssesmentView()
        .environment(AppStateManager.withSampleData())
}
