#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# colors.sh — Color manipulation and palette generation for vscode-theme-gen
# ═══════════════════════════════════════════════════════════════════════════════
# All pastel wrappers and palette-building logic lives here.
# Requires: pastel CLI, deps.sh sourced for logging
# ═══════════════════════════════════════════════════════════════════════════════

# ─── Low-Level Pastel Wrappers ────────────────────────────────────────────────

# Get hex color from pastel
get_hex() {
    pastel format hex "$1" 2>/dev/null | tr -d '\n'
}

# Generate gradient shades
generate_gradient() {
    local from="$1"
    local to="$2"
    local count="${3:-6}"
    pastel gradient -n "$count" "$from" "$to" | pastel format hex
}

# Mix two colors
mix_colors() {
    local color1="$1"
    local color2="$2"
    local factor="${3:-0.5}"
    pastel mix -f "$factor" "$color1" "$color2" | pastel format hex
}

# Lighten a color
lighten() {
    local color="$1"
    local amount="${2:-0.1}"
    pastel lighten "$amount" "$color" | pastel format hex
}

# Darken a color
darken() {
    local color="$1"
    local amount="${2:-0.1}"
    pastel darken "$amount" "$color" | pastel format hex
}

# Set lightness
set_lightness() {
    local color="$1"
    local lightness="$2"
    pastel set lightness "$lightness" "$color" | pastel format hex
}

# Get complementary color
get_complementary() {
    local color="$1"
    pastel complement "$color" | pastel format hex
}

# Rotate hue by N degrees
rotate_hue() {
    local color="$1"
    local degrees="$2"
    pastel rotate "$degrees" "$color" | pastel format hex
}

# Saturate color
saturate() {
    local color="$1"
    local amount="${2:-0.2}"
    pastel saturate "$amount" "$color" | pastel format hex
}

# Desaturate color
desaturate() {
    local color="$1"
    local amount="${2:-0.2}"
    pastel desaturate "$amount" "$color" | pastel format hex
}

# ─── Font/Foreground Safety ──────────────────────────────────────────────────
# Ensures foreground/font colors are never too dark to read on dark backgrounds.
# Returns the color lightened to at least MIN_FG_LIGHTNESS if needed.

MIN_FG_LIGHTNESS="0.45"

# Compute relative luminance (sRGB → linear → Y) for a hex colour.
# Returns a value 0.0 (black) – 1.0 (white).
_luminance() {
    local hex="$1"
    # Strip leading #
    hex="${hex#\#}"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    awk "BEGIN {
        r = $r/255.0; g = $g/255.0; b = $b/255.0;
        r = (r<=0.03928) ? r/12.92 : ((r+0.055)/1.055)^2.4;
        g = (g<=0.03928) ? g/12.92 : ((g+0.055)/1.055)^2.4;
        b = (b<=0.03928) ? b/12.92 : ((b+0.055)/1.055)^2.4;
        printf \"%.6f\", 0.2126*r + 0.7152*g + 0.0722*b
    }"
}

# WCAG contrast ratio between two hex colours.
_contrast_ratio() {
    local lum1 lum2
    lum1=$(_luminance "$1")
    lum2=$(_luminance "$2")
    awk "BEGIN {
        l1 = ($lum1 > $lum2) ? $lum1 : $lum2;
        l2 = ($lum1 > $lum2) ? $lum2 : $lum1;
        printf \"%.2f\", (l1 + 0.05) / (l2 + 0.05)
    }"
}

# Ensure a foreground colour is readable on a dark editor background.
# Strategy: first check HSL lightness floor, then verify WCAG contrast
# ratio ≥ 3.0 against a typical dark background (#1e1e1e). If too low,
# lighten iteratively until it passes.
ensure_readable() {
    local color="$1"
    local min_lightness="${2:-$MIN_FG_LIGHTNESS}"
    local hex
    hex=$(get_hex "$color")

    # ── Step 1: HSL lightness floor ──
    local current_lightness
    current_lightness=$(pastel format hsl "$hex" 2>/dev/null \
        | grep -oP '[\d.]+(?=%)' | tail -1)

    if [[ -n "$current_lightness" ]]; then
        local norm
        norm=$(awk "BEGIN { printf \"%.4f\", $current_lightness / 100.0 }")
        local too_dark
        too_dark=$(awk "BEGIN { print ($norm < $min_lightness) ? 1 : 0 }")
        if [[ "$too_dark" == "1" ]]; then
            log_verbose "Lightness guard: $hex → lifting to L=$min_lightness"
            hex=$(set_lightness "$hex" "$min_lightness")
        fi
    fi

    # ── Step 2: WCAG contrast ratio check against dark bg ──
    local bg="#1e1e1e"
    local ratio
    ratio=$(_contrast_ratio "$hex" "$bg")
    local attempts=0
    while (( $(awk "BEGIN { print ($ratio < 3.0) ? 1 : 0 }") )) && (( attempts < 8 )); do
        log_verbose "Contrast guard: $hex ratio=$ratio < 3.0 — lightening"
        hex=$(lighten "$hex" 0.05)
        ratio=$(_contrast_ratio "$hex" "$bg")
        ((attempts++))
    done

    echo "$hex"
}

# ─── Palette Generation ──────────────────────────────────────────────────────
# Populates the global shade arrays used by the theme generator.
#
# Globals expected (set before calling):
#   PRIMARY_COLOR, SECONDARY_COLOR, TERTIARY_COLOR
#   USE_COMPLEMENTARY, VARIATION
#   PRIMARY_SHADES, SECONDARY_SHADES, TERTIARY_SHADES
#   COMPLEMENTARY_COLORS, VARIATION_COLORS

generate_palette() {
    log_info "Generating color palette..."

    # ── base hex values ──
    local primary_hex secondary_hex tertiary_hex
    primary_hex=$(get_hex "$PRIMARY_COLOR")
    secondary_hex=$(get_hex "$SECONDARY_COLOR")
    tertiary_hex=$(get_hex "$TERTIARY_COLOR")

    log_verbose "Primary base:   $primary_hex"
    log_verbose "Secondary base: $secondary_hex"
    log_verbose "Tertiary base:  $tertiary_hex"

    # ── primary shades ──
    log_verbose "Generating primary gradient..."
    local primary_bright primary_soft
    primary_bright=$(saturate "$PRIMARY_COLOR" 0.2)
    primary_soft=$(lighten "$PRIMARY_COLOR" 0.15)
    mapfile -t PRIMARY_SHADES < <(generate_gradient "$primary_bright" "$primary_soft" 8)

    # ── secondary shades ──
    log_verbose "Generating secondary gradient..."
    local secondary_bright secondary_soft
    secondary_bright=$(saturate "$SECONDARY_COLOR" 0.2)
    secondary_soft=$(lighten "$SECONDARY_COLOR" 0.2)
    mapfile -t SECONDARY_SHADES < <(generate_gradient "$secondary_bright" "$secondary_soft" 8)

    # ── tertiary shades ──
    log_verbose "Generating tertiary gradient..."
    local tertiary_bright tertiary_soft
    tertiary_bright=$(saturate "$TERTIARY_COLOR" 0.15)
    tertiary_soft=$(lighten "$TERTIARY_COLOR" 0.18)
    mapfile -t TERTIARY_SHADES < <(generate_gradient "$tertiary_bright" "$tertiary_soft" 8)

    # ── complementary colors ──
    if [[ "$USE_COMPLEMENTARY" == true ]]; then
        log_verbose "Generating complementary colors..."
        local compl_primary compl_secondary compl_tertiary mixed
        compl_primary=$(get_complementary "$PRIMARY_COLOR")
        compl_secondary=$(get_complementary "$SECONDARY_COLOR")
        compl_tertiary=$(get_complementary "$TERTIARY_COLOR")
        mixed=$(mix_colors "$PRIMARY_COLOR" "$SECONDARY_COLOR" 0.5)

        COMPLEMENTARY_COLORS=(
            "$compl_primary"
            "$compl_secondary"
            "$(lighten "$compl_primary" 0.2)"
            "$(lighten "$compl_secondary" 0.2)"
            "$mixed"
            "$(get_complementary "$mixed")"
            "$compl_tertiary"
            "$(lighten "$compl_tertiary" 0.15)"
        )
    fi

    # ── variation-driven extra hues ──
    # VARIATION 0 = no extras, 0.5 = standard, 1.0 = rainbow cacophony
    if (( $(awk "BEGIN { print ($VARIATION > 0) }") )); then
        log_verbose "Generating variation hues (level $VARIATION)..."
        local steps angle_step
        # Number of extra hues scales with variation: 0→0  0.5→4  1.0→12
        steps=$(awk "BEGIN { printf \"%d\", 4 + 8 * $VARIATION }")
        angle_step=$(awk "BEGIN { printf \"%.1f\", 360.0 / $steps }")
        VARIATION_COLORS=()

        for (( i=0; i<steps; i++ )); do
            local angle
            angle=$(awk "BEGIN { printf \"%.1f\", $i * $angle_step }")
            local rotated
            rotated=$(rotate_hue "$primary_hex" "$angle")

            # Mix back toward primary by (1 - variation) so low variation
            # keeps hues close while high variation lets them go wild.
            local mix_factor
            mix_factor=$(awk "BEGIN { printf \"%.2f\", 1.0 - $VARIATION }")
            if (( $(awk "BEGIN { print ($mix_factor > 0.02) }") )); then
                rotated=$(mix_colors "$rotated" "$primary_hex" "$mix_factor")
            fi

            VARIATION_COLORS+=("$rotated")
        done
    fi

    log_success "Palette generated (${#PRIMARY_SHADES[@]}+${#SECONDARY_SHADES[@]}+${#TERTIARY_SHADES[@]} shades)"
}

# ─── Palette Preview ─────────────────────────────────────────────────────────

show_palette_preview() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  🎨 ${THEME_NAME} - Color Palette Preview"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    echo "  Primary: ${PRIMARY_COLOR}"
    echo "  ─────────────────────────────────────"
    for i in "${!PRIMARY_SHADES[@]}"; do
        local hex="${PRIMARY_SHADES[$i]}"
        printf "  "
        pastel paint "$hex" "████"
        printf " %s\n" "$hex"
    done

    echo ""
    echo "  Secondary: ${SECONDARY_COLOR}"
    echo "  ─────────────────────────────────────"
    for i in "${!SECONDARY_SHADES[@]}"; do
        local hex="${SECONDARY_SHADES[$i]}"
        printf "  "
        pastel paint "$hex" "████"
        printf " %s\n" "$hex"
    done

    echo ""
    echo "  Tertiary: ${TERTIARY_COLOR}"
    echo "  ─────────────────────────────────────"
    for i in "${!TERTIARY_SHADES[@]}"; do
        local hex="${TERTIARY_SHADES[$i]}"
        printf "  "
        pastel paint "$hex" "████"
        printf " %s\n" "$hex"
    done

    if [[ "$USE_COMPLEMENTARY" == true ]] && [[ ${#COMPLEMENTARY_COLORS[@]} -gt 0 ]]; then
        echo ""
        echo "  Complementary Accents:"
        echo "  ─────────────────────────────────────"
        for i in "${!COMPLEMENTARY_COLORS[@]}"; do
            local hex="${COMPLEMENTARY_COLORS[$i]}"
            printf "  "
            pastel paint "$hex" "████"
            printf " %s\n" "$hex"
        done
    fi

    if [[ ${#VARIATION_COLORS[@]} -gt 0 ]]; then
        echo ""
        echo "  Variation Hues (level ${VARIATION}):"
        echo "  ─────────────────────────────────────"
        for i in "${!VARIATION_COLORS[@]}"; do
            local hex="${VARIATION_COLORS[$i]}"
            printf "  "
            pastel paint "$hex" "████"
            printf " %s\n" "$hex"
        done
    fi

    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo ""
}
