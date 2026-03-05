#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# json-gen.sh — VS Code theme JSON generation for vscode-theme-gen
# ═══════════════════════════════════════════════════════════════════════════════
# Builds the "workbench.colourCustomizations" and
# "editor.tokenColourCustomizations" JSON blocks.
#
# Requires: colours.sh sourced (for pastel helpers + ensure_readable)
# ═══════════════════════════════════════════════════════════════════════════════

generate_theme_json() {
    local primary_hex secondary_hex tertiary_hex
    primary_hex=$(get_hex "$PRIMARY_COLOUR")
    secondary_hex=$(get_hex "$SECONDARY_COLOUR")
    tertiary_hex=$(get_hex "$TERTIARY_COLOUR")

    # ── Background colours (subtle tint from primary) ──
    local bg_main bg_sidebar bg_panel bg_dark bg_hover bg_input bg_widget
    bg_main=$(mix_colors "#1e1e1e" "$primary_hex" 0.95)
    bg_sidebar=$(mix_colors "#252526" "$primary_hex" 0.92)
    bg_panel=$(mix_colors "#2d2d30" "$primary_hex" 0.90)
    bg_dark=$(mix_colors "#1a1a1a" "$primary_hex" 0.96)
    bg_hover=$(mix_colors "#3a3a3a" "$primary_hex" 0.88)
    bg_input=$(mix_colors "#303030" "$primary_hex" 0.93)
    bg_widget=$(mix_colors "#2a2a2a" "$primary_hex" 0.91)

    # ── Foreground colours – all passed through ensure_readable ──
    local fg_main fg_soft fg_muted fg_bright
    fg_main=$(ensure_readable "$(lighten "$primary_hex" 0.35)")
    fg_soft=$(ensure_readable "${PRIMARY_SHADES[4]:-$(lighten "$primary_hex" 0.25)}")
    fg_muted=$(ensure_readable "$(lighten "$primary_hex" 0.18)" 0.40)
    fg_bright=$(ensure_readable "$(lighten "$secondary_hex" 0.30)")

    # ── Accent colours ──
    local accent_primary accent_secondary accent_tertiary accent_soft
    accent_primary=$(ensure_readable "${PRIMARY_SHADES[0]:-$primary_hex}")
    accent_secondary=$(ensure_readable "${SECONDARY_SHADES[0]:-$secondary_hex}")
    accent_tertiary=$(ensure_readable "${TERTIARY_SHADES[0]:-$tertiary_hex}")
    accent_soft=$(ensure_readable "${PRIMARY_SHADES[3]:-$(lighten "$primary_hex" 0.1)}")

    # ── Tertiary accent helpers ──
    local tert_soft tert_bright
    tert_soft=$(ensure_readable "${TERTIARY_SHADES[3]:-$(lighten "$tertiary_hex" 0.1)}")
    tert_bright=$(ensure_readable "${TERTIARY_SHADES[1]:-$(lighten "$tertiary_hex" 0.2)}")

    # ── Complementary accents (if enabled) ──
    local compl_highlight="" compl_border="" compl_accent=""
    if [[ "$USE_COMPLEMENTARY" == true ]] && [[ ${#COMPLEMENTARY_COLOURS[@]} -gt 0 ]]; then
        compl_highlight="${COMPLEMENTARY_COLOURS[0]}"
        compl_border="${COMPLEMENTARY_COLOURS[2]}"
        compl_accent="${COMPLEMENTARY_COLOURS[4]}"
    fi

    # ── Analogous & triadic helpers ──
    local ana0 ana1 ana2 ana3 tri0 tri1 bln0 bln1 bln2 bln3
    ana0=$(ensure_readable "${ANALOGOUS_COLOURS[0]:-$accent_primary}")
    ana1=$(ensure_readable "${ANALOGOUS_COLOURS[1]:-$accent_primary}")
    ana2=$(ensure_readable "${ANALOGOUS_COLOURS[2]:-$accent_secondary}")
    ana3=$(ensure_readable "${ANALOGOUS_COLOURS[3]:-$accent_secondary}")
    tri0=$(ensure_readable "${TRIADIC_COLOURS[0]:-$accent_tertiary}")
    tri1=$(ensure_readable "${TRIADIC_COLOURS[1]:-$accent_tertiary}")
    bln0=$(ensure_readable "${BLEND_COLOURS[0]:-$accent_primary}")
    bln1=$(ensure_readable "${BLEND_COLOURS[1]:-$accent_secondary}")
    bln2=$(ensure_readable "${BLEND_COLOURS[2]:-$accent_tertiary}")
    bln3=$(ensure_readable "${BLEND_COLOURS[3]:-$fg_soft}")

    # ── Variation accents ──
    local var0="" var1="" var2="" var3=""
    if [[ ${#VARIATION_COLOURS[@]} -gt 0 ]]; then
        var0=$(ensure_readable "${VARIATION_COLOURS[0]}")
        var1=$(ensure_readable "${VARIATION_COLOURS[1]:-$var0}")
        var2=$(ensure_readable "${VARIATION_COLOURS[2]:-$var0}")
        var3=$(ensure_readable "${VARIATION_COLOURS[3]:-$var0}")
    fi

    # ── Readable shade helpers (used extensively below) ──
    local p1 p2 p3 p4 p5 p6 p7
    p1=$(ensure_readable "${PRIMARY_SHADES[1]:-$accent_primary}")
    p2=$(ensure_readable "${PRIMARY_SHADES[2]:-$accent_soft}")
    p3=$(ensure_readable "${PRIMARY_SHADES[3]:-$accent_soft}")
    p4=$(ensure_readable "${PRIMARY_SHADES[4]:-$fg_soft}")
    p5=$(ensure_readable "${PRIMARY_SHADES[5]:-$fg_soft}")
    p6=$(ensure_readable "${PRIMARY_SHADES[6]:-$fg_main}")
    p7=$(ensure_readable "${PRIMARY_SHADES[7]:-$fg_main}")

    local s1 s2 s3 s4 s5 s6 s7
    s1=$(ensure_readable "${SECONDARY_SHADES[1]:-$accent_secondary}")
    s2=$(ensure_readable "${SECONDARY_SHADES[2]:-$accent_secondary}")
    s3=$(ensure_readable "${SECONDARY_SHADES[3]:-$accent_secondary}")
    s4=$(ensure_readable "${SECONDARY_SHADES[4]:-$fg_bright}")
    s5=$(ensure_readable "${SECONDARY_SHADES[5]:-$fg_main}")
    s6=$(ensure_readable "${SECONDARY_SHADES[6]:-$fg_main}")
    s7=$(ensure_readable "${SECONDARY_SHADES[7]:-$fg_main}")

    local t1 t2 t3 t4 t5
    t1=$(ensure_readable "${TERTIARY_SHADES[1]:-$accent_tertiary}")
    t2=$(ensure_readable "${TERTIARY_SHADES[2]:-$accent_tertiary}")
    t3=$(ensure_readable "${TERTIARY_SHADES[3]:-$tert_soft}")
    t4=$(ensure_readable "${TERTIARY_SHADES[4]:-$tert_soft}")
    t5=$(ensure_readable "${TERTIARY_SHADES[5]:-$tert_bright}")

    # ── Emit JSON ─────────────────────────────────────────────────────────────
    cat << THEME_EOF
		"workbench.colorCustomizations": {
			// ═══════════════════════════════════════════════════════════
			// 🎨 ${THEME_NAME}
			// Generated with the vsGen design flow (https://github.io/XAOSTECH/design-tools) using pastel (https://github.com/sharkdp/pastel)
			// Primary:   ${PRIMARY_COLOUR} (${primary_hex})
			// Secondary: ${SECONDARY_COLOUR} (${secondary_hex})
			// Tertiary:  ${TERTIARY_COLOUR} (${tertiary_hex})
			// Variation: ${VARIATION}
			// ═══════════════════════════════════════════════════════════

			// ── Editor Background ──
			"editor.background": "${bg_main}",
			"editor.foreground": "${fg_main}",
			"editorLineNumber.foreground": "${p2}",
			"editorLineNumber.activeForeground": "${accent_secondary}",
			"editorCursor.foreground": "${s1}",
			"editor.selectionBackground": "${accent_primary}50",
			"editor.selectionHighlightBackground": "${fg_soft}30",
			"editor.wordHighlightBackground": "${s2}30",
			"editor.wordHighlightStrongBackground": "${accent_tertiary}30",
			"editor.findMatchBackground": "${accent_secondary}50",
			"editor.findMatchHighlightBackground": "${s3}40",
			"editor.lineHighlightBackground": "${bg_hover}60",
			"editor.lineHighlightBorder": "${accent_primary}15",
			"editor.rangeHighlightBackground": "${accent_tertiary}15",
			"editorBracketMatch.background": "${accent_primary}30",
			"editorBracketMatch.border": "${accent_primary}",
			"editorIndentGuide.background1": "${p2}20",
			"editorIndentGuide.activeBackground1": "${accent_primary}",
			"editorRuler.foreground": "${p2}30",
			"editorWhitespace.foreground": "${p2}20",
			"editorLink.activeForeground": "${s1}",

			// ── Bracket Pair Colourisation ──
			"editorBracketHighlight.foreground1": "${accent_primary}",
			"editorBracketHighlight.foreground2": "${accent_secondary}",
			"editorBracketHighlight.foreground3": "${accent_tertiary}",
			"editorBracketHighlight.foreground4": "${ana0}",
			"editorBracketHighlight.foreground5": "${tri0}",
			"editorBracketHighlight.foreground6": "${bln0}",
			"editorBracketHighlight.unexpectedBracket.foreground": "#ff5555",

			// ── Editor Gutter ──
			"editorGutter.addedBackground": "${s2}cc",
			"editorGutter.modifiedBackground": "${accent_tertiary}cc",
			"editorGutter.deletedBackground": "${p1}cc",
			"editorGutter.commentRangeForeground": "${p3}60",
			"editorGutter.foldingControlForeground": "${fg_soft}",

			// ── Editor Overview Ruler ──
			"editorOverviewRuler.border": "${bg_dark}",
			"editorOverviewRuler.findMatchForeground": "${accent_secondary}80",
			"editorOverviewRuler.rangeHighlightForeground": "${accent_tertiary}60",
			"editorOverviewRuler.selectionHighlightForeground": "${fg_soft}60",
			"editorOverviewRuler.wordHighlightForeground": "${accent_primary}60",
			"editorOverviewRuler.modifiedForeground": "${accent_tertiary}cc",
			"editorOverviewRuler.addedForeground": "${s2}cc",
			"editorOverviewRuler.deletedForeground": "${p1}cc",
			"editorOverviewRuler.errorForeground": "#ff5555cc",
			"editorOverviewRuler.warningForeground": "${accent_secondary}cc",
			"editorOverviewRuler.infoForeground": "${accent_tertiary}cc",

			// ── Editor Widgets ──
			"editorWidget.background": "${bg_widget}",
			"editorWidget.border": "${accent_primary}60",
			"editorWidget.foreground": "${fg_soft}",
			"editorSuggestWidget.background": "${bg_widget}",
			"editorSuggestWidget.border": "${accent_primary}40",
			"editorSuggestWidget.foreground": "${fg_main}",
			"editorSuggestWidget.highlightForeground": "${accent_secondary}",
			"editorSuggestWidget.selectedBackground": "${accent_primary}30",
			"editorSuggestWidget.focusHighlightForeground": "${s1}",
			"editorHoverWidget.background": "${bg_widget}",
			"editorHoverWidget.border": "${accent_primary}40",
			"editorHoverWidget.foreground": "${fg_main}",

			// ── Error / Warning / Info ──
			"editorError.foreground": "#ff5555",
			"editorWarning.foreground": "${accent_secondary}",
			"editorInfo.foreground": "${accent_tertiary}",
			"problemsErrorIcon.foreground": "#ff5555",
			"problemsWarningIcon.foreground": "${accent_secondary}",
			"problemsInfoIcon.foreground": "${accent_tertiary}",

			// ── Sidebar & Activity Bar ──
			"sideBar.background": "${bg_sidebar}",
			"sideBar.foreground": "${fg_soft}",
			"sideBar.border": "${bg_dark}",
			"sideBarTitle.foreground": "${s1}",
			"sideBarSectionHeader.background": "${bg_panel}",
			"sideBarSectionHeader.foreground": "${p1}",
			"activityBar.background": "${bg_dark}",
			"activityBar.foreground": "${accent_primary}",
			"activityBar.inactiveForeground": "${p2}60",
			"activityBar.border": "${bg_dark}",
			"activityBarBadge.background": "${accent_secondary}",
			"activityBarBadge.foreground": "${bg_dark}",

			// ── Title Bar ──
			"titleBar.activeBackground": "${bg_dark}",
			"titleBar.activeForeground": "${fg_soft}",
			"titleBar.inactiveBackground": "${bg_main}",
			"titleBar.inactiveForeground": "${p2}80",
			"titleBar.border": "${bg_dark}",

			// ── Status Bar ──
			"statusBar.background": "${accent_primary}",
			"statusBar.foreground": "${bg_dark}",
			"statusBar.border": "${accent_primary}",
			"statusBar.debuggingBackground": "${accent_secondary}",
			"statusBar.debuggingForeground": "${bg_dark}",
			"statusBar.noFolderBackground": "${p3}",
			"statusBarItem.hoverBackground": "${p1}",
			"statusBarItem.prominentBackground": "${s1}",
			"statusBarItem.prominentForeground": "${bg_dark}",
			"statusBarItem.errorBackground": "#ff5555",
			"statusBarItem.errorForeground": "#ffffff",
			"statusBarItem.warningBackground": "${accent_secondary}",
			"statusBarItem.warningForeground": "${bg_dark}",

			// ── Tabs ──
			"tab.activeBackground": "${bg_panel}",
			"tab.activeForeground": "${s5}",
			"tab.inactiveBackground": "${bg_main}",
			"tab.inactiveForeground": "${fg_soft}80",
			"tab.border": "${bg_dark}",
			"tab.activeBorderTop": "${accent_primary}",
			"tab.hoverBackground": "${bg_hover}",
			"tab.hoverForeground": "${fg_main}",
			"tab.unfocusedActiveBackground": "${bg_main}",
			"tab.unfocusedActiveForeground": "${fg_soft}",
			"tab.unfocusedInactiveForeground": "${p3}80",
			"tab.lastPinnedBorder": "${accent_tertiary}50",
			"editorGroupHeader.tabsBackground": "${bg_dark}",
			"editorGroupHeader.tabsBorder": "${bg_dark}",
			"editorGroup.border": "${accent_primary}30",

			// ── Panel (Terminal, Output, etc.) ──
			"panel.background": "${bg_main}",
			"panel.border": "${accent_primary}50",
			"panelTitle.activeBorder": "${accent_secondary}",
			"panelTitle.activeForeground": "${s1}",
			"panelTitle.inactiveForeground": "${fg_soft}80",
			"terminal.foreground": "${fg_main}",
			"terminal.background": "${bg_main}",
			"terminal.ansiBlack": "${bg_dark}",
			"terminal.ansiRed": "${p1}",
			"terminal.ansiGreen": "${s2}",
			"terminal.ansiYellow": "${accent_secondary}",
			"terminal.ansiBlue": "${accent_tertiary}",
			"terminal.ansiMagenta": "${accent_primary}",
			"terminal.ansiCyan": "${tri0}",
			"terminal.ansiWhite": "${fg_main}",
			"terminal.ansiBrightBlack": "${p2}",
			"terminal.ansiBrightRed": "${ana1}",
			"terminal.ansiBrightGreen": "${s4}",
			"terminal.ansiBrightYellow": "${bln1}",
			"terminal.ansiBrightBlue": "${tri1}",
			"terminal.ansiBrightMagenta": "${ana0}",
			"terminal.ansiBrightCyan": "${t4}",
			"terminal.ansiBrightWhite": "#ffffff",
			"terminalCursor.foreground": "${s1}",

			// ── Lists & Trees ──
			"list.activeSelectionBackground": "${accent_primary}50",
			"list.activeSelectionForeground": "${s5}",
			"list.hoverBackground": "${p2}20",
			"list.hoverForeground": "${fg_main}",
			"list.focusBackground": "${accent_secondary}30",
			"list.focusForeground": "${fg_main}",
			"list.highlightForeground": "${accent_secondary}",
			"list.inactiveSelectionBackground": "${fg_soft}20",
			"list.inactiveSelectionForeground": "${fg_soft}",
			"list.invalidItemForeground": "#ff5555",
			"list.errorForeground": "#ff5555",
			"list.warningForeground": "${accent_secondary}",
			"tree.indentGuidesStroke": "${p2}40",

			// ── Input & Dropdowns ──
			"input.background": "${bg_input}",
			"input.foreground": "${fg_main}",
			"input.border": "${accent_primary}50",
			"input.placeholderForeground": "${fg_soft}60",
			"inputOption.activeBorder": "${accent_secondary}",
			"inputOption.activeBackground": "${accent_secondary}30",
			"inputOption.activeForeground": "${fg_main}",
			"inputValidation.errorBorder": "#ff5555",
			"inputValidation.warningBorder": "${accent_secondary}",
			"inputValidation.infoBorder": "${accent_tertiary}",
			"dropdown.background": "${bg_input}",
			"dropdown.border": "${accent_primary}50",
			"dropdown.foreground": "${fg_soft}",
			"dropdown.listBackground": "${bg_sidebar}",

			// ── Buttons ──
			"button.background": "${accent_primary}",
			"button.foreground": "${bg_dark}",
			"button.hoverBackground": "${p1}",
			"button.secondaryBackground": "${accent_secondary}",
			"button.secondaryForeground": "${bg_dark}",
			"button.secondaryHoverBackground": "${s1}",
			"button.separator": "${bg_dark}40",

			// ── Scrollbar ──
			"scrollbar.shadow": "${bg_dark}50",
			"scrollbarSlider.background": "${accent_primary}30",
			"scrollbarSlider.hoverBackground": "${accent_primary}60",
			"scrollbarSlider.activeBackground": "${accent_primary}80",

			// ── Notifications ──
			"notificationCenter.border": "${accent_primary}",
			"notifications.background": "${bg_sidebar}",
			"notifications.foreground": "${fg_soft}",
			"notificationsInfoIcon.foreground": "${s1}",
			"notificationsWarningIcon.foreground": "${accent_secondary}",
			"notificationsErrorIcon.foreground": "#ff5555",

			// ── Git Decorations ──
			"gitDecoration.addedResourceForeground": "${s2}",
			"gitDecoration.modifiedResourceForeground": "${accent_tertiary}",
			"gitDecoration.deletedResourceForeground": "${p1}",
			"gitDecoration.renamedResourceForeground": "${bln2}",
			"gitDecoration.untrackedResourceForeground": "${ana2}",
			"gitDecoration.conflictingResourceForeground": "${accent_secondary}",
			"gitDecoration.ignoredResourceForeground": "${p2}60",
			"gitDecoration.stageModifiedResourceForeground": "${bln3}",
			"gitDecoration.stageDeletedResourceForeground": "${p1}",
			"gitDecoration.submoduleResourceForeground": "${tri0}",

			// ── Diff Editor ──
			"diffEditor.insertedTextBackground": "${s2}20",
			"diffEditor.removedTextBackground": "${p1}20",
			"diffEditor.insertedLineBackground": "${s2}15",
			"diffEditor.removedLineBackground": "${p1}15",
			"diffEditor.border": "${accent_primary}30",
			"diffEditorGutter.insertedLineBackground": "${s2}40",
			"diffEditorGutter.removedLineBackground": "${p1}40",

			// ── Merge Conflict ──
			"merge.currentHeaderBackground": "${accent_primary}40",
			"merge.currentContentBackground": "${accent_primary}20",
			"merge.incomingHeaderBackground": "${accent_tertiary}40",
			"merge.incomingContentBackground": "${accent_tertiary}20",
			"merge.border": "${fg_soft}30",

			// ── Minimap ──
			"minimap.background": "${bg_dark}",
			"minimap.selectionHighlight": "${accent_primary}80",
			"minimap.findMatchHighlight": "${accent_secondary}80",
			"minimap.errorHighlight": "#ff555580",
			"minimap.warningHighlight": "${accent_secondary}80",
			"minimap.selectionOccurrenceHighlight": "${fg_soft}40",

			// ── Peek View ──
			"peekView.border": "${accent_primary}",
			"peekViewEditor.background": "${bg_main}",
			"peekViewResult.background": "${bg_sidebar}",
			"peekViewTitle.background": "${bg_dark}",
			"peekViewTitleLabel.foreground": "${fg_soft}",
			"peekViewTitleDescription.foreground": "${fg_muted}",
			"peekViewEditor.matchHighlightBackground": "${accent_secondary}50",
			"peekViewResult.matchHighlightBackground": "${accent_secondary}40",
			"peekViewResult.fileForeground": "${fg_main}",
			"peekViewResult.lineForeground": "${fg_soft}",
			"peekViewResult.selectionBackground": "${accent_primary}30",
			"peekViewResult.selectionForeground": "${fg_main}",

			// ── Breadcrumbs ──
			"breadcrumb.foreground": "${fg_soft}",
			"breadcrumb.focusForeground": "${s1}",
			"breadcrumb.activeSelectionForeground": "${accent_primary}",
			"breadcrumbPicker.background": "${bg_widget}",

			// ── Welcome Page ──
			"welcomePage.tileBackground": "${bg_sidebar}",
			"welcomePage.tileBorder": "${accent_primary}30",
			"welcomePage.progress.foreground": "${accent_secondary}",
			"walkThrough.embeddedEditorBackground": "${bg_main}",

			// ── Settings Editor ──
			"settings.headerForeground": "${fg_main}",
			"settings.modifiedItemIndicator": "${accent_secondary}",
			"settings.textInputBackground": "${bg_input}",
			"settings.textInputBorder": "${accent_primary}40",
			"settings.checkboxBackground": "${bg_input}",
			"settings.checkboxBorder": "${accent_primary}40",
			"settings.dropdownBackground": "${bg_input}",
			"settings.dropdownBorder": "${accent_primary}40",
			"settings.numberInputBackground": "${bg_input}",
			"settings.numberInputBorder": "${accent_primary}40",

			// ── Debug ──
			"debugToolBar.background": "${bg_widget}",
			"debugToolBar.border": "${accent_secondary}60",
			"debugExceptionWidget.background": "${bg_widget}",
			"debugExceptionWidget.border": "#ff555580",
			"debugTokenExpression.name": "${accent_tertiary}",
			"debugTokenExpression.value": "${s2}",
			"debugTokenExpression.string": "${s3}",
			"debugTokenExpression.number": "${s1}",
			"debugTokenExpression.boolean": "${accent_primary}",
			"debugTokenExpression.error": "#ff5555",
			"debugIcon.breakpointForeground": "${accent_primary}",
			"debugIcon.breakpointDisabledForeground": "${p2}60",
			"debugIcon.startForeground": "${s2}",
			"debugIcon.pauseForeground": "${accent_secondary}",
			"debugIcon.stopForeground": "#ff5555",
			"debugConsole.infoForeground": "${accent_tertiary}",
			"debugConsole.warningForeground": "${accent_secondary}",
			"debugConsole.errorForeground": "#ff5555",
			"debugConsole.sourceForeground": "${fg_soft}",
			"debugConsoleInputIcon.foreground": "${accent_primary}",

			// ── Testing ──
			"testing.iconPassed": "${s2}",
			"testing.iconFailed": "#ff5555",
			"testing.iconErrored": "#ff5555",
			"testing.iconQueued": "${accent_tertiary}",
			"testing.iconUnset": "${p2}60",
			"testing.iconSkipped": "${fg_soft}60",

			// ── Command Palette / Quick Input ──
			"quickInput.background": "${bg_widget}",
			"quickInput.foreground": "${fg_main}",
			"quickInputList.focusBackground": "${accent_primary}30",
			"quickInputList.focusForeground": "${fg_main}",
			"quickInputTitle.background": "${bg_dark}",
			"commandCenter.foreground": "${fg_soft}",
			"commandCenter.background": "${bg_dark}",
			"commandCenter.border": "${accent_primary}30",
			"commandCenter.activeForeground": "${fg_main}",
			"commandCenter.activeBackground": "${bg_hover}",
			"commandCenter.activeBorder": "${accent_primary}60",

			// ── Keybinding Label ──
			"keybindingLabel.background": "${accent_primary}20",
			"keybindingLabel.foreground": "${fg_main}",
			"keybindingLabel.border": "${accent_primary}40",
			"keybindingLabel.bottomBorder": "${accent_primary}60",

			// ── Inlay Hints ──
			"editorInlayHint.foreground": "${p3}90",
			"editorInlayHint.background": "${bg_hover}40",
			"editorInlayHint.typeForeground": "${t3}90",
			"editorInlayHint.parameterForeground": "${s3}90",

			// ── Focus Borders ──
			"focusBorder": "${accent_primary}80",
			"contrastBorder": "${accent_primary}30",
			"widget.shadow": "${bg_dark}80",
			"selection.background": "${accent_primary}40",
			"icon.foreground": "${fg_soft}",
			"foreground": "${fg_main}",
			"descriptionForeground": "${fg_soft}",
			"errorForeground": "#ff5555",
			"textLink.foreground": "${accent_tertiary}",
			"textLink.activeForeground": "${t1}",
			"textBlockQuote.background": "${bg_sidebar}",
			"textBlockQuote.border": "${accent_primary}40",
			"textCodeBlock.background": "${bg_panel}",
			"textPreformat.foreground": "${s2}",
			"textSeparator.foreground": "${p2}30"$(if [[ "$USE_COMPLEMENTARY" == true ]] && [[ -n "$compl_highlight" ]]; then echo ",

			// ── Complementary Accents ──
			\"badge.background\": \"${compl_highlight}\",
			\"badge.foreground\": \"${bg_dark}\""; fi)$(if [[ ${#VARIATION_COLOURS[@]} -gt 0 ]]; then echo ",

			// ── Variation Accents ──
			\"editorBracketHighlight.foreground1\": \"${var0}\",
			\"editorBracketHighlight.foreground2\": \"${var1}\",
			\"editorBracketHighlight.foreground3\": \"${var2}\",
			\"editorBracketHighlight.foreground4\": \"${var3}\""; fi)
		},
		"editor.tokenColourCustomizations": {
			"comments": "${p3}80",
			"strings": "${s2}",
			"keywords": "${accent_primary}",
			"numbers": "${s1}",
			"types": "${accent_tertiary}",
			"functions": "${bln0}",
			"variables": "${fg_main}",
			"textMateRules": [
				{
					"scope": ["entity.name.function", "support.function"],
					"settings": { "foreground": "${bln0}" }
				},
				{
					"scope": ["entity.name.type", "support.type", "support.class"],
					"settings": { "foreground": "${accent_tertiary}" }
				},
				{
					"scope": ["keyword", "storage.type", "storage.modifier"],
					"settings": { "foreground": "${accent_primary}" }
				},
				{
					"scope": ["keyword.operator"],
					"settings": { "foreground": "${p4}" }
				},
				{
					"scope": ["string", "string.quoted"],
					"settings": { "foreground": "${s2}" }
				},
				{
					"scope": ["string.regexp"],
					"settings": { "foreground": "${tri0}" }
				},
				{
					"scope": ["constant.numeric"],
					"settings": { "foreground": "${s1}" }
				},
				{
					"scope": ["constant.language", "support.constant"],
					"settings": { "foreground": "${accent_secondary}" }
				},
				{
					"scope": ["constant.character", "constant.other"],
					"settings": { "foreground": "${ana0}" }
				},
				{
					"scope": ["variable.parameter"],
					"settings": { "foreground": "${fg_main}", "fontStyle": "italic" }
				},
				{
					"scope": ["variable.other"],
					"settings": { "foreground": "${fg_main}" }
				},
				{
					"scope": ["variable.language"],
					"settings": { "foreground": "${accent_primary}", "fontStyle": "italic" }
				},
				{
					"scope": ["comment", "punctuation.definition.comment"],
					"settings": { "foreground": "${p3}80", "fontStyle": "italic" }
				},
				{
					"scope": ["entity.name.tag"],
					"settings": { "foreground": "${p1}" }
				},
				{
					"scope": ["entity.other.attribute-name"],
					"settings": { "foreground": "${s3}" }
				},
				{
					"scope": ["entity.other.attribute-name.id"],
					"settings": { "foreground": "${accent_tertiary}", "fontStyle": "bold" }
				},
				{
					"scope": ["entity.name.section", "entity.name.namespace"],
					"settings": { "foreground": "${tri1}" }
				},
				{
					"scope": ["punctuation", "meta.brace"],
					"settings": { "foreground": "${p4}" }
				},
				{
					"scope": ["punctuation.definition.tag"],
					"settings": { "foreground": "${p2}" }
				},
				{
					"scope": ["meta.decorator", "entity.name.function.decorator"],
					"settings": { "foreground": "${bln2}", "fontStyle": "italic" }
				},
				{
					"scope": ["meta.selector", "entity.other.attribute-name.class.css"],
					"settings": { "foreground": "${ana2}" }
				},
				{
					"scope": ["support.type.property-name.css"],
					"settings": { "foreground": "${bln3}" }
				},
				{
					"scope": ["markup.heading"],
					"settings": { "foreground": "${accent_primary}", "fontStyle": "bold" }
				},
				{
					"scope": ["markup.italic"],
					"settings": { "fontStyle": "italic" }
				},
				{
					"scope": ["markup.bold"],
					"settings": { "fontStyle": "bold" }
				},
				{
					"scope": ["markup.underline"],
					"settings": { "fontStyle": "underline" }
				},
				{
					"scope": ["markup.inline.raw"],
					"settings": { "foreground": "${s2}" }
				},
				{
					"scope": ["markup.deleted"],
					"settings": { "foreground": "${p1}" }
				},
				{
					"scope": ["markup.inserted"],
					"settings": { "foreground": "${s2}" }
				},
				{
					"scope": ["markup.changed"],
					"settings": { "foreground": "${accent_tertiary}" }
				},
				{
					"scope": ["markup.list"],
					"settings": { "foreground": "${accent_primary}" }
				},
				{
					"scope": ["markup.quote"],
					"settings": { "foreground": "${t3}", "fontStyle": "italic" }
				},
				{
					"scope": ["source.json support.type.property-name"],
					"settings": { "foreground": "${bln2}" }
				},
				{
					"scope": ["meta.embedded", "source.groovy.embedded"],
					"settings": { "foreground": "${fg_main}" }
				},
				{
					"scope": ["invalid", "invalid.illegal"],
					"settings": { "foreground": "#ff5555", "fontStyle": "strikethrough" }
				},
				{
					"scope": ["invalid.deprecated"],
					"settings": { "foreground": "${fg_muted}", "fontStyle": "strikethrough" }
				}$(if [[ "$USE_COMPLEMENTARY" == true ]] && [[ -n "$compl_highlight" ]]; then echo ",
				{
					\"scope\": [\"markup.heading\", \"entity.name.section\"],
					\"settings\": { \"foreground\": \"${compl_highlight}\" }
				},
				{
					\"scope\": [\"markup.bold\"],
					\"settings\": { \"foreground\": \"${compl_accent}\", \"fontStyle\": \"bold\" }
				}"; fi)$(if [[ ${#VARIATION_COLOURS[@]} -gt 0 ]]; then echo ",
				{
					\"scope\": [\"meta.object-literal.key\"],
					\"settings\": { \"foreground\": \"${var0}\" }
				},
				{
					\"scope\": [\"entity.name.method\"],
					\"settings\": { \"foreground\": \"${var1}\" }
				},
				{
					\"scope\": [\"support.variable\"],
					\"settings\": { \"foreground\": \"${var2}\" }
				}"; fi)
			]
		}
THEME_EOF
}
