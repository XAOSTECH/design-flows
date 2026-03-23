#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# presets.sh — Built-in colour presets for vscode-theme-gen
# ═══════════════════════════════════════════════════════════════════════════════
# Each preset defines PRIMARY_COLOUR, SECONDARY_COLOUR, TERTIARY_COLOUR,
# THEME_NAME, and optionally USE_COMPLEMENTARY / VARIATION.
# ═══════════════════════════════════════════════════════════════════════════════

declare -A PRESET_NAMES=(
    [sakura]="Sakura Sunset"
    [ocean]="Deep Ocean"
    [forest]="Enchanted Forest"
    [sunset]="Golden Sunset"
    [neon]="Neon Nights"
    [nord]="Nordic Frost"
    [dracula]="Dracula Rose"
    [pastel]="Pastel Dream"
)

apply_preset() {
    local preset="$1"
    case "$preset" in
        sakura)
            PRIMARY_COLOUR="#ff69b4"
            SECONDARY_COLOUR="#ffd700"
            TERTIARY_COLOUR="#b19cd9"
            THEME_NAME="Sakura Sunset"
            USE_COMPLEMENTARY=true
            ;;
        ocean)
            PRIMARY_COLOUR="#0077be"
            SECONDARY_COLOUR="#00bcd4"
            TERTIARY_COLOUR="#80deea"
            THEME_NAME="Deep Ocean"
            VARIATION="0.3"
            ;;
        forest)
            PRIMARY_COLOUR="#2e7d32"
            SECONDARY_COLOUR="#aed581"
            TERTIARY_COLOUR="#795548"
            THEME_NAME="Enchanted Forest"
            ;;
        sunset)
            PRIMARY_COLOUR="#ff6f00"
            SECONDARY_COLOUR="#ffd54f"
            TERTIARY_COLOUR="#e65100"
            THEME_NAME="Golden Sunset"
            USE_COMPLEMENTARY=true
            VARIATION="0.4"
            ;;
        neon)
            PRIMARY_COLOUR="#ff00ff"
            SECONDARY_COLOUR="#00ff41"
            TERTIARY_COLOUR="#00d4ff"
            THEME_NAME="Neon Nights"
            VARIATION="0.8"
            USE_COMPLEMENTARY=true
            ;;
        nord)
            PRIMARY_COLOUR="#81a1c1"
            SECONDARY_COLOUR="#a3be8c"
            TERTIARY_COLOUR="#b48ead"
            THEME_NAME="Nordic Frost"
            VARIATION="0.2"
            ;;
        dracula)
            PRIMARY_COLOUR="#ff79c6"
            SECONDARY_COLOUR="#f1fa8c"
            TERTIARY_COLOUR="#bd93f9"
            THEME_NAME="Dracula Rose"
            USE_COMPLEMENTARY=true
            VARIATION="0.5"
            ;;
        pastel)
            PRIMARY_COLOUR="#f8bbd0"
            SECONDARY_COLOUR="#fff9c4"
            TERTIARY_COLOUR="#c5cae9"
            THEME_NAME="Pastel Dream"
            VARIATION="0.3"
            ;;
        *)
            log_error "Unknown preset: $preset"
            echo ""
            list_presets
            exit 1
            ;;
    esac
    log_info "Applied preset: ${THEME_NAME}"
}

list_presets() {
    echo "  Available presets:"
    echo "  ─────────────────────────────────────"
    echo "    sakura   — Pink / Gold / Lavender (complementary)"
    echo "    ocean    — Blue / Cyan / Light Cyan"
    echo "    forest   — Green / Light Green / Brown"
    echo "    sunset   — Orange / Gold / Deep Orange (complementary)"
    echo "    neon     — Magenta / Neon Green / Cyan (high variation)"
    echo "    nord     — Steel Blue / Sage / Purple"
    echo "    dracula  — Pink / Yellow / Purple (complementary)"
    echo "    pastel   — Pastel Pink / Yellow / Indigo"
    echo ""
}
