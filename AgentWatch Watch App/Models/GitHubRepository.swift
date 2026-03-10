import Foundation

/// Represents a GitHub repository (lightweight)
struct GitHubRepository: Identifiable, Codable {
    let id: Int
    let name: String
    let fullName: String
    let owner: Owner
    let isPrivate: Bool
    let description: String?
    let defaultBranch: String

    struct Owner: Codable {
        let login: String
    }

    enum CodingKeys: String, CodingKey {
        case id, name, owner, description
        case fullName = "full_name"
        case isPrivate = "private"
        case defaultBranch = "default_branch"
    }
}

/// Configuration for the app
struct AppConfiguration {
    var githubToken: String
    var defaultRepository: String

    static let tokenKey = "github_pat_token"
    static let repoKey = "default_repository"
}
