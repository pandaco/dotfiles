#!/bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

case $1 in
    -i|--install)
        ACTION='install_symlinks'
        ;;
    -d|--delete)
        ACTION='delete_symlinks'
        ;;
    *)
        echo $"Usage: $0 {-i|--install|-d|--delete}"
        exit 1 
esac


function install_symlinks
{
    SYMLINK_SOURCE_PATH=$1
    SYMLINK_DEST=$2

    # Create symlink only if the file or directory ~/.$SYMLINK_DEST does not exist
    if [ ! -f ~/.$SYMLINK_DEST ] && [ ! -d ~/.$SYMLINK_DEST ]; then
        ln -s $SYMLINK_SOURCE_PATH ~/.$SYMLINK_DEST 2>/dev/null
        
        [ $? -eq 0 ]  && echo "Symlink created: ~/.$SYMLINK_DEST"
    fi
}

function delete_symlinks
{
    SYMLINK_SOURCE_PATH=$1
    SYMLINK_DEST=$2

    # Remove symlinks
    if [ -h ~/.$SYMLINK_DEST ]; then
        rm -f ~/.$SYMLINK_DEST
        echo "Symlink deleted: ~/.$SYMLINK_DEST"
    fi
}


find $ROOT_DIR -maxdepth 2 -name *.symlink -print0 | while read -d '' -r SYMLINK_SOURCE_PATH;
do
    SYMLINK_DEST=`basename ${SYMLINK_SOURCE_PATH%%.symlink}` #< Remove the string ".symlink"
    
    $ACTION $SYMLINK_SOURCE_PATH $SYMLINK_DEST
done
