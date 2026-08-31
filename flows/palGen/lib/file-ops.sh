#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# file-ops.sh — File I/O and token flattening for palGen
# ═══════════════════════════════════════════════════════════════════════════════
# Handles output-directory resolution, writing generated files to disk, and
# flattening the palette arrays into an ordered list of named colour tokens
# that every export format consumes.
#
# Requires: colours.sh sourced first (for log_* helpers and pastel wrappers)
# ═══════════════════════════════════════════════════════════════════════════════

PALGEN_VERSION="0.1.0"

# Standard tint/shade scale (lightest → darkest) for the 10-stop shade arrays.
PALGEN_SCALE=(50 100 200 300 400 500 600 700 800 900)

# ─── Default output path ─────────────────────────────────────────────────────
# ./out/<PaletteName>-<date>/

resolve_default_output() {
    local out_dir="${SCRIPT_DIR}/../out"
    local datestamp
    datestamp=$(date +%Y-%m-%d)
    echo "${out_dir}/$(safe_theme_name)-${datestamp}"
}

# ─── Safe, filesystem-friendly palette name ──────────────────────────────────

safe_theme_name() {
    local safe
    safe=$(echo "$THEME_NAME" | tr ' ' '-' | tr -cd '[:alnum:]-_')
    [[ -z "$safe" ]] && safe="palette"
    printf '%s' "$safe"
}

# ─── Hex → "R G B" (space-separated, padded) ─────────────────────────────────
# Usage: hex_rgb_spaced "#ff69b4" → "255 105 180"

hex_rgb_spaced() {
    local hex="${1#\#}"
    printf '%3d %3d %3d' "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

# ─── Write an export file ────────────────────────────────────────────────────
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

# ─── Token flattening ────────────────────────────────────────────────────────
# Flattens every palette array into three parallel, order-preserving globals:
#   TOKEN_NAMES[]   — hyphenated token name (e.g. "primary-500", "analogous-1")
#   TOKEN_HEXES[]   — matching #rrggbb value
#   TOKEN_GROUPS[]  — ordered, de-duplicated group prefixes (name before last '-')
#
# Every token name uses exactly one hyphen so group/key splitting is trivial:
#   group="${name%-*}"   key="${name##*-}"

_add_token() {
    TOKEN_NAMES+=("$1")
    TOKEN_HEXES+=("$2")
}

# Emit a 10-stop shade array as <prefix>-50 … <prefix>-900 (lightest → darkest).
# The source array runs darkest → lightest, so the scale index is reversed.
_add_shade_group() {
    local prefix="$1"; shift
    local -a shades=("$@")
    local count="${#shades[@]}"
    local i scale_idx step
    for (( i = 0; i < count; i++ )); do
        scale_idx=$(( count - 1 - i ))
        step="${PALGEN_SCALE[$scale_idx]:-$(( (i + 1) * 100 ))}"
        _add_token "${prefix}-${step}" "$(get_hex "${shades[$i]}")"
    done
}

# Emit an accent array as <prefix>-1 … <prefix>-N.
_add_accent_group() {
    local prefix="$1"; shift
    local -a cols=("$@")
    local i
    for i in "${!cols[@]}"; do
        _add_token "${prefix}-$(( i + 1 ))" "$(get_hex "${cols[$i]}")"
    done
}

# Emit derived surface/foreground tokens driven by BG_LIGHTNESS.
_add_base_group() {
    local primary_hex tertiary_hex bg surface overlay fg muted
    primary_hex=$(get_hex "$PRIMARY_COLOUR")
    tertiary_hex=$(get_hex "$TERTIARY_COLOUR")

    bg=$(set_lightness "$tertiary_hex" "$BG_LIGHTNESS")
    surface=$(lighten "$bg" 0.05)
    overlay=$(lighten "$bg" 0.10)
    fg=$(ensure_readable "$(lighten "$primary_hex" 0.35)")
    muted=$(ensure_readable "$(mix_colors "$fg" "$bg" 0.35)")

    _add_token "base-bg" "$bg"
    _add_token "base-surface" "$surface"
    _add_token "base-overlay" "$overlay"
    _add_token "base-fg" "$fg"
    _add_token "base-muted" "$muted"
}

collect_tokens() {
    log_info "Flattening palette into tokens..."

    TOKEN_NAMES=()
    TOKEN_HEXES=()
    TOKEN_GROUPS=()

    _add_base_group
    _add_shade_group "primary"   "${PRIMARY_SHADES[@]}"
    _add_shade_group "secondary" "${SECONDARY_SHADES[@]}"
    _add_shade_group "tertiary"  "${TERTIARY_SHADES[@]}"

    [[ ${#ANALOGOUS_COLOURS[@]}     -gt 0 ]] && _add_accent_group "analogous"     "${ANALOGOUS_COLOURS[@]}"
    [[ ${#TRIADIC_COLOURS[@]}       -gt 0 ]] && _add_accent_group "triadic"       "${TRIADIC_COLOURS[@]}"
    [[ ${#BLEND_COLOURS[@]}         -gt 0 ]] && _add_accent_group "blend"         "${BLEND_COLOURS[@]}"
    [[ ${#COMPLEMENTARY_COLOURS[@]} -gt 0 ]] && _add_accent_group "complementary" "${COMPLEMENTARY_COLOURS[@]}"
    [[ ${#VARIATION_COLOURS[@]}     -gt 0 ]] && _add_accent_group "variation"     "${VARIATION_COLOURS[@]}"

    # Build the ordered, de-duplicated list of group prefixes.
    local seen=" " name g
    for name in "${TOKEN_NAMES[@]}"; do
        g="${name%-*}"
        if [[ "$seen" != *" $g "* ]]; then
            TOKEN_GROUPS+=("$g")
            seen="${seen}${g} "
        fi
    done

    log_success "Collected ${#TOKEN_NAMES[@]} tokens across ${#TOKEN_GROUPS[@]} groups"
}

# ─── Token queries (used by format writers) ──────────────────────────────────
# Echoes "key<TAB>hex" for each token belonging to a group, preserving order.

tokens_in_group() {
    local group="$1" i name
    for i in "${!TOKEN_NAMES[@]}"; do
        name="${TOKEN_NAMES[$i]}"
        [[ "${name%-*}" == "$group" ]] || continue
        printf '%s\t%s\n' "${name##*-}" "${TOKEN_HEXES[$i]}"
    done
}
