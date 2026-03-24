#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# gnome-shell.sh — GNOME Shell theme target for uiGen
# ═══════════════════════════════════════════════════════════════════════════════
# Generates a comprehensive gnome-shell.css covering:
#   Stage, panel, popup menus, modal dialogs, workspace switcher, overview,
#   search, buttons, quick settings, calendar, notifications, tooltips,
#   sliders/switches, window picker, app icons, dash, looking glass, OSD,
#   lock screen, alt-tab switcher, app grid/folders, screenshot UI,
#   on-screen keyboard, system dialogs, world clock/weather, tile preview,
#   and global typography.
# ═══════════════════════════════════════════════════════════════════════════════

generate_gnome_shell() {
    local base
    base=$(create_gnome_shell_dirs)
    local outfile="${base}/gnome-shell/gnome-shell.css"

    # ── Derive colours from palette ──────────────────────────────────────────
    local primary_hex secondary_hex tertiary_hex
    primary_hex=$(get_hex "$PRIMARY_COLOUR")
    secondary_hex=$(get_hex "$SECONDARY_COLOUR")
    tertiary_hex=$(get_hex "$TERTIARY_COLOUR")

    local fg_colour accent_colour accent_bright
    fg_colour="${PRIMARY_SHADES[8]:-$(lighten "$primary_hex" 0.35)}"
    accent_colour="${PRIMARY_SHADES[5]:-$primary_hex}"
    accent_bright="${PRIMARY_SHADES[3]:-$(saturate "$primary_hex" 0.2)}"

    local bg_deep bg_mid bg_light
    bg_deep="$tertiary_hex"
    bg_mid="$secondary_hex"
    bg_light="${SECONDARY_SHADES[7]:-$(lighten "$secondary_hex" 0.15)}"

    local glow_colour glow_soft border_colour
    glow_colour="${BLEND_COLOURS[0]:-$(mix_colors "$primary_hex" "$secondary_hex" 0.5)}"
    glow_soft="${BLEND_COLOURS[1]:-$(lighten "$glow_colour" 0.15)}"
    border_colour="${PRIMARY_SHADES[6]:-$(lighten "$primary_hex" 0.25)}"

    # RGB components for rgba() usage
    local bg_deep_rgb bg_mid_rgb bg_light_rgb
    bg_deep_rgb=$(hex_to_rgb "$bg_deep")
    bg_mid_rgb=$(hex_to_rgb "$bg_mid")
    bg_light_rgb=$(hex_to_rgb "$bg_light")

    local accent_rgb accent_bright_rgb fg_rgb
    accent_rgb=$(hex_to_rgb "$accent_colour")
    accent_bright_rgb=$(hex_to_rgb "$accent_bright")
    fg_rgb=$(hex_to_rgb "$fg_colour")

    local glow_rgb glow_soft_rgb border_rgb
    glow_rgb=$(hex_to_rgb "$glow_colour")
    glow_soft_rgb=$(hex_to_rgb "$glow_soft")
    border_rgb=$(hex_to_rgb "$border_colour")

    local blur="${BLUR_RADIUS}"
    local radius="${BORDER_RADIUS}"

    # ── Animation block (conditional) ────────────────────────────────────────
    local anim_header="" anim_panels="" anim_panel_bar="" anim_panel_hover=""
    local anim_popup="" anim_stage_extra=""

    if [[ "$ANIMATED" == true ]]; then
        anim_header="$(cat << ANIMEOF
@keyframes pastelGlow {
  0%   {
    box-shadow: 0 0 6px rgba(${glow_rgb}, 0.3), 0 0 12px rgba(${glow_soft_rgb}, 0.2), 0 0 18px rgba(${border_rgb}, 0.15), inset 0 0 10px rgba(${fg_rgb}, 0.1);
    border-color: rgba(${border_rgb}, 0.4);
  }
  25%  {
    box-shadow: 0 0 15px rgba(${glow_rgb}, 0.5), 0 0 25px rgba(${glow_soft_rgb}, 0.4), 0 0 35px rgba(${border_rgb}, 0.3), inset 0 0 18px rgba(${fg_rgb}, 0.25);
    border-color: rgba(${border_rgb}, 0.8);
  }
  50%  {
    box-shadow: 0 0 8px rgba(${glow_rgb}, 0.35), 0 0 15px rgba(${glow_soft_rgb}, 0.25), 0 0 22px rgba(${border_rgb}, 0.18), inset 0 0 12px rgba(${fg_rgb}, 0.12);
    border-color: rgba(${border_rgb}, 0.5);
  }
  75%  {
    box-shadow: 0 0 18px rgba(${glow_rgb}, 0.55), 0 0 30px rgba(${glow_soft_rgb}, 0.45), 0 0 40px rgba(${glow_rgb}, 0.35), inset 0 0 20px rgba(${glow_soft_rgb}, 0.28);
    border-color: rgba(${fg_rgb}, 0.85);
  }
  100% {
    box-shadow: 0 0 6px rgba(${glow_rgb}, 0.3), 0 0 12px rgba(${glow_soft_rgb}, 0.2), 0 0 18px rgba(${border_rgb}, 0.15), inset 0 0 10px rgba(${fg_rgb}, 0.1);
    border-color: rgba(${border_rgb}, 0.4);
  }
}

@keyframes mistDrift {
  0%   { background-position: 0% 0%; opacity: 0.5; }
  25%  { background-position: 100% 0%; opacity: 0.7; }
  50%  { background-position: 100% 100%; opacity: 0.5; }
  75%  { background-position: 0% 100%; opacity: 0.7; }
  100% { background-position: 0% 0%; opacity: 0.5; }
}

ANIMEOF
)"
        anim_stage_extra="  background-size: 400% 400%;
  animation: mistDrift 6s ease-in-out infinite;"
        anim_panels="  animation: pastelGlow 2s ease-in-out infinite;"
        anim_panel_bar="  animation: pastelGlow 1.8s ease-in-out infinite;"
        anim_panel_hover="  animation: pastelGlow 1.2s ease-in-out infinite;"
        anim_popup="  animation: pastelGlow 2.2s ease-in-out infinite;"
    fi

    # ── Static box-shadow fallbacks (used when not animated) ─────────────────
    local shadow_panels="" shadow_panel_bar="" shadow_popup=""
    if [[ "$ANIMATED" != true ]]; then
        shadow_panels="  box-shadow: 0 0 10px rgba(${glow_rgb}, 0.4),
              0 0 20px rgba(${glow_soft_rgb}, 0.25),
              0 0 30px rgba(${border_rgb}, 0.15),
              inset 0 0 15px rgba(${fg_rgb}, 0.15);"
        shadow_panel_bar="  box-shadow: 0 0 12px rgba(${glow_rgb}, 0.45),
              0 0 24px rgba(${glow_soft_rgb}, 0.3),
              0 0 35px rgba(${border_rgb}, 0.2),
              inset 0 0 18px rgba(${fg_rgb}, 0.18);"
        shadow_popup="  box-shadow: 0 0 10px rgba(${glow_rgb}, 0.4),
              0 0 20px rgba(${glow_soft_rgb}, 0.25),
              inset 0 0 12px rgba(${fg_rgb}, 0.12);"
    fi

    # ── Build the CSS ────────────────────────────────────────────────────────
    local css
    css="$(cat << CSSEOF
/* ═══════════════════════════════════════════════════════════════════
 * ${THEME_NAME} — GNOME Shell Theme
 * Generated by uiGen (https://github.com/XAOSTECH/design-flows)
 * Colours derived with pastel (https://github.com/sharkdp/pastel)
 * ═══════════════════════════════════════════════════════════════════ */

${anim_header}
/* ─── Global Typography ───────────────────────────────────────────── */
stage {
  font-family: 'Cantarell', 'Inter', 'Noto Sans', sans-serif;
  font-size: 11pt;
  color: ${fg_colour};
  background: linear-gradient(45deg,
    rgba(${bg_deep_rgb}, 0.45),
    rgba(${accent_bright_rgb}, 0.15),
    rgba(${bg_mid_rgb}, 0.5),
    rgba(${bg_light_rgb}, 0.2),
    rgba(${bg_deep_rgb}, 0.48));
${anim_stage_extra}
}

/* ─── Panels & Menus — glassmorphism base ─────────────────────────── */
#panel,
.popup-menu,
.modal-dialog,
.notification-banner,
.osd-window {
  background: linear-gradient(135deg, rgba(${bg_mid_rgb}, 0.35) 0%, rgba(${bg_deep_rgb}, 0.4) 100%);
  backdrop-filter: blur(${blur}px);
  border: 2px solid rgba(${border_rgb}, 0.6);
  border-radius: ${radius}px;
${shadow_panels}${anim_panels}
}

/* ─── Top Bar ─────────────────────────────────────────────────────── */
#panel {
  border-width: 2px;
${shadow_panel_bar}${anim_panel_bar}
}

#panel .panel-button {
  border: 1px solid rgba(${glow_soft_rgb}, 0.4);
  border-radius: ${radius}px;
  background: linear-gradient(135deg, rgba(${bg_deep_rgb}, 0.25), rgba(${bg_mid_rgb}, 0.3));
  transition: all 0.2s ease;
}

#panel .panel-button:hover {
  border-color: rgba(${border_rgb}, 0.8);
  background: rgba(${glow_rgb}, 0.25);
  box-shadow: 0 0 10px rgba(${glow_soft_rgb}, 0.5), inset 0 0 8px rgba(${fg_rgb}, 0.4);
${anim_panel_hover}
}

/* Panel status details */
#panel .panel-status-indicators-box,
.system-status-icon {
  color: ${fg_colour};
}

#appMenu {
  color: ${fg_colour};
  font-weight: bold;
}

.panel-corner {
  -panel-corner-radius: 0;
  -panel-corner-background-color: transparent;
}

/* ─── Popup Menus ─────────────────────────────────────────────────── */
.popup-menu,
.popup-menu-content {
  border-width: 2px;
${shadow_popup}${anim_popup}
}

.popup-menu-item {
  border-radius: 10px;
  transition: all 0.15s ease;
}

.popup-menu-item:focus,
.popup-menu-item:hover {
  background: linear-gradient(90deg, rgba(${glow_rgb}, 0.2), rgba(${fg_rgb}, 0.15));
  box-shadow: inset 0 0 10px rgba(${glow_soft_rgb}, 0.35), 0 0 6px rgba(${border_rgb}, 0.3);
}

.popup-separator-menu-item {
  background-color: rgba(${border_rgb}, 0.3);
  height: 1px;
}

.popup-sub-menu {
  background: rgba(${bg_deep_rgb}, 0.2);
  border-radius: 8px;
}

/* ─── Modal Dialogs ───────────────────────────────────────────────── */
.modal-dialog {
  box-shadow: 0 0 15px rgba(${glow_rgb}, 0.45),
              0 0 30px rgba(${glow_soft_rgb}, 0.3),
              0 0 45px rgba(${border_rgb}, 0.2),
              inset 0 0 20px rgba(${fg_rgb}, 0.15);
}

/* ─── Workspace Switcher ──────────────────────────────────────────── */
.workspace-switcher,
.workspace-thumbnails {
  background: rgba(${bg_mid_rgb}, 0.3);
  border: 2px solid rgba(${border_rgb}, 0.5);
  border-radius: ${radius}px;
  backdrop-filter: blur(10px);
  box-shadow: 0 0 10px rgba(${glow_rgb}, 0.3), inset 0 0 8px rgba(${fg_rgb}, 0.1);
}

.workspace-thumbnail-indicator {
  border: 2px solid rgba(${border_rgb}, 0.9);
  background: rgba(${glow_rgb}, 0.4);
  box-shadow: 0 0 8px rgba(${glow_soft_rgb}, 0.6);
}

/* ─── Overview & Search ───────────────────────────────────────────── */
.overview-controls,
#overview {
  background: rgba(${bg_deep_rgb}, 0.25);
}

.search-entry {
  background: rgba(${bg_mid_rgb}, 0.35);
  border: 2px solid rgba(${border_rgb}, 0.6);
  border-radius: 14px;
  color: ${fg_colour};
  backdrop-filter: blur(8px);
  box-shadow: inset 0 0 10px rgba(${fg_rgb}, 0.15), 0 0 8px rgba(${glow_rgb}, 0.3);
  transition: all 0.2s ease;
}

.search-entry:focus {
  border-color: rgba(${border_rgb}, 0.9);
  box-shadow: inset 0 0 12px rgba(${fg_rgb}, 0.25), 0 0 12px rgba(${glow_soft_rgb}, 0.5);
}

.search-section,
.search-section-content {
  background: rgba(${bg_mid_rgb}, 0.3);
  border: 1px solid rgba(${border_rgb}, 0.4);
  border-radius: 10px;
  backdrop-filter: blur(8px);
}

.search-result {
  border-radius: 8px;
  transition: all 0.15s ease;
}

.search-result:hover,
.search-result:focus,
.search-result:selected {
  background: rgba(${glow_rgb}, 0.25);
  box-shadow: inset 0 0 8px rgba(${glow_soft_rgb}, 0.3);
}

/* ─── Buttons ─────────────────────────────────────────────────────── */
.button,
.modal-dialog-linked-button {
  background: linear-gradient(135deg, rgba(${bg_mid_rgb}, 0.4), rgba(${bg_deep_rgb}, 0.45));
  border: 1px solid rgba(${border_rgb}, 0.5);
  border-radius: 10px;
  color: ${fg_colour};
  box-shadow: 0 0 6px rgba(${glow_rgb}, 0.25);
  transition: all 0.15s ease;
}

.button:hover {
  background: linear-gradient(135deg, rgba(${glow_rgb}, 0.5), rgba(${bg_mid_rgb}, 0.55));
  border-color: rgba(${border_rgb}, 0.8);
  box-shadow: 0 0 10px rgba(${glow_soft_rgb}, 0.5), inset 0 0 8px rgba(${fg_rgb}, 0.2);
}

.button:active {
  background: rgba(${bg_deep_rgb}, 0.6);
  box-shadow: inset 0 0 10px rgba(${bg_mid_rgb}, 0.5);
}

/* ─── Quick Settings ──────────────────────────────────────────────── */
.quick-settings,
.quick-settings-grid,
.quick-toggle {
  background: rgba(${bg_mid_rgb}, 0.35);
  border: 1px solid rgba(${border_rgb}, 0.5);
  border-radius: ${radius}px;
  backdrop-filter: blur(10px);
}

.quick-toggle:hover {
  background: rgba(${glow_rgb}, 0.4);
  box-shadow: 0 0 8px rgba(${glow_soft_rgb}, 0.4);
}

.quick-toggle:checked {
  background: linear-gradient(135deg, rgba(${accent_bright_rgb}, 0.6), rgba(${glow_rgb}, 0.65));
  border-color: rgba(${border_rgb}, 0.9);
  box-shadow: 0 0 10px rgba(${glow_soft_rgb}, 0.6), inset 0 0 10px rgba(${fg_rgb}, 0.3);
}

/* ─── Calendar ────────────────────────────────────────────────────── */
.calendar,
.calendar-day-base {
  background: rgba(${bg_mid_rgb}, 0.3);
  border: 1px solid rgba(${border_rgb}, 0.4);
  border-radius: 8px;
}

.calendar-day-base:hover,
.calendar-day-base:focus {
  background: rgba(${glow_rgb}, 0.35);
  box-shadow: inset 0 0 6px rgba(${glow_soft_rgb}, 0.3);
}

.calendar-day-base:selected {
  background: linear-gradient(135deg, rgba(${accent_bright_rgb}, 0.5), rgba(${glow_rgb}, 0.55));
  border-color: rgba(${border_rgb}, 0.8);
  box-shadow: 0 0 8px rgba(${glow_soft_rgb}, 0.5);
}

.calendar-today {
  border: 2px solid rgba(${border_rgb}, 0.8);
  background: rgba(${glow_rgb}, 0.4);
  font-weight: bold;
  color: ${accent_bright};
}

/* ─── World Clock & Weather ───────────────────────────────────────── */
.world-clocks-header,
.weather-header {
  color: ${accent_bright};
  font-weight: bold;
}

.world-clocks-city,
.weather-forecast-time {
  color: ${fg_colour};
}

.world-clocks-time,
.weather-forecast-temp {
  color: ${accent_colour};
  font-weight: 600;
}

.weather-icon {
  icon-size: 32px;
}

/* ─── Notifications ───────────────────────────────────────────────── */
.notification-banner {
  background: rgba(${bg_mid_rgb}, 0.4);
  border: 2px solid rgba(${border_rgb}, 0.6);
  box-shadow: 0 0 12px rgba(${glow_rgb}, 0.4), 0 0 20px rgba(${glow_soft_rgb}, 0.25);
}

.notification-banner:hover {
  background: rgba(${glow_rgb}, 0.45);
  box-shadow: 0 0 15px rgba(${glow_soft_rgb}, 0.5);
}

.message-list,
.message-list-section {
  background: rgba(${bg_mid_rgb}, 0.25);
  border-radius: 10px;
}

.message {
  background: rgba(${bg_mid_rgb}, 0.35);
  border: 1px solid rgba(${border_rgb}, 0.4);
  border-radius: 10px;
  backdrop-filter: blur(8px);
  margin: 4px;
}

.message:hover {
  background: rgba(${glow_rgb}, 0.4);
  border-color: rgba(${border_rgb}, 0.7);
}

/* ─── Tooltips ────────────────────────────────────────────────────── */
.tooltip,
.candidate-popup-boxpointer {
  background: rgba(${bg_deep_rgb}, 0.85);
  border: 1px solid rgba(${border_rgb}, 0.7);
  border-radius: 8px;
  color: ${fg_colour};
  box-shadow: 0 0 10px rgba(${glow_rgb}, 0.4), inset 0 0 8px rgba(${fg_rgb}, 0.15);
  backdrop-filter: blur(10px);
}

/* ─── Sliders & Switches ─────────────────────────────────────────── */
.slider {
  -barlevel-height: 6px;
  -barlevel-background-color: rgba(${bg_mid_rgb}, 0.4);
  -barlevel-active-background-color: rgba(${accent_bright_rgb}, 0.8);
  -barlevel-overdrive-color: rgba(${glow_rgb}, 1);
  -barlevel-border-width: 1px;
  -barlevel-border-color: rgba(${border_rgb}, 0.5);
}

.toggle-switch {
  background-color: rgba(${bg_mid_rgb}, 0.4);
  border: 1px solid rgba(${border_rgb}, 0.5);
}

.toggle-switch:checked {
  background-color: rgba(${accent_bright_rgb}, 0.7);
  border-color: rgba(${glow_rgb}, 0.9);
  box-shadow: 0 0 8px rgba(${glow_soft_rgb}, 0.5);
}

/* ─── Window Picker & App Icons ───────────────────────────────────── */
.window-clone-border {
  border: 3px solid rgba(${border_rgb}, 0.7);
  border-radius: ${radius}px;
  box-shadow: 0 0 15px rgba(${glow_rgb}, 0.5);
}

.app-well-app,
.grid-search-result {
  border-radius: ${radius}px;
  transition: all 0.15s ease;
}

.app-well-app:hover,
.grid-search-result:hover {
  background: rgba(${glow_rgb}, 0.3);
  box-shadow: 0 0 10px rgba(${glow_soft_rgb}, 0.4), inset 0 0 10px rgba(${fg_rgb}, 0.2);
}

.app-well-app:active,
.app-well-app:checked {
  background: rgba(${accent_bright_rgb}, 0.4);
  box-shadow: 0 0 12px rgba(${glow_rgb}, 0.6);
}

/* ─── Dash & Dock ─────────────────────────────────────────────────── */
.dash-background {
  background: rgba(${bg_mid_rgb}, 0.35);
  border: 2px solid rgba(${border_rgb}, 0.5);
  border-radius: ${radius}px;
  backdrop-filter: blur(${blur}px);
  box-shadow: 0 0 10px rgba(${glow_rgb}, 0.3), inset 0 0 12px rgba(${fg_rgb}, 0.1);
}

.dash-item-container > StButton {
  border-radius: 10px;
}

.dash-separator {
  background-color: rgba(${border_rgb}, 0.4);
  width: 1px;
  margin: 4px 2px;
}

.show-apps {
  border-radius: ${radius}px;
  transition: all 0.15s ease;
}

.show-apps:hover {
  background: rgba(${glow_rgb}, 0.3);
  box-shadow: 0 0 8px rgba(${glow_soft_rgb}, 0.4);
}

.show-apps:active {
  background: rgba(${accent_bright_rgb}, 0.4);
}

/* Running indicator dot */
.app-well-app .overview-icon .app-grid-running-dot {
  background-color: ${accent_bright};
}

/* ─── Looking Glass (Alt+F2 Debugger) ─────────────────────────────── */
.lg-dialog {
  background: rgba(${bg_deep_rgb}, 0.9);
  border: 2px solid rgba(${border_rgb}, 0.8);
  border-radius: ${radius}px;
  backdrop-filter: blur(8px);
  box-shadow: 0 0 20px rgba(${glow_rgb}, 0.5);
}

.lg-objects-window,
.lg-results-container {
  background: rgba(${bg_deep_rgb}, 0.8);
  border-radius: 8px;
}

.lg-dialog-entry {
  background: rgba(${bg_mid_rgb}, 0.4);
  border: 1px solid rgba(${border_rgb}, 0.5);
  border-radius: 6px;
  color: ${fg_colour};
}

.lg-completions-text {
  color: ${accent_colour};
}

.lg-inspector-button {
  border: 1px solid rgba(${border_rgb}, 0.5);
  border-radius: 6px;
  background: rgba(${bg_mid_rgb}, 0.3);
}

/* ─── OSD ─────────────────────────────────────────────────────────── */
.osd-window {
  background: rgba(${bg_mid_rgb}, 0.75);
  border: 2px solid rgba(${border_rgb}, 0.7);
  box-shadow: 0 0 15px rgba(${glow_rgb}, 0.5), inset 0 0 15px rgba(${fg_rgb}, 0.15);
}

.osd-monitor-label {
  font-size: 48pt;
  color: ${accent_bright};
}

.level,
.level-bar {
  -barlevel-height: 8px;
  -barlevel-background-color: rgba(${bg_mid_rgb}, 0.4);
  -barlevel-active-background-color: rgba(${accent_bright_rgb}, 0.8);
  -barlevel-border-color: rgba(${border_rgb}, 0.4);
}

/* ─── Lock Screen ─────────────────────────────────────────────────── */
.screen-shield-background {
  background: linear-gradient(45deg,
    rgba(${bg_deep_rgb}, 0.6),
    rgba(${accent_bright_rgb}, 0.2),
    rgba(${bg_mid_rgb}, 0.65),
    rgba(${bg_light_rgb}, 0.25));
}

.screen-shield-clock {
  color: ${fg_colour};
  font-weight: bold;
  text-shadow: 0 0 12px rgba(${glow_rgb}, 0.6);
}

.screen-shield-notifications-container {
  background: rgba(${bg_mid_rgb}, 0.3);
  border-radius: ${radius}px;
}

.unlock-dialog {
  background: rgba(${bg_mid_rgb}, 0.4);
  border: 2px solid rgba(${border_rgb}, 0.6);
  border-radius: ${radius}px;
  backdrop-filter: blur(15px);
  box-shadow: 0 0 20px rgba(${glow_rgb}, 0.5);
}

.unlock-dialog-clock {
  color: ${fg_colour};
  font-weight: bold;
}

.unlock-dialog-notification-label {
  color: rgba(${fg_rgb}, 0.8);
}

/* ─── Alt-Tab / Switcher ──────────────────────────────────────────── */
.switcher-popup {
  padding: 8px;
  border-radius: ${radius}px;
}

.switcher-list {
  background: rgba(${bg_mid_rgb}, 0.5);
  border: 2px solid rgba(${border_rgb}, 0.6);
  border-radius: ${radius}px;
  backdrop-filter: blur(${blur}px);
  box-shadow: 0 0 15px rgba(${glow_rgb}, 0.4);
  padding: 12px;
}

.switcher-list-item-container {
  border-radius: 10px;
  padding: 8px;
  transition: all 0.15s ease;
}

.switcher-list-item-container:selected {
  background: rgba(${accent_bright_rgb}, 0.35);
  border: 2px solid rgba(${border_rgb}, 0.8);
  box-shadow: 0 0 12px rgba(${glow_soft_rgb}, 0.5);
}

.switcher-arrow {
  color: rgba(${border_rgb}, 0.7);
}

.thumbnail-scroll-gradient-left,
.thumbnail-scroll-gradient-right {
  background-gradient-start: rgba(${bg_deep_rgb}, 0.8);
  background-gradient-end: transparent;
}

/* ─── App Grid & Folders ──────────────────────────────────────────── */
.app-grid {
  background: transparent;
}

.icon-grid {
  spacing: 12px;
}

.app-folder-popup {
  background: rgba(${bg_mid_rgb}, 0.5);
  border: 2px solid rgba(${border_rgb}, 0.6);
  border-radius: ${radius}px;
  backdrop-filter: blur(${blur}px);
  box-shadow: 0 0 15px rgba(${glow_rgb}, 0.4),
              inset 0 0 10px rgba(${fg_rgb}, 0.1);
}

.app-folder-icon {
  border-radius: ${radius}px;
  background: rgba(${bg_mid_rgb}, 0.3);
  border: 1px solid rgba(${border_rgb}, 0.4);
  transition: all 0.15s ease;
}

.app-folder-icon:hover {
  background: rgba(${glow_rgb}, 0.35);
  box-shadow: 0 0 8px rgba(${glow_soft_rgb}, 0.4);
}

.page-indicator .page-indicator-icon {
  background-color: rgba(${border_rgb}, 0.4);
  border-radius: 50%;
  width: 10px;
  height: 10px;
}

.page-indicator:checked .page-indicator-icon {
  background-color: ${accent_bright};
  box-shadow: 0 0 6px rgba(${glow_soft_rgb}, 0.5);
}

.page-navigation-arrow {
  color: rgba(${border_rgb}, 0.6);
}

.page-navigation-arrow:hover {
  color: ${accent_bright};
}

/* ─── Screenshot UI (GNOME 42+) ───────────────────────────────────── */
.screenshot-ui-panel {
  background: rgba(${bg_mid_rgb}, 0.6);
  border: 2px solid rgba(${border_rgb}, 0.6);
  border-radius: ${radius}px;
  backdrop-filter: blur(${blur}px);
  box-shadow: 0 0 15px rgba(${glow_rgb}, 0.4);
}

.screenshot-ui-type-button {
  background: rgba(${bg_mid_rgb}, 0.35);
  border: 1px solid rgba(${border_rgb}, 0.5);
  border-radius: ${radius}px;
  color: ${fg_colour};
  transition: all 0.15s ease;
}

.screenshot-ui-type-button:hover {
  background: rgba(${glow_rgb}, 0.4);
  border-color: rgba(${border_rgb}, 0.8);
}

.screenshot-ui-type-button:checked {
  background: linear-gradient(135deg, rgba(${accent_bright_rgb}, 0.5), rgba(${glow_rgb}, 0.55));
  border-color: rgba(${border_rgb}, 0.9);
  box-shadow: 0 0 8px rgba(${glow_soft_rgb}, 0.5);
}

.screenshot-ui-shot-cast-container {
  background: rgba(${bg_deep_rgb}, 0.4);
  border-radius: 8px;
}

.screenshot-ui-window-selector {
  border-radius: ${radius}px;
}

.screenshot-ui-screen-selector {
  border-radius: ${radius}px;
}

.screenshot-ui-shot-cast-button {
  background: rgba(${accent_bright_rgb}, 0.5);
  border: 1px solid rgba(${border_rgb}, 0.7);
  border-radius: 20px;
  color: ${fg_colour};
}

.screenshot-ui-shot-cast-button:hover {
  background: rgba(${accent_bright_rgb}, 0.65);
  box-shadow: 0 0 10px rgba(${glow_soft_rgb}, 0.5);
}

/* ─── On-Screen Keyboard ──────────────────────────────────────────── */
.keyboard {
  background: rgba(${bg_deep_rgb}, 0.85);
  backdrop-filter: blur(${blur}px);
}

.keyboard-layout {
  spacing: 4px;
  padding: 8px;
}

.keyboard-key {
  background: rgba(${bg_mid_rgb}, 0.4);
  border: 1px solid rgba(${border_rgb}, 0.4);
  border-radius: 6px;
  color: ${fg_colour};
  font-size: 14pt;
  transition: all 0.1s ease;
}

.keyboard-key:hover {
  background: rgba(${glow_rgb}, 0.4);
  border-color: rgba(${border_rgb}, 0.7);
}

.keyboard-key:active {
  background: rgba(${accent_bright_rgb}, 0.5);
  box-shadow: 0 0 8px rgba(${glow_soft_rgb}, 0.4);
}

.keyboard-key:grayed {
  background: rgba(${bg_mid_rgb}, 0.2);
  color: rgba(${fg_rgb}, 0.4);
}

.keyboard-key:latched,
.keyboard-key:checked {
  background: rgba(${accent_bright_rgb}, 0.5);
  border-color: rgba(${border_rgb}, 0.8);
  box-shadow: 0 0 6px rgba(${glow_soft_rgb}, 0.4);
}

.keyboard-subkeys {
  background: rgba(${bg_deep_rgb}, 0.9);
  border: 1px solid rgba(${border_rgb}, 0.6);
  border-radius: 8px;
  backdrop-filter: blur(8px);
}

/* ─── System Dialogs ──────────────────────────────────────────────── */
.nm-dialog,
.polkit-dialog,
.end-session-dialog,
.run-dialog {
  background: rgba(${bg_mid_rgb}, 0.5);
  border: 2px solid rgba(${border_rgb}, 0.6);
  border-radius: ${radius}px;
  backdrop-filter: blur(${blur}px);
  box-shadow: 0 0 15px rgba(${glow_rgb}, 0.4),
              0 0 30px rgba(${glow_soft_rgb}, 0.25);
}

.prompt-dialog {
  background: rgba(${bg_mid_rgb}, 0.5);
  border: 2px solid rgba(${border_rgb}, 0.6);
  border-radius: ${radius}px;
  backdrop-filter: blur(${blur}px);
}

.prompt-dialog-password-entry {
  background: rgba(${bg_deep_rgb}, 0.6);
  border: 1px solid rgba(${border_rgb}, 0.5);
  border-radius: 6px;
  color: ${fg_colour};
}

.prompt-dialog-password-entry:focus {
  border-color: rgba(${border_rgb}, 0.9);
  box-shadow: 0 0 8px rgba(${glow_soft_rgb}, 0.4);
}

/* Aggregate / system menu */
.aggregate-menu {
  background: rgba(${bg_mid_rgb}, 0.35);
}

.system-menu-action {
  border-radius: ${radius}px;
  transition: all 0.15s ease;
}

.system-menu-action:hover {
  background: rgba(${glow_rgb}, 0.3);
}

/* ─── Tile Preview (Snap/Tiling) ──────────────────────────────────── */
.tile-preview {
  background: rgba(${accent_bright_rgb}, 0.2);
  border: 2px solid rgba(${border_rgb}, 0.6);
  border-radius: ${radius}px;
  box-shadow: 0 0 10px rgba(${glow_rgb}, 0.3);
}

/* ─── Window Menu ─────────────────────────────────────────────────── */
.window-menu {
  background: rgba(${bg_mid_rgb}, 0.5);
  border: 1px solid rgba(${border_rgb}, 0.5);
  border-radius: 8px;
  backdrop-filter: blur(${blur}px);
}

.window-menu-app-icon {
  margin: 4px;
}

/* ─── Ripple Effect ───────────────────────────────────────────────── */
.ripple-pointer-location {
  background-color: rgba(${accent_bright_rgb}, 0.4);
  border-radius: 50%;
}

/* ─── Accessibility ───────────────────────────────────────────────── */
.access-dot {
  background-color: ${accent_bright};
}

.a11y-menu {
  background: rgba(${bg_mid_rgb}, 0.5);
  border: 1px solid rgba(${border_rgb}, 0.5);
  border-radius: 8px;
}
CSSEOF
)"

    write_target_file "$outfile" "$css"
}
