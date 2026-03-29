#!/usr/bin/env bash

DEST="/F/steam/steamapps/common/Kerbal Space Program/Ships/Script/"
SRC="$(cygpath -w "$(dirname "$0")")"

while true; do
    OUTPUT=$(robocopy "$SRC" "$DEST" //S 2>&1)
    if [ -n "$OUTPUT" ]; then
        echo "$(date '+%H:%M:%S') Synced:"
        echo "$OUTPUT"
    fi
    sleep 1
done
