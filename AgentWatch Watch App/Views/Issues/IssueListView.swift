import SwiftUI

struct IssueListView: View {
    @State private var issues: [Issue] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var owner = ""
    @State private var repo = ""

    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading issues...")
            } else if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            } else if issues.isEmpty {
                Text("No open issues found.")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else {
                ForEach(issues) { issue in
                    NavigationLink {
                        AssignCopilotView(issue: issue, owner: owner, repo: repo)
                    } label: {
                        IssueRow(issue: issue)
                    }
                }
            }
        }
        .navigationTitle("Issues")
        .refreshable {
            await loadIssues()
        }
        .task {
            loadRepository()
            await loadIssues()
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

    private func loadIssues() async {
        guard !owner.isEmpty, !repo.isEmpty else {
            errorMessage = "No repository configured."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            issues = try await GitHubService.shared.fetchIssues(owner: owner, repo: repo)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

struct IssueRow: View {
    let issue: Issue

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: issue.state == .open ? "circle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(issue.state == .open ? .green : .purple)
                    .font(.caption2)
                Text("#\(issue.number)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(issue.title)
                .font(.caption)
                .lineLimit(2)
            if issue.isCopilotAssigned {
                Label("Copilot", systemImage: "cpu")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
        }
    }
}

#Preview {
    NavigationStack {
        IssueListView()
    }
}
