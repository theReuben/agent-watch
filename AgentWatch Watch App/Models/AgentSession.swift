import Foundation

/// Represents a Copilot coding agent session
struct AgentSession: Identifiable, Codable {
    let id: Int
    let name: String
    let status: SessionStatus
    let createdAt: Date
    let updatedAt: Date
    let repository: Repository?
    let issue: SessionIssue?

    enum SessionStatus: String, Codable {
        case queued
        case inProgress = "in_progress"
        case completed
        case failed
        case stopped

        var displayName: String {
            switch self {
            case .queued: return "Queued"
            case .inProgress: return "In Progress"
            case .completed: return "Completed"
            case .failed: return "Failed"
            case .stopped: return "Stopped"
            }
        }

        var iconName: String {
            switch self {
            case .queued: return "clock"
            case .inProgress: return "arrow.triangle.2.circlepath"
            case .completed: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            case .stopped: return "stop.circle.fill"
            }
        }
    }

    struct Repository: Codable {
        let fullName: String
    }

    struct SessionIssue: Codable {
        let number: Int
        let title: String
    }
}

extension AgentSession {
    var isActive: Bool {
        status == .queued || status == .inProgress
    }

    var statusColor: String {
        switch status {
        case .queued: return "orange"
        case .inProgress: return "blue"
        case .completed: return "green"
        case .failed: return "red"
        case .stopped: return "gray"
        }
    }
}
