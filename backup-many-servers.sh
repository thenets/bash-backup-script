#!/bin/bash

##
# Variables
##

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

for CONFIG_FILE in servers/*.properties; do
    [ -e "${CONFIG_FILE}" ] || continue

    # Get ENV from config file
    source ${CONFIG_FILE}

    # Show selected server
    echo "[START] Starting backup for ${SERVER_NAME}"
echo "SERVER_DIR=root@172.31.12.35:/b2m"
echo "SERVER_NAME=${SERVER_NAME}"


##
# Backup
#
# Don't edit the code below.
##

echo "[....] Sync data from ${SERVER_DIR}"
mkdir -p ${TARGET_DIR}/${SERVER_NAME}/latest/

# Update latest backup version
rsync -av --delete ${SERVER_DIR} ${TARGET_DIR}/${SERVER_NAME}/latest/
echo "[DONE] Saved into ${TARGET_DIR}/${SERVER_NAME}/latest/"
echo ""

# Get current time
CURRENT_DATE=$(date +"%y-%m-%d")

# Compress files
echo "[....] Starting compression process"
ORIGIN_DIR=${TARGET_DIR}/${SERVER_NAME}/latest/
OUT_DIR=${TARGET_DIR}/${SERVER_NAME}/older/${CURRENT_DATE}
DIR_TO_BACKUP=$(find $ORIGIN_DIR -maxdepth 1 ! -path $ORIGIN_DIR -type d)
for D_PATH in $DIR_TO_BACKUP; do
    D_NAME=${D_PATH/$ORIGIN_DIR/}
    D_NAME="${D_NAME}"
    OUT_FILE=$OUT_DIR"/./"$D_NAME"_"$CURRENT_DATE".tar.gz"

    mkdir -p ${OUT_DIR}

    # Check if backup already exists for the same $CURRENT_DATE
    if [ -f $OUT_FILE ]; then
        echo "[skip] Backup $OUT_FILE already exist."
    elif [[ $D_NAME = *"docker"* ]]; then
        echo "[skip] Ignoring $ORIGIN_DIR dir."
    else
        # Create backup
        echo "[....] Compressing $D_NAME..."
        cd $ORIGIN_DIR
        tar -zcf ${OUT_FILE} ${D_NAME}
	echo "[DONE] ${OUT_FILE}"
	#echo "[DONE] ${D_NAME}"
    fi

    #exit
done

# Remove backups older than day
find ${TARGET_DIR}/${SERVER_NAME}/older -mtime +${DELETE_OLDER_THAN_X_DAYS} -exec rm {} \;

done
