const service = require('../services/recommendationService');

async function recommend(req, res) {
  const preferences = service.readPreferences(req.body);
  if (!preferences) return res.status(400).json({ message: 'Enter valid travel preferences.' });
  return res.json({ recommendations: await service.recommend(preferences) });
}

async function route(req, res) {
  const stops = await service.orderStops(req.body?.attractionIds);
  if (!stops) return res.status(400).json({ message: 'Choose valid attractions for your route.' });
  return res.json({ stops });
}

function handleError(error, req, res, next) {
  console.error('Trip planning request failed:', error.name);
  return res.status(503).json({ message: 'Trip planning is temporarily unavailable. Please try again.' });
}

module.exports = { recommend, route, handleError };
