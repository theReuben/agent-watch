import SwiftUI

struct CreateSessionView: View {
    let owner: String
    let repo: String

    @State private var issues: [Issue] = []
    @State private var isLoading = false
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var selectedIssue: Issue?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading issues...")
            } else if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            } else if let success = successMessage {
                Section {
                    Label(success, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            } else if issues.isEmpty {
                Text("No open issues found.")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else {
                Section("Select an issue for Copilot") {
                    ForEach(issues) { issue in
                        Button {
                            selectedIssue = issue
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("#\(issue.number)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(issue.title)
                                        .font(.caption)
                                        .lineLimit(2)
                                }
                                Spacer()
                                if selectedIssue?.id == issue.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                if selectedIssue != nil {
                    Section {
                        Button {
                            Task { await createSession() }
                        } label: {
                            if isCreating {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Label("Start Copilot Session", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .disabled(isCreating)
                    }
                }
            }
        }
        .navigationTitle("New Session")
        .task {
            await loadIssues()
        }
    }

    private func loadIssues() async {
        guard !owner.isEmpty, !repo.isEmpty else {
            errorMessage = "No repository configured."
            return
        }

        isLoading = true
        do {
            issues = try await GitHubService.shared.fetchIssues(owner: owner, repo: repo)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func createSession() async {
        guard let issue = selectedIssue else { return }

        isCreating = true
        errorMessage = nil

        do {
            _ = try await GitHubService.shared.createAgentSession(
                owner: owner,
                repo: repo,
                issueNumber: issue.number
            )
            successMessage = "Session created for #\(issue.number)"

            try? await Task.sleep(nanoseconds: 2_000_000_000)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isCreating = false
    }
}

#Preview {
    NavigationStack {
        CreateSessionView(owner: "owner", repo: "repo")
    }
}
