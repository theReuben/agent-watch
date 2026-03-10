# AgentWatch ⌚

An Apple Watch app to monitor and interact with AI coding agents — starting with GitHub Copilot.

## Features

- **Dashboard** — View real-time agent session progress with active, completed, and failed session counts
- **Agent Sessions** — Browse Copilot coding agent sessions, view details, and create new sessions from issues
- **Issue Management** — List repository issues and assign GitHub Copilot to work on them
- **Pull Request Review** — Browse PRs, view file changes and reviews, request Copilot as a reviewer, and submit your own reviews (approve, request changes, or comment)
- **Settings** — Configure your GitHub personal access token and default repository

## Requirements

- watchOS 10.0+
- Xcode 15.4+
- Swift 5.5+
- A GitHub personal access token with `repo` scope

## Development

A `Makefile` provides convenient shortcuts so you never need to remember `xcodebuild` flags:

```bash
make build      # compile for watchOS Simulator
make test       # run unit tests
make coverage   # run tests + print line-coverage summary
make clean      # remove build artifacts
make lint       # run SwiftLint (optional, install via `brew install swiftlint`)
make help       # list all available targets
```

### Continuous Integration

Every push and pull request to `main` triggers the **Test** workflow (`.github/workflows/test.yml`) which:

1. Builds the app on macOS with Xcode
2. Runs the full test suite with code coverage enabled
3. Posts a coverage summary to the PR's **Actions** tab
4. Uploads the `.xcresult` bundle as an artifact for deeper inspection

Redundant CI runs on the same branch are automatically cancelled so you get fast feedback.

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/theReuben/agent-watch.git
cd agent-watch
```

### 2. Open in Xcode

```bash
open AgentWatch.xcodeproj
```

### 3. Build & Run

1. Select the **AgentWatch Watch App** scheme
2. Choose a watchOS simulator or your paired Apple Watch
3. Press **⌘R** to build and run

### 4. Configure the app

On first launch you'll be shown the Settings screen:

1. Enter your **GitHub Personal Access Token** (needs `repo` scope)
2. Enter the **default repository** in `owner/repo` format (e.g., `octocat/Hello-World`)
3. Tap **Save**

## Project Structure

```
AgentWatch Watch App/
├── AgentWatchApp.swift              # App entry point
├── ContentView.swift                # Root navigation
├── Models/
│   ├── Agent.swift                  # AI agent model
│   ├── AgentSession.swift           # Copilot session model
│   ├── Issue.swift                  # GitHub issue model
│   ├── PullRequest.swift            # PR, review & file models
│   └── GitHubRepository.swift       # Repository model & config
├── Services/
│   ├── GitHubService.swift          # GitHub REST API client
│   └── KeychainService.swift        # Secure token storage
└── Views/
    ├── Dashboard/
    │   └── DashboardView.swift      # Agent progress overview
    ├── Sessions/
    │   ├── SessionListView.swift    # List Copilot sessions
    │   ├── SessionDetailView.swift  # Session details
    │   └── CreateSessionView.swift  # Start new Copilot session
    ├── Issues/
    │   ├── IssueListView.swift      # Repository issues
    │   └── AssignCopilotView.swift  # Assign Copilot to issue
    ├── PullRequests/
    │   ├── PRListView.swift         # List pull requests
    │   ├── PRDetailView.swift       # PR details & files
    │   └── PRReviewView.swift       # Submit PR review
    └── Settings/
        └── SettingsView.swift       # Token & repo configuration

AgentWatchTests/
├── ModelTests.swift                 # Unit tests for data models
└── GitHubServiceTests.swift         # Unit tests for API service
```

## GitHub Token Permissions

Your personal access token needs the following scope:

| Scope  | Reason |
|--------|--------|
| `repo` | Read/write access to issues, pull requests, and Copilot sessions |

## Architecture

- **SwiftUI** — Declarative UI framework for watchOS
- **async/await** — Modern Swift concurrency for API calls
- **Keychain** — Secure storage for sensitive credentials
- **GitHub REST API v3** — All interactions with GitHub

## License

MIT
