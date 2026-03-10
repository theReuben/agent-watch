import Foundation

/// Errors that can occur during GitHub API interactions
enum GitHubServiceError: LocalizedError {
    case invalidURL
    case noToken
    case httpError(statusCode: Int, message: String)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noToken:
            return "No GitHub token configured. Add your token in Settings."
        case .httpError(let code, let message):
            return "HTTP \(code): \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

/// Service for interacting with the GitHub API
final class GitHubService {
    static let shared = GitHubService()

    private let baseURL = "https://api.github.com"
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    private var token: String? {
        KeychainService.shared.retrieve(key: AppConfiguration.tokenKey)
    }

    var isAuthenticated: Bool {
        token != nil && !(token?.isEmpty ?? true)
    }

    // MARK: - Generic Request

    private func makeRequest(
        path: String,
        method: String = "GET",
        body: Data? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> Data {
        guard let token = token, !token.isEmpty else {
            throw GitHubServiceError.noToken
        }

        var components = URLComponents(string: baseURL + path)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw GitHubServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw GitHubServiceError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubServiceError.networkError(
                NSError(domain: "GitHubService", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
            )
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GitHubServiceError.httpError(statusCode: httpResponse.statusCode, message: message)
        }

        return data
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw GitHubServiceError.decodingError(error)
        }
    }

    // MARK: - Repositories

    /// Fetch repositories for the authenticated user
    func fetchRepositories() async throws -> [GitHubRepository] {
        let data = try await makeRequest(
            path: "/user/repos",
            queryItems: [
                URLQueryItem(name: "sort", value: "updated"),
                URLQueryItem(name: "per_page", value: "30")
            ]
        )
        return try decode([GitHubRepository].self, from: data)
    }

    // MARK: - Copilot Agent Sessions (Workflow Runs)

    /// Fetch Copilot coding agent sessions for a repository
    /// Uses the workflow runs API filtered for Copilot agent events
    func fetchAgentSessions(owner: String, repo: String) async throws -> [AgentSession] {
        let data = try await makeRequest(
            path: "/repos/\(owner)/\(repo)/copilot/coding_agent/sessions",
            queryItems: [
                URLQueryItem(name: "per_page", value: "30")
            ]
        )

        struct SessionsResponse: Decodable {
            let sessions: [AgentSession]
        }

        let response = try decode(SessionsResponse.self, from: data)
        return response.sessions
    }

    /// Create a new Copilot coding agent session
    func createAgentSession(owner: String, repo: String, issueNumber: Int) async throws -> AgentSession {
        let body = try JSONSerialization.data(withJSONObject: [
            "issue_number": issueNumber
        ])

        let data = try await makeRequest(
            path: "/repos/\(owner)/\(repo)/copilot/coding_agent/sessions",
            method: "POST",
            body: body
        )

        return try decode(AgentSession.self, from: data)
    }

    // MARK: - Issues

    /// Fetch open issues for a repository
    func fetchIssues(owner: String, repo: String, state: String = "open") async throws -> [Issue] {
        let data = try await makeRequest(
            path: "/repos/\(owner)/\(repo)/issues",
            queryItems: [
                URLQueryItem(name: "state", value: state),
                URLQueryItem(name: "per_page", value: "30"),
                URLQueryItem(name: "sort", value: "updated")
            ]
        )
        return try decode([Issue].self, from: data)
    }

    /// Assign Copilot to an issue
    func assignCopilotToIssue(owner: String, repo: String, issueNumber: Int) async throws {
        let body = try JSONSerialization.data(withJSONObject: [
            "assignees": ["copilot-swe-agent[bot]"]
        ])

        _ = try await makeRequest(
            path: "/repos/\(owner)/\(repo)/issues/\(issueNumber)/assignees",
            method: "POST",
            body: body
        )
    }

    // MARK: - Pull Requests

    /// Fetch pull requests for a repository
    func fetchPullRequests(owner: String, repo: String, state: String = "open") async throws -> [PullRequest] {
        let data = try await makeRequest(
            path: "/repos/\(owner)/\(repo)/pulls",
            queryItems: [
                URLQueryItem(name: "state", value: state),
                URLQueryItem(name: "per_page", value: "30"),
                URLQueryItem(name: "sort", value: "updated")
            ]
        )
        return try decode([PullRequest].self, from: data)
    }

    /// Fetch a single pull request with full details
    func fetchPullRequest(owner: String, repo: String, number: Int) async throws -> PullRequest {
        let data = try await makeRequest(
            path: "/repos/\(owner)/\(repo)/pulls/\(number)"
        )
        return try decode(PullRequest.self, from: data)
    }

    /// Fetch files changed in a pull request
    func fetchPRFiles(owner: String, repo: String, number: Int) async throws -> [PRFile] {
        let data = try await makeRequest(
            path: "/repos/\(owner)/\(repo)/pulls/\(number)/files"
        )
        return try decode([PRFile].self, from: data)
    }

    /// Fetch reviews for a pull request
    func fetchPRReviews(owner: String, repo: String, number: Int) async throws -> [PRReview] {
        let data = try await makeRequest(
            path: "/repos/\(owner)/\(repo)/pulls/\(number)/reviews"
        )
        return try decode([PRReview].self, from: data)
    }

    /// Request Copilot as a reviewer on a pull request
    func requestCopilotReview(owner: String, repo: String, number: Int) async throws {
        let body = try JSONSerialization.data(withJSONObject: [
            "reviewers": ["copilot-swe-agent[bot]"]
        ])

        _ = try await makeRequest(
            path: "/repos/\(owner)/\(repo)/pulls/\(number)/requested_reviewers",
            method: "POST",
            body: body
        )
    }

    /// Submit a review on a pull request
    func submitReview(
        owner: String,
        repo: String,
        number: Int,
        event: String,
        body: String
    ) async throws {
        let requestBody = try JSONSerialization.data(withJSONObject: [
            "event": event,
            "body": body
        ])

        _ = try await makeRequest(
            path: "/repos/\(owner)/\(repo)/pulls/\(number)/reviews",
            method: "POST",
            body: requestBody
        )
    }
}
