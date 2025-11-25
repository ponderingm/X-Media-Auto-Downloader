#!/bin/bash

# 設定ファイルパス
URL_LIST="/downloads/urls.txt"
COOKIE_FILE="/config/cookies.txt"
ARCHIVE_FILE="/config/archive.sqlite3"

echo "----------------------------------------"
echo "Job started at $(date)"

# 初回用デフォルトファイル作成
if [ ! -f "$URL_LIST" ]; then
    echo "# Download Targets (1 URL per line)" > "$URL_LIST"
    echo "# Comment out with #" >> "$URL_LIST"
fi

if [ -f "$URL_LIST" ]; then
    # 行ごとに読み込み
    while IFS= read -r url || [ -n "$url" ]; do
        # 空行・コメント行スキップ
        [[ -z "$url" ]] && continue
        [[ "$url" =~ ^#.*$ ]] && continue
        
        # 整形
        url=$(echo "$url" | tr -d '\r' | xargs)
        echo "Processing: $url"
        
        # 実行 (履歴管理あり)
        gallery-dl --cookies "$COOKIE_FILE" \
                   --directory /downloads \
                   --download-archive "$ARCHIVE_FILE" \
                   "$url"
                   
    done < "$URL_LIST"
else
    echo "Error: $URL_LIST not found."
fi

echo "Job finished at $(date)"
echo "----------------------------------------"
