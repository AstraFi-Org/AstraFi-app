import Foundation

enum UpstoxServiceError: LocalizedError {
    case missingConfiguration
    case invalidAuthorizationURL
    case invalidResponse
    case authenticationFailed(String)
    case expiredToken
    case networkUnavailable
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Add your Upstox API key, secret, and redirect URI in APIConfig before connecting."
        case .invalidAuthorizationURL:
            return "Could not create the Upstox authorization URL."
        case .invalidResponse:
            return "Upstox returned an invalid response."
        case .authenticationFailed(let message):
            return message
        case .expiredToken:
            return "Your Upstox session expired. Please reconnect your account."
        case .networkUnavailable:
            return "No internet connection. Check your network and try again."
        case .serverError(let code):
            return "Upstox request failed with status \(code)."
        }
    }
}

struct UpstoxService {
    static let shared = UpstoxService()

    private let tokenService = "com.astrafi.upstox"
    private let accessTokenAccount = "accessToken"
    private let authorizationBaseURL = URL(string: "https://api.upstox.com/v2/login/authorization/dialog")!
    private let tokenURL = URL(string: "https://api.upstox.com/v2/login/authorization/token")!
    private let profileURL = URL(string: "https://api.upstox.com/v2/user/profile")!
    private let holdingsURL = URL(string: "https://api.upstox.com/v2/portfolio/long-term-holdings")!
    private let positionsURL = URL(string: "https://api.upstox.com/v2/portfolio/short-term-positions")!
    private let mutualFundHoldingsURL = URL(string: "https://api.upstox.com/v2/mf/holdings")!

    var storedAccessToken: String? {
        try? KeychainManager.shared.read(service: tokenService, account: accessTokenAccount)
    }

    func authorizationURL() throws -> URL {
        guard !APIConfig.upstoxAPIKey.isEmpty, !APIConfig.redirectURI.isEmpty else {
            throw UpstoxServiceError.missingConfiguration
        }

        var components = URLComponents(url: authorizationBaseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: APIConfig.upstoxAPIKey),
            URLQueryItem(name: "redirect_uri", value: APIConfig.redirectURI),
            URLQueryItem(name: "response_type", value: "code")
        ]

        guard let url = components?.url else { throw UpstoxServiceError.invalidAuthorizationURL }
        return url
    }

    func exchangeCodeForToken(_ code: String) async throws -> String {
        guard !APIConfig.upstoxAPIKey.isEmpty,
              !APIConfig.upstoxAPISecret.isEmpty,
              !APIConfig.redirectURI.isEmpty else {
            throw UpstoxServiceError.missingConfiguration
        }

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let form: [String: String] = [
            "code": code,
            "client_id": APIConfig.upstoxAPIKey,
            "client_secret": APIConfig.upstoxAPISecret,
            "redirect_uri": APIConfig.redirectURI,
            "grant_type": "authorization_code"
        ]
        request.httpBody = form.percentEncoded()

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            try validate(response: response, data: data)
            let tokenResponse = try JSONDecoder().decode(UpstoxTokenResponse.self, from: data)
            try KeychainManager.shared.save(tokenResponse.accessToken, service: tokenService, account: accessTokenAccount)
            return tokenResponse.accessToken
        } catch let error as UpstoxServiceError {
            throw error
        } catch let error as URLError where error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
            throw UpstoxServiceError.networkUnavailable
        } catch {
            throw UpstoxServiceError.authenticationFailed(error.localizedDescription)
        }
    }

    func fetchProfile(accessToken: String? = nil, connectedDate: Date = Date()) async throws -> UpstoxProfile {
        guard let token = accessToken ?? storedAccessToken, !token.isEmpty else {
            throw UpstoxServiceError.expiredToken
        }

        var request = URLRequest(url: profileURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            try validate(response: response, data: data)
            let profileResponse = try JSONDecoder().decode(UpstoxProfileResponse.self, from: data)
            guard let data = profileResponse.data else { throw UpstoxServiceError.invalidResponse }
            return try data.profile(connectedDate: connectedDate)
        } catch let error as UpstoxServiceError {
            throw error
        } catch let error as URLError where error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
            throw UpstoxServiceError.networkUnavailable
        } catch {
            throw UpstoxServiceError.invalidResponse
        }
    }

    func fetchHoldings(accessToken: String? = nil) async throws -> [UpstoxHolding] {
        guard let token = accessToken ?? storedAccessToken, !token.isEmpty else {
            throw UpstoxServiceError.expiredToken
        }

        var request = URLRequest(url: holdingsURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            try validate(response: response, data: data)
            let holdingsResponse = try JSONDecoder().decode(UpstoxHoldingResponse.self, from: data)
            return holdingsResponse.data ?? []
        } catch let error as UpstoxServiceError {
            throw error
        } catch let error as URLError where error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
            throw UpstoxServiceError.networkUnavailable
        } catch {
            throw UpstoxServiceError.invalidResponse
        }
    }

    func fetchPositions(accessToken: String? = nil) async throws -> [UpstoxPosition] {
        guard let token = accessToken ?? storedAccessToken, !token.isEmpty else {
            throw UpstoxServiceError.expiredToken
        }

        var request = URLRequest(url: positionsURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            try validate(response: response, data: data)
            let positionsResponse = try JSONDecoder().decode(UpstoxPositionResponse.self, from: data)
            return positionsResponse.data ?? []
        } catch let error as UpstoxServiceError {
            throw error
        } catch let error as URLError where error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
            throw UpstoxServiceError.networkUnavailable
        } catch {
            throw UpstoxServiceError.invalidResponse
        }
    }

    func fetchMutualFundHoldings(accessToken: String? = nil) async throws -> [UpstoxMutualFundHolding] {
        guard let token = accessToken ?? storedAccessToken, !token.isEmpty else {
            throw UpstoxServiceError.expiredToken
        }

        var request = URLRequest(url: mutualFundHoldingsURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            try validate(response: response, data: data)
            let mutualFundResponse = try JSONDecoder().decode(UpstoxMutualFundHoldingResponse.self, from: data)
            return mutualFundResponse.data ?? []
        } catch let error as UpstoxServiceError {
            throw error
        } catch let error as URLError where error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
            throw UpstoxServiceError.networkUnavailable
        } catch {
            throw UpstoxServiceError.invalidResponse
        }
    }

    func fetchInvestments(accessToken: String? = nil) async throws -> [UpstoxHolding] {
        var firstError: Error?
        var didReceivePortfolioResponse = false
        var holdings: [UpstoxHolding] = []

        do {
            holdings = try await fetchHoldings(accessToken: accessToken)
            didReceivePortfolioResponse = true
        } catch {
            firstError = error
        }

        do {
            let positions = try await fetchPositions(accessToken: accessToken)
                .map(\.asHolding)
                .filter { position in
                    !holdings.contains { holding in
                        holding.id == position.id || (
                            holding.tradingSymbol == position.tradingSymbol &&
                            holding.exchange == position.exchange
                        )
                    }
                }
            holdings.append(contentsOf: positions)
            didReceivePortfolioResponse = true
        } catch {
            firstError = firstError ?? error
        }

        if !didReceivePortfolioResponse, let firstError {
            throw firstError
        }

        return holdings
    }

    func logout() throws {
        try KeychainManager.shared.delete(service: tokenService, account: accessTokenAccount)
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UpstoxServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return
        case 401, 403:
            throw UpstoxServiceError.expiredToken
        default:
            if let message = try? JSONDecoder().decode(UpstoxProfileResponse.self, from: data).errors?.compactMap(\.message).first {
                throw UpstoxServiceError.authenticationFailed(message)
            }
            throw UpstoxServiceError.serverError(httpResponse.statusCode)
        }
    }
}

private extension Dictionary where Key == String, Value == String {
    func percentEncoded() -> Data? {
        map { key, value in
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(encodedKey)=\(encodedValue)"
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}
