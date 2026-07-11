#!/bin/bash
set -euo pipefail

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ACTION=""
DRY_RUN=false

usage()
{
    echo "Usage: $0 {-i|--install|-d|--delete} [-n|--dry-run]"
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
        echo "Skipped (symlink already exists): $target"
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
