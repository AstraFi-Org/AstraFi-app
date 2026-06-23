import AuthenticationServices

import UIKit

/// A lightweight delegate for ASAuthorizationController that forwards
/// the result back via a closure so AppStateManager can handle it.
final class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding, @unchecked Sendable {
    private let completion: @Sendable (Result<ASAuthorization, Error>) -> Void

    init(completion: @escaping @Sendable (Result<ASAuthorization, Error>) -> Void) {
        self.completion = completion
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        print("AppleSignInDelegate: didCompleteWithAuthorization success")
        completion(.success(authorization))
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        print("AppleSignInDelegate: didCompleteWithError: \(error.localizedDescription) (code: \((error as NSError).code))")
        completion(.failure(error))
    }

    @MainActor
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
            ?? scenes.first as? UIWindowScene
        
        let window = windowScene?.windows.first { $0.isKeyWindow }
            ?? windowScene?.windows.first
            ?? UIApplication.shared.windows.first { $0.isKeyWindow }
            ?? UIApplication.shared.windows.first
            ?? UIWindow()
            
        return window
    }
}
