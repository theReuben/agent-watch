import SwiftUI

struct ContentView: View {
    @State private var isAuthenticated = GitHubService.shared.isAuthenticated

    var body: some View {
        if isAuthenticated {
            MainTabView()
        } else {
            SettingsView(isAuthenticated: $isAuthenticated)
        }
    }
}

struct MainTabView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    DashboardView()
                } label: {
                    Label("Dashboard", systemImage: "gauge.medium")
                }

                NavigationLink {
                    SessionListView()
                } label: {
                    Label("Sessions", systemImage: "terminal")
                }

                NavigationLink {
                    IssueListView()
                } label: {
                    Label("Issues", systemImage: "exclamationmark.circle")
                }

                NavigationLink {
                    PRListView()
                } label: {
                    Label("Pull Requests", systemImage: "arrow.triangle.pull")
                }

                NavigationLink {
                    SettingsView(isAuthenticated: .constant(true))
                } label: {
                    Label("Settings", systemImage: "gear")
                }
            }
            .navigationTitle("AgentWatch")
        }
    }
}

#Preview {
    ContentView()
}
