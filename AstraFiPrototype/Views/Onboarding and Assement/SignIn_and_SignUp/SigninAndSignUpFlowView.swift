import SwiftUI

struct AuthenticationFlowView: View {
    @State private var showSignUp: Bool = false

    var body: some View {
        if showSignUp {
            SignUpView(showSignUp: $showSignUp)
        } else {
            SignInView(showSignUp: $showSignUp)
        }
    }
}



#Preview {
    NavigationStack {
        AuthenticationFlowView()
            .environment(AppStateManager())
    }
}
