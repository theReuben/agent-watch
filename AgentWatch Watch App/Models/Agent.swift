import Foundation

/// Represents an AI coding agent (e.g., GitHub Copilot)
struct Agent: Identifiable, Codable {
    let id: String
    let name: String
    let type: AgentType
    var status: AgentStatus

    enum AgentType: String, Codable, CaseIterable {
        case copilot = "github_copilot"
    }

    enum AgentStatus: String, Codable {
        case idle
        case working
        case completed
        case failed
        case waiting
    }
}

extension Agent {
    static let copilot = Agent(
        id: "github-copilot",
        name: "GitHub Copilot",
        type: .copilot,
        status: .idle
    )
}
