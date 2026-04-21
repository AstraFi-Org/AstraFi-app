import SwiftUI

struct StartAssesmentView: View {
    @Environment(AppStateManager.self) var appState
    @State private var data = CompleteAssessmentData()

    var body: some View {
        NavigationStack {
            BasicDetailView(data: data)
        }
    }
}

#Preview {
    StartAssesmentView()
        .environment(AppStateManager.withSampleData())
}
