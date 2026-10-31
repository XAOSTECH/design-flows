#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# ansi.sh — Shared ANSI 16-colour derivation for terminal targets
# ═══════════════════════════════════════════════════════════════════════════════
# Maps the generated palette (shades, analogous, triadic, complementary) onto the
# standard terminal model: foreground, background, cursor, selection and the
# 16 ANSI colours. Used by the kitty, alacritty and foot targets so the mapping
# lives in exactly one place.
#
# Requires: colours.sh (pastel wrappers) and a populated palette (generate_palette).
#
# Populates globals:
#   TUI_FG TUI_BG TUI_CURSOR TUI_SELECTION
#   TUI_C0 … TUI_C15   (normal 0-7, bright 8-15)
# ═══════════════════════════════════════════════════════════════════════════════

derive_ansi_palette() {
    local primary_hex secondary_hex tertiary_hex
    primary_hex=$(get_hex "$PRIMARY_COLOUR")
    secondary_hex=$(get_hex "$SECONDARY_COLOUR")
    tertiary_hex=$(get_hex "$TERTIARY_COLOUR")

    TUI_FG="${PRIMARY_SHADES[8]:-$(lighten "$primary_hex" 0.35)}"
    TUI_BG="$(set_lightness "$tertiary_hex" "$BG_LIGHTNESS")"
    TUI_CURSOR="${PRIMARY_SHADES[3]:-$(saturate "$primary_hex" 0.2)}"
    TUI_SELECTION="${PRIMARY_SHADES[5]:-$primary_hex}"

    # ── Normal 0-7 ──
    TUI_C0="$(darken "$TUI_BG" 0.05)"                                       # black
    TUI_C1="${COMPLEMENTARY_COLOURS[0]:-$(rotate_hue "$primary_hex" 180)}"  # red
    TUI_C2="${TRIADIC_COLOURS[2]:-$(rotate_hue "$primary_hex" 120)}"        # green
    TUI_C3="${ANALOGOUS_COLOURS[2]:-$(rotate_hue "$secondary_hex" 30)}"     # yellow
    TUI_C4="${ANALOGOUS_COLOURS[0]:-$(rotate_hue "$primary_hex" 30)}"       # blue
    TUI_C5="$primary_hex"                                                   # magenta
    TUI_C6="${TRIADIC_COLOURS[0]:-$(rotate_hue "$primary_hex" 120)}"        # cyan
    TUI_C7="$(lighten "$TUI_FG" 0.0)"                                       # white

    # ── Bright 8-15 (lifted variants of the normal set) ──
    TUI_C8="$(lighten "$TUI_C0" 0.15)"    # bright black
    TUI_C9="$(lighten "$TUI_C1" 0.1)"     # bright red
    TUI_C10="$(lighten "$TUI_C2" 0.1)"    # bright green
    TUI_C11="$(lighten "$TUI_C3" 0.1)"    # bright yellow
    TUI_C12="$(lighten "$TUI_C4" 0.1)"    # bright blue
    TUI_C13="$(lighten "$TUI_C5" 0.1)"    # bright magenta
    TUI_C14="$(lighten "$TUI_C6" 0.1)"    # bright cyan
    TUI_C15="$(lighten "$TUI_C7" 0.1)"    # bright white
}
