from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
import os

app = FastAPI()

# ディレクトリ設定
CONFIG_DIR = "/config"
DOWNLOADS_DIR = "/downloads"
URLS_FILE = os.path.join(DOWNLOADS_DIR, "urls.txt")
LOG_FILE = os.path.join(CONFIG_DIR, "download.log")

# テンプレートと静的ファイルの設定
app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")

class UrlsUpdate(BaseModel):
    content: str

@app.get("/", response_class=HTMLResponse)
async def read_root(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})

@app.get("/api/urls")
async def get_urls():
    if not os.path.exists(URLS_FILE):
        return JSONResponse(content={"content": ""})
    try:
        with open(URLS_FILE, "r") as f:
            content = f.read()
        return JSONResponse(content={"content": content})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/urls")
async def update_urls(update: UrlsUpdate):
    try:
        with open(URLS_FILE, "w") as f:
            f.write(update.content)
        return JSONResponse(content={"status": "success"})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/logs")
async def get_logs():
    if not os.path.exists(LOG_FILE):
        return JSONResponse(content={"logs": "Log file not found."})
    try:
        # 最後の1000行を取得（簡易実装）
        with open(LOG_FILE, "r") as f:
            lines = f.readlines()
            # 最新のログが下に来るようにそのまま返す
            content = "".join(lines[-1000:])
        return JSONResponse(content={"logs": content})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
