# Kondo File Organizer - Cross-Platform Makefile

BINARY_NAME = kondo
CARGO = cargo

# Detect OS
ifeq ($(OS),Windows_NT)
	# Windows detection
	DETECTED_OS := Windows
	EXE_EXT := .exe
	CONFIG_DIR := $(APPDATA)/kondo
	INSTALL_DIR := $(LOCALAPPDATA)/Programs/kondo
	RM := del /Q
	MKDIR := mkdir
	CP := copy
	PATH_SEP := \\
else
	# Unix-like systems
	DETECTED_OS := $(shell uname -s)
	EXE_EXT :=
	CONFIG_DIR := $(HOME)/.config/kondo
	INSTALL_DIR := $(HOME)/.local/bin
	RM := rm -f
	MKDIR := mkdir -p
	CP := cp
	PATH_SEP := /
endif

BINARY = $(BINARY_NAME)$(EXE_EXT)
CONFIG_FILE = $(CONFIG_DIR)$(PATH_SEP)kondo.toml
LOG_FILE = $(CONFIG_DIR)$(PATH_SEP)kondo.log

.PHONY: help build install clean run test config-edit config-path config-reset uninstall check dev fmt lint

# Default target
help:
	@echo "Kondo File Organizer - Make Commands"
	@echo "===================================="
	@echo ""
	@echo "Detected OS: $(DETECTED_OS)"
	@echo ""
	@echo "Build & Install:"
	@echo "  make build        - Build release binary"
	@echo "  make install      - Build and install"
	@echo "  make uninstall    - Remove installed binary"
	@echo ""
	@echo "Development:"
	@echo "  make run          - Run in current directory"
	@echo "  make dev          - Build and run debug version"
	@echo "  make test         - Run tests"
	@echo "  make clean        - Clean build artifacts"
	@echo ""
	@echo "Configuration:"
	@echo "  make config-edit  - Edit config file"
	@echo "  make config-path  - Show config file path"
	@echo "  make config-view  - View config contents"
	@echo "  make config-reset - Reset config to defaults"
	@echo "  make config-backup- Backup current config"
	@echo ""
	@echo "Quality:"
	@echo "  make fmt          - Format code"
	@echo "  make lint         - Run clippy"
	@echo "  make check        - Check setup"
	@echo ""
	@echo "Note: On Windows, consider using build.ps1 instead:"
	@echo "      .\\build.ps1 [command]"
	@echo ""

# Build release binary
build:
	@echo "Building Kondo for $(DETECTED_OS)..."
	@$(CARGO) build --release
	@echo "Build complete: target/release/$(BINARY)"

# Build and install
ifeq ($(OS),Windows_NT)
install:
	@echo "On Windows, please use PowerShell script instead:"
	@echo "  .\\build.ps1 install"
	@echo ""
	@echo "Or install manually:"
	@echo "  1. Run: make build"
	@echo "  2. Copy target\\release\\$(BINARY) to a directory in your PATH"
	@exit 1
else
install: build
	@echo "Installing Kondo..."
	@$(MKDIR) $(INSTALL_DIR)
	@$(MKDIR) $(CONFIG_DIR)
	@$(CP) target/release/$(BINARY) $(INSTALL_DIR)/$(BINARY)
	@chmod +x $(INSTALL_DIR)/$(BINARY)
	@echo "Installed to: $(INSTALL_DIR)/$(BINARY)"
	@echo "Config directory: $(CONFIG_DIR)"
	@echo ""
	@echo "Run 'kondo --help' to start organizing!"
	@if ! echo "$$PATH" | grep -q "$(INSTALL_DIR)"; then \
		echo ""; \
		echo "Add $(INSTALL_DIR) to your PATH:"; \
		echo "   export PATH=\"$$HOME/.local/bin:$$PATH\""; \
	fi
endif

# Uninstall
ifeq ($(OS),Windows_NT)
uninstall:
	@echo "On Windows, please use PowerShell script:"
	@echo "  .\\build.ps1 uninstall"
else
uninstall:
	@echo "Uninstalling Kondo..."
	@$(RM) $(INSTALL_DIR)/$(BINARY)
	@echo "Binary removed"
	@echo ""
	@echo "Config still exists at: $(CONFIG_DIR)"
	@echo "To remove config: rm -rf $(CONFIG_DIR)"
endif

# Run in current directory
run:
	@$(CARGO) run --release

# Run tests
test:
	@echo "Running tests..."
	@$(CARGO) test

# Clean build artifacts
clean:
	@echo "Cleaning..."
	@$(CARGO) clean
	@echo "Clean complete"

# Edit configuration
config-edit:
	@if [ ! -f "$(CONFIG_FILE)" ]; then \
		echo "Config doesn't exist. Run 'make run' first."; \
		exit 1; \
	fi
	@$${EDITOR:-nano} "$(CONFIG_FILE)"

# Show config path
config-path:
	@echo "$(CONFIG_FILE)"

# View config
config-view:
	@if [ ! -f "$(CONFIG_FILE)" ]; then \
		echo "Config doesn't exist. Run 'make run' first."; \
		exit 1; \
	fi
	@cat "$(CONFIG_FILE)"

# Reset config to defaults
config-reset:
	@echo "Resetting config to defaults..."
	@if [ -f "$(CONFIG_FILE)" ]; then \
		$(RM) "$(CONFIG_FILE)"; \
		echo "Config removed. Run 'kondo' to generate new defaults."; \
	else \
		echo "No config to reset."; \
	fi

# Backup config
config-backup:
	@if [ ! -f "$(CONFIG_FILE)" ]; then \
		echo "No config to backup."; \
		exit 1; \
	fi
	@$(CP) "$(CONFIG_FILE)" "$(CONFIG_FILE).backup-$$(date +%Y%m%d-%H%M%S)"
	@echo "Config backed up"

# Check setup
check:
	@echo "Checking setup..."
	@echo ""
	@echo "OS: $(DETECTED_OS)"
	@echo ""
	@echo "Rust version:"
	@rustc --version
	@$(CARGO) --version
	@echo ""
	@echo "Binary location:"
	@if [ -f "$(INSTALL_DIR)/$(BINARY)" ]; then \
		echo "  Installed: $(INSTALL_DIR)/$(BINARY)"; \
	else \
		echo "  Not installed (run 'make install')"; \
	fi
	@echo ""
	@echo "Config file:"
	@if [ -f "$(CONFIG_FILE)" ]; then \
		echo "  Found: $(CONFIG_FILE)"; \
	else \
		echo "  Not found (will be created on first run)"; \
	fi
	@echo ""
	@if [ "$(DETECTED_OS)" != "Windows" ]; then \
		echo "PATH includes install dir:"; \
		if echo "$$PATH" | grep -q "$(INSTALL_DIR)"; then \
			echo "  Yes"; \
		else \
			echo "  No - add 'export PATH=\"$$HOME/.local/bin:$$PATH\"'"; \
		fi; \
	fi

# Development build (debug)
dev:
	@$(CARGO) build
	@./target/debug/$(BINARY)

# Format code
fmt:
	@$(CARGO) fmt
	@echo "Format complete"

# Lint code
lint:
	@$(CARGO) clippy -- -D warnings

# Full quality check
quality: fmt lint test
	@echo "All checks passed"

# Show version info
version:
	@grep '^version' Cargo.toml | head -1 | cut -d'"' -f2

# Quick start guide
quickstart:
	@echo "Kondo Quick Start Guide"
	@echo "======================="
	@echo ""
	@echo "1. Build the project:"
	@echo "   make build"
	@echo ""
	@echo "2. Run in current directory:"
	@echo "   make run"
	@echo ""
	@echo "3. Or install system-wide:"
ifeq ($(OS),Windows_NT)
	@echo "   .\\build.ps1 install"
else
	@echo "   make install"
endif
	@echo ""
	@echo "4. Organize files:"
	@echo "   kondo -c /path/to/directory    # By extension"
	@echo "   kondo -f /path/to/directory    # By filename similarity"
	@echo ""
