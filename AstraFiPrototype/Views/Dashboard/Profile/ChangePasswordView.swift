import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppStateManager.self) var appState
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    // Visibility toggles
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
    
    // Success / Failure alerts
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    // Local validation checks
    private var isLengthValid: Bool {
        newPassword.count >= 6
    }
    
    private var isMatchValid: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword
    }
    
    private var isFormValid: Bool {
        isLengthValid && isMatchValid
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.orange.gradient)
                        .shadow(color: .orange.opacity(0.2), radius: 10, y: 5)
                        .padding(.top, 20)
                    
                    Text("Update Your Password")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Create a secure password to protect your financial profile and personal account details.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                // Form Fields
                VStack(spacing: 16) {
                    // New Password field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("New Password")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            if showNewPassword {
                                TextField("Enter at least 6 characters", text: $newPassword)
                                    .textContentType(.newPassword)
                            } else {
                                SecureField("Enter at least 6 characters", text: $newPassword)
                                    .textContentType(.newPassword)
                            }
                            
                            Button {
                                showNewPassword.toggle()
                            } label: {
                                Image(systemName: showNewPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                        )
                    }
                    
                    // Confirm Password field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Confirm Password")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            if showConfirmPassword {
                                TextField("Repeat your new password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                            } else {
                                SecureField("Repeat your new password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                            }
                            
                            Button {
                                showConfirmPassword.toggle()
                            } label: {
                                Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal)
                
                // Validation Indicators
                VStack(alignment: .leading, spacing: 10) {
                    Text("PASSWORD REQUIREMENTS")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        requirementRow(text: "At least 6 characters", isValid: isLengthValid)
                        requirementRow(text: "Passwords match exactly", isValid: isMatchValid)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer(minLength: 24)
                
                // Submit Button
                Button {
                    Task {
                        await handlePasswordUpdate()
                    }
                } label: {
                    HStack {
                        if appState.isAuthLoading {
                            ProgressView()
                                .tint(.white)
                                .padding(.trailing, 8)
                        }
                        Text("Update Password")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid && !appState.isAuthLoading ? Color.blue : Color.blue.opacity(0.4))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!isFormValid || appState.isAuthLoading)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if isSuccess {
                        dismiss()
                    }
                }
            )
        }
    }
    
    // UI Helpers
    private func requirementRow(text: String, isValid: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isValid ? .green : .secondary)
                .font(.system(size: 16, weight: .semibold))
            
            Text(text)
                .font(.footnote)
                .foregroundColor(isValid ? .primary : .secondary)
            
            Spacer()
        }
    }
    
    private func handlePasswordUpdate() async {
        let success = await appState.updatePassword(newPassword: newPassword)
        if success {
            isSuccess = true
            alertTitle = "Success"
            alertMessage = "Your password has been successfully updated."
            showAlert = true
        } else {
            isSuccess = false
            alertTitle = "Failed to Update"
            alertMessage = appState.authError ?? "An unexpected error occurred. Please try again."
            showAlert = true
        }
    }
}

#Preview {
    NavigationStack {
        ChangePasswordView()
            .environment(AppStateManager())
    }
}
