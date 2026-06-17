import SwiftUI

struct MFAChallengeView: View {
    @Environment(AppStateManager.self) var appState
    @State private var code: String = ""
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color(hex: "#007AFF"))
                .padding(.top, 40)
            
            Text("Two-Factor Authentication")
                .font(.title2.bold())
            
            Text("Please enter the 6-digit code from your authenticator app to continue.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            TextField("6-digit code", text: $code)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.title.bold())
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 40)
            
            if let error = errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            
            Button {
                Task {
                    let success = await appState.completeMFA(code: code)
                    if !success {
                        errorMessage = appState.authError ?? "Invalid code. Please try again."
                    }
                }
            } label: {
                HStack {
                    Spacer()
                    if appState.isAuthLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Verify")
                            .font(.headline)
                    }
                    Spacer()
                }
                .padding()
                .background(code.count == 6 ? Color(hex: "#007AFF") : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(code.count != 6 || appState.isAuthLoading)
            .padding(.horizontal, 40)
            
            Spacer()
            
            Button("Cancel") {
                Task { await appState.signOut() }
            }
            .padding(.bottom, 20)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
    }
}
