#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# file-ops.sh — File I/O operations for uiGen
# ═══════════════════════════════════════════════════════════════════════════════
# Handles output directory creation, theme directory structures, and
# writing generated files to disk.
#
# Requires: colours.sh sourced first (for log_* helpers)
# ═══════════════════════════════════════════════════════════════════════════════

UIGEN_VERSION="0.1.0"

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

# ─── Create GTK theme directory structure ─────────────────────────────────────
# Creates:  <output>/<ThemeName>/gtk-4.0/gtk.css
#           <output>/<ThemeName>/gtk-3.0/  (symlink → gtk-4.0/ for agnostic compat)

create_gtk_dirs() {
    local base="${OUTPUT_DIR}/${THEME_NAME}"
    mkdir -p "${base}/gtk-4.0"
    if [[ ! -e "${base}/gtk-3.0" ]]; then
        ln -s gtk-4.0 "${base}/gtk-3.0"
        log_verbose "Symlinked gtk-3.0 → gtk-4.0"
    fi
    echo "${base}"
}

# ─── Create GNOME Shell theme directory structure ─────────────────────────────

create_gnome_shell_dirs() {
    local base="${OUTPUT_DIR}/${THEME_NAME}"
    mkdir -p "${base}/gnome-shell"
    echo "${base}"
}