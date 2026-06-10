CREATE TABLE users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE venues (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  sport TEXT NOT NULL CHECK (sport IN ('badminton', 'turf')),
  location TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE slots (
  id SERIAL PRIMARY KEY,
  venue_id INTEGER NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'booked')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (venue_id, date, start_time)
);

CREATE TABLE bookings (
  id SERIAL PRIMARY KEY,
  slot_id INTEGER NOT NULL REFERENCES slots(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id),
  booked_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (slot_id)
);

CREATE INDEX idx_slots_venue_date ON slots(venue_id, date);
CREATE INDEX idx_bookings_user ON bookings(user_id);

-- Seed users
INSERT INTO users (id, name, email) VALUES
  ('user_001', 'Akriti', 'akriti@quickslot.com'),
  ('user_002', 'Utsav', 'utsav@quickslot.com'),
  ('user_003', 'Rahul', 'rahul@quickslot.com');

-- Seed venues
INSERT INTO venues (name, sport, location, description) VALUES
  ('Smash Arena', 'badminton', 'Koramangala, Bengaluru', '4 professional courts with wooden flooring'),
  ('Court Kings', 'badminton', 'Indiranagar, Bengaluru', '3 courts, AC, open till 11 PM'),
  ('Green Turf FC', 'turf', 'HSR Layout, Bengaluru', 'Full-size synthetic turf with floodlights'),
  ('Goal Zone', 'turf', 'Whitefield, Bengaluru', '7-a-side turf, parking available'),
  ('Rally Point', 'badminton', 'Jayanagar, Bengaluru', '2 courts, budget-friendly');
