#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# file-ops.sh — File I/O operations for vscode-theme-gen
# ═══════════════════════════════════════════════════════════════════════════════
# Handles creating new workspace files, updating existing ones, and
# generating the default output path with date+version stamps.
#
# Requires: deps.sh, json-gen.sh sourced
# ═══════════════════════════════════════════════════════════════════════════════

VSGEN_VERSION="1.1.0"

# ─── Default output path ─────────────────────────────────────────────────────
# If the user does not supply -o, we write to
#   ./out/<ThemeName>-<date>-v<version>.code-workspace
# e.g. ./out/Sakura-2026-02-07-v1.1.0.code-workspace

resolve_default_output() {
    local out_dir="${SCRIPT_DIR}/../out"
    mkdir -p "$out_dir"

    # Sanitise theme name for a filename (spaces → dashes, strip specials)
    local safe_name
    safe_name=$(echo "$THEME_NAME" | tr ' ' '-' | tr -cd '[:alnum:]-_')
    [[ -z "$safe_name" ]] && safe_name="theme"

    local datestamp
    datestamp=$(date +%Y-%m-%d)

    echo "${out_dir}/${safe_name}-${datestamp}-v${VSGEN_VERSION}.code-workspace"
}

# ─── Create new workspace file ───────────────────────────────────────────────

create_workspace_file() {
    local output="$1"
    local theme_settings
    theme_settings=$(generate_theme_json)

    # Ensure target directory exists
    mkdir -p "$(dirname "$output")"

    cat << EOF > "$output"
{
	"folders": [
		{
			"path": "../"
		}
	],
	"settings": {
${theme_settings}
	}
}
EOF
    log_success "Created workspace file: $output"
}

# ─── Update existing workspace file ─────────────────────────────────────────

update_workspace_file() {
    local config="$1"
    local theme_settings
    theme_settings=$(generate_theme_json)

    # Backup original
    cp "$config" "${config}.bak"
    log_verbose "Backup created: ${config}.bak"

    # Check if file has settings section
    if grep -q '"settings"' "$config"; then
        # Check if colourCustomizations exists
        if grep -q '"workbench.colourCustomizations"' "$config"; then
            local tmp_file
            tmp_file=$(mktemp)

            awk -v theme="$theme_settings" '
            BEGIN { in_color_section = 0; in_token_section = 0; brace_count = 0 }

            /"workbench\.colourCustomizations"/ {
                in_color_section = 1
                brace_count = 0
                next
            }

            /"editor\.tokenColourCustomizations"/ && !in_color_section {
                in_token_section = 1
                brace_count = 0
                next
            }

            in_color_section {
                if (/{/) brace_count++
                if (/}/) {
                    brace_count--
                    if (brace_count <= 0) {
                        in_color_section = 0
                        print theme
                        if (/},/) print ","
                    }
                }
                next
            }

            in_token_section {
                if (/{/) brace_count++
                if (/}/) {
                    brace_count--
                    if (brace_count <= 0) {
                        in_token_section = 0
                    }
                }
                next
            }

            { print }
            ' "$config" > "$tmp_file"

            mv "$tmp_file" "$config"
            log_success "Updated colour customizations in: $config"
        else
            local tmp_file
            tmp_file=$(mktemp)

            awk -v theme="$theme_settings" '
            /"settings"[[:space:]]*:[[:space:]]*{/ {
                print
                getline
                print theme ","
                print
                next
            }
            { print }
            ' "$config" > "$tmp_file"

            mv "$tmp_file" "$config"
            log_success "Added colour customizations to: $config"
        fi
    else
        local tmp_file
        tmp_file=$(mktemp)

        awk -v theme="$theme_settings" '
        {
            if (/^}[[:space:]]*$/ && !done) {
                print "\t,\"settings\": {"
                print theme
                print "\t}"
                done = 1
            }
            print
        }
        ' "$config" > "$tmp_file"

        mv "$tmp_file" "$config"
        log_success "Added settings section to: $config"
    fi
}

# ─── Create workspace file with optional symlink ─────────────────────────────
# If symlink_path is provided, creates the workspace at export_path and
# creates a symlink at symlink_path pointing to it.

create_workspace_with_symlink() {
    local export_path="$1"
    local symlink_path="$2"
    local theme_settings
    theme_settings=$(generate_theme_json)

    # Create the actual workspace file at export location
    mkdir -p "$(dirname "$export_path")"

    cat << EOF > "$export_path"
{
	"folders": [
		{
			"path": "../"
		}
	],
	"settings": {
${theme_settings}
	}
}
EOF
    log_success "Created workspace file: $export_path"

    # Create symlink if symlink path provided
    if [[ -n "$symlink_path" ]]; then
        mkdir -p "$(dirname "$symlink_path")"

        # Remove existing symlink/file at symlink location
        if [[ -L "$symlink_path" ]] || [[ -f "$symlink_path" ]]; then
            rm -f "$symlink_path"
            log_verbose "Removed existing file/link: $symlink_path"
        fi

        # Create symlink with relative path if possible
        local target_dir
        target_dir="$(dirname "$symlink_path")"
        
        # Get relative path from symlink directory to export file
        local export_dir
        export_dir="$(dirname "$export_path")"
        
        # Try to create relative symlink
        if [[ "$target_dir" == "$export_dir" ]]; then
            # Same directory, use filename only
            ln -s "$(basename "$export_path")" "$symlink_path"
        else
            # Different directories, use relative path
            local rel_path
            rel_path=$(python3 -c "import os.path; print(os.path.relpath('$export_path', '$target_dir'))" 2>/dev/null || echo "$export_path")
            ln -s "$rel_path" "$symlink_path"
        fi

        log_success "Created symlink: $symlink_path → $(basename "$export_path")"
    fi
}
