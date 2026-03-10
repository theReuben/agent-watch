import SwiftUI

struct PRReviewView: View {
    let pullRequest: PullRequest
    let owner: String
    let repo: String

    @State private var reviewBody = ""
    @State private var selectedAction: ReviewAction = .approve
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var submitted = false

    @Environment(\.dismiss) private var dismiss

    enum ReviewAction: String, CaseIterable {
        case approve = "APPROVE"
        case requestChanges = "REQUEST_CHANGES"
        case comment = "COMMENT"

        var displayName: String {
            switch self {
            case .approve: return "Approve"
            case .requestChanges: return "Request Changes"
            case .comment: return "Comment"
            }
        }

        var iconName: String {
            switch self {
            case .approve: return "checkmark.circle"
            case .requestChanges: return "exclamationmark.circle"
            case .comment: return "text.bubble"
            }
        }

        var color: Color {
            switch self {
            case .approve: return .green
            case .requestChanges: return .red
            case .comment: return .blue
            }
        }
    }

    var body: some View {
        List {
            Section("PR #\(pullRequest.number)") {
                Text(pullRequest.title)
                    .font(.caption)
                    .lineLimit(3)
            }

            Section("Review Type") {
                ForEach(ReviewAction.allCases, id: \.rawValue) { action in
                    Button {
                        selectedAction = action
                    } label: {
                        HStack {
                            Image(systemName: action.iconName)
                                .foregroundStyle(action.color)
                            Text(action.displayName)
                                .font(.caption)
                            Spacer()
                            if selectedAction == action {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }

            Section("Comment") {
                TextField("Review comment...", text: $reviewBody, axis: .vertical)
                    .font(.caption)
                    .lineLimit(3...6)
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            if submitted {
                Section {
                    Label("Review submitted!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }

            Section {
                Button {
                    Task { await submitReview() }
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Submit Review", systemImage: "paperplane.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isSubmitting || submitted)
            }
        }
        .navigationTitle("Review")
    }

    private func submitReview() async {
        isSubmitting = true
        errorMessage = nil

        do {
            try await GitHubService.shared.submitReview(
                owner: owner,
                repo: repo,
                number: pullRequest.number,
                event: selectedAction.rawValue,
                body: reviewBody
            )
            submitted = true

            try? await Task.sleep(nanoseconds: 2_000_000_000)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }
}
