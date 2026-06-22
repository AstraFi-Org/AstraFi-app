import SwiftUI
import CoreImage.CIFilterBuiltins
import Supabase

struct TwoFactorSetupView: View {
    @State private var qrCodeImage: UIImage?
    @State private var factorId: String?
    @State private var verificationCode: String = ""
    @State private var isLoading = true
    @State private var isEnrolled = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var totpUri: String?
    @State private var totpSecret: String?
    @State private var isConfirmingDisable = false
    @State private var disableVerificationCode = ""
    @State private var isDisabling = false
    
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Checking MFA Status...")
                        .padding(.top, 50)
                } else if isEnrolled {
                    VStack(spacing: 20) {
                        if isConfirmingDisable {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.red)
                                .padding(.top, 40)
                            
                            Text("Confirm Disabling 2FA")
                                .font(.title2.bold())
                            
                            Text("For your security, please enter the 6-digit verification code from your authenticator app to disable Two-Factor Authentication.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            TextField("6-digit code", text: $disableVerificationCode)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .font(.title2.bold())
                                .padding()
                                .background(Color(uiColor: .secondarySystemBackground))
                                .cornerRadius(12)
                                .padding(.horizontal, 40)
                            
                            Button(role: .destructive) {
                                Task { await confirmAndUnenroll() }
                            } label: {
                                if isDisabling {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Verify and Disable")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(disableVerificationCode.count == 6 ? Color.red : Color.gray)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                            }
                            .disabled(disableVerificationCode.count != 6 || isDisabling)
                            .padding(.horizontal, 40)
                            
                            Button("Cancel") {
                                isConfirmingDisable = false
                                disableVerificationCode = ""
                                errorMessage = nil
                            }
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        } else {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.green)
                                .padding(.top, 40)
                            
                            Text("2FA is Enabled")
                                .font(.title2.bold())
                            
                            Text("Your account is secured with Authenticator-based Two-Factor Authentication.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            Button(role: .destructive) {
                                Task { await initiateUnenroll() }
                            } label: {
                                Text("Disable 2FA")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 40)
                            .padding(.top, 20)
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        Text("Set Up Two-Factor Authentication")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                            .padding(.top, 20)
                        
                        Text("1. Scan this QR code with an authenticator app (like Google Authenticator or Authy).")
                            .multilineTextAlignment(.center)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        if let qrCode = qrCodeImage {
                            Image(uiImage: qrCode)
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(radius: 2)
                        } else {
                            ProgressView()
                                .frame(width: 200, height: 200)
                        }
                        
                        if let uri = totpUri, let secret = totpSecret {
                            Menu {
                                Button("Apple Passwords") {
                                    if let url = URL(string: uri) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                Button("Google Authenticator") {
                                    if let url = URL(string: uri.replacingOccurrences(of: "otpauth://", with: "googleauthenticator://")) {
                                        UIApplication.shared.open(url) { success in
                                            if !success {
                                                errorMessage = "Google Authenticator could not be opened. You may need to copy the setup key instead."
                                            }
                                        }
                                    }
                                }
                                Button("Microsoft Authenticator") {
                                    if let url = URL(string: uri.replacingOccurrences(of: "otpauth://", with: "microsoft-authenticator://")) {
                                        UIApplication.shared.open(url) { success in
                                            if !success {
                                                errorMessage = "Microsoft Authenticator could not be opened. Please copy the setup key and enter it manually."
                                            }
                                        }
                                    }
                                }
                                Button("Copy Setup Key") {
                                    UIPasteboard.general.string = secret
                                    successMessage = "Setup key copied to clipboard!"
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text("Open in Authenticator App")
                                    Image(systemName: "chevron.down")
                                        .font(.caption.weight(.bold))
                                }
                                .font(.headline)
                                .foregroundColor(Color(hex: "#007AFF"))
                                .padding(.top, -8)
                            }
                        }
                        
                        if let secret = totpSecret {
                            VStack(spacing: 4) {
                                Text("Or enter setup key manually:")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                Button {
                                    UIPasteboard.general.string = secret
                                } label: {
                                    HStack {
                                        Text(secret)
                                            .font(.system(.subheadline, design: .monospaced).bold())
                                        Image(systemName: "doc.on.doc")
                                            .font(.caption)
                                    }
                                }
                                .foregroundColor(.primary)
                                .padding(8)
                                .background(Color(uiColor: .systemGray5))
                                .cornerRadius(6)
                            }
                            .padding(.top, 4)
                        }
                        
                        Text("2. Enter the 6-digit code from your app below.")
                            .multilineTextAlignment(.center)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        TextField("6-digit code", text: $verificationCode)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.title2.bold())
                            .padding()
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal, 40)
                        
                        Button {
                            Task { await verifyAndCompleteSetup() }
                        } label: {
                            Text("Verify and Enable")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(verificationCode.count == 6 ? Color(hex: "#007AFF") : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(verificationCode.count != 6)
                        .padding(.horizontal, 40)
                    }
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding()
                }
                
                if let success = successMessage {
                    Text(success)
                        .font(.footnote)
                        .foregroundColor(.green)
                        .padding()
                }
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("Two-Factor Auth")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .task {
            await checkStatusAndEnroll()
        }
    }
    
    private func checkStatusAndEnroll() async {
        isLoading = true
        errorMessage = nil
        do {
            let factors = try await supabase.auth.mfa.listFactors()
            if let verifiedFactor = factors.all.first(where: { $0.status == FactorStatus.verified }) {
                self.factorId = verifiedFactor.id
                self.isEnrolled = true
            } else {
                // Delete unverified factors to avoid name conflict
                let unverified = factors.all.filter { $0.status == FactorStatus.unverified }
                for factor in unverified {
                    try? await supabase.auth.mfa.unenroll(params: MFAUnenrollParams(factorId: factor.id))
                }
                
                let enrollment = try await supabase.auth.mfa.enroll(params: MFAEnrollParams(issuer: "AstraFi", friendlyName: "AstraFi-\(UUID().uuidString.prefix(4))"))
                self.factorId = enrollment.id
                self.totpUri = enrollment.totp?.uri
                self.totpSecret = enrollment.totp?.secret
                self.qrCodeImage = generateQRCode(from: enrollment.totp?.uri ?? "")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    private func verifyAndCompleteSetup() async {
        guard let factorId = factorId else { return }
        errorMessage = nil
        do {
            let challenge = try await supabase.auth.mfa.challenge(params: MFAChallengeParams(factorId: factorId))
            _ = try await supabase.auth.mfa.verify(params: MFAVerifyParams(factorId: factorId, challengeId: challenge.id, code: verificationCode))
            
            isEnrolled = true
            successMessage = "2FA has been successfully enabled."
            verificationCode = ""
        } catch {
            errorMessage = "Verification failed: \(error.localizedDescription)"
        }
    }
    
    private func initiateUnenroll() async {
        guard let factorId = factorId else { return }
        errorMessage = nil
        do {
            let aal = try await supabase.auth.mfa.getAuthenticatorAssuranceLevel()
            if aal.currentLevel == "aal1" {
                await MainActor.run {
                    self.isConfirmingDisable = true
                }
            } else {
                await MainActor.run {
                    self.isDisabling = true
                }
                try await supabase.auth.mfa.unenroll(params: MFAUnenrollParams(factorId: factorId))
                _ = try? await supabase.auth.refreshSession()
                await MainActor.run {
                    self.isEnrolled = false
                    self.factorId = nil
                    self.isDisabling = false
                    dismiss()
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to disable 2FA: \(error.localizedDescription)"
                self.isDisabling = false
            }
        }
    }
    
    private func confirmAndUnenroll() async {
        guard let factorId = factorId else { return }
        errorMessage = nil
        await MainActor.run { isDisabling = true }
        do {
            let challenge = try await supabase.auth.mfa.challenge(params: MFAChallengeParams(factorId: factorId))
            _ = try await supabase.auth.mfa.verify(params: MFAVerifyParams(factorId: factorId, challengeId: challenge.id, code: disableVerificationCode))
            
            try await supabase.auth.mfa.unenroll(params: MFAUnenrollParams(factorId: factorId))
            _ = try? await supabase.auth.refreshSession()
            
            await MainActor.run {
                isEnrolled = false
                self.factorId = nil
                self.isConfirmingDisable = false
                self.disableVerificationCode = ""
                isDisabling = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Verification or disabling failed: \(error.localizedDescription)"
                isDisabling = false
            }
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            if let cgimg = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}
