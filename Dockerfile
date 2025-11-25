FROM python:3.11-slim

# 必須パッケージ (ffmpeg, cron)
RUN apt-get update && \
    apt-get install -y ffmpeg cron && \
    rm -rf /var/lib/apt/lists/*

# gallery-dl
RUN pip install --no-cache-dir gallery-dl

# スクリプト配置
# スクリプト配置
COPY download.sh /download.sh
COPY entrypoint.sh /entrypoint.sh
COPY crontab /etc/cron.d/downloader-cron

# 権限設定 & Crontab登録
RUN chmod +x /download.sh && \
    chmod +x /entrypoint.sh && \
    chmod 0644 /etc/cron.d/downloader-cron && \
    crontab /etc/cron.d/downloader-cron

WORKDIR /downloads

# エントリーポイント実行
CMD ["/entrypoint.sh"]
