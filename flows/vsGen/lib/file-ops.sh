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

# ─── Get next version number for incremental generations ────────────────────
# Takes a base filename (e.g., "theme.code-workspace") and finds the highest
# numbered version (theme1.code-workspace, theme2.code-workspace, etc.),
# then returns the next number and full versioned filename.
#
# Output: prints comma-separated "next_number,versioned_filename"
# Examples:
#   get_next_version "theme.code-workspace" "/path/to/theme.code-workspace"
#   Output: "1,/path/to/theme1.code-workspace" (if no existing versions)
#   Output: "3,/path/to/theme3.code-workspace" (if theme1.code-workspace and theme2.code-workspace exist)

get_next_version() {
    local base_filename="$1"
    local full_path="$2"
    
    # Extract directory and base name without extension
    local dir="${full_path%/*}"
    local filename="${base_filename%.*}"
    local ext=".${base_filename##*.}"
    
    # Find highest existing version number (theme1, theme2, etc.)
    local max_ver=0
    if [[ -d "$dir" ]]; then
        local matching_files
        matching_files=$(find "$dir" -maxdepth 1 -name "${filename}[0-9]*${ext}" 2>/dev/null | sort)
        if [[ -n "$matching_files" ]]; then
            while IFS= read -r file; do
                # Extract number from filename: theme2.code-workspace → 2
                local num=$(echo "$(basename "$file")" | sed "s/${filename}\([0-9]\+\)${ext}/\1/")
                if (( num > max_ver )); then
                    max_ver=$num
                fi
            done <<< "$matching_files"
        fi
    fi
    
    local next_ver=$((max_ver + 1))
    local versioned_path="${dir}/${filename}${next_ver}${ext}"
    
    echo "${next_ver},${versioned_path}"
}

# ─── Create new workspace file ───────────────────────────────────────────────
# When -o is used alone (no -e), write directly with versioning (numbering only)
# Creates: theme1.code-workspace, theme2.code-workspace, etc.
# No symlinks, no overwriting — just append to history

create_workspace_file() {
    local output="$1"
    local theme_settings
    theme_settings=$(generate_theme_json)

    # Ensure target directory exists
    mkdir -p "$(dirname "$output")"

    # Get next version number
    local base_filename=$(basename "$output")
    local version_info
    version_info=$(get_next_version "$base_filename" "$output")
    local next_num=$(echo "$version_info" | cut -d',' -f1)
    local versioned_output=$(echo "$version_info" | cut -d',' -f2)

    cat << EOF > "$versioned_output"
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
    log_success "Created workspace file: $versioned_output"
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
# Enables incremental versioning with symlink → hard copy progression:
#   The export file (actual workspace) is overwritten, maintaining single source of truth
#   Numbered symlinks initially point to export, but convert to hard copies on next run
#   This preserves all generations while staying DRY (Don't Repeat Yourself)
#
# Workflow:
#   Run 1: Create export → create symlink 1 (points to export)
#   Run 2: Restore symlink 1 to hard copy (before overwrite) → create new export → symlink 2
#   Run 3: Restore symlink 2 to hard copy → create new export → symlink 3

create_workspace_with_symlink() {
    local export_path="$1"
    local symlink_path="$2"
    local theme_settings
    theme_settings=$(generate_theme_json)

    # Ensure export directory exists
    mkdir -p "$(dirname "$export_path")"

    # ─── Restore previous version (convert symlink to hard copy) ─────────────────
    # Before overwriting export, convert the latest numbered symlink to a hard copy
    # This preserves the previous generation before we overwrite the export file
    if [[ -n "$symlink_path" ]] && [[ -e "$export_path" ]]; then
        local symlink_dir
        symlink_dir="$(dirname "$symlink_path")"
        local base_filename=$(basename "$symlink_path")
        
        # Find the next version number to determine current version
        local version_info
        version_info=$(get_next_version "$base_filename" "$symlink_path")
        local next_num=$(echo "$version_info" | cut -d',' -f1)
        local current_num=$((next_num - 1))
        
        # If not first run, restore previous version (convert symlink to hard copy)
        if (( current_num > 0 )); then
            local current_symlink="${symlink_dir}/${base_filename%.*}${current_num}.${base_filename##*.}"
            
            if [[ -L "$current_symlink" ]]; then
                # This symlink points to the old export file; convert to hard copy
                local tmp_copy
                tmp_copy=$(mktemp "$(dirname "$current_symlink")/XXXXXX")
                cp "$export_path" "$tmp_copy"
                rm "$current_symlink"
                mv "$tmp_copy" "$current_symlink"
                log_success "Restored workspace file: $(readlink -f "$export_path") → $current_symlink"
            fi
        fi
    fi

    # ─── Write new workspace file ───────────────────────────────────────────────
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

    # ─── Create new versioned symlink ──────────────────────────────────────────
    if [[ -n "$symlink_path" ]]; then
        mkdir -p "$(dirname "$symlink_path")"

        local base_filename=$(basename "$symlink_path")
        local version_info
        version_info=$(get_next_version "$base_filename" "$symlink_path")
        local next_num=$(echo "$version_info" | cut -d',' -f1)
        local versioned_symlink=$(echo "$version_info" | cut -d',' -f2)

        local symlink_dir
        symlink_dir="$(dirname "$versioned_symlink")"
        local export_dir
        export_dir="$(dirname "$export_path")"
        
        # Create relative or absolute symlink
        if [[ "$symlink_dir" == "$export_dir" ]]; then
            ln -s "$(basename "$export_path")" "$versioned_symlink"
        else
            local rel_path
            rel_path=$(python3 -c "import os.path; print(os.path.relpath('$export_path', '$symlink_dir'))" 2>/dev/null || echo "$export_path")
            ln -s "$rel_path" "$versioned_symlink"
        fi

        log_success "Created symlink: $versioned_symlink → $(basename "$export_path")"
    fi
}
