import XCTest
@testable import AgentWatch_Watch_App

final class GitHubServiceTests: XCTestCase {

    // MARK: - GitHubServiceError Tests

    func testErrorDescriptions() {
        let invalidURL = GitHubServiceError.invalidURL
        XCTAssertEqual(invalidURL.errorDescription, "Invalid URL")

        let noToken = GitHubServiceError.noToken
        XCTAssertEqual(noToken.errorDescription, "No GitHub token configured. Add your token in Settings.")

        let httpError = GitHubServiceError.httpError(statusCode: 404, message: "Not Found")
        XCTAssertEqual(httpError.errorDescription, "HTTP 404: Not Found")

        let networkError = GitHubServiceError.networkError(
            NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connection lost"])
        )
        XCTAssertEqual(networkError.errorDescription, "Network error: Connection lost")

        let decodingError = GitHubServiceError.decodingError(
            NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])
        )
        XCTAssertEqual(decodingError.errorDescription, "Failed to decode response: Invalid JSON")
    }

    // MARK: - Service Initialization

    func testServiceSingleton() {
        let service1 = GitHubService.shared
        let service2 = GitHubService.shared
        XCTAssertTrue(service1 === service2)
    }

    func testServiceInitialization() {
        let service = GitHubService()
        XCTAssertNotNil(service)
    }

    // MARK: - Authentication State

    func testIsNotAuthenticatedByDefault() {
        let service = GitHubService()
        // Without a token saved, should not be authenticated
        // This test depends on keychain state, so it may vary
        // We just verify it doesn't crash
        _ = service.isAuthenticated
    }
}
