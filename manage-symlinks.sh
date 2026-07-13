#!/bin/bash
set -euo pipefail

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ACTION=""
DRY_RUN=false
FORCE=false
SKIPPED_COUNT=0

usage()
{
    echo "Usage: $0 {-i|--install|-d|--delete} [-n|--dry-run] [-f|--force]"
    exit 1
}

for arg in "$@"; do
    case "$arg" in
        -i|--install)
            ACTION='install_symlinks'
            ;;
        -d|--delete)
            ACTION='delete_symlinks'
            ;;
        -n|--dry-run)
            DRY_RUN=true
            ;;
        -f|--force)
            FORCE=true
            ;;
        *)
            usage
            ;;
    esac
done

if [ -z "$ACTION" ]; then
    usage
fi


function short_path
{
    printf '%s' "${1/#"$HOME"/~}"
}

RESULTS=()

function record_result
{
    local category=$1
    local target_display=$2
    local message=$3
    RESULTS+=("$category"$'\t'"$target_display"$'\t'"$message")
}

function print_results
{
    [ ${#RESULTS[@]} -eq 0 ] && return
    local prev_category="" category target_display message
    while IFS=$'\t' read -r category target_display message; do
        if [[ -n "$prev_category" && "$category" != "$prev_category" ]]; then
            echo
        fi
        echo "$message"
        prev_category="$category"
    done < <(printf '%s\n' "${RESULTS[@]}" | sort -t $'\t' -k1,1 -k2,2)
}

function install_symlinks
{
    local symlink_source_path=$1
    local symlink_dest=$2
    local symlink_source_rel=$3
    local target="$HOME/$symlink_dest"
    local target_display
    target_display="$(short_path "$target")"

    if [ -L "$target" ]; then
        if $FORCE; then
            if $DRY_RUN; then
                record_result "would overwrite" "$target_display" "[dry-run] ✅ $target_display (would overwrite -> $symlink_source_rel)"
            else
                rm -f "$target"
                mkdir -p "$(dirname "$target")"
                ln -s "$symlink_source_path" "$target"
                record_result "overwritten" "$target_display" "✅ $target_display (overwritten -> $symlink_source_rel)"
            fi
        else
            record_result "linked" "$target_display" "🟢 $target_display (already linked, ok)"
            SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        fi
        return
    fi

    if [ -e "$target" ]; then
        record_result "conflict" "$target_display" "🟠 $target_display (real file/dir here, not touched)"
        return
    fi

    if $DRY_RUN; then
        record_result "would create" "$target_display" "[dry-run] ✅ $target_display (would create -> $symlink_source_rel)"
        return
    fi

    mkdir -p "$(dirname "$target")"
    ln -s "$symlink_source_path" "$target"
    record_result "created" "$target_display" "✅ $target_display (created -> $symlink_source_rel)"
}

function delete_symlinks
{
    local symlink_source_path=$1
    local symlink_dest=$2
    local symlink_source_rel=$3
    local target="$HOME/$symlink_dest"
    local target_display
    target_display="$(short_path "$target")"

    if [ -L "$target" ]; then
        if $DRY_RUN; then
            record_result "would delete" "$target_display" "[dry-run] ✅ $target_display (would delete)"
        else
            rm -f "$target"
            record_result "deleted" "$target_display" "✅ $target_display (deleted)"
        fi
        return
    fi

    if [ -e "$target" ]; then
        record_result "conflict" "$target_display" "🟠 $target_display (real file/dir here, not touched)"
        return
    fi

    record_result "nothing to delete" "$target_display" "-  $target_display (nothing to delete)"
}


while IFS= read -r -d '' symlink_source_path; do
    relative_path="${symlink_source_path#"$ROOT_DIR"/}"
    # Path inside the (always plain) app folder, e.g. "bashrc.symlink" or
    # ".claude/CLAUDE.md.symlink".
    rest="${relative_path#*/}"
    rest_first_segment="${rest%%/*}"

    if [[ "$rest_first_segment" == .* && "$rest" == */* ]]; then
        # A dot-prefixed folder anywhere under the app folder (e.g.
        # claude/.claude/) mirrors its own relative path under $HOME, so
        # several files can share the same real parent directory instead of
        # each becoming their own top-level dotfile.
        symlink_dest="${rest%.symlink}"
    else
        # Otherwise the app folder is just organisational: only the basename
        # matters, and it becomes a single dotfile/dotdir at the top of $HOME.
        symlink_dest=".$(basename "${symlink_source_path%%.symlink}")"
    fi

    "$ACTION" "$symlink_source_path" "$symlink_dest" "$relative_path"
done < <(find "$ROOT_DIR" -maxdepth 4 -name "*.symlink" -print0 | sort -z)

print_results

if [ "$SKIPPED_COUNT" -gt 0 ] && ! $FORCE; then
    echo "$SKIPPED_COUNT symlink(s) skipped — use -f/--force to overwrite them."
fi
