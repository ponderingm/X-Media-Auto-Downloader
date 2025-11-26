#!/bin/bash

# 実行権限付与
chmod +x /download.sh

echo "----------------------------------------"
echo "Container started at $(date)"
echo "Running initial download..."
/download.sh
echo "Initial download completed."

# Background watcher for immediate download trigger
(
    while true; do
        if [ -f /config/.trigger_download ]; then
            echo "Trigger detected at $(date), starting download..."
            rm /config/.trigger_download
            /download.sh
        fi
        sleep 5
    done
) &

echo "Starting cron daemon..."
exec cron -f
