# AgentWatch – Developer Commands
# Run `make help` to see available targets.

SCHEME    = AgentWatch Watch App
PROJECT   = AgentWatch.xcodeproj
DEST      = platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)
XCARGS    = -project "$(PROJECT)" -scheme "$(SCHEME)" -destination '$(DEST)'

.PHONY: build test clean help

## Build the watchOS app
build:
	xcodebuild build $(XCARGS) | xcbeautify || xcodebuild build $(XCARGS)

## Build and run all unit tests
test:
	xcodebuild test $(XCARGS) -enableCodeCoverage YES | xcbeautify || xcodebuild test $(XCARGS) -enableCodeCoverage YES

## Remove derived data for this project
clean:
	xcodebuild clean $(XCARGS)
	rm -rf DerivedData

## Print available targets
help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  build   Build the watchOS app"
	@echo "  test    Build and run all unit tests (with code coverage)"
	@echo "  clean   Remove build artifacts"
	@echo "  help    Show this help message"
