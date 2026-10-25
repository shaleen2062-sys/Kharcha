# Kharcha backend

Node 22 + Express + TypeScript + MongoDB (Mongoose). Auth with Firebase (or a dev token). Photos in a local folder or a private Supabase bucket. The AI reader is a separate Python service in `../reader`.


## Run it
```bash
cp .env.example .env        # AUTH_MODE=dev needs no Firebase; MongoDB must be running (MONGODB_URI)
npm install
npm run dev                 # http://localhost:4000/api/health
npm run seed                # optional demo data for user "demo"  (Authorization: Bearer dev:demo)
npm test                    # unit tests + end-to-end tests (the latter download an in-memory MongoDB once)
npm run typecheck
```
Try it: `curl -H "Authorization: Bearer dev:demo" http://localhost:4000/api/categories`

Phone or emulator: set `PUBLIC_BASE_URL` to an address the phone can reach (`http://10.0.2.2:4000` for the Android emulator, `http://<your-pc-ip>:4000` for a real phone). Photo links are built from it.

## The AI reader
`READER=manual` (default): no AI, the user types receipts in. `READER=http` + `READER_URL=http://localhost:8000`: photos are sent to `../reader`. See `../reader/README.md` and [the root AI usage disclosure](../AI_USAGE.md).

## Layout
```
src/
  config/        env (zod), db, firebase, supabase
  middleware/    auth, validate, upload (multer), errors
  users/ categories/            auth + per-user categories (AI-supported defaults + fallback)
  receipts/      model, routes, service, reader.client (manual | http), schemas
  agents/        processReceipt (pipeline), validation.agent (decides confirm vs review), agentRun (audit log)
  corrections/   remembers the categories a user changed
  budgets/       budget history (effectiveFrom), service, routes
  alerts/        in-app alerts (80% / 100% of a budget, needs review, duplicates)
  dashboard/     summary + trend (pure maths in stats.ts)
  storage/       local | supabase | memory + signed links
  jobs/queue.ts  in-process background queue (swap for BullMQ + Redis for production)
docs/api-contract.md            every endpoint, request and response
```
