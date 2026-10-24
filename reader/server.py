"""
Kharcha reader service: turns a receipt photo into structured data.

    POST /read        body = JPEG bytes (Content-Type: image/jpeg)   -> reading JSON   (what the backend calls)
    POST /read-file   multipart form, field "file"                   -> reading JSON   (for testing from /docs)
    GET  /health      -> { ok, ocr, models }

Auth: when READER_TOKEN is set, /read and /read-file need  Authorization: Bearer <READER_TOKEN>.
Run:  uvicorn server:app --host 0.0.0.0 --port 8000
"""
import hmac
import io
import os
import threading

from fastapi import FastAPI, File, HTTPException, Request, UploadFile
from fastapi.responses import JSONResponse
from PIL import Image, UnidentifiedImageError

import kharcha_reader as kr

MODEL_DIR = os.environ.get("KHARCHA_MODEL_DIR", os.path.dirname(os.path.abspath(__file__)))
TOKEN = os.environ.get("READER_TOKEN", "")
MAX_BYTES = int(float(os.environ.get("READER_MAX_MB", "15")) * 1024 * 1024)
DEBUG_TRACE = os.environ.get("READER_DEBUG_TRACE", "").lower() in {"1", "true", "yes", "on"}

app = FastAPI(title="Kharcha reader", version="1.0")

_reader = None
_load_lock = threading.Lock()   # guards loading the models once
_read_lock = threading.Lock()   # one photo at a time


def get_reader():
    """Loads the trained models on first use. A missing or incompatible model is a 503, never a silent guess."""
    global _reader
    if _reader is None:
        with _load_lock:
            if _reader is None:
                try:
                    _reader = kr.KharchaReader(MODEL_DIR)
                except kr.ModelsMissing as e:
                    raise HTTPException(503, f"{e} Retrain in notebooks/Kharcha_Model_Lab.ipynb and export again "
                                             f"(scikit-learn must match requirements.txt).")
    return _reader


def check_auth(request: Request):
    if not TOKEN:
        return
    given = request.headers.get("authorization", "")
    if not hmac.compare_digest(given, f"Bearer {TOKEN}"):
        raise HTTPException(401, "Missing or wrong reader token.")


def read_image(data: bytes):
    if not data:
        raise HTTPException(400, "Send the photo as the request body.")
    if len(data) > MAX_BYTES:
        raise HTTPException(413, "That photo is too large.")
    try:
        image = Image.open(io.BytesIO(data))
        image.load()
    except (UnidentifiedImageError, OSError):
        raise HTTPException(422, "That file is not an image.")
    # The reader is CPU/GPU heavy and not thread-safe in every OCR engine: one photo at a time.
    reader = get_reader()
    with _read_lock:
        trace = {} if DEBUG_TRACE else None
        result = reader.read(image, trace=trace)
        if trace is not None:
            kr.show(result, trace, name="HTTP upload", full_json=False)
        return JSONResponse(result)


@app.get("/health")
def health():
    try:
        get_reader()
        models = "ok"
    except HTTPException as e:
        models = str(e.detail)
    return {"ok": models == "ok", "models": models, "ocr": kr.ENGINE, "tesseract_langs": _langs()}


def _langs():
    try:
        return kr.available_langs()
    except Exception as e:  # Tesseract missing
        return f"unavailable: {e}"


@app.post("/read")
async def read(request: Request):
    check_auth(request)
    return read_image(await request.body())


@app.post("/read-file")
async def read_file(request: Request, file: UploadFile = File(...)):
    check_auth(request)
    return read_image(await file.read())
