import SwiftUI

struct SettingsView: View {
    @Binding var isAuthenticated: Bool

    @State private var token = ""
    @State private var repository = ""
    @State private var isSaving = false
    @State private var saveSuccess = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("GitHub Token") {
                SecureField("ghp_...", text: $token)
                    .font(.caption)
                    .textContentType(.password)
                Text("Personal access token with repo scope")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Section("Default Repository") {
                TextField("owner/repo", text: $repository)
                    .font(.caption)
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                Text("e.g., octocat/Hello-World")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            if saveSuccess {
                Section {
                    Label("Settings saved!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }

            Section {
                Button {
                    saveSettings()
                } label: {
                    if isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Save", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(token.isEmpty || repository.isEmpty || isSaving)
            }

            if isAuthenticated {
                Section {
                    Button(role: .destructive) {
                        clearSettings()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            loadSettings()
        }
    }

    private func loadSettings() {
        if let savedToken = KeychainService.shared.retrieve(key: AppConfiguration.tokenKey) {
            token = savedToken
        }
        if let savedRepo = KeychainService.shared.retrieve(key: AppConfiguration.repoKey) {
            repository = savedRepo
        }
    }

    private func saveSettings() {
        isSaving = true
        errorMessage = nil
        saveSuccess = false

        // Validate repository format
        let parts = repository.split(separator: "/")
        guard parts.count == 2 else {
            errorMessage = "Repository must be in owner/repo format"
            isSaving = false
            return
        }

        let tokenSaved = KeychainService.shared.save(key: AppConfiguration.tokenKey, value: token)
        let repoSaved = KeychainService.shared.save(key: AppConfiguration.repoKey, value: repository)

        if tokenSaved && repoSaved {
            saveSuccess = true
            isAuthenticated = true
        } else {
            errorMessage = "Failed to save settings"
        }

        isSaving = false
    }

    private func clearSettings() {
        _ = KeychainService.shared.delete(key: AppConfiguration.tokenKey)
        _ = KeychainService.shared.delete(key: AppConfiguration.repoKey)
        token = ""
        repository = ""
        isAuthenticated = false
    }
}

#Preview {
    NavigationStack {
        SettingsView(isAuthenticated: .constant(true))
    }
}
