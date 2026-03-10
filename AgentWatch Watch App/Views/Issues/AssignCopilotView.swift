import SwiftUI

struct AssignCopilotView: View {
    let issue: Issue
    let owner: String
    let repo: String

    @State private var isAssigning = false
    @State private var isCreatingSession = false
    @State private var errorMessage: String?
    @State private var assignSuccess = false
    @State private var sessionSuccess = false

    var body: some View {
        List {
            Section("Issue #\(issue.number)") {
                Text(issue.title)
                    .font(.caption)

                if let body = issue.body, !body.isEmpty {
                    Text(body)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(5)
                }
            }

            Section("Assignees") {
                if issue.assignees.isEmpty {
                    Text("No assignees")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(issue.assignees) { assignee in
                        Text(assignee.login)
                            .font(.caption)
                    }
                }
            }

            if !issue.labels.isEmpty {
                Section("Labels") {
                    ForEach(issue.labels) { label in
                        Text(label.name)
                            .font(.caption)
                    }
                }
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            Section("Actions") {
                // Assign Copilot
                Button {
                    Task { await assignCopilot() }
                } label: {
                    if isAssigning {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if assignSuccess {
                        Label("Copilot Assigned", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label("Assign Copilot", systemImage: "cpu")
                    }
                }
                .disabled(isAssigning || assignSuccess)

                // Create session
                Button {
                    Task { await createSession() }
                } label: {
                    if isCreatingSession {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if sessionSuccess {
                        Label("Session Created", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label("Start Copilot Session", systemImage: "play.fill")
                    }
                }
                .disabled(isCreatingSession || sessionSuccess)
            }
        }
        .navigationTitle("Issue #\(issue.number)")
    }

    private func assignCopilot() async {
        isAssigning = true
        errorMessage = nil

        do {
            try await GitHubService.shared.assignCopilotToIssue(
                owner: owner, repo: repo, issueNumber: issue.number
            )
            assignSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isAssigning = false
    }

    private func createSession() async {
        isCreatingSession = true
        errorMessage = nil

        do {
            _ = try await GitHubService.shared.createAgentSession(
                owner: owner, repo: repo, issueNumber: issue.number
            )
            sessionSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isCreatingSession = false
    }
}
