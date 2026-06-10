const express = require('express');
const router = express.Router();
const pool = require('../db/pool');
const { requireAuth, USERS } = require('../middleware/auth');

router.get('/', (req, res) => res.json({ users: Object.values(USERS) }));

router.get('/:id/bookings', requireAuth, async (req, res) => {
  if (req.params.id !== req.user.id) {
    return res.status(403).json({ error: 'You can only view your own bookings' });
  }
  try {
    const result = await pool.query(`
      SELECT b.id AS booking_id, b.booked_at, b.user_id,
             s.id AS slot_id, s.date, s.start_time, s.end_time, s.status,
             v.id AS venue_id, v.name AS venue_name, v.sport, v.location
      FROM bookings b
      JOIN slots s ON s.id = b.slot_id
      JOIN venues v ON v.id = s.venue_id
      WHERE b.user_id = $1
      ORDER BY s.date, s.start_time
    `, [req.params.id]);
    res.json({ user_id: req.params.id, bookings: result.rows });
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
