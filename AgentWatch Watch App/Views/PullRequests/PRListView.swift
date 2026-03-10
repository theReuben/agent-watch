import SwiftUI

struct PRListView: View {
    @State private var pullRequests: [PullRequest] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var owner = ""
    @State private var repo = ""

    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading PRs...")
            } else if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            } else if pullRequests.isEmpty {
                Text("No open pull requests.")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else {
                ForEach(pullRequests) { pr in
                    NavigationLink {
                        PRDetailView(pullRequest: pr, owner: owner, repo: repo)
                    } label: {
                        PRRow(pullRequest: pr)
                    }
                }
            }
        }
        .navigationTitle("Pull Requests")
        .refreshable {
            await loadPRs()
        }
        .task {
            loadRepository()
            await loadPRs()
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

    private func loadPRs() async {
        guard !owner.isEmpty, !repo.isEmpty else {
            errorMessage = "No repository configured."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            pullRequests = try await GitHubService.shared.fetchPullRequests(owner: owner, repo: repo)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

struct PRRow: View {
    let pullRequest: PullRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: pullRequest.draft ? "doc.text" : "arrow.triangle.pull")
                    .foregroundStyle(pullRequest.state == .open ? .green : .purple)
                    .font(.caption2)
                Text("#\(pullRequest.number)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(pullRequest.title)
                .font(.caption)
                .lineLimit(2)
            HStack {
                Text(pullRequest.user.login)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if pullRequest.isCopilotReviewer {
                    Label("Copilot Review", systemImage: "cpu")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PRListView()
    }
}
