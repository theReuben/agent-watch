import SwiftUI

struct PRDetailView: View {
    let pullRequest: PullRequest
    let owner: String
    let repo: String

    @State private var reviews: [PRReview] = []
    @State private var files: [PRFile] = []
    @State private var isLoading = false
    @State private var isRequestingReview = false
    @State private var reviewRequested = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            // PR Info
            Section("Details") {
                LabeledContent("Author") {
                    Text(pullRequest.user.login)
                        .font(.caption)
                }
                LabeledContent("Branch") {
                    Text(pullRequest.head.ref)
                        .font(.caption)
                        .lineLimit(1)
                }
                LabeledContent("Base") {
                    Text(pullRequest.base.ref)
                        .font(.caption)
                }
                if let additions = pullRequest.additions, let deletions = pullRequest.deletions {
                    LabeledContent("Changes") {
                        HStack(spacing: 4) {
                            Text("+\(additions)")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Text("-\(deletions)")
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }
                }
                if pullRequest.draft {
                    Label("Draft", systemImage: "doc.text")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Files changed
            if !files.isEmpty {
                Section("Files (\(files.count))") {
                    ForEach(files) { file in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(file.filename)
                                .font(.caption2)
                                .lineLimit(2)
                            HStack(spacing: 4) {
                                Text("+\(file.additions)")
                                    .foregroundStyle(.green)
                                    .font(.caption2)
                                Text("-\(file.deletions)")
                                    .foregroundStyle(.red)
                                    .font(.caption2)
                            }
                        }
                    }
                }
            }

            // Reviews
            if !reviews.isEmpty {
                Section("Reviews") {
                    ForEach(reviews) { review in
                        HStack {
                            Image(systemName: review.state.iconName)
                                .foregroundStyle(colorForReviewState(review.state))
                                .font(.caption)
                            VStack(alignment: .leading) {
                                Text(review.user.login)
                                    .font(.caption)
                                Text(review.state.displayName)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
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

            // Actions
            Section("Actions") {
                Button {
                    Task { await requestCopilotReview() }
                } label: {
                    if isRequestingReview {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if reviewRequested || pullRequest.isCopilotReviewer {
                        Label("Copilot Review Requested", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    } else {
                        Label("Request Copilot Review", systemImage: "cpu")
                            .font(.caption)
                    }
                }
                .disabled(isRequestingReview || reviewRequested || pullRequest.isCopilotReviewer)

                NavigationLink {
                    PRReviewView(pullRequest: pullRequest, owner: owner, repo: repo)
                } label: {
                    Label("Write Review", systemImage: "pencil.line")
                        .font(.caption)
                }
            }
        }
        .navigationTitle("PR #\(pullRequest.number)")
        .task {
            await loadDetails()
        }
    }

    private func loadDetails() async {
        isLoading = true

        async let fetchedReviews = GitHubService.shared.fetchPRReviews(
            owner: owner, repo: repo, number: pullRequest.number
        )
        async let fetchedFiles = GitHubService.shared.fetchPRFiles(
            owner: owner, repo: repo, number: pullRequest.number
        )

        do {
            reviews = try await fetchedReviews
        } catch {
            // Non-critical, continue
        }

        do {
            files = try await fetchedFiles
        } catch {
            // Non-critical, continue
        }

        isLoading = false
    }

    private func requestCopilotReview() async {
        isRequestingReview = true
        errorMessage = nil

        do {
            try await GitHubService.shared.requestCopilotReview(
                owner: owner, repo: repo, number: pullRequest.number
            )
            reviewRequested = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isRequestingReview = false
    }

    private func colorForReviewState(_ state: PRReview.ReviewState) -> Color {
        switch state {
        case .approved: return .green
        case .changesRequested: return .red
        case .commented: return .blue
        case .pending: return .orange
        case .dismissed: return .gray
        }
    }
}
