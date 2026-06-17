import Foundation

struct UpstoxProfileResponse: Decodable {
    let status: String?
    let data: UpstoxProfileData?
    let errors: [UpstoxAPIMessage]?
}

struct UpstoxProfileData: Decodable {
    let email: String?
    let userName: String?
    let userID: String?
    let exchanges: [String]?
    let products: [String]?

    enum CodingKeys: String, CodingKey {
        case email
        case userName = "user_name"
        case userID = "user_id"
        case exchanges
        case products
    }

    func profile(connectedDate: Date) throws -> UpstoxProfile {
        guard let email, let userName, let userID else {
            throw UpstoxServiceError.invalidResponse
        }

        return UpstoxProfile(
            email: email,
            userName: userName,
            userID: userID,
            exchanges: exchanges ?? [],
            products: products ?? [],
            connectedDate: connectedDate
        )
    }
}

struct UpstoxAPIMessage: Decodable {
    let errorCode: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case errorCode = "error_code"
        case message
    }
}

struct UpstoxTokenResponse: Decodable {
    let accessToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}
