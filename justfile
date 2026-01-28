# MoonBit Project Commands

# Default target (js for browser compatibility)
target := "js"

# Default task: check and test
default: check test

# Format code
fmt:
    moon fmt

# Type check
check:
    moon check --deny-warn --target {{target}}

# Run tests
test:
    moon test --target {{target}}

# Update snapshot tests
test-update:
    moon test --update --target {{target}}

# Generate semver oracle tests (requires npm install)
oracle:
    node scripts/gen_oracle.mjs

# Generate type definition files
info:
    moon info

# Clean build artifacts
clean:
    moon clean

# Pre-release check
release-check: fmt info check test

# Build and install native CLI to ~/.local/bin/moonver
install:
    moon build --target native src/cli
    mkdir -p "${HOME}/.local/bin"
    cp target/native/release/build/cli/cli.exe "${HOME}/.local/bin/moonver"
    chmod +x "${HOME}/.local/bin/moonver"
