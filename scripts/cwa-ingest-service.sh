#!/bin/bash

# https://github.com/janeczku/calibre-web/wiki/Automatically-import-new-books-(Linux)

# This script is used to automatically import downloaded ebooks into a Calibre database.
# Reference: https://manual.calibre-ebook.com/generated/en/calibredb.html#add
echo "========== STARTING CWA-INGEST SERVICE =========="

WATCH_FOLDER=$(grep -o '"ingest_folder": "[^"]*' /config/dirs.json | grep -o '[^"]*$')
echo "[cwa-ingest-service] Watching folder: $WATCH_FOLDER"

# Monitor the folder for new files
inotifywait -m -r --format="%e %w%f" -e close_write -e moved_to "$WATCH_FOLDER" |
while read -r events filepath ; do
        # if [[ $(grep "$filepath" ingest-log-test.txt | egrep -o '[0-9]{10}') ]]; then
        #         CURRENT_TIME=$(date +'%s')
        #         TIME_OF_MATCH=$(grep "$filepath" ingest-log-test.txt | egrep -o '[0-9]{10}')
        #         TODO NEED TO GET DIFFERENCE BETWEEN THE 2 TIMES AND IF LESS THAN 60 SECONDS, IGNORE
        echo "[cwa-ingest-service] New files detected - $filepath - Starting Ingest Processor..."
        python3 /app/calibre-web-automated/scripts/ingest_processor.py "$filepath" # &
        # echo "'${filepath}' - $(date +'%s')" >> /config/.ingest_dupe_list
        # INGEST_PROCESSOR_PID=$!
        # Wait for the ingest processor to finish
        # wait $INGEST_PROCESSOR_PID
        # if ! [[ $(ls -A "$WATCH_FOLDER") ]]; then
        #         FILES="${WATCH_FOLDER}/*"
        #         for f in $FILES
        #         do
        #                 python3 /app/calibre-web-automated/scripts/ingest_processor.py "$f" &
        #                 INGEST_PROCESSOR_PID=$!
        #                 # Wait for the ingest processor to finish
        #                 wait $INGEST_PROCESSOR_PID
        #         done
        # fi
done

