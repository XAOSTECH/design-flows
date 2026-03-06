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

# Wrapper so existing calls like `pastel ...` can route via selected binary.
pastel() {
    if [[ -n "${PASTEL_BIN:-}" ]] && [[ -x "${PASTEL_BIN}" ]]; then
        "${PASTEL_BIN}" "$@"
    else
        local system_pastel
        system_pastel="$(type -P pastel || true)"
        if [[ -n "$system_pastel" ]]; then
            "$system_pastel" "$@"
        else
            log_error "pastel executable not found"
            return 127
        fi
    fi
}

# ─── Dependency Checks ───────────────────────────────────────────────────────

# Find monorepo root (where .gitmodules lives) by walking up from this flow.
find_monorepo_root() {
    local current_dir
    current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

    while [[ "$current_dir" != "/" ]]; do
        if [[ -f "$current_dir/.gitmodules" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done

    return 1
}

# Prefer pastel from design-tools root submodule if a binary exists.
find_monorepo_pastel_binary() {
    local monorepo_root
    if ! monorepo_root="$(find_monorepo_root)"; then
        return 1
    fi

    local release_bin="$monorepo_root/pastel/target/release/pastel"
    local debug_bin="$monorepo_root/pastel/target/debug/pastel"

    if [[ -x "$release_bin" ]]; then
        echo "$release_bin"
        return 0
    fi

    if [[ -x "$debug_bin" ]]; then
        echo "$debug_bin"
        return 0
    fi

    return 1
}

# Locate monorepo pastel source directory.
find_monorepo_pastel_source_dir() {
    local monorepo_root
    if ! monorepo_root="$(find_monorepo_root)"; then
        return 1
    fi

    local source_dir="$monorepo_root/pastel"
    if [[ -f "$source_dir/Cargo.toml" ]]; then
        echo "$source_dir"
        return 0
    fi

    return 1
}

# Build pastel from monorepo submodule source if cargo is available.
build_monorepo_pastel_binary() {
    # Only run when explicitly requested via --build.
    if [[ "${VSGEN_BUILD_PASTEL:-0}" != "1" ]]; then
        return 1
    fi

    local source_dir
    if ! source_dir="$(find_monorepo_pastel_source_dir)"; then
        return 1
    fi

    local cargo_bin
    cargo_bin="$(type -P cargo || true)"
    local installed_temp_cargo=false
    if [[ -z "$cargo_bin" ]]; then
        log_info "--build enabled: cargo not found, installing temporary Rust toolchain..."

        if command -v apt-get >/dev/null 2>&1; then
            if [[ "$(id -u)" -eq 0 ]]; then
                DEBIAN_FRONTEND=noninteractive apt-get update -y >/dev/null 2>&1 || true
                if DEBIAN_FRONTEND=noninteractive apt-get install -y cargo rustc >/dev/null 2>&1; then
                    installed_temp_cargo=true
                else
                    log_warn "Could not install cargo/rustc automatically; falling back"
                    return 1
                fi
            elif command -v sudo >/dev/null 2>&1; then
                if sudo -n true >/dev/null 2>&1; then
                    sudo DEBIAN_FRONTEND=noninteractive apt-get update -y >/dev/null 2>&1 || true
                    if sudo DEBIAN_FRONTEND=noninteractive apt-get install -y cargo rustc >/dev/null 2>&1; then
                        installed_temp_cargo=true
                    else
                        log_warn "Could not install cargo/rustc automatically; falling back"
                        return 1
                    fi
                else
                    log_warn "sudo requires a password; cannot auto-install cargo in non-interactive mode"
                    return 1
                fi
            else
                log_warn "No root/sudo access to install cargo automatically; falling back"
                return 1
            fi
        else
            log_warn "Unsupported package manager for temporary cargo install; falling back"
            return 1
        fi

        cargo_bin="$(type -P cargo || true)"
        if [[ -z "$cargo_bin" ]]; then
            log_warn "cargo still unavailable after install attempt; falling back"
            return 1
        fi
    fi

    log_info "Building pastel from monorepo submodule (${source_dir})..."
    local build_ok=true
    if ! (cd "$source_dir" && "$cargo_bin" build --release >/dev/null 2>&1); then
        log_warn "Failed to build monorepo pastel with cargo; falling back"
        build_ok=false
    fi

    local built_bin="$source_dir/target/release/pastel"
    if [[ "$installed_temp_cargo" == true ]]; then
        log_info "Removing temporary Rust toolchain..."
        if [[ "$(id -u)" -eq 0 ]]; then
            DEBIAN_FRONTEND=noninteractive apt-get purge -y cargo rustc >/dev/null 2>&1 || true
            DEBIAN_FRONTEND=noninteractive apt-get autoremove -y >/dev/null 2>&1 || true
        elif command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
            sudo DEBIAN_FRONTEND=noninteractive apt-get purge -y cargo rustc >/dev/null 2>&1 || true
            sudo DEBIAN_FRONTEND=noninteractive apt-get autoremove -y >/dev/null 2>&1 || true
        fi
    fi

    if [[ "$build_ok" == true ]] && [[ -x "$built_bin" ]]; then
        echo "$built_bin"
        return 0
    fi

    if [[ "$build_ok" == true ]]; then
        log_warn "cargo build completed but pastel binary not found at $built_bin"
    fi
    return 1
}

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

    # Release archives contain a versioned directory; locate the binary.
    local pastel_binary
    pastel_binary=$(find "$temp_dir" -type f -name pastel | head -1)
    if [[ -z "$pastel_binary" ]]; then
        log_error "Binary not found in archive"
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
    if ! mv "$pastel_binary" "${install_dir}/pastel"; then
        log_error "Installation failed (permission denied?)"
        rm -rf "$temp_dir"
        echo ""
        echo "Try manually:"
        echo "  sudo mv $pastel_binary /usr/local/bin/"
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
    # 1) Explicit override
    if [[ -n "${PASTEL_BIN:-}" ]] && [[ -x "${PASTEL_BIN}" ]]; then
        local explicit_version
        explicit_version=$("${PASTEL_BIN}" --version 2>/dev/null | grep -oP 'pastel \K[0-9.]+' || echo "unknown")
        log_verbose "pastel ${explicit_version} found via PASTEL_BIN (${PASTEL_BIN})"
        return 0
    fi

    # 2) Monorepo submodule binary (design-tools/pastel)
    local monorepo_pastel
    if monorepo_pastel=$(find_monorepo_pastel_binary); then
        export PASTEL_BIN="$monorepo_pastel"
        local monorepo_version
        monorepo_version=$("${PASTEL_BIN}" --version 2>/dev/null | grep -oP 'pastel \K[0-9.]+' || echo "unknown")
        log_verbose "pastel ${monorepo_version} found in monorepo submodule (${PASTEL_BIN})"
        return 0
    fi

    # 3) Monorepo submodule source auto-build (if cargo exists)
    if monorepo_pastel=$(build_monorepo_pastel_binary); then
        export PASTEL_BIN="$monorepo_pastel"
        local built_version
        built_version=$("${PASTEL_BIN}" --version 2>/dev/null | grep -oP 'pastel \K[0-9.]+' || echo "unknown")
        log_verbose "pastel ${built_version} built from monorepo submodule (${PASTEL_BIN})"
        return 0
    fi

    # 4) System PATH
    local system_pastel
    system_pastel="$(type -P pastel || true)"
    if [[ -n "$system_pastel" ]]; then
        export PASTEL_BIN="$system_pastel"
        local version
        version=$("${PASTEL_BIN}" --version 2>/dev/null | grep -oP 'pastel \K[0-9.]+' || echo "unknown")
        log_verbose "pastel ${version} found in PATH (${PASTEL_BIN})"
        return 0
    fi

    # 5) Install fallback
    install_pastel
    export PASTEL_BIN="$(type -P pastel || true)"
    if [[ -z "${PASTEL_BIN}" ]]; then
        log_error "pastel installation did not produce a usable executable"
        exit 1
    fi
}

print_deps_usage() {
    cat << 'EOF'
Usage: deps.sh [OPTIONS]

Dependency helper for vsGen.

OPTIONS:
    --build     Attempt to build ../pastel submodule binary first.
    --check     Resolve dependencies and print detected pastel binary.
    -v          Verbose logging.
    -h, --help  Show this help message.

Examples:
    ./flows/vsGen/lib/deps.sh --check
    ./flows/vsGen/lib/deps.sh --build --check -v
EOF
}

deps_main() {
    local run_check=false
    local build_requested=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --build)
                build_requested=true
                shift
                ;;
            --check)
                run_check=true
                shift
                ;;
            -v)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                print_deps_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                print_deps_usage
                exit 1
                ;;
        esac
    done

    if [[ "$build_requested" == true ]]; then
        export VSGEN_BUILD_PASTEL=1
    else
        export VSGEN_BUILD_PASTEL=0
    fi

    if [[ "$run_check" == true ]]; then
        check_dependencies
        echo "$PASTEL_BIN"
        exit 0
    fi

    # Default manual behaviour: perform dependency resolution.
    check_dependencies
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    deps_main "$@"
fi
