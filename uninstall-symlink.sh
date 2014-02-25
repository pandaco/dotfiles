ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

find $ROOT_DIR -maxdepth 2 -name *.symlink -print0 | while read -d '' -r SYMLINK_SOURCE_PATH;
do
    SYMLINK_DEST=`basename ${SYMLINK_SOURCE_PATH%%.symlink}` #< Remove the string ".symlink"

    if [ -h ~/.$SYMLINK_DEST ]; then
        rm -f ~/.$SYMLINK_DEST
        echo "Symlink deleted: ~/.$SYMLINK_DEST"
    fi
done
