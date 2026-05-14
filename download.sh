#!/bin/bash

set -o pipefail

# 設定ファイルパス
DOWNLOAD_ROOT="${DOWNLOAD_ROOT:-/downloads}"
CONFIG_ROOT="${CONFIG_ROOT:-/config}"
URL_LIST="${URL_LIST:-$DOWNLOAD_ROOT/urls.txt}"
COOKIE_FILE="${COOKIE_FILE:-$CONFIG_ROOT/cookies.txt}"
ARCHIVE_FILE="${ARCHIVE_FILE:-$CONFIG_ROOT/archive.sqlite3}"

# ログファイル設定
LOG_FILE="${LOG_FILE:-$CONFIG_ROOT/download.log}"
RATE_LIMIT_WAIT_SECONDS="${RATE_LIMIT_WAIT_SECONDS:-900}"
RATE_LIMIT_MAX_RETRIES="${RATE_LIMIT_MAX_RETRIES:-1}"
# rate limit系の代表的なメッセージ/HTTP 429 を検知
RATE_LIMIT_PATTERN="rate[ -]?limit|rate-limited|too many requests|http error 429|(^|[^0-9])429([^0-9]|$)"
# trapで後始末するためにグローバルで保持
attempt_log=""

cleanup_attempt_log() {
    [ -n "$attempt_log" ] && rm -f "$attempt_log"
    attempt_log=""
}
trap cleanup_attempt_log EXIT INT TERM

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
            DOWNLOAD_DIR="$DOWNLOAD_ROOT/$account"
            mkdir -p "$DOWNLOAD_DIR"
        else
            log "Warning: Could not extract account name from URL, using $DOWNLOAD_ROOT/_unknown"
            DOWNLOAD_DIR="$DOWNLOAD_ROOT/_unknown"
            mkdir -p "$DOWNLOAD_DIR"
        fi
        
        # 実行 (履歴管理あり)
        # gallery-dlの出力もログに記録
        attempt=0
        attempt_log=$(mktemp)
        while [ "$attempt" -le "$RATE_LIMIT_MAX_RETRIES" ]; do
            > "$attempt_log"

            "${GALLERY_DL_CMD[@]}" --cookies "$COOKIE_FILE" \
                                   --directory "$DOWNLOAD_DIR" \
                                   --download-archive "$ARCHIVE_FILE" \
                                   "$url" 2>&1 | tee -a "$LOG_FILE" "$attempt_log"
            gallery_dl_status=${PIPESTATUS[0]}

            if [ "$gallery_dl_status" -eq 0 ]; then
                cleanup_attempt_log
                break
            fi

            if grep -Eqi "$RATE_LIMIT_PATTERN" "$attempt_log"; then
                if [ "$attempt" -lt "$RATE_LIMIT_MAX_RETRIES" ]; then
                    log "Rate limit detected. Waiting $RATE_LIMIT_WAIT_SECONDS seconds before retrying: $url"
                    sleep "$RATE_LIMIT_WAIT_SECONDS"
                    attempt=$((attempt + 1))
                    continue
                fi
                log "Rate limit detected again after retry. Skipping for now: $url"
            else
                log "Download failed (exit code: $gallery_dl_status): $url"
            fi

            cleanup_attempt_log
            break
        done
        cleanup_attempt_log
                    
    done < "$URL_LIST"
else
    log "Error: $URL_LIST not found."
fi

log "Job finished"
log "----------------------------------------"
