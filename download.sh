#!/bin/bash

# 設定ファイルパス
URL_LIST="/downloads/urls.txt"
COOKIE_FILE="/config/cookies.txt"
ARCHIVE_FILE="/config/archive.sqlite3"

# ログファイル設定
LOG_FILE="/config/download.log"

# ログ出力関数 (stdout とファイルの両方に出力)
log() {
    local msg="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') $msg" | tee -a "$LOG_FILE"
}

log "----------------------------------------"
log "Job started"

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
        log "Processing: $url"
        
        # 実行 (履歴管理あり)
        # gallery-dlの出力もログに記録
        gallery-dl --cookies "$COOKIE_FILE" \
                   --directory /downloads \
                   --download-archive "$ARCHIVE_FILE" \
                   "$url" 2>&1 | tee -a "$LOG_FILE"
                   
    done < "$URL_LIST"
else
    log "Error: $URL_LIST not found."
fi

log "Job finished"
log "----------------------------------------"
