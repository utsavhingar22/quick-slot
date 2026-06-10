# QuickSlot — Hackathon Day Cheat Sheet

## ⚡ HOUR-BY-HOUR PLAN (3 hours)

| Time | Task | Done? |
|------|------|-------|
| 0:00–0:10 | Open quick-slot in Cursor, paste .cursorrules, paste MASTER PROMPT in Agent Mode | |
| 0:10–0:30 | Let agent scaffold all files. Review diffs. Accept. | |
| 0:30–0:40 | Supabase: create project → SQL Editor → paste schema.sql → run | |
| 0:40–0:50 | Copy DB URL to server/.env. `npm install`. `node index.js`. Test /health | |
| 0:50–1:10 | `flutter pub get`. Fix any dependency errors. `flutter run` on emulator | |
| 1:10–1:30 | Smoke test full flow: login → venue → pick date → book a slot | |
| 1:30–1:40 | Test double-booking with 2 curl commands simultaneously | |
| 1:40–1:55 | Fix any bugs. Use FOLLOWUP_PROMPTS if stuck | |
| 1:55–2:10 | Git commits (follow the commit plan) | |
| 2:10–2:30 | Deploy to Render (optional). Write README | |
| 2:30–2:45 | Run flutter analyze. Final UI polish | |
| 2:45–3:00 | Practice your demo flow + defense answers | |

---

## 🧪 TEST COMMANDS

```bash
# Health check
curl http://localhost:3000/health

# List venues
curl http://localhost:3000/venues

# Get slots for venue 1, today
curl -H "X-User-Id: user_001" \
  "http://localhost:3000/venues/1/slots?date=$(date +%Y-%m-%d)"

# Book slot 1
curl -X POST http://localhost:3000/bookings \
  -H "Content-Type: application/json" \
  -H "X-User-Id: user_001" \
  -d '{"slot_id": 1}'

# Book same slot (should get 409)
curl -X POST http://localhost:3000/bookings \
  -H "Content-Type: application/json" \
  -H "X-User-Id: user_002" \
  -d '{"slot_id": 1}'

# My bookings
curl -H "X-User-Id: user_001" http://localhost:3000/users/user_001/bookings

# Cancel booking 1
curl -X DELETE -H "X-User-Id: user_001" http://localhost:3000/bookings/1
```

---

## 🎤 DEFENSE ROUND ANSWERS

**Q: Why Riverpod over Bloc/Provider?**
> Riverpod is compile-time safe — typos in provider names are caught at build time, not runtime. It doesn't need a BuildContext to read providers, so business logic can live in plain Dart classes. FutureProvider.family auto-caches based on the key and invalidates cleanly. Compared to Bloc, there's far less boilerplate for this app's scale.

**Q: Explain the concurrency approach.**
> In `POST /bookings` I open a Postgres transaction, then run `SELECT ... FOR UPDATE` on the slot row. This acquires a row-level lock. If two requests hit the same slot simultaneously, one grabs the lock first; the second blocks until the first commits. After commit, the second transaction sees `status='booked'` and returns 409. There's also a UNIQUE constraint on `bookings.slot_id` as a second safety net — even if the application logic somehow fails, the DB will reject the duplicate insert.

**Q: What would you do differently with more time?**
> Slot polling every 8–10 seconds on the venue detail screen so the grid auto-updates without refresh. Offline read cache for My Bookings using SharedPreferences. Unit tests for the booking transaction logic — that's the highest-value test target. And I'd add a proper date-based slot auto-generation at midnight (cron job) instead of lazy generation per request.

**Q: Why FutureProvider.family for slots?**
> Each (venueId, date) pair needs its own cache entry. When the user changes the date, the key changes and Riverpod fetches fresh data automatically. No manual invalidation needed on date change — the new key is a cache miss by definition.

**Q: Why not use an ORM like Prisma?**
> For a hackathon, raw `pg` is faster to reason about and debug. The critical query — `SELECT FOR UPDATE` inside a transaction — is much easier to understand and explain as plain SQL than through an ORM abstraction. Judges can read the SQL and understand the lock immediately.

---

## 🚨 COMMON ERRORS AND FIXES

| Error | Fix |
|-------|-----|
| `flutter: Connection refused` | Check emulator uses 10.0.2.2:3000, not localhost |
| `pg: SSL connection required` | Add `ssl: { rejectUnauthorized: false }` in pool.js for prod |
| `flutter analyze: Record type error` | Ensure Dart SDK >=3.0.0 in pubspec.yaml |
| `23505 unique constraint` on booking | Expected — it's the DB-level safety net (return 409) |
| Slots not showing after date change | DateFormat must produce 'yyyy-MM-dd' exactly |
| `shimmer: type error` | Run `flutter pub get` again |

---

## 📱 DEPLOY CHECKLIST (Render)

1. Push code to GitHub
2. render.com → New Web Service → connect repo → set root to `server/`
3. Build: `npm install` | Start: `npm start`
4. Environment: add `DATABASE_URL` from Supabase, `NODE_ENV=production`
5. After deploy, copy Render URL
6. In Flutter: change `defaultValue` in `AppConfig.baseUrl` to Render URL
7. `flutter run` — verify it hits the deployed backend
