# Kharcha API contract

Base URL: `PUBLIC_BASE_URL` (default `http://localhost:4000`). Everything is JSON except the photo upload.

## Rules every endpoint follows
- **Auth:** every `/api/*` call except `/api/health` needs `Authorization: Bearer <token>`.
  `AUTH_MODE=firebase`: a Firebase ID token. `AUTH_MODE=dev`: `dev:<anything>` (for example `dev:demo`).
  A user only ever sees their own data. `401` means sign the user out.
- **Errors:** `{ "error": { "code": "NOT_FOUND", "message": "Receipt not found", "details"?: {...} } }`.
  Codes: `BAD_REQUEST` 400, `VALIDATION_ERROR` 400 (`details` = field errors), `UNAUTHORIZED` 401, `FORBIDDEN` 403,
  `NOT_FOUND` 404, `CONFLICT` 409, `FILE_TOO_LARGE` 413, `INVALID_IMAGE` 422, `INTERNAL_ERROR` 500.
  `message` is safe to show to a user.
- **Dates** are `YYYY-MM-DD`, **months** `YYYY-MM`, both in the user's time zone (`APP_TZ`, Asia/Kathmandu).
- **Money** is a number in the receipt's currency (default NPR). Item `price` is the price of ONE unit; the line cost is `price * quantity`.
- **Only `confirmed` receipts count** in any total, budget or chart.
- `imageUrl` is a complete, time-limited link that opens with no headers. Cache by receipt `id`, not by URL.

## Health
`GET /api/health` (public) -> `{ "status": "ok", "env": "development" }`

## Users (already built)
| Call | Body / notes | Returns |
|---|---|---|
| `GET /api/users/me` | creates the user and their default categories on the first call | `{ user }` |
| `PATCH /api/users/me` | any of `name`, `photoUrl`, `currency` (NPR/USD/INR/EUR), `aiEnabled`, `onboardingCompleted`, `alertPercent` (50-100, default 80), `notificationsEnabled`, `monthlyIncome`, `totalBudget` (null allowed) | `{ user }` |
| `DELETE /api/users/me` | soft delete | 204 |

`user`: `{ id, uid, email, name, photoUrl, currency, aiEnabled, onboardingCompleted, alertPercent, notificationsEnabled, monthlyIncome, totalBudget, lastLoginAt, createdAt, updatedAt }`

## Categories (already built)
Every user starts with 12 defaults plus a fallback "Uncategorized". Items and budgets refer to categories by `id`.
| Call | Body | Returns |
|---|---|---|
| `GET /api/categories` | | `{ categories: [{ id, name, essential, icon, color, isFallback }] }` |
| `POST /api/categories` | `{ name, essential?, icon?, color? "#RRGGBB" }` (returns the existing one if the name exists) | 201 `{ category }` |
| `PATCH /api/categories/:id` | same fields, all optional; the fallback cannot be renamed | `{ category }` |
| `DELETE /api/categories/:id` | soft delete; the fallback cannot be deleted | 204 |

## Receipts
`receipt`:
```json
{
  "id": "…", "status": "processing | needs_review | confirmed | failed",
  "merchant": "Bhat-Bhateni" , "total": 1130.0, "currency": "NPR", "date": "2026-10-03",
  "imageUrl": "http://…/files/ab12.jpg?exp=…&sig=…",
  "confidence": 0.82, "reviewReasons": ["total_mismatch"], "createdAt": "…",
  "items": [{ "name": "Rice 5kg", "price": 850, "quantity": 1, "categoryId": "…", "category": "Groceries" }]
}
```
`reviewReasons` explains why a receipt is `needs_review`: `unreadable`, `low_confidence`, `reader_flagged`, `no_merchant`,
`no_total`, `no_items`, `total_mismatch`, `bad_date`, `possible_duplicate`.

| Call | Notes | Returns |
|---|---|---|
| `POST /api/receipts` | `multipart/form-data`, one JPEG in field `image`. Optional header `Idempotency-Key` (1-64 of `A-Za-z0-9_.:-`): the same key from the same user returns the first receipt again. Answers at once; the photo is read in the background. | `202 { receipt }` (`status: "processing"`), or `200 { receipt }` for a repeated key |
| `GET /api/receipts?status=&month=&limit=` | newest first; `limit` 1-200 (default 100) | `{ receipts: [receipt] }` |
| `GET /api/receipts/:id` | poll this while `status` is `processing` (every 2 s is fine) | `{ receipt }` |
| `PATCH /api/receipts/:id` | the user's corrections. Body `{ status: "confirmed", merchant?, total?, currency?, date?, items: [{ name, price, quantity?, categoryId? }] }`. Saving confirms it and the server remembers every category the user changed. `409` while still `processing`. | `{ receipt }` |
| `DELETE /api/receipts/:id` | soft delete | 204 |

Life of a receipt: `processing` -> `confirmed` (nothing to doubt) or `needs_review` (user fixes it with PATCH) or `failed` (the photo could not be read: the user types it in with PATCH).

## Budgets
A budget is a history, so changing a limit never rewrites old months: for month M the limit in force is the entry with the latest `effectiveFrom <= M`.
| Call | Notes | Returns |
|---|---|---|
| `GET /api/budgets?month=` | budgets in force in that month (default this month) with `spent` for that month | `{ budgets: [{ categoryId, category, limit, spent, currency }] }` |
| `PUT /api/budgets/:categoryId` | `{ limit > 0, effectiveFrom? "YYYY-MM" (default this month) }`. Earlier months keep their old limit. May raise an alert. | `{ budget }` |
| `DELETE /api/budgets/:categoryId?effectiveFrom=` | no budget from that month on; earlier months untouched | 204 |

## Alerts (in-app notifications)
Raised once each, while the month is still running: when a category reaches the user's `alertPercent` of its limit (`budget_warning`), when it passes 100% (`budget_exceeded`), and for receipts the AI is unsure about (`needs_review`, `possible_duplicate`; only when the AI reader is on).
| Call | Returns |
|---|---|
| `GET /api/alerts?unread=true` | `{ alerts: [{ id, type, categoryId, receiptId, month, percent, message, readAt, createdAt }], unreadCount }` |
| `POST /api/alerts/:id/read` | `{ alert }` |
| `POST /api/alerts/read-all` | 204 |

## Dashboard
| Call | Returns |
|---|---|
| `GET /api/dashboard/summary?month=` | `{ summary: { month, currency, total, previousTotal, receiptCount, byCategory: [{categoryId, category, amount}], previousByCategory: [...], daily: [{day, amount}] (every day of the month) } }` |
| `GET /api/dashboard/trend?months=6&month=` | `{ trend: { currency, months: [{ month, total }] } }` oldest first, zeros included, `months` 2-24 |

## Photo links
`GET /files/:name?exp=&sig=` serves a photo to anyone with a valid unexpired signed link (STORAGE_MODE=local). With `STORAGE_MODE=supabase` the link is a Supabase signed URL.
