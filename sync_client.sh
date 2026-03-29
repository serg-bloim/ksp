#!/usr/bin/env bash

# Path to the KSP kOS scripts network share (adjust as needed)
DEST="/Volumes/home/projects/ksp"

if [ ! -d "$DEST" ]; then
    echo "ERROR: Destination '$DEST' not found. Is the network share mounted?"
    exit 1
fi

while true; do
    OUTPUT=$(rsync -a --delete --exclude='.*/' --itemize-changes . "$DEST/")
    if [ -n "$OUTPUT" ]; then
        echo "$(date '+%H:%M:%S') Synced:"
        echo "$OUTPUT"
    fi
    sleep 1
done
