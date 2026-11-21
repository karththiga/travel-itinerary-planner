const regionalAttractions = require('../data/regionalAttractions.json');
const attractions = require('../repositories/attractionRepository');

function listAttractions() {
  return attractions.list();
}

function ensureRegionalAttractions() {
  return attractions.insertMissing(regionalAttractions);
}

module.exports = { listAttractions, ensureRegionalAttractions };
