#!/bin/bash

#------------------------------------------------------------------------------------------------------------------------
#  Make sure required directories exist
#------------------------------------------------------------------------------------------------------------------------

mkdir -p /config/processed_books/converted
mkdir -p /config/processed_books/imported
mkdir -p /config/processed_books/failed
mkdir -p /config/processed_books/fixed_originals
mkdir -p /config/log_archive
mkdir -p /config/.cwa_conversion_tmp

#------------------------------------------------------------------------------------------------------------------------
#  Remove any leftover lock files
#------------------------------------------------------------------------------------------------------------------------

declare -a lockFiles=("ingest_processor.lock" "convert_library.lock" "cover_enforcer.lock" "kindle_epub_fixer.lock")

echo "[cwa-init] Checking for leftover lock files from previous instance..."

counter=0

for f in "${lockFiles[@]}"
do
    if [ -f "/tmp/$f" ]
    then
        echo "[cwa-init] Leftover $f exists, removing now..."
        rm "/tmp/$f"
        echo "[cwa-init] Leftover $f removed."
        let counter++
    fi
done

if [[ "$counter" -eq 0 ]]
then
    echo "[cwa-init] No leftover lock files to remove. Ending service..."
else
    echo "[cwa-init] $counter lock file(s) removed. Ending service..."
fi

#------------------------------------------------------------------------------------------------------------------------
#  Check for existing app.db and create one from the included example if one doesn't already exist
#------------------------------------------------------------------------------------------------------------------------

echo "[cwa-init] Checking for an existing app.db in /config..."

if [ ! -f /config/app.db ]; then
    echo "[cwa-init] No existing app.db found! Creating new one..."
    cp /app/calibre-web-automated/empty_library/app.db /config/app.db
else
    echo "[cwa-init] Existing app.db found!"
fi

#------------------------------------------------------------------------------------------------------------------------
#  Ensure correct binary paths in app.db
#------------------------------------------------------------------------------------------------------------------------

echo "[cwa-init] Setting binary paths in '/config/app.db' to the correct ones..."

sqlite3 /config/app.db <<EOS
    update settings set config_kepubifypath='/usr/bin/kepubify', config_converterpath='/usr/bin/ebook-convert', config_binariesdir='/usr/bin';
EOS

if [[ $? == 0 ]]
then
    echo "[cwa-init] Successfully set binary paths in '/config/app.db'!"
elif [[ $? > 0 ]]
then
    echo "[cwa-init] Service could not successfully set binary paths for '/config/app.db' (see errors above)."
fi


# Copy dirs.json to config because the app dir is read-only, but /config isn't
echo "[cwa-init] cp /app/calibre-web-automated/dirs.json /config/dirs.json"
cp /app/calibre-web-automated/dirs.json /config/dirs.json

echo "[cwa-init] CWA-init complete! Service exiting now..."

#------------------------------------------------------------------------------------------------------------------------
#  Set required permissions
#------------------------------------------------------------------------------------------------------------------------

declare -a requiredDirs=("/config" "/calibre-library" "/app/calibre-web-automated")

dirs=$(printf ", %s" "${requiredDirs[@]}")
dirs=${dirs:1}

# echo "[cwa-init] Recursively setting ownership of everything in$dirs to abc:abc..."

# for d in "${requiredDirs[@]}"
# do
#     chown -R abc:abc $d
#     if [[ $? == 0 ]]
#     then
#         echo "[cwa-init] Successfully set permissions for '$d'!"
#     elif [[ $? > 0 ]]
#     then
#         echo "[cwa-init] Service could not successfully set permissions for '$d' (see errors above)."
#     fi
# done

