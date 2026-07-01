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
        let windowScene = scenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
            ?? scenes.first as? UIWindowScene
        
        if let windowScene = windowScene {
            if let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first {
                return window
            }
            return UIWindow(windowScene: windowScene)
        }
        
        if let fallbackScene = scenes.compactMap({ $0 as? UIWindowScene }).first {
            if let window = fallbackScene.windows.first(where: { $0.isKeyWindow }) ?? fallbackScene.windows.first {
                return window
            }
            return UIWindow(windowScene: fallbackScene)
        }
        
        return UIWindow(frame: .zero)
    }
}
