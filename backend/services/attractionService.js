const attractions = require('../repositories/attractionRepository');

function listAttractions() {
  return attractions.list();
}

module.exports = { listAttractions };
