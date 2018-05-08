#!/bin/bash

# Bash dir
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Backup all dirs from $ORIGIN_DIR and send to $OUT_DIR.
# Will keep only $N_OF_REVISIONS latest versions
ORIGIN_DIR=''
OUT_DIR=''
N_OF_REVISIONS=5
REMOVE_FILES_OLDER_THAN_X_DAYS=30

# Get current time
CURRENT_DATE=$(date +"%y-%m-%d_%H-%M")
echo "Starting backup process $CURRENT_DATE"
echo "Params: $@"

# Check if ORIGIN_DIR and OUT_DIR args exists
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "./backup /bkp_from_here /output_bkp_file_here [N_OF_REVISIONS] [REMOVE_FILES_OLDER_THAN_X_DAYS]"
    exit
else
    ORIGIN_DIR=$1
    OUT_DIR=$2
fi

# Check if N_OF_REVISIONS exist and is valid
if [ "$3" ]; then
    if [[ $3 =~ ^-?[0-9]+$ ]]; then
    N_OF_REVISIONS=$3

    else
        echo "The N_OF_REVISIONS arg must be an integer!"
        exit
    fi
fi

# Check if REMOVE_FILES_OLDER_THAN_X_DAYS exist and is valid
if [ "$4" ]; then
    if [[ $4 =~ ^-?[0-9]+$ ]]; then
    REMOVE_FILES_OLDER_THAN_X_DAYS=$4

    else
        echo "The REMOVE_FILES_OLDER_THAN_X_DAYS arg must be an integer!"
        exit
    fi
fi

# Check if ORIGIN_DIR exist and has file
if [ -d "$ORIGIN_DIR" ] && [ "$(find $ORIGIN_DIR -maxdepth 1 -type d)" ]; then
    echo "[ ok ] ORIGIN_DIR='$ORIGIN_DIR' is valid..."
else
    echo "[fail] The ORIGIN_DIR='$ORIGIN_DIR' doesn't exist or doesn't have any folder!"
    exit
fi

# Check if ORIGIN_DIR exist and has file
if [ -d "$OUT_DIR" ]; then
    echo "[ ok ] OUT_DIR='$OUT_DIR' is valid..."
else
    echo "[fail] The OUT_DIR='$OUT_DIR' doesn't exist!"
    exit
fi

# For each dir in ORIGIN_DIR
DIR_TO_BACKUP=$(find $ORIGIN_DIR -maxdepth 1 ! -path $ORIGIN_DIR -type d)
for D_PATH in $DIR_TO_BACKUP; do
    D_NAME=${D_PATH/$ORIGIN_DIR/}
    D_NAME="${D_NAME}" | sed 's/\///g'
    OUT_FILE=$OUT_DIR""$D_NAME"_"$CURRENT_DATE".tar.gz"

    # Check if backup already exists for the same $CURRENT_DATE
    if [ -f $OUT_FILE ]; then
        echo "[skip] Backup $OUT_FILE already exist."
    elif [[ $D_NAME = *"docker"* ]]; then
        echo "[skip] Ignoring $ORIGIN_DIR dir."
    else
        # Create backup
        echo "[....] Compressing $D_NAME..."
        cd $ORIGIN_DIR
        tar -zcf $OUT_FILE $D_NAME
    fi
done
echo "[ ok ] Backup complete!"

set -x
# Upload to Dropbox
echo ""
echo "[    ] Uploading to Dropbox"
$DIR/dropbox_uploader.sh delete latest
$DIR/dropbox_uploader.sh mkdir latest
for D_PATH in $DIR_TO_BACKUP; do
    D_NAME=${D_PATH/$ORIGIN_DIR/}
    D_NAME="${D_NAME}" | sed 's/\///g'
    FILE_NAME=$D_NAME"_"$CURRENT_DATE".tar.gz"
    OUT_FILE=$OUT_DIR""$FILE_NAME

    # Upload data to Dropbox
    if [[ $D_NAME = *"docker"* ]]; then
        # Ignore Dropbox dir
        echo "[skip] Ignoring  $D_NAME..."
    else
        echo "[....] Uploading $FILE_NAME..."
        $DIR/dropbox_uploader.sh upload $OUT_FILE ./latest/
    fi
done
echo "[ ok ] Upload complete!"
set +x

# Remove backups older than day
FILE_TO_REMOVE=$(find $OUT_DIR -maxdepth 1 -type f -mtime +$REMOVE_FILES_OLDER_THAN_X_DAYS)
if [ ! -z "$FILE_TO_REMOVE" ]; then echo "Removing old files"; fi
for F in $FILE_TO_REMOVE; do
    rm -f $F
    echo "[ ok ] Deleted: $F"
done
echo "DONE!"