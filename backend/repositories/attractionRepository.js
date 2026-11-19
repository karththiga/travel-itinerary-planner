const Attraction = require('../models/Attraction');

async function list() {
  const attractions = await Attraction.find().exec();
  return attractions.map((attraction) => attraction.toJSON());
}

module.exports = { list };
