#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# file-ops.sh — File I/O operations for tuiGen
# ═══════════════════════════════════════════════════════════════════════════════
# Handles output directory resolution, writing generated files to disk, and
# optional installation into a user's live config directory.
#
# Requires: colours.sh sourced first (for log_* helpers)
# ═══════════════════════════════════════════════════════════════════════════════

TUIGEN_VERSION="0.1.0"

# ─── Default output path ─────────────────────────────────────────────────────
# ./out/<ThemeName>-<date>/

resolve_default_output() {
    local out_dir="${SCRIPT_DIR}/../out"

    local safe_name
    safe_name=$(echo "$THEME_NAME" | tr ' ' '-' | tr -cd '[:alnum:]-_')
    [[ -z "$safe_name" ]] && safe_name="theme"

    local datestamp
    datestamp=$(date +%Y-%m-%d)

    echo "${out_dir}/${safe_name}-${datestamp}"
}

# ─── Theme-safe name ─────────────────────────────────────────────────────────
# Sanitise the theme name for use as a file or palette identifier.
# Usage: safe_theme_name → "Neon-Pink"

safe_theme_name() {
    local safe_name
    safe_name=$(echo "$THEME_NAME" | tr ' ' '-' | tr -cd '[:alnum:]-_')
    [[ -z "$safe_name" ]] && safe_name="theme"
    echo "$safe_name"
}

# ─── Hex to RGB components ───────────────────────────────────────────────────
# Usage: hex_to_rgb "#ff69b4" → "255, 105, 180"

hex_to_rgb() {
    local hex="${1#\#}"
    printf "%d, %d, %d" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

# ─── Write a target file ─────────────────────────────────────────────────────
# Creates parent directories and writes content.
# In dry-run mode, prints to stdout instead.
#
# Usage: write_target_file "path/to/file" "$content"

write_target_file() {
    local filepath="$1"
    local content="$2"

    if [[ "$DRY_RUN" == true ]]; then
        echo "─── ${filepath} ───────────────────────────────"
        echo "$content"
        echo "────────────────────────────────────────────────"
        echo ""
        return
    fi

    local dir
    dir="$(dirname "$filepath")"
    mkdir -p "$dir"
    printf '%s\n' "$content" > "$filepath"
    log_success "Wrote: ${filepath}"
}

# ─── Install a generated file into a live config directory ───────────────────
# Copies a generated file into a destination directory, but only when that
# directory already exists (we never create a user's tool config tree for them).
# Honours dry-run. Advisory and non-fatal: a skipped install is a normal
# outcome, so this always returns 0 — never let it abort a target under set -e.
#
# Usage: install_to_config "$generated_file" "${HOME}/.config/kitty" ["label"]

install_to_config() {
    local source_file="$1"
    local dest_dir="$2"
    local label="${3:-$(basename "$dest_dir")}"

    if [[ "$DRY_RUN" == true ]]; then
        return 0
    fi
    if [[ ! -d "$dest_dir" ]]; then
        log_verbose "Skipped ${label} install: ${dest_dir} not present"
        return 0
    fi

    cp "$source_file" "${dest_dir}/"
    log_success "Installed ${label}: ${dest_dir}/$(basename "$source_file")"
    return 0
}
