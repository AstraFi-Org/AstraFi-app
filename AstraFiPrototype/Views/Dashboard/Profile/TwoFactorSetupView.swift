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
                            Task { await unenrollMFA() }
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
                        
                        if let uri = totpUri, let url = URL(string: uri) {
                            Button("Open in Authenticator App") {
                                UIApplication.shared.open(url)
                            }
                            .font(.headline)
                            .foregroundColor(Color(hex: "#007AFF"))
                            .padding(.top, -8)
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
    
    private func unenrollMFA() async {
        guard let factorId = factorId else { return }
        errorMessage = nil
        do {
            try await supabase.auth.mfa.unenroll(params: MFAUnenrollParams(factorId: factorId))
            isEnrolled = false
            self.factorId = nil
            successMessage = "2FA has been disabled."
            // Restart enrollment
            await checkStatusAndEnroll()
        } catch {
            errorMessage = "Failed to disable 2FA: \(error.localizedDescription)"
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
