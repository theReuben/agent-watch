# AgentWatch – convenience targets for local development
# Usage:
#   make build        – compile the app (watchOS Simulator)
#   make test         – run unit tests
#   make coverage     – run tests and show a line-coverage summary
#   make clean        – remove build artifacts
#   make lint         – run SwiftLint if installed (optional)
#   make help         – print this help message

SCHEME   := AgentWatch Watch App
PROJECT  := AgentWatch.xcodeproj
SDK      := watchsimulator
DEST     := generic/platform=watchOS Simulator
XCARGS   := -project "$(PROJECT)" -scheme "$(SCHEME)" -sdk $(SDK) -destination '$(DEST)'

.DEFAULT_GOAL := help

.PHONY: build test coverage clean lint help

build: ## Compile the app for watchOS Simulator
	@echo "▸ Building $(SCHEME)…"
	xcodebuild build $(XCARGS) CODE_SIGN_IDENTITY=- AD_HOC_CODE_SIGNING_ALLOWED=YES | xcpretty || xcodebuild build $(XCARGS) CODE_SIGN_IDENTITY=- AD_HOC_CODE_SIGNING_ALLOWED=YES

test: ## Run unit tests
	@echo "▸ Running tests…"
	xcodebuild test $(XCARGS) CODE_SIGN_IDENTITY=- AD_HOC_CODE_SIGNING_ALLOWED=YES | xcpretty || xcodebuild test $(XCARGS) CODE_SIGN_IDENTITY=- AD_HOC_CODE_SIGNING_ALLOWED=YES

coverage: ## Run tests and print a line-coverage summary
	@echo "▸ Running tests with coverage…"
	xcodebuild test $(XCARGS) CODE_SIGN_IDENTITY=- AD_HOC_CODE_SIGNING_ALLOWED=YES \
		-enableCodeCoverage YES \
		-resultBundlePath .build/results.xcresult | xcpretty || true
	@echo "\n▸ Coverage summary:"
	@xcrun xccov view --report .build/results.xcresult 2>/dev/null || echo "  (install Xcode command-line tools to view coverage)"

clean: ## Remove build artifacts and derived data
	@echo "▸ Cleaning…"
	xcodebuild clean $(XCARGS) 2>/dev/null || true
	rm -rf .build DerivedData build

lint: ## Run SwiftLint (if installed)
	@if command -v swiftlint >/dev/null 2>&1; then \
		echo "▸ Running SwiftLint…"; \
		swiftlint lint --strict; \
	else \
		echo "⚠ SwiftLint not found – install it with 'brew install swiftlint' (optional)"; \
	fi

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'
