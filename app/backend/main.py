from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
import os

app = FastAPI(title="Server App Starter")

@app.get("/health")
def health_check():
    return {"status": "ok"}

static_dir = os.path.join(os.path.dirname(__file__), "static")
if os.path.exists(static_dir):
    app.mount("/", StaticFiles(directory=static_dir, html=True), name="static")
else:
    @app.get("/")
    def root():
        return {"message": "Backend running, awaiting Flutter web build."}