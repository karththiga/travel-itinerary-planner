const trips = require('../services/savedTripService');
const { readToken } = require('./authController');

async function list(req, res) {
  res.json({ trips: await trips.list(readToken(req)) });
}

async function save(req, res) {
  res.json({ trip: await trips.save(readToken(req), req.body) });
}

async function remove(req, res) {
  await trips.remove(readToken(req), req.params.id);
  res.sendStatus(204);
}

module.exports = { list, save, remove };
