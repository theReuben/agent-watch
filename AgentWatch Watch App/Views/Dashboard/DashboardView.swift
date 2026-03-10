import SwiftUI

struct DashboardView: View {
    @State private var sessions: [AgentSession] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var owner = ""
    @State private var repo = ""

    var activeSessions: [AgentSession] {
        sessions.filter { $0.isActive }
    }

    var completedSessions: [AgentSession] {
        sessions.filter { $0.status == .completed }
    }

    var failedSessions: [AgentSession] {
        sessions.filter { $0.status == .failed }
    }

    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity)
            } else if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            } else if sessions.isEmpty {
                Section {
                    Text("No agent sessions found. Configure a repository in Settings.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            } else {
                // Summary
                Section("Overview") {
                    HStack {
                        Label("\(activeSessions.count)", systemImage: "arrow.triangle.2.circlepath")
                            .foregroundStyle(.blue)
                        Spacer()
                        Text("Active")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("\(completedSessions.count)", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Spacer()
                        Text("Completed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("\(failedSessions.count)", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Spacer()
                        Text("Failed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Active sessions
                if !activeSessions.isEmpty {
                    Section("Active") {
                        ForEach(activeSessions) { session in
                            SessionRow(session: session)
                        }
                    }
                }

                // Recent completed
                if !completedSessions.isEmpty {
                    Section("Recently Completed") {
                        ForEach(completedSessions.prefix(5)) { session in
                            SessionRow(session: session)
                        }
                    }
                }
            }
        }
        .navigationTitle("Dashboard")
        .refreshable {
            await loadData()
        }
        .task {
            loadRepository()
            await loadData()
        }
    }

    private func loadRepository() {
        let repoString = KeychainService.shared.retrieve(key: AppConfiguration.repoKey) ?? ""
        let parts = repoString.split(separator: "/")
        if parts.count == 2 {
            owner = String(parts[0])
            repo = String(parts[1])
        }
    }

    private func loadData() async {
        guard !owner.isEmpty, !repo.isEmpty else {
            errorMessage = "No repository configured. Set one in Settings."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            sessions = try await GitHubService.shared.fetchAgentSessions(owner: owner, repo: repo)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

struct SessionRow: View {
    let session: AgentSession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: session.status.iconName)
                    .foregroundStyle(colorForStatus(session.status))
                    .font(.caption)
                Text(session.name)
                    .font(.caption)
                    .lineLimit(2)
            }
            if let issue = session.issue {
                Text("#\(issue.number) \(issue.title)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
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

#Preview {
    NavigationStack {
        DashboardView()
    }
}
