#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# colours.sh — Colour manipulation and palette generation for vscode-theme-gen
# ═══════════════════════════════════════════════════════════════════════════════
# All pastel wrappers and palette-building logic lives here.
# Requires: pastel CLI, deps.sh sourced for logging
# ═══════════════════════════════════════════════════════════════════════════════

# ─── Low-Level Pastel Wrappers ────────────────────────────────────────────────

# Get hex colour from pastel
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

# Mix two colours
mix_colors() {
    local colour1="$1"
    local colour2="$2"
    local factor="${3:-0.5}"
    pastel mix -f "$factor" "$colour1" "$colour2" | pastel format hex
}

# Lighten a colour
lighten() {
    local colour="$1"
    local amount="${2:-0.1}"
    pastel lighten "$amount" "$colour" | pastel format hex
}

# Darken a colour
darken() {
    local colour="$1"
    local amount="${2:-0.1}"
    pastel darken "$amount" "$colour" | pastel format hex
}

# Set lightness
set_lightness() {
    local colour="$1"
    local lightness="$2"
    pastel set lightness "$lightness" "$colour" | pastel format hex
}

# Get complementary colour
get_complementary() {
    local colour="$1"
    pastel complement "$colour" | pastel format hex
}

# Rotate hue by N degrees (supports negative values)
rotate_hue() {
    local colour="$1"
    local degrees="$2"
    pastel rotate -- "$degrees" "$colour" | pastel format hex
}

# Saturate colour
saturate() {
    local colour="$1"
    local amount="${2:-0.2}"
    pastel saturate "$amount" "$colour" | pastel format hex
}

# Desaturate colour
desaturate() {
    local colour="$1"
    local amount="${2:-0.2}"
    pastel desaturate "$amount" "$colour" | pastel format hex
}

# ─── Font/Foreground Safety ──────────────────────────────────────────────────
# Ensures foreground/font colours are never too dark to read on dark backgrounds.
# Returns the colour lightened to at least MIN_FG_LIGHTNESS if needed.

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
    local colour="$1"
    local min_lightness="${2:-$MIN_FG_LIGHTNESS}"
    local hex
    hex=$(get_hex "$colour")

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
#   PRIMARY_COLOUR, SECONDARY_COLOUR, TERTIARY_COLOUR
#   USE_COMPLEMENTARY, VARIATION
#   PRIMARY_SHADES, SECONDARY_SHADES, TERTIARY_SHADES
#   COMPLEMENTARY_COLOURS, VARIATION_COLOURS
#   ANALOGOUS_COLOURS, TRIADIC_COLOURS, BLEND_COLOURS

generate_palette() {
    log_info "Generating colour palette..."

    # ── base hex values ──
    local primary_hex secondary_hex tertiary_hex
    primary_hex=$(get_hex "$PRIMARY_COLOUR")
    secondary_hex=$(get_hex "$SECONDARY_COLOUR")
    tertiary_hex=$(get_hex "$TERTIARY_COLOUR")

    log_verbose "Primary base:   $primary_hex"
    log_verbose "Secondary base: $secondary_hex"
    log_verbose "Tertiary base:  $tertiary_hex"

    # ── primary shades (saturated → soft, 10 stops) ──
    # Variation affects the intensity of lightness/saturation shifts
    log_verbose "Generating primary gradient..."
    local primary_bright primary_soft primary_dark
    local sat_amount light_amount dark_amount
    sat_amount=$(awk "BEGIN { printf \"%.3f\", 0.15 + 0.15 * $VARIATION }")
    light_amount=$(awk "BEGIN { printf \"%.3f\", 0.10 + 0.20 * $VARIATION }")
    dark_amount=$(awk "BEGIN { printf \"%.3f\", 0.10 + 0.15 * $VARIATION }")
    primary_bright=$(saturate "$PRIMARY_COLOUR" "$sat_amount")
    primary_soft=$(lighten "$PRIMARY_COLOUR" "$light_amount")
    primary_dark=$(darken "$PRIMARY_COLOUR" "$dark_amount")
    mapfile -t PRIMARY_SHADES < <(generate_gradient "$primary_dark" "$primary_bright" 4; generate_gradient "$primary_bright" "$primary_soft" 6)

    # ── secondary shades ──
    log_verbose "Generating secondary gradient..."
    local secondary_bright secondary_soft secondary_dark
    sat_amount=$(awk "BEGIN { printf \"%.3f\", 0.15 + 0.15 * $VARIATION }")
    light_amount=$(awk "BEGIN { printf \"%.3f\", 0.12 + 0.20 * $VARIATION }")
    dark_amount=$(awk "BEGIN { printf \"%.3f\", 0.08 + 0.12 * $VARIATION }")
    secondary_bright=$(saturate "$SECONDARY_COLOUR" "$sat_amount")
    secondary_soft=$(lighten "$SECONDARY_COLOUR" "$light_amount")
    secondary_dark=$(darken "$SECONDARY_COLOUR" "$dark_amount")
    mapfile -t SECONDARY_SHADES < <(generate_gradient "$secondary_dark" "$secondary_bright" 4; generate_gradient "$secondary_bright" "$secondary_soft" 6)

    # ── tertiary shades ──
    log_verbose "Generating tertiary gradient..."
    local tertiary_bright tertiary_soft tertiary_dark
    sat_amount=$(awk "BEGIN { printf \"%.3f\", 0.12 + 0.15 * $VARIATION }")
    light_amount=$(awk "BEGIN { printf \"%.3f\", 0.10 + 0.20 * $VARIATION }")
    dark_amount=$(awk "BEGIN { printf \"%.3f\", 0.07 + 0.10 * $VARIATION }")
    tertiary_bright=$(saturate "$TERTIARY_COLOUR" "$sat_amount")
    tertiary_soft=$(lighten "$TERTIARY_COLOUR" "$light_amount")
    tertiary_dark=$(darken "$TERTIARY_COLOUR" "$dark_amount")
    mapfile -t TERTIARY_SHADES < <(generate_gradient "$tertiary_dark" "$tertiary_bright" 4; generate_gradient "$tertiary_bright" "$tertiary_soft" 6)

    # ── analogous colours (±30° from each base) ──
    log_verbose "Generating analogous colours..."
    ANALOGOUS_COLOURS=(
        "$(rotate_hue "$primary_hex"  30)"
        "$(rotate_hue "$primary_hex" -30)"
        "$(rotate_hue "$secondary_hex"  30)"
        "$(rotate_hue "$secondary_hex" -30)"
        "$(rotate_hue "$tertiary_hex"  30)"
        "$(rotate_hue "$tertiary_hex" -30)"
    )

    # ── triadic colours (±120° from primary) ──
    log_verbose "Generating triadic colours..."
    TRIADIC_COLOURS=(
        "$(rotate_hue "$primary_hex" 120)"
        "$(rotate_hue "$primary_hex" 240)"
        "$(rotate_hue "$secondary_hex" 120)"
        "$(rotate_hue "$tertiary_hex" 120)"
    )

    # ── cross-blended accent colours ──
    log_verbose "Generating cross-blend colours..."
    BLEND_COLOURS=(
        "$(mix_colors "$primary_hex" "$secondary_hex" 0.3)"
        "$(mix_colors "$primary_hex" "$secondary_hex" 0.7)"
        "$(mix_colors "$primary_hex" "$tertiary_hex" 0.4)"
        "$(mix_colors "$secondary_hex" "$tertiary_hex" 0.5)"
        "$(mix_colors "$primary_hex" "$tertiary_hex" 0.6)"
        "$(mix_colors "$(lighten "$primary_hex" 0.15)" "$secondary_hex" 0.5)"
    )

    # ── complementary colours ──
    if [[ "$USE_COMPLEMENTARY" == true ]]; then
        log_verbose "Generating complementary colours..."
        local compl_primary compl_secondary compl_tertiary mixed
        compl_primary=$(get_complementary "$PRIMARY_COLOUR")
        compl_secondary=$(get_complementary "$SECONDARY_COLOUR")
        compl_tertiary=$(get_complementary "$TERTIARY_COLOUR")
        mixed=$(mix_colors "$PRIMARY_COLOUR" "$SECONDARY_COLOUR" 0.5)

        # Split-complementary (±150° from primary)
        local split_a split_b
        split_a=$(rotate_hue "$primary_hex" 150)
        split_b=$(rotate_hue "$primary_hex" 210)

        COMPLEMENTARY_COLOURS=(
            "$compl_primary"
            "$compl_secondary"
            "$(lighten "$compl_primary" 0.2)"
            "$(lighten "$compl_secondary" 0.2)"
            "$mixed"
            "$(get_complementary "$mixed")"
            "$compl_tertiary"
            "$(lighten "$compl_tertiary" 0.15)"
            "$split_a"
            "$split_b"
            "$(mix_colors "$compl_primary" "$compl_tertiary" 0.5)"
            "$(saturate "$compl_secondary" 0.15)"
        )
    fi

    # ── variation-driven extra hues ──
    # VARIATION 0 = no extras, 0.5 = standard, 1.0 = rainbow cacophony
    if (( $(awk "BEGIN { print ($VARIATION > 0) }") )); then
        log_verbose "Generating variation hues (level $VARIATION)..."
        local steps angle_step
        # Number of extra hues scales with variation: 0→0  0.5→6  1.0→16
        steps=$(awk "BEGIN { printf \"%d\", 4 + 12 * $VARIATION }")
        angle_step=$(awk "BEGIN { printf \"%.1f\", 360.0 / $steps }")
        VARIATION_COLOURS=()

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

            VARIATION_COLOURS+=("$rotated")
        done
    fi

    log_success "Palette generated (${#PRIMARY_SHADES[@]}+${#SECONDARY_SHADES[@]}+${#TERTIARY_SHADES[@]} shades, ${#ANALOGOUS_COLOURS[@]} analogous, ${#TRIADIC_COLOURS[@]} triadic, ${#BLEND_COLOURS[@]} blends)"
}

# ─── Palette Preview ─────────────────────────────────────────────────────────

show_palette_preview() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  🎨 ${THEME_NAME} - Colour Palette Preview"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    echo "  Primary: ${PRIMARY_COLOUR}"
    echo "  ─────────────────────────────────────"
    for i in "${!PRIMARY_SHADES[@]}"; do
        local hex="${PRIMARY_SHADES[$i]}"
        printf "  "
        pastel paint "$hex" "████"
        printf " %s\n" "$hex"
    done

    echo ""
    echo "  Secondary: ${SECONDARY_COLOUR}"
    echo "  ─────────────────────────────────────"
    for i in "${!SECONDARY_SHADES[@]}"; do
        local hex="${SECONDARY_SHADES[$i]}"
        printf "  "
        pastel paint "$hex" "████"
        printf " %s\n" "$hex"
    done

    echo ""
    echo "  Tertiary: ${TERTIARY_COLOUR}"
    echo "  ─────────────────────────────────────"
    for i in "${!TERTIARY_SHADES[@]}"; do
        local hex="${TERTIARY_SHADES[$i]}"
        printf "  "
        pastel paint "$hex" "████"
        printf " %s\n" "$hex"
    done

    if [[ "$USE_COMPLEMENTARY" == true ]] && [[ ${#COMPLEMENTARY_COLOURS[@]} -gt 0 ]]; then
        echo ""
        echo "  Complementary Accents:"
        echo "  ─────────────────────────────────────"
        for i in "${!COMPLEMENTARY_COLOURS[@]}"; do
            local hex="${COMPLEMENTARY_COLOURS[$i]}"
            printf "  "
            pastel paint "$hex" "████"
            printf " %s\n" "$hex"
        done
    fi

    if [[ ${#VARIATION_COLOURS[@]} -gt 0 ]]; then
        echo ""
        echo "  Variation Hues (level ${VARIATION}):"
        echo "  ─────────────────────────────────────"
        for i in "${!VARIATION_COLOURS[@]}"; do
            local hex="${VARIATION_COLOURS[$i]}"
            printf "  "
            pastel paint "$hex" "████"
            printf " %s\n" "$hex"
        done
    fi

    if [[ ${#ANALOGOUS_COLOURS[@]} -gt 0 ]]; then
        echo ""
        echo "  Analogous (±30°):"
        echo "  ─────────────────────────────────────"
        for i in "${!ANALOGOUS_COLOURS[@]}"; do
            local hex="${ANALOGOUS_COLOURS[$i]}"
            printf "  "
            pastel paint "$hex" "████"
            printf " %s\n" "$hex"
        done
    fi

    if [[ ${#TRIADIC_COLOURS[@]} -gt 0 ]]; then
        echo ""
        echo "  Triadic (±120°):"
        echo "  ─────────────────────────────────────"
        for i in "${!TRIADIC_COLOURS[@]}"; do
            local hex="${TRIADIC_COLOURS[$i]}"
            printf "  "
            pastel paint "$hex" "████"
            printf " %s\n" "$hex"
        done
    fi

    if [[ ${#BLEND_COLOURS[@]} -gt 0 ]]; then
        echo ""
        echo "  Cross-Blends:"
        echo "  ─────────────────────────────────────"
        for i in "${!BLEND_COLOURS[@]}"; do
            local hex="${BLEND_COLOURS[$i]}"
            printf "  "
            pastel paint "$hex" "████"
            printf " %s\n" "$hex"
        done
    fi

    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo ""
}
