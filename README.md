# QuickSlot

Mini sports slot booking app — badminton courts & turf grounds.

## Setup

### Backend
```bash
cd server && cp .env.example .env
# Set DATABASE_URL to your Neon.tech Postgres connection string
npm install && node index.js
```

### Flutter
```bash
cd app && fvm flutter pub get && fvm flutter run
```

## Architecture

Backend: Node.js + Express REST API with Neon.tech (Postgres) via the `pg` library. Deployed on Render.
Flutter frontend uses Riverpod for state management — FutureProviders for async data,
NotifierProviders for actions (booking, cancel), StateProvider.family for per-venue date selection.

**Concurrency approach:** `POST /bookings` opens a Postgres transaction, locks the slot row
with `SELECT ... FOR UPDATE`, checks status, updates it, and inserts the booking — all before
COMMIT. A second concurrent request blocks at the lock, then sees `status='booked'` and returns
409. The DB also has a UNIQUE constraint on `bookings.slot_id` as a second safety net.

## What I cut
- Full JWT auth (replaced with X-User-Id header as permitted)
- Unit tests (ran out of time; booking logic is the obvious test target)

## What I'd add with one more day
- Offline cache for My Bookings using SharedPreferences
- Unit test for the booking concurrency path
- Push notifications on slot cancellation

## AI usage
Used Claude/Cursor to scaffold boilerplate files, generate model fromJson methods,
and suggest the SELECT FOR UPDATE pattern for concurrency.
One thing it got wrong: the initial slot generator used a parameterized query that
broke when building the VALUES list dynamically — fixed by switching to string interpolation
inside the loop (safe here since venueId/date come from validated server-side params, not user input).
