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


function install_symlinks
{
    local symlink_source_path=$1
    local symlink_dest=$2
    local target="$HOME/.$symlink_dest"

    if [ -L "$target" ]; then
        if $FORCE; then
            if $DRY_RUN; then
                echo "[dry-run] Would overwrite existing symlink: $target -> $symlink_source_path"
            else
                rm -f "$target"
                ln -s "$symlink_source_path" "$target"
                echo "Symlink overwritten: $target"
            fi
        else
            echo "Skipped: $target (already -> $(readlink "$target"))"
            SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        fi
        return
    fi

    if [ -e "$target" ]; then
        echo "Skipped (real file/directory exists, will not overwrite): $target"
        return
    fi

    if $DRY_RUN; then
        echo "[dry-run] Would create symlink: $target -> $symlink_source_path"
        return
    fi

    ln -s "$symlink_source_path" "$target"
    echo "Symlink created: $target"
}

function delete_symlinks
{
    local symlink_source_path=$1
    local symlink_dest=$2
    local target="$HOME/.$symlink_dest"

    if [ -L "$target" ]; then
        if $DRY_RUN; then
            echo "[dry-run] Would delete symlink: $target"
        else
            rm -f "$target"
            echo "Symlink deleted: $target"
        fi
        return
    fi

    if [ -e "$target" ]; then
        echo "Skipped (real file/directory, not a symlink, will not delete): $target"
        return
    fi

    echo "Nothing to delete (no symlink at): $target"
}


while IFS= read -r -d '' symlink_source_path; do
    symlink_dest="$(basename "${symlink_source_path%%.symlink}")" #< Remove the string ".symlink"

    "$ACTION" "$symlink_source_path" "$symlink_dest"
done < <(find "$ROOT_DIR" -maxdepth 2 -name "*.symlink" -print0)

if [ "$SKIPPED_COUNT" -gt 0 ] && ! $FORCE; then
    echo "$SKIPPED_COUNT symlink(s) skipped — use -f/--force to overwrite them."
fi
