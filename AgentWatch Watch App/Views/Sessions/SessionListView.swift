import SwiftUI

struct SessionListView: View {
    @State private var sessions: [AgentSession] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var owner = ""
    @State private var repo = ""

    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading sessions...")
            } else if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            } else if sessions.isEmpty {
                Text("No Copilot sessions found.")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else {
                ForEach(sessions) { session in
                    NavigationLink {
                        SessionDetailView(session: session, owner: owner, repo: repo)
                    } label: {
                        SessionRow(session: session)
                    }
                }
            }
        }
        .navigationTitle("Sessions")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    CreateSessionView(owner: owner, repo: repo)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .refreshable {
            await loadSessions()
        }
        .task {
            loadRepository()
            await loadSessions()
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

    private func loadSessions() async {
        guard !owner.isEmpty, !repo.isEmpty else {
            errorMessage = "No repository configured."
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

#Preview {
    NavigationStack {
        SessionListView()
    }
}
