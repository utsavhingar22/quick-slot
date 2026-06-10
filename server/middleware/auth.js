const USERS = {
  user_001: { id: 'user_001', name: 'Akriti', email: 'akriti@quickslot.com' },
  user_002: { id: 'user_002', name: 'Utsav', email: 'utsav@quickslot.com' },
  user_003: { id: 'user_003', name: 'Rahul', email: 'rahul@quickslot.com' },
};

function requireAuth(req, res, next) {
  const userId = req.headers['x-user-id'];
  if (!userId || !USERS[userId]) {
    return res.status(401).json({ error: 'Unauthorized. Use X-User-Id header: user_001 / user_002 / user_003' });
  }
  req.user = USERS[userId];
  next();
}

module.exports = { requireAuth, USERS };
