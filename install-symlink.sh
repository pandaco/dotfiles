ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

find $ROOT_DIR -maxdepth 2 -name *.symlink -print0 | while read -d '' -r SYMLINK_SOURCE_PATH;
do
    SYMLINK_DEST=`basename ${SYMLINK_SOURCE_PATH%%.symlink}` #< Remove the string ".symlink"
    if [ ! -f ~/.$SYMLINK_DEST ]; then
        ln -s $SYMLINK_SOURCE_PATH ~/.$SYMLINK_DEST 2>/dev/null
        
        [ $? -eq 0 ]  && echo "Symlink created: ~/.$SYMLINK_DEST"
    fi
done
