#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# svg.sh — SVG swatch-sheet export for palGen
# ═══════════════════════════════════════════════════════════════════════════════
# Emits a printable SVG contact sheet: one row per token group, each swatch
# labelled with its key and hex value on a dark canvas.
# ═══════════════════════════════════════════════════════════════════════════════

generate_svg() {
    local outfile="${OUTPUT_DIR}/$(safe_theme_name).svg"

    # Layout metrics (px).
    local pad=20 sw=92 sh=52 gap=10 labelh=22 below=30
    local rowh=$(( labelh + sh + below ))

    # Widest group decides the canvas width.
    local maxcols=1 g count
    for g in "${TOKEN_GROUPS[@]}"; do
        count=$(tokens_in_group "$g" | wc -l | tr -d ' ')
        (( count > maxcols )) && maxcols=$count
    done

    local ngroups=${#TOKEN_GROUPS[@]}
    local width=$(( pad * 2 + maxcols * sw + (maxcols - 1) * gap ))
    local height=$(( pad * 2 + ngroups * rowh ))

    local svg=""
    svg+="<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"${width}\" height=\"${height}\" viewBox=\"0 0 ${width} ${height}\" font-family=\"ui-monospace, monospace\">"$'\n'
    svg+="  <rect width=\"${width}\" height=\"${height}\" fill=\"#1e1e1e\"/>"$'\n'

    local r=0
    for g in "${TOKEN_GROUPS[@]}"; do
        local gy=$(( pad + r * rowh ))
        svg+="  <text x=\"${pad}\" y=\"$(( gy + 15 ))\" fill=\"#e8e8e8\" font-size=\"14\" font-weight=\"bold\">${g}</text>"$'\n'

        local c=0 key hex x sy cx
        while IFS=$'\t' read -r key hex; do
            x=$(( pad + c * (sw + gap) ))
            sy=$(( gy + labelh ))
            cx=$(( x + sw / 2 ))
            svg+="  <rect x=\"${x}\" y=\"${sy}\" width=\"${sw}\" height=\"${sh}\" rx=\"8\" fill=\"${hex}\" stroke=\"#ffffff22\"/>"$'\n'
            svg+="  <text x=\"${cx}\" y=\"$(( sy + sh + 14 ))\" fill=\"#d0d0d0\" font-size=\"11\" text-anchor=\"middle\">${key}</text>"$'\n'
            svg+="  <text x=\"${cx}\" y=\"$(( sy + sh + 26 ))\" fill=\"#8a8a8a\" font-size=\"10\" text-anchor=\"middle\">${hex}</text>"$'\n'
            c=$(( c + 1 ))
        done < <(tokens_in_group "$g")

        r=$(( r + 1 ))
    done

    svg+="</svg>"

    write_target_file "$outfile" "$svg"
}
