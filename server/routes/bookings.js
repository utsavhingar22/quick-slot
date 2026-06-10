const express = require('express');
const router = express.Router();
const pool = require('../db/pool');
const { requireAuth } = require('../middleware/auth');

// POST /bookings — CONCURRENCY-SAFE booking
// Strategy: BEGIN transaction → SELECT slot FOR UPDATE (acquires row lock) →
//           check status → UPDATE status → INSERT booking → COMMIT
// If two requests arrive simultaneously, one gets the lock; the other waits,
// then sees status='booked' and returns 409. The UNIQUE constraint on
// bookings.slot_id is a second safety net.
router.post('/', requireAuth, async (req, res) => {
  const { slot_id } = req.body;
  if (!slot_id) return res.status(400).json({ error: 'slot_id is required' });

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Lock the row — any concurrent transaction hitting this slot will wait here
    const slotRes = await client.query(
      'SELECT id, status, venue_id, date, start_time, end_time FROM slots WHERE id = $1 FOR UPDATE',
      [slot_id]
    );

    if (!slotRes.rows.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Slot not found' });
    }

    const slot = slotRes.rows[0];

    if (slot.status === 'booked') {
      await client.query('ROLLBACK');
      return res.status(409).json({
        error: 'Slot already booked',
        message: 'Sorry, this slot was just taken. Please choose another.',
      });
    }

    await client.query("UPDATE slots SET status = 'booked' WHERE id = $1", [slot_id]);
    const bookingRes = await client.query(
      'INSERT INTO bookings (slot_id, user_id) VALUES ($1, $2) RETURNING *',
      [slot_id, req.user.id]
    );

    await client.query('COMMIT');

    res.status(201).json({
      message: 'Booking confirmed!',
      booking: { ...bookingRes.rows[0], slot },
    });
  } catch (err) {
    await client.query('ROLLBACK');
    if (err.code === '23505') {
      return res.status(409).json({
        error: 'Slot already booked',
        message: 'Sorry, this slot was just taken. Please choose another.',
      });
    }
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    client.release();
  }
});

// DELETE /bookings/:id — cancel booking
router.delete('/:id', requireAuth, async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const bookingRes = await client.query(
      'SELECT * FROM bookings WHERE id = $1 FOR UPDATE',
      [req.params.id]
    );
    if (!bookingRes.rows.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Booking not found' });
    }
    if (bookingRes.rows[0].user_id !== req.user.id) {
      await client.query('ROLLBACK');
      return res.status(403).json({ error: 'You can only cancel your own bookings' });
    }
    await client.query('DELETE FROM bookings WHERE id = $1', [req.params.id]);
    await client.query("UPDATE slots SET status = 'available' WHERE id = $1", [bookingRes.rows[0].slot_id]);
    await client.query('COMMIT');
    res.json({ message: 'Booking cancelled', booking_id: parseInt(req.params.id) });
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    client.release();
  }
});

module.exports = router;
