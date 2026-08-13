#!/bin/bash
set -e

BACKUP_DIR="/srv/backups/mongo"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
DEST="$BACKUP_DIR/backup_$TIMESTAMP"

mkdir -p "$DEST"

docker exec restauranty-mongo mongodump --db Restauranty --archive > "$DEST/restauranty.archive"

# Keep only the 7 most recent backups
cd "$BACKUP_DIR"
ls -1dt backup_* | tail -n +8 | xargs -r rm -rf

echo "Backup completed: $DEST"
