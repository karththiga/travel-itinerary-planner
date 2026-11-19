const attempts = new Map();
let resetAt = Date.now() + 60_000;

function limitAttempts(req, res, next) {
  if (Date.now() >= resetAt) {
    attempts.clear();
    resetAt = Date.now() + 60_000;
  }
  const count = attempts.get(req.ip) ?? 0;
  if (count >= 10 || (count === 0 && attempts.size >= 10000)) {
    res.set('Retry-After', String(Math.max(1, Math.ceil((resetAt - Date.now()) / 1000))));
    return res.status(429).json({ message: 'Too many attempts. Try again shortly.' });
  }
  attempts.set(req.ip, count + 1);
  next();
}

module.exports = limitAttempts;
