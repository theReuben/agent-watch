import Foundation

/// Represents a GitHub pull request
struct PullRequest: Identifiable, Codable {
    let id: Int
    let number: Int
    let title: String
    let body: String?
    let state: PRState
    let draft: Bool
    let createdAt: Date
    let updatedAt: Date
    let user: User
    let head: Branch
    let base: Branch
    let requestedReviewers: [User]
    let mergeable: Bool?
    let additions: Int?
    let deletions: Int?
    let changedFiles: Int?

    enum PRState: String, Codable {
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

    struct Branch: Codable {
        let ref: String
        let sha: String
    }

    enum CodingKeys: String, CodingKey {
        case id, number, title, body, state, draft, user, head, base, mergeable, additions, deletions
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case requestedReviewers = "requested_reviewers"
        case changedFiles = "changed_files"
    }
}

/// Represents a review on a pull request
struct PRReview: Identifiable, Codable {
    let id: Int
    let user: PullRequest.User
    let body: String?
    let state: ReviewState
    let submittedAt: Date?

    enum ReviewState: String, Codable {
        case approved = "APPROVED"
        case changesRequested = "CHANGES_REQUESTED"
        case commented = "COMMENTED"
        case pending = "PENDING"
        case dismissed = "DISMISSED"

        var displayName: String {
            switch self {
            case .approved: return "Approved"
            case .changesRequested: return "Changes Requested"
            case .commented: return "Commented"
            case .pending: return "Pending"
            case .dismissed: return "Dismissed"
            }
        }

        var iconName: String {
            switch self {
            case .approved: return "checkmark.circle.fill"
            case .changesRequested: return "exclamationmark.circle.fill"
            case .commented: return "text.bubble"
            case .pending: return "clock"
            case .dismissed: return "xmark.circle"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, user, body, state
        case submittedAt = "submitted_at"
    }
}

/// A file changed in a pull request
struct PRFile: Identifiable, Codable {
    var id: String { sha + filename }
    let sha: String
    let filename: String
    let status: String
    let additions: Int
    let deletions: Int
    let changes: Int
    let patch: String?
}

extension PullRequest {
    var isCopilotReviewer: Bool {
        requestedReviewers.contains { $0.login.lowercased().contains("copilot") }
    }

    var changesDescription: String {
        guard let additions = additions, let deletions = deletions else {
            return "No change info"
        }
        return "+\(additions) -\(deletions)"
    }
}
