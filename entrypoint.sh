#!/bin/bash

# 実行権限付与
chmod +x /download.sh

echo "----------------------------------------"
echo "Container started at $(date)"
echo "Running initial download..."
/download.sh
echo "Initial download completed."

echo "Starting cron daemon..."
exec cron -f
