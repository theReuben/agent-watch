import XCTest
@testable import AgentWatch_Watch_App

final class ModelTests: XCTestCase {

    // MARK: - Agent Tests

    func testAgentCreation() {
        let agent = Agent(id: "test-agent", name: "Test Agent", type: .copilot, status: .idle)
        XCTAssertEqual(agent.id, "test-agent")
        XCTAssertEqual(agent.name, "Test Agent")
        XCTAssertEqual(agent.type, .copilot)
        XCTAssertEqual(agent.status, .idle)
    }

    func testAgentStaticCopilot() {
        let copilot = Agent.copilot
        XCTAssertEqual(copilot.id, "github-copilot")
        XCTAssertEqual(copilot.name, "GitHub Copilot")
        XCTAssertEqual(copilot.type, .copilot)
        XCTAssertEqual(copilot.status, .idle)
    }

    func testAgentStatusValues() {
        XCTAssertEqual(Agent.AgentStatus.idle.rawValue, "idle")
        XCTAssertEqual(Agent.AgentStatus.working.rawValue, "working")
        XCTAssertEqual(Agent.AgentStatus.completed.rawValue, "completed")
        XCTAssertEqual(Agent.AgentStatus.failed.rawValue, "failed")
        XCTAssertEqual(Agent.AgentStatus.waiting.rawValue, "waiting")
    }

    // MARK: - AgentSession Tests

    func testAgentSessionIsActive() {
        let queuedSession = AgentSession(
            id: 1, name: "Test", status: .queued,
            createdAt: Date(), updatedAt: Date(),
            repository: nil, issue: nil
        )
        XCTAssertTrue(queuedSession.isActive)

        let inProgressSession = AgentSession(
            id: 2, name: "Test", status: .inProgress,
            createdAt: Date(), updatedAt: Date(),
            repository: nil, issue: nil
        )
        XCTAssertTrue(inProgressSession.isActive)

        let completedSession = AgentSession(
            id: 3, name: "Test", status: .completed,
            createdAt: Date(), updatedAt: Date(),
            repository: nil, issue: nil
        )
        XCTAssertFalse(completedSession.isActive)

        let failedSession = AgentSession(
            id: 4, name: "Test", status: .failed,
            createdAt: Date(), updatedAt: Date(),
            repository: nil, issue: nil
        )
        XCTAssertFalse(failedSession.isActive)

        let stoppedSession = AgentSession(
            id: 5, name: "Test", status: .stopped,
            createdAt: Date(), updatedAt: Date(),
            repository: nil, issue: nil
        )
        XCTAssertFalse(stoppedSession.isActive)
    }

    func testSessionStatusDisplayName() {
        XCTAssertEqual(AgentSession.SessionStatus.queued.displayName, "Queued")
        XCTAssertEqual(AgentSession.SessionStatus.inProgress.displayName, "In Progress")
        XCTAssertEqual(AgentSession.SessionStatus.completed.displayName, "Completed")
        XCTAssertEqual(AgentSession.SessionStatus.failed.displayName, "Failed")
        XCTAssertEqual(AgentSession.SessionStatus.stopped.displayName, "Stopped")
    }

    func testSessionStatusIconName() {
        XCTAssertEqual(AgentSession.SessionStatus.queued.iconName, "clock")
        XCTAssertEqual(AgentSession.SessionStatus.inProgress.iconName, "arrow.triangle.2.circlepath")
        XCTAssertEqual(AgentSession.SessionStatus.completed.iconName, "checkmark.circle.fill")
        XCTAssertEqual(AgentSession.SessionStatus.failed.iconName, "xmark.circle.fill")
        XCTAssertEqual(AgentSession.SessionStatus.stopped.iconName, "stop.circle.fill")
    }

    // MARK: - Issue Tests

    func testIssueCopilotAssigned() throws {
        let copilotUser = Issue.User(id: 1, login: "copilot-swe-agent[bot]", avatarURL: nil)
        let regularUser = Issue.User(id: 2, login: "developer", avatarURL: nil)

        let issueWithCopilot = Issue(
            id: 1, number: 1, title: "Test Issue", body: nil, state: .open,
            createdAt: Date(), updatedAt: Date(),
            assignees: [copilotUser], labels: [], repositoryURL: nil
        )
        XCTAssertTrue(issueWithCopilot.isCopilotAssigned)

        let issueWithoutCopilot = Issue(
            id: 2, number: 2, title: "Test Issue", body: nil, state: .open,
            createdAt: Date(), updatedAt: Date(),
            assignees: [regularUser], labels: [], repositoryURL: nil
        )
        XCTAssertFalse(issueWithoutCopilot.isCopilotAssigned)
    }

    // MARK: - PullRequest Tests

    func testPRCopilotReviewer() {
        let copilotUser = PullRequest.User(id: 1, login: "copilot-swe-agent[bot]", avatarURL: nil)
        let regularUser = PullRequest.User(id: 2, login: "developer", avatarURL: nil)

        let prWithCopilot = PullRequest(
            id: 1, number: 1, title: "Test PR", body: nil, state: .open, draft: false,
            createdAt: Date(), updatedAt: Date(),
            user: regularUser, head: PullRequest.Branch(ref: "feature", sha: "abc"),
            base: PullRequest.Branch(ref: "main", sha: "def"),
            requestedReviewers: [copilotUser], mergeable: nil,
            additions: 10, deletions: 5, changedFiles: 3
        )
        XCTAssertTrue(prWithCopilot.isCopilotReviewer)

        let prWithoutCopilot = PullRequest(
            id: 2, number: 2, title: "Test PR", body: nil, state: .open, draft: false,
            createdAt: Date(), updatedAt: Date(),
            user: regularUser, head: PullRequest.Branch(ref: "feature", sha: "abc"),
            base: PullRequest.Branch(ref: "main", sha: "def"),
            requestedReviewers: [regularUser], mergeable: nil,
            additions: 10, deletions: 5, changedFiles: 3
        )
        XCTAssertFalse(prWithoutCopilot.isCopilotReviewer)
    }

    func testPRChangesDescription() {
        let user = PullRequest.User(id: 1, login: "dev", avatarURL: nil)

        let prWithChanges = PullRequest(
            id: 1, number: 1, title: "Test", body: nil, state: .open, draft: false,
            createdAt: Date(), updatedAt: Date(),
            user: user, head: PullRequest.Branch(ref: "f", sha: "a"),
            base: PullRequest.Branch(ref: "m", sha: "b"),
            requestedReviewers: [], mergeable: nil,
            additions: 42, deletions: 7, changedFiles: 5
        )
        XCTAssertEqual(prWithChanges.changesDescription, "+42 -7")

        let prWithoutChanges = PullRequest(
            id: 2, number: 2, title: "Test", body: nil, state: .open, draft: false,
            createdAt: Date(), updatedAt: Date(),
            user: user, head: PullRequest.Branch(ref: "f", sha: "a"),
            base: PullRequest.Branch(ref: "m", sha: "b"),
            requestedReviewers: [], mergeable: nil,
            additions: nil, deletions: nil, changedFiles: nil
        )
        XCTAssertEqual(prWithoutChanges.changesDescription, "No change info")
    }

    // MARK: - PRReview Tests

    func testReviewStateDisplayName() {
        XCTAssertEqual(PRReview.ReviewState.approved.displayName, "Approved")
        XCTAssertEqual(PRReview.ReviewState.changesRequested.displayName, "Changes Requested")
        XCTAssertEqual(PRReview.ReviewState.commented.displayName, "Commented")
        XCTAssertEqual(PRReview.ReviewState.pending.displayName, "Pending")
        XCTAssertEqual(PRReview.ReviewState.dismissed.displayName, "Dismissed")
    }

    func testReviewStateIconName() {
        XCTAssertEqual(PRReview.ReviewState.approved.iconName, "checkmark.circle.fill")
        XCTAssertEqual(PRReview.ReviewState.changesRequested.iconName, "exclamationmark.circle.fill")
        XCTAssertEqual(PRReview.ReviewState.commented.iconName, "text.bubble")
        XCTAssertEqual(PRReview.ReviewState.pending.iconName, "clock")
        XCTAssertEqual(PRReview.ReviewState.dismissed.iconName, "xmark.circle")
    }
}
