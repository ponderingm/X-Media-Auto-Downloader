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

# URLからアカウント名を抽出する関数 (x.com / twitter.com に対応)
extract_account() {
    echo "$1" | sed -E 's#^https?://(www\.|mobile\.)?(x|twitter)\.com/@?([^/?#]+).*$#\3#'
}

if command -v gallery-dl >/dev/null 2>&1; then
    GALLERY_DL_CMD=(gallery-dl)
elif python3 -m gallery_dl --version >/dev/null 2>&1; then
    GALLERY_DL_CMD=(python3 -m gallery_dl)
else
    log "Error: gallery-dl is not available (checked: 'gallery-dl' and 'python3 -m gallery_dl'). Verify installation in the container, then rebuild/restart the container if needed."
    exit 1
fi

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

        # URLからアカウント名を抽出してアカウント別ディレクトリを決定
        account=$(extract_account "$url")
        if [ -n "$account" ] && [ "$account" != "$url" ]; then
            DOWNLOAD_DIR="/downloads/$account"
            mkdir -p "$DOWNLOAD_DIR"
        else
            log "Warning: Could not extract account name from URL, using /downloads/_unknown"
            DOWNLOAD_DIR="/downloads/_unknown"
            mkdir -p "$DOWNLOAD_DIR"
        fi
        
        # 実行 (履歴管理あり)
        # gallery-dlの出力もログに記録
        "${GALLERY_DL_CMD[@]}" --cookies "$COOKIE_FILE" \
                               --directory "$DOWNLOAD_DIR" \
                               --download-archive "$ARCHIVE_FILE" \
                               "$url" 2>&1 | tee -a "$LOG_FILE"
                   
    done < "$URL_LIST"
else
    log "Error: $URL_LIST not found."
fi

log "Job finished"
log "----------------------------------------"
