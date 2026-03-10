import Foundation

/// Represents a GitHub issue
struct Issue: Identifiable, Codable {
    let id: Int
    let number: Int
    let title: String
    let body: String?
    let state: IssueState
    let createdAt: Date
    let updatedAt: Date
    let assignees: [User]
    let labels: [Label]
    let repositoryURL: String?

    enum IssueState: String, Codable {
        case open
        case closed
    }

    struct User: Identifiable, Codable {
        let id: Int
        let login: String
        let avatarURL: String?

        enum CodingKeys: String, CodingKey {
            case id, login
            case avatarURL = "avatar_url"
        }
    }

    struct Label: Identifiable, Codable {
        let id: Int
        let name: String
        let color: String
    }

    enum CodingKeys: String, CodingKey {
        case id, number, title, body, state, assignees, labels
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case repositoryURL = "repository_url"
    }
}

extension Issue {
    var isCopilotAssigned: Bool {
        assignees.contains { $0.login.lowercased().contains("copilot") }
    }
}
