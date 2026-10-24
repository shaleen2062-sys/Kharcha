# Kharcha reader (the AI)

Photo of a receipt in, structured JSON out: merchant, date, total, line items, a category per item, and a confidence.
Everything is open and self-hosted (docTR + Tesseract OCR, two small scikit-learn models trained in `../notebooks/Kharcha_Model_Lab.ipynb`).

## Run it
```bash
# system: Tesseract with English and Nepali   (Ubuntu: apt install tesseract-ocr tesseract-ocr-eng tesseract-ocr-nep)
#                                              (Windows: install Tesseract, then set TESSERACT_CMD="C:\Program Files\Tesseract-OCR\tesseract.exe")
python -m venv .venv && source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt                          # or requirements-lite.txt (Tesseract only, no PyTorch)
uvicorn server:app --host 0.0.0.0 --port 8000
```
Open <http://localhost:8000/docs>, use **POST /read-file**, choose a bill photo: you get the JSON.
Or: `curl -X POST --data-binary @bill.jpg -H "Content-Type: image/jpeg" http://localhost:8000/read`

Then in `backend/.env`: `READER=http` and `READER_URL=http://localhost:8000`.

To inspect the OCR and model decisions in Python or a notebook:
```python
from kharcha_reader import KharchaReader, show

reader = KharchaReader(".")
debug_dict = {}
result = reader.read("bill.jpg", trace=debug_dict)
show(result, debug_dict)
```

## Settings (environment variables)
| Variable | Default | Meaning |
|---|---|---|
| `READER_TOKEN` | empty | if set, callers must send `Authorization: Bearer <token>` (use the same value as the backend's `READER_TOKEN`) |
| `OCR_ENGINE` | `auto` | `auto` = docTR with Tesseract as the rescue, `doctr`, or `tesseract` |
| `OCR_LANGS` | `eng+nep` | Tesseract languages (use `eng` if the Nepali pack is not installed) |
| `KHARCHA_DATE_ORDER` | `mdy` | how an ambiguous 05/10/2026 is read (`mdy` for Nepali POS printers, or `dmy`) |
| `KHARCHA_MODEL_DIR` | this folder | where `line_model.joblib` and `category_model.joblib` are |
| `TESSERACT_CMD` | | path to tesseract.exe on Windows |
| `READER_DEBUG_TRACE` | empty | set to `1` to print OCR/model reasoning in the server terminal |

## Output
```json
{ "merchant": "BHAT BHATENI SUPERMARKET", "date": "2026-10-03", "total": 1870.0,
  "tax": 120.0, "discount": 0.0, "cash_paid": 2000.0, "change": 130.0,
  "items": [{ "name": "Rice 5kg", "qty": 1, "price": 850.0, "category": "Groceries" }],
  "confidence": 0.91, "confidence_reason": "items add up to the total: confidence raised to at least 0.75",
  "needs_review": false, "reconciliation": "Items add up to the total (VAT and discount included)" }
```
`price` is the printed line amount and `qty` is the detected quantity. The reader also returns tax/VAT, discount, cash paid, and change when they are visible. `category` is one of Groceries, Dining, Transport, Shopping, Health, Bills, Entertainment, Other (the backend maps them to the user's categories).
`readable: false` appears only when the photo is noise (handwriting, unsupported script). `needs_review` is the reader's own verdict.

## Models and versions
`line_model.joblib` and `category_model.joblib` were saved with **scikit-learn 1.6.1**: keep that version, or retrain in the notebook and re-export
(Colab: run all cells, the last cell downloads `kharcha_export.zip`; copy its two `.joblib` files and `kharcha_reader.py` here).
If the models cannot be loaded the server answers 503 with an explanation instead of guessing.

## Tests
```bash
pip install -r requirements-lite.txt httpx
OCR_ENGINE=tesseract OCR_LANGS=eng python -m unittest discover tests -v
```
