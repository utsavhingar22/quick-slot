const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

app.use((req, _, next) => {
  console.log(`${req.method} ${req.path} [user: ${req.headers['x-user-id'] || 'none'}]`);
  next();
});

app.get('/health', (_, res) => res.json({ status: 'ok', ts: new Date() }));
app.use('/venues', require('./routes/venues'));
app.use('/bookings', require('./routes/bookings'));
app.use('/users', require('./routes/users'));

app.use((_, res) => res.status(404).json({ error: 'Not found' }));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`QuickSlot server running on :${PORT}`));
