import Foundation

struct UpstoxProfile: Codable, Equatable {
    let email: String
    let userName: String
    let userID: String
    let exchanges: [String]
    let products: [String]
    let connectedDate: Date

    enum CodingKeys: String, CodingKey {
        case email
        case userName = "user_name"
        case userID = "user_id"
        case exchanges
        case products
        case connectedDate
    }
}
