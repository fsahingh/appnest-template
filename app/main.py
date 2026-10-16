import os
import sqlite3
from contextlib import asynccontextmanager, contextmanager
from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

BASE_DIR = Path(__file__).parent
DB_PATH = Path(os.getenv("DB_PATH", BASE_DIR.parent / "data" / "app.db"))
APP_NAME = os.getenv("APP_NAME", "appnest app")

templates = Jinja2Templates(directory=BASE_DIR / "templates")


@contextmanager
def db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    try:
        with conn:  # commits on success, rolls back on error
            yield conn
    finally:
        conn.close()


@asynccontextmanager
async def lifespan(app: FastAPI):
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    with db() as conn:
        conn.execute("CREATE TABLE IF NOT EXISTS counter (id INTEGER PRIMARY KEY, value INTEGER NOT NULL)")
        conn.execute("INSERT OR IGNORE INTO counter (id, value) VALUES (1, 0)")
    yield


app = FastAPI(lifespan=lifespan)


def read_count(conn) -> int:
    return conn.execute("SELECT value FROM counter WHERE id = 1").fetchone()["value"]


@app.get("/", response_class=HTMLResponse)
def index(request: Request):
    with db() as conn:
        count = read_count(conn)
    return templates.TemplateResponse(request, "index.html", {"app_name": APP_NAME, "count": count})


@app.post("/click", response_class=HTMLResponse)
def click(request: Request):
    with db() as conn:
        conn.execute("UPDATE counter SET value = value + 1 WHERE id = 1")
        count = read_count(conn)
    return templates.TemplateResponse(request, "_counter.html", {"count": count})


@app.get("/health")
def health():
    return {"status": "ok"}
