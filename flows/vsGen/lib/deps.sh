#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# deps.sh — Dependency checks and logging helpers for vscode-theme-gen
# ═══════════════════════════════════════════════════════════════════════════════

# ─── Logging Helpers ──────────────────────────────────────────────────────────

log_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "  \033[0;90m$1\033[0m"
    fi
}

log_info() {
    echo -e "  \033[0;36m→\033[0m $1"
}

log_success() {
    echo -e "  \033[0;32m✓\033[0m $1"
}

log_warn() {
    echo -e "  \033[0;33m⚠\033[0m $1" >&2
}

log_error() {
    echo -e "  \033[0;31m✗\033[0m $1" >&2
}

# ─── Dependency Checks ───────────────────────────────────────────────────────

check_dependencies() {
    if ! command -v pastel &> /dev/null; then
        log_error "pastel is not installed"
        echo ""
        echo "Install with one of:"
        echo "  cargo install pastel"
        echo "  wget -qO- https://github.com/sharkdp/pastel/releases/download/v0.9.0/pastel-v0.9.0-x86_64-unknown-linux-musl.tar.gz | tar xz"
        exit 1
    fi
}
