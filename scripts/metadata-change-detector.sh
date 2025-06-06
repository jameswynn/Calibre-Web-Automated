#!/bin/bash

echo "========== STARTING METADATA CHANGE DETECTOR ==========="

# Folder to monitor
WATCH_FOLDER="/config/metadata_change_logs"
echo "[metadata-change-detector] Watching folder: $WATCH_FOLDER"

# Monitor the folder for new files
inotifywait -m -e close_write -e moved_to --exclude '^.*\.(swp)$' "$WATCH_FOLDER" |
while read -r directory events filename; do
        echo "[metadata-change-detector] New file detected: $filename"
        python3 /app/calibre-web-automated/scripts/cover_enforcer.py "--log" "$filename"
done