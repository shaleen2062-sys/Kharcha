# AI usage disclosure

All AI here is **open and self-hosted**: no proprietary API is called anywhere. Models and OCR run on our own machine.

## What the AI does
A photo of a receipt goes in; clean, categorised line items come out. Nobody types the receipt in.

| Step | AI component | Where (file / function) |
|---|---|---|
| Read the text on the photo | docTR OCR (open source, PyTorch), Tesseract (English + Nepali) as the fallback | `reader/kharcha_reader.py` `ocr_lines()` |
| Decide which line is the store name, an item, the total | **our trained model** (scikit-learn, trained in `notebooks/Kharcha_Model_Lab.ipynb`) | `reader/kharcha_reader.py` `LineModel`, used by `parse_receipt()` |
| Put every item in a category | **our trained model** (TF-IDF + logistic regression) | `reader/kharcha_reader.py` `CategoryModel`, used by `read_lines()` |
| One call for all of the above | | `reader/kharcha_reader.py` `read_photo()` / `KharchaReader.read()`, exposed as `POST /read` by `reader/server.py` |

## Where the AI output is consumed by code (not just shown)
1. **`backend/src/receipts/reader.client.ts` `normalizeReading()`** parses the reader's JSON into typed data.
2. **`backend/src/agents/processReceipt.ts` `processReceipt()`** takes that data and
   - maps each AI category to the user's own categories (`backend/src/categories/readerCategories.ts` `categoryNameFor()`),
   - lets the user's earlier corrections override the AI (`backend/src/corrections/corrections.service.ts`),
   - writes merchant, total, date and items into the database.
3. **`backend/src/agents/validation.agent.ts` `validateReading()`** uses the AI's **confidence** and its own arithmetic check to **route** the receipt: auto-confirm, or send to the review screen with reasons. Different AI output means different system behaviour.
4. Confirmed receipts feed budgets, alerts and the dashboard (`backend/src/budgets`, `backend/src/alerts`, `backend/src/dashboard`).
5. Every AI step is logged in the `AgentRun` collection (`backend/src/agents/agentRun.model.ts`).

## Delete-the-AI test
Set `READER=manual` in `backend/.env`. The server still runs, but every receipt arrives empty and flagged `needs_review`, and the user must type every merchant, amount and category by hand. The product's core promise (photograph a receipt, get line items) is gone. That is the AI doing real work.

## Limits
Trained on a small set of Nepali and English bills; handwriting and very blurry photos are sent to review rather than guessed. See `reader/README.md`.
