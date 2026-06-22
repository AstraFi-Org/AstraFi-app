import AuthenticationServices

/// A lightweight delegate for ASAuthorizationController that forwards
/// the result back via a closure so AppStateManager can handle it.
final class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, @unchecked Sendable {
    private let completion: @Sendable (Result<ASAuthorization, Error>) -> Void

    init(completion: @escaping @Sendable (Result<ASAuthorization, Error>) -> Void) {
        self.completion = completion
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        completion(.success(authorization))
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        completion(.failure(error))
    }
}
