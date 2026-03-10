import SwiftUI

struct SessionDetailView: View {
    let session: AgentSession
    let owner: String
    let repo: String

    var body: some View {
        List {
            Section("Status") {
                HStack {
                    Image(systemName: session.status.iconName)
                        .foregroundStyle(colorForStatus(session.status))
                    Text(session.status.displayName)
                        .font(.headline)
                }
            }

            Section("Details") {
                LabeledContent("Session") {
                    Text(session.name)
                        .font(.caption)
                }

                if let repository = session.repository {
                    LabeledContent("Repository") {
                        Text(repository.fullName)
                            .font(.caption)
                    }
                }

                if let issue = session.issue {
                    LabeledContent("Issue") {
                        Text("#\(issue.number)")
                            .font(.caption)
                    }
                    LabeledContent("Title") {
                        Text(issue.title)
                            .font(.caption)
                            .lineLimit(3)
                    }
                }
            }

            Section("Timeline") {
                LabeledContent("Created") {
                    Text(session.createdAt, style: .relative)
                        .font(.caption)
                }
                LabeledContent("Updated") {
                    Text(session.updatedAt, style: .relative)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Session")
    }

    private func colorForStatus(_ status: AgentSession.SessionStatus) -> Color {
        switch status {
        case .queued: return .orange
        case .inProgress: return .blue
        case .completed: return .green
        case .failed: return .red
        case .stopped: return .gray
        }
    }
}
