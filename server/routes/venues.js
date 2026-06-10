const express = require('express');
const router = express.Router();
const pool = require('../db/pool');
const { ensureSlotsExist } = require('../db/slotGenerator');
const { requireAuth } = require('../middleware/auth');

// GET /venues
router.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM venues ORDER BY id');
    res.json({ venues: result.rows });
  } catch (err) {
    console.error('GET /venues error:', err.message);
    res.status(500).json({ error: 'Internal server error', detail: err.message });
  }
});

// GET /venues/:id/slots?date=YYYY-MM-DD
router.get('/:id/slots', requireAuth, async (req, res) => {
  const { id } = req.params;
  const { date } = req.query;

  if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    return res.status(400).json({ error: 'date query param required: YYYY-MM-DD' });
  }

  const client = await pool.connect();
  try {
    const venueCheck = await client.query('SELECT id FROM venues WHERE id = $1', [id]);
    if (!venueCheck.rows.length) return res.status(404).json({ error: 'Venue not found' });

    await ensureSlotsExist(client, id, date);

    const result = await client.query(`
      SELECT s.id, s.venue_id, s.date, s.start_time, s.end_time, s.status,
             b.user_id AS booked_by, b.id AS booking_id
      FROM slots s
      LEFT JOIN bookings b ON b.slot_id = s.id
      WHERE s.venue_id = $1 AND s.date = $2
      ORDER BY s.start_time
    `, [id, date]);

    res.json({ venue_id: parseInt(id), date, slots: result.rows });
  } finally {
    client.release();
  }
});

module.exports = router;
