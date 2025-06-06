#!/bin/bash

echo "[cwa-auto-zipper] Starting CWA-Auto-Zipper service..."
echo "[cwa-auto-zipper] Matching internal localtime & timezone with the one provided..."

tz=$TZ
if [[ $tz == "" ]]
then
    echo "[cwa-auto-zipper] No TZ env found. Defaulting to UTC..."
else
    region=$(echo $tz | awk -F '/' '{ print $1 }')
    city=$(echo $tz | awk -F '/' '{ print $2 }')

    zoneinfo_file="/usr/share/zoneinfo/$region/$city"
    if test -f $zoneinfo_file; then
        echo "[cwa-auto-zipper] Zoneinfo for $tz found. Setting /etc/localtime and /etc/timezone to match..."
        ln -sfn $zoneinfo_file /etc/localtime
        echo $tz > '/etc/timezone'
        echo "[cwa-auto-zipper] Timezone & Localtime successfully set to $tz. Initiating Auto-Zipper ..."
    else
        echo "[cwa-auto-zipper] Zoneinfo $tz not found. Using UTC as default..."
    fi
fi

WAKEUP="23:59" # Wake up at this time tomorrow and run a command

# Sometimes you want to sleep until a specific time in a bash script. This is useful, for instance
# in a docker container that does a single thing at a specific time on a regular interval, but does not want to be bothered
# with cron or at. The -d option to date is VERY flexible for relative times.
# See https://www.gnu.org/software/coreutils/manual/html_node/Relative-items-in-date-strings.html#Relative-items-in-date-strings

# This script runs in an infinite loop, waking up every night at 23:59
while :
do
    SECS=$(expr `date -d "$WAKEUP" +%s` - `date -d "now" +%s`)
    if [[ $SECS -lt 0 ]]
    then
        SECS=$(expr `date -d "tomorrow $WAKEUP" +%s` - `date -d "now" +%s`)
    fi
    echo "[cwa-auto-zipper] Next run in $SECS seconds."
    sleep $SECS &  # We sleep in the background to make the script interruptible via SIGTERM when running in docker
    wait $!
    python3 /app/calibre-web-automated/scripts/auto_zip.py
    if [[ $? == 1 ]]
    then
        echo "[cwa-auto-zipper] Error occurred during script initialisation (see errors above)."
    elif [[ $? == 2 ]]
    then
        echo "[cwa-auto-zipper] Error occurred while zipping today's files (see errors above)."
    elif [[ $? == 3 ]]
    then
        echo "[cwa-auto-zipper] Error occurred while trying to removed the files that have been zipped (see errors above)."
    fi
    sleep 60
done
