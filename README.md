# X Media Auto-Downloader

指定したX（旧Twitter）アカウントのメディア（画像・動画）を定期的に自動収集するシステムです。
ダウンロードしたメディアはImmich等の外部ビューワーで閲覧することを想定しています。
Coolify (Docker Compose) 上での稼働を想定しています。

## プロジェクト概要

*   **目的**: Xのメディア自動収集と閲覧
*   **プラットフォーム**: Coolify (Docker Compose)
*   **主要コンポーネント**:
    *   `downloader`: Python (gallery-dl, ffmpeg, cron) - バックエンド

## ディレクトリ構成

```text
.
├── docker-compose.yml      # サービス定義
├── Dockerfile              # downloader用ビルド定義
├── crontab                 # 定期実行スケジュール設定
├── entrypoint.sh           # ダウンロード処理実行スクリプト
├── config/                 # 設定ファイルディレクトリ
│   ├── urls.txt            # ダウンロード対象URLリスト
│   └── cookies.txt         # X認証用Cookie (要手動配置)
└── README.md               # 本ドキュメント
```

## サービス詳細

### 1. Downloader (`x_downloader`)

Cronを使用し、毎日定時にスクレイピングを実行するコンテナです。

*   **Base Image**: `python:3.11-slim`
*   **機能**:
    *   `crontab` に基づきスケジュール実行 (デフォルト: 毎日 04:00)
    *   `config/urls.txt` から対象URLを読み込み
    *   `config/cookies.txt` を使用して認証
    *   `gallery-dl` を使用してメディアをダウンロード
    *   ダウンロード履歴を `archive.sqlite3` に保存し、重複ダウンロードを防止

### 2. Viewer (Immich)

本プロジェクトにはビューワーは含まれていません。
ダウンロードしたメディアを閲覧するには、別途 **Immich** をデプロイし、連携することを推奨します。

*   **連携方法**:
    1.  Coolify等で Immich をデプロイします。
    2.  Immich の設定で、本プロジェクトの `x_downloads` ボリュームを **External Library** としてマウントします。
    3.  Immich 上で External Library のスキャンを実行すると、ダウンロードされたメディアが取り込まれます。

## デプロイ・設定手順

### 1. 必須要件
*   Docker および Docker Compose がインストールされていること (または Coolify 環境)

### 2. 初期設定

1.  **リポジトリのクローン**:
    ```bash
    git clone <repository-url>
    cd x_media_downloader
    ```

2.  **Cookieの配置**:
    *   ブラウザ拡張機能などで X (Twitter) の Cookie を `Netscape HTTP Cookie File` 形式でエクスポートします。
    *   `config/cookies.txt` に内容を貼り付けます。
    *   **注意**: `config/cookies.txt` は `.gitignore` に含まれているため、デプロイ環境で直接作成するか、セキュアな方法で配置してください。

3.  **ダウンロード対象の設定**:
    *   `config/urls.txt` にダウンロードしたい X ユーザーやリストの URL を1行ずつ記述します。

### 3. 起動

```bash
docker-compose up -d
```

### 4. ログ確認

```bash
docker-compose logs -f downloader
```

## 開発・運用メモ

*   **ログ**: `downloader` の標準出力は Docker ログにリダイレクトされているため、`docker logs` コマンドや Coolify のログ画面で確認できます。
*   **永続化**: ダウンロードデータは `x_downloads` ボリュームに保存されます。
*   **認証エラー**: ダウンロードが失敗する場合は、Cookie の有効期限切れの可能性があります。`cookies.txt` を更新してください。
