const { listAttractions } = require('../services/attractionService');

async function list(req, res) {
  try {
    res.json(await listAttractions());
  } catch (error) {
    console.error('Attraction retrieval error:', error);
    res.status(500).json({ message: 'Failed to retrieve attractions' });
  }
}

module.exports = { list };
