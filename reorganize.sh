#!/bin/bash
# reorganize.sh
# 既存のダウンロード済みファイルをアカウントごとのサブディレクトリに振り分けるスクリプト
#
# 使い方 / Usage:
#   ./reorganize.sh
#
# 説明 / Description:
#   /downloads 直下にある既存ファイルを、urls.txt に記載されたアカウントに対応する
#   サブディレクトリ (/downloads/{account}/) へ移動します。
#   各アカウントに属するファイルの特定には gallery-dl の --simulate モードを使用します。
#   ※ Twitter API へのアクセスが発生するため、アカウントのメディア数に応じて
#     時間がかかる場合があります。
#
#   Moves existing files from the flat /downloads directory into per-account
#   subdirectories (/downloads/{account}/).  It uses gallery-dl's --simulate mode
#   to determine which filenames belong to each account without re-downloading media.
#   Note: this queries the Twitter API and may take time for large accounts.

COOKIE_FILE="/config/cookies.txt"
URL_LIST="/downloads/urls.txt"
DOWNLOADS_DIR="/downloads"
LOG_FILE="/config/download.log"

# ログ出力関数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

# URLからアカウント名を抽出する関数 (x.com / twitter.com に対応)
extract_account() {
    echo "$1" | sed -E 's#https?://(x|twitter)\.com/([^/?]+).*#\2#i'
}

log "----------------------------------------"
log "Reorganization started"

# 前提ファイルの確認
if [ ! -f "$URL_LIST" ]; then
    log "Error: $URL_LIST not found"
    exit 1
fi

if [ ! -f "$COOKIE_FILE" ]; then
    log "Error: $COOKIE_FILE not found"
    exit 1
fi

moved_count=0
error_count=0

while IFS= read -r url || [ -n "$url" ]; do
    # 空行・コメント行スキップ
    [[ -z "$url" ]] && continue
    [[ "$url" =~ ^#.*$ ]] && continue
    url=$(echo "$url" | tr -d '\r' | xargs)

    # URLからアカウント名を抽出
    account=$(extract_account "$url")
    if [ -z "$account" ] || [ "$account" = "$url" ]; then
        log "Warning: Cannot extract account name from: $url"
        ((error_count++))
        continue
    fi

    target_dir="$DOWNLOADS_DIR/$account"
    mkdir -p "$target_dir"
    log "Processing account: $account"

    # 一時アーカイブファイルを使用してダウンロード済み履歴を迂回し、
    # gallery-dl --simulate でダウンロードせずにファイル名一覧を取得する
    temp_archive=$(mktemp --suffix=.sqlite3)

    while IFS= read -r filename; do
        [ -z "$filename" ] && continue
        src="$DOWNLOADS_DIR/$filename"
        dst="$target_dir/$filename"
        if [ -f "$src" ]; then
            if [ ! -f "$dst" ]; then
                mv "$src" "$dst"
                log "Moved: $filename -> $account/"
                ((moved_count++))
            else
                log "Skip (already exists at destination): $account/$filename"
            fi
        fi
    done < <(gallery-dl \
        --cookies "$COOKIE_FILE" \
        --download-archive "$temp_archive" \
        --simulate \
        --print "{filename}.{extension}" \
        "$url" 2>/dev/null)

    rm -f "$temp_archive"

done < "$URL_LIST"

log "Reorganization complete: ${moved_count} file(s) moved, ${error_count} account(s) failed"
log "----------------------------------------"
