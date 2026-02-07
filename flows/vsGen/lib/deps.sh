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

# Fetch latest pastel release info from GitHub API
get_latest_pastel_version() {
    curl -s https://api.github.com/repos/sharkdp/pastel/releases/latest \
        | grep '"tag_name":' \
        | sed -E 's/.*"v([^"]+)".*/\1/'
}

# Auto-install pastel if missing
install_pastel() {
    log_info "pastel not found — attempting automatic installation..."
    
    # Detect OS and architecture
    local os arch download_url
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    arch=$(uname -m)
    
    # Map architecture names
    case "$arch" in
        x86_64|amd64)
            arch="x86_64"
            ;;
        aarch64|arm64)
            arch="aarch64"
            ;;
        *)
            log_error "Unsupported architecture: $arch"
            log_info "Please install pastel manually:"
            echo "  cargo install pastel"
            echo "  or visit: https://github.com/sharkdp/pastel/releases"
            exit 1
            ;;
    esac
    
    # Map OS names
    case "$os" in
        linux)
            os="unknown-linux-musl"
            ;;
        darwin)
            os="apple-darwin"
            ;;
        *)
            log_error "Unsupported OS: $os"
            log_info "Please install pastel manually:"
            echo "  cargo install pastel"
            echo "  or visit: https://github.com/sharkdp/pastel/releases"
            exit 1
            ;;
    esac
    
    # Get latest version
    local version
    version=$(get_latest_pastel_version)
    if [[ -z "$version" ]]; then
        log_warn "Could not fetch latest version — trying v0.10.0"
        version="0.10.0"
    fi
    
    log_verbose "Latest pastel version: v${version}"
    
    # Construct download URL
    download_url="https://github.com/sharkdp/pastel/releases/download/v${version}/pastel-v${version}-${arch}-${os}.tar.gz"
    
    log_info "Downloading pastel v${version} for ${arch}-${os}..."
    log_verbose "URL: $download_url"
    
    # Download to temp dir
    local temp_dir
    temp_dir=$(mktemp -d)
    
    if ! curl -fsSL "$download_url" -o "${temp_dir}/pastel.tar.gz"; then
        log_error "Download failed"
        rm -rf "$temp_dir"
        echo ""
        echo "Please install pastel manually:"
        echo "  cargo install pastel"
        echo "  or visit: https://github.com/sharkdp/pastel/releases"
        exit 1
    fi
    
    # Extract
    log_info "Extracting..."
    if ! tar -xzf "${temp_dir}/pastel.tar.gz" -C "$temp_dir"; then
        log_error "Extraction failed"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Install to user bin or /usr/local/bin
    local install_dir
    if [[ -w "/usr/local/bin" ]]; then
        install_dir="/usr/local/bin"
    elif [[ -d "$HOME/.local/bin" ]]; then
        install_dir="$HOME/.local/bin"
    elif [[ -d "$HOME/bin" ]]; then
        install_dir="$HOME/bin"
    else
        # Create ~/.local/bin
        mkdir -p "$HOME/.local/bin"
        install_dir="$HOME/.local/bin"
        log_warn "Created $install_dir — add to PATH if needed"
    fi
    
    log_info "Installing to ${install_dir}/pastel..."
    if ! mv "${temp_dir}/pastel" "${install_dir}/pastel"; then
        log_error "Installation failed (permission denied?)"
        rm -rf "$temp_dir"
        echo ""
        echo "Try manually:"
        echo "  sudo mv ${temp_dir}/pastel /usr/local/bin/"
        exit 1
    fi
    
    chmod +x "${install_dir}/pastel"
    rm -rf "$temp_dir"
    
    # Verify
    if command -v pastel &> /dev/null; then
        log_success "pastel v${version} installed successfully"
    else
        log_error "Installation completed but pastel not in PATH"
        echo ""
        echo "Add to PATH:"
        echo "  export PATH=\"${install_dir}:\$PATH\""
        exit 1
    fi
}

check_dependencies() {
    if ! command -v pastel &> /dev/null; then
        install_pastel
    else
        local version
        version=$(pastel --version 2>/dev/null | grep -oP 'pastel \K[0-9.]+' || echo "unknown")
        log_verbose "pastel ${version} found"
    fi
}
