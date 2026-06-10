/**
 * Generates hourly slots 06:00–22:00 for a venue+date if they don't exist.
 * Uses INSERT ON CONFLICT DO NOTHING — safe to call multiple times.
 *
 * Note: venueId and date come from validated server-side params (not user input),
 * so string interpolation is safe here.
 */
async function ensureSlotsExist(client, venueId, date) {
  const rows = [];
  for (let hour = 6; hour < 22; hour++) {
    const start = `${String(hour).padStart(2, '0')}:00`;
    const end = `${String(hour + 1).padStart(2, '0')}:00`;
    rows.push(`(${venueId}, '${date}', '${start}', '${end}')`);
  }
  await client.query(`
    INSERT INTO slots (venue_id, date, start_time, end_time)
    VALUES ${rows.join(', ')}
    ON CONFLICT (venue_id, date, start_time) DO NOTHING
  `);
}

module.exports = { ensureSlotsExist };
